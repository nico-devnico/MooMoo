"""Job handlers run by the worker. Each one reads its inputs from the DB and
writes every result (progress, experiments, epochs, metrics, models) back."""

from __future__ import annotations

import random
import time
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

from . import artifacts, db
from .context import Cancelled, JobContext
from .data import PreparedData, prepare
from .datasets.analyzer import analyze_dataset, samples_for_training
from .datasets.source import resolve_source
from .evaluate import evaluate_split, keras_predictor
from .model import architecture_summary, merge_config
from .preprocessing.extract import extract_dataset
from .search import hyperband_schedule, sample_unique
from .train import load_best, train_experiment

DEFAULT_PREPROCESSING = {"include_face": False, "max_frames": 96, "model_complexity": 1,
                         "require_hands": True}


def _now() -> datetime:
    return datetime.now(timezone.utc)


# ---------------------------------------------------------------------------
# Dataset jobs
# ---------------------------------------------------------------------------
def _dataset_or_fail(job: dict) -> dict:
    if not job.get("dataset_id"):
        raise ValueError("Ce job n'est rattaché à aucun dataset.")
    dataset = db.get_dataset(job["dataset_id"])
    if not dataset:
        raise ValueError("Dataset introuvable (supprimé ?).")
    return dataset


def run_analyze(ctx: JobContext, job: dict) -> dict:
    dataset = _dataset_or_fail(job)
    db.update_dataset(dataset["id"], status="analyzing", error_message=None)
    try:
        root = resolve_source(dataset["source_type"], dataset["uri"],
                              lambda m: ctx.progress(1, m, force=True))
        ctx.log(f"Analyse de {root}")
        analysis = analyze_dataset(
            root,
            is_structured=dataset["is_structured"],
            is_labeled=dataset["is_labeled"],
            label_mapping=dataset.get("label_mapping") or {},
            media_format=dataset["media_format"],
            progress=lambda p, m: ctx.progress(p * 0.99, m),
            should_stop=ctx.should_stop,
        )
    except Exception as exc:
        db.update_dataset(dataset["id"], status="failed", error_message=str(exc)[:1000])
        raise
    db.update_dataset(dataset["id"], status="analyzed", analysis=analysis, error_message=None)
    for w in analysis["warnings"]:
        ctx.log(w, "warning")
    ctx.log(
        f"{analysis['files_total']} fichiers, {analysis['classes_count']} classes, "
        f"{analysis['samples_labeled']} échantillons étiquetés, {analysis['signers_count']} signataires"
    )
    return {"classes": analysis["classes_count"], "samples": analysis["samples_labeled"],
            "trainable": analysis["trainable"]}


def run_preprocess(ctx: JobContext, job: dict, dataset: dict | None = None,
                   prep: dict | None = None, weight: float = 100.0) -> dict:
    """[weight] is the share (in %) of the job's progress bar this step fills."""
    dataset = dataset or _dataset_or_fail(job)
    if not dataset.get("analysis"):
        ctx.log("Dataset jamais analysé : analyse préalable.")
        run_analyze(ctx, job)
        dataset = db.get_dataset(dataset["id"])
    if not dataset["analysis"].get("trainable"):
        raise ValueError(
            "Dataset non exploitable pour l'entraînement (au moins 2 classes étiquetées). "
            "Voir les avertissements de l'analyse."
        )
    prep = {**DEFAULT_PREPROCESSING, **(prep or job.get("config", {}).get("preprocessing") or {})}
    db.update_dataset(dataset["id"], status="preprocessing", error_message=None)
    try:
        root = resolve_source(dataset["source_type"], dataset["uri"])
        samples = samples_for_training(root, dataset)
        ctx.log(f"Extraction MediaPipe Holistic de {len(samples)} échantillon(s)")
        summary = extract_dataset(
            samples, root, dataset["id"], prep,
            progress=lambda p, m: ctx.progress(p * weight / 100, m),
            should_stop=ctx.should_stop,
        )
    except Exception as exc:
        db.update_dataset(dataset["id"], status="failed", error_message=str(exc)[:1000])
        raise
    summary["config"] = prep
    db.update_dataset(dataset["id"], status="ready", preprocessing=summary, error_message=None)
    ctx.log(f"{summary['samples']} séquences prêtes, {summary['rejected']} rejetée(s)")
    if summary["rejected"]:
        ctx.log(f"Exemples rejetés : {summary['rejected_examples'][:5]}", "warning")
    return summary


def _ensure_prepared(ctx: JobContext, job: dict, weight: float) -> tuple[dict, dict]:
    dataset = _dataset_or_fail(job)
    wanted = {**DEFAULT_PREPROCESSING, **(job.get("config", {}).get("preprocessing") or {})}
    current = (dataset.get("preprocessing") or {}).get("config")
    if dataset["status"] != "ready" or current != wanted:
        run_preprocess(ctx, job, dataset, wanted, weight)
        dataset = db.get_dataset(dataset["id"])
    return dataset, dataset["preprocessing"]


def _check_language(job: dict, dataset: dict) -> str:
    lang = job.get("language_code") or dataset["language_code"]
    if lang != dataset["language_code"]:
        raise ValueError(
            f"Le job vise {lang} mais le dataset est en {dataset['language_code']} : "
            "les langues ne sont jamais mélangées dans un modèle."
        )
    return lang


# ---------------------------------------------------------------------------
# Experiments
# ---------------------------------------------------------------------------
class EpochReporter:
    """Writes each epoch to ml_epoch_metrics and the running totals to the job."""

    def __init__(self, ctx: JobContext, exp: dict, exp_dir: Path, progress_of):
        self.ctx, self.exp, self.exp_dir, self.progress_of = ctx, exp, exp_dir, progress_of
        self.best_acc = exp.get("best_val_accuracy")
        self.best_loss = exp.get("best_val_loss")

    def __call__(self, epoch: int, logs: dict, lr: float, duration: float) -> None:
        db.record_epoch(self.exp["id"], epoch, logs, lr, duration)
        va, vl = logs.get("val_accuracy"), logs.get("val_loss")
        if va is not None and (self.best_acc is None or va > self.best_acc):
            self.best_acc = va
        if vl is not None and (self.best_loss is None or vl < self.best_loss):
            self.best_loss = vl
        db.update_experiment(self.exp["id"], current_epoch=epoch,
                             best_val_accuracy=self.best_acc, best_val_loss=self.best_loss)
        line = (f"{self.exp['code']} epoch {epoch}: loss={logs.get('loss', 0):.4f} "
                f"acc={logs.get('accuracy', 0):.4f} val_loss={vl if vl is None else round(vl, 4)} "
                f"val_acc={va if va is None else round(va, 4)} lr={lr:.2e}")
        artifacts.append_log(self.exp_dir, line)
        self.ctx.progress(self.progress_of(epoch), line, current_epoch=epoch,
                          total_epochs=self.exp.get("total_epochs"))


def _train_rung(ctx: JobContext, data: PreparedData, exp: dict, cfg: dict, target: int,
                progress_of) -> dict:
    exp_dir = artifacts.experiment_dir(exp["language_code"], exp["code"])
    if exp["status"] == "queued":
        db.update_experiment(exp["id"], status="running", started_at=_now(), total_epochs=target)
        exp = {**exp, "status": "running", "total_epochs": target}
    else:
        db.update_experiment(exp["id"], total_epochs=target, budget_epochs=target)
        exp = {**exp, "total_epochs": target}
    ctx.log(f"{exp['code']} : entraînement jusqu'à l'epoch {target}", experiment_id=exp["id"])
    t0 = time.perf_counter()
    outcome = train_experiment(
        data, cfg, exp_dir,
        target_epochs=target,
        on_epoch=EpochReporter(ctx, exp, exp_dir, progress_of),
        should_stop=ctx.should_stop,
        log=lambda m: ctx.log(f"{exp['code']} : {m}", experiment_id=exp["id"]),
    )
    elapsed = time.perf_counter() - t0
    previous = db.get_experiment(exp["id"])
    duration = (previous.get("duration_s") or 0) + elapsed
    db.update_experiment(exp["id"], duration_s=duration, params_count=outcome["params"],
                         budget_epochs=target, current_epoch=outcome["epochs_done"])
    if outcome["cancelled"]:
        db.update_experiment(exp["id"], status="cancelled", finished_at=_now())
        raise Cancelled()
    return {**outcome, "duration_s": duration}


def finalize_experiment(ctx: JobContext, data: PreparedData, exp: dict, cfg: dict,
                        dataset: dict) -> dict:
    """Evaluates the best checkpoint on val/test and writes every artifact."""
    exp_dir = artifacts.experiment_dir(exp["language_code"], exp["code"])
    model = load_best(exp_dir)
    model_path = exp_dir / "model.keras"
    model.save(model_path)
    predict = keras_predictor(model)
    val = evaluate_split(predict, data.x_val, data.y_val, data.labels)
    test = evaluate_split(predict, data.x_test, data.y_test, data.labels)
    reference = test or val
    history = db.epoch_history(exp["id"])
    arch = architecture_summary(cfg, data.input_shape, data.num_classes)

    np.savez_compressed(exp_dir / "test_data.npz", x=data.x_test, y=data.y_test,
                        x_val=data.x_val, y_val=data.y_val)
    artifacts.write_json(exp_dir, "labels.json", data.labels)
    artifacts.write_json(exp_dir, "preprocessing.json", data.preprocessing)
    artifacts.write_json(exp_dir, "history.json", history)
    artifacts.write_json(exp_dir, "confusion_matrix.json",
                         {"labels": data.labels, "matrix": reference["confusion_matrix"] if reference else []})
    metrics = {
        "validation": _strip(val),
        "test": _strip(test),
        "evaluated_on": "test" if test else ("validation" if val else None),
        "data": data.report,
    }
    artifacts.write_json(exp_dir, "metrics.json", metrics)
    metadata = {
        "experiment": exp["code"],
        "language": exp["language_code"],
        "dataset": {"id": dataset["id"], "name": dataset["name"], "uri": dataset["uri"]},
        "classes": data.labels,
        "input_shape": list(data.input_shape),
        "architecture": arch,
        "hyperparameters": cfg,
        "created_at": _now().isoformat(),
        "framework": _framework_versions(),
    }
    artifacts.write_json(exp_dir, "metadata.json", metadata)

    listing = artifacts.listing(exp_dir)
    db.update_experiment(
        exp["id"],
        status="completed",
        finished_at=_now(),
        metrics=metrics,
        per_class=reference["per_class"] if reference else None,
        confusion_matrix=reference["confusion_matrix"] if reference else None,
        labels=data.labels,
        model_size_bytes=model_path.stat().st_size,
        artifacts=listing,
    )
    if reference:
        ctx.log(
            f"{exp['code']} évalué sur {metrics['evaluated_on']} : "
            f"accuracy={reference['accuracy']:.4f} macro_f1={reference['macro_f1']:.4f}",
            experiment_id=exp["id"],
        )
    return {"metrics": metrics, "architecture": arch, "model_path": model_path}


def _strip(m: dict | None) -> dict | None:
    if m is None:
        return None
    return {k: v for k, v in m.items() if k not in ("per_class", "confusion_matrix")}


def _framework_versions() -> dict:
    import tensorflow as tf

    out = {"tensorflow": tf.__version__}
    try:
        import mediapipe as mp

        out["mediapipe"] = mp.__version__
    except Exception:
        pass
    return out


# ---------------------------------------------------------------------------
# Registry + TFLite
# ---------------------------------------------------------------------------
def register_model(ctx: JobContext, job: dict, exp: dict, dataset: dict) -> dict:
    exp = db.get_experiment(exp["id"])
    exp_dir = artifacts.experiment_dir(exp["language_code"], exp["code"])
    import json

    metadata = json.loads((exp_dir / "metadata.json").read_text(encoding="utf-8"))
    lang = exp["language_code"]
    stamp = _now().strftime("%Y%m%d-%H%M")
    model = db.insert_model(
        name=f"moomoo-{lang.lower()}-lstm",
        version=f"{lang.lower()}-{stamp}-{exp['code'].lower()}",
        dataset=dataset["name"][:120],
        description=f"LSTM {metadata['architecture']['text']} — {exp['code']}",
        language_code=lang,
        stage="evaluated",
        status="ready",
        is_active=False,
        experiment_id=exp["id"],
        dataset_id=dataset["id"],
        classes=metadata["classes"],
        architecture=metadata["architecture"],
        input_shape=metadata["input_shape"],
        hyperparameters=metadata["hyperparameters"],
        metrics=exp["metrics"],
        training_duration_s=exp.get("duration_s"),
        size_bytes=exp.get("model_size_bytes"),
        artifacts=exp.get("artifacts"),
        artifact_url=str(exp_dir / "model.keras"),
        created_by=job.get("requested_by"),
    )
    db.update_experiment(exp["id"], model_id=model["id"])
    test = (exp["metrics"] or {}).get("test") or {}
    db.execute(
        """INSERT INTO public.model_metrics (model_id, accuracy, latency_ms, dataset, notes)
           VALUES (%s, %s, %s, %s, %s)""",
        (model["id"], test.get("accuracy"), test.get("latency_ms_per_sample"), dataset["name"][:120],
         f"Évaluation réelle {exp['code']} ({(exp['metrics'] or {}).get('evaluated_on')})"),
    )
    ctx.log(f"Modèle {model['version']} enregistré (EVALUATED)")
    return model


def convert_to_tflite(ctx: JobContext, model_row: dict, quantization: str = "dynamic") -> dict:
    from tensorflow import keras

    from .tflite_export import benchmark, convert

    exp = db.get_experiment(model_row["experiment_id"]) if model_row.get("experiment_id") else None
    if not exp:
        raise ValueError("Ce modèle n'est lié à aucune expérience : artefacts introuvables.")
    exp_dir = artifacts.experiment_dir(exp["language_code"], exp["code"])
    model = keras.models.load_model(exp_dir / "model.keras")
    input_shape = tuple(model_row["input_shape"])
    ctx.log(f"Conversion TFLite ({quantization}) de {model_row['version']}")
    info = convert(model, input_shape, exp_dir / "model.tflite", quantization)
    data = np.load(exp_dir / "test_data.npz")
    x, y = (data["x"], data["y"]) if len(data["x"]) else (data["x_val"], data["y_val"])
    keras_probs = model.predict(x[:500], verbose=0) if len(x) else None
    bench = benchmark(exp_dir / "model.tflite", x, y, model_row["classes"], keras_probs)
    report = {**info, **{"benchmark": bench}}
    artifacts.write_json(exp_dir, "tflite_report.json", report)
    listing = artifacts.listing(exp_dir)
    storage = artifacts.mirror_to_storage(exp_dir, f"{exp['language_code']}/{exp['code']}")
    if storage:
        listing["storage"] = storage
    db.update_model(model_row["id"], tflite_size_bytes=info["size_bytes"], tflite_metrics=report,
                    artifacts=listing)
    db.update_experiment(exp["id"], artifacts=listing)
    ctx.log(
        f"TFLite : {info['size_bytes'] / 1024:.0f} Ko, "
        f"{'compatible mobile' if info['mobile_compatible'] else 'délégué Flex requis'}, "
        f"accuracy={bench.get('accuracy')}, latence moyenne={bench.get('latency_ms_mean', 0):.2f} ms"
    )
    return report


# ---------------------------------------------------------------------------
# Train / search
# ---------------------------------------------------------------------------
def run_train(ctx: JobContext, job: dict) -> dict:
    cfg_all = job.get("config") or {}
    dataset, prep = _ensure_prepared(ctx, job, weight=20)
    lang = _check_language(job, dataset)
    job = {**job, "language_code": lang}
    cfg = merge_config(cfg_all.get("model"))
    data = prepare(prep, cfg_all, seed=int(cfg["seed"]))
    for w in data.report["warnings"]:
        ctx.log(w, "warning")
    ctx.log(f"Données : train={len(data.x_train)} val={len(data.x_val)} test={len(data.x_test)}, "
            f"{data.num_classes} classes, entrée {list(data.input_shape)}")

    exp = db.create_experiment(job, {**cfg_all, "model": cfg}, budget_epochs=cfg["epochs"])
    db.update_job(job["id"], total_epochs=cfg["epochs"], language_code=lang)
    base = 20.0
    outcome = _train_rung(ctx, data, exp, cfg, cfg["epochs"],
                          lambda e: base + (e / cfg["epochs"]) * 65)
    if outcome["stopped_early"]:
        ctx.log(f"{exp['code']} : arrêt anticipé à l'epoch {outcome['epochs_done']}")
    ctx.progress(86, "Évaluation", force=True)
    final = finalize_experiment(ctx, data, exp, cfg, dataset)
    result = {"experiments": [exp["code"]], "best_experiment": exp["code"],
              "metrics": final["metrics"]["test"] or final["metrics"]["validation"]}
    if cfg_all.get("auto_register", True):
        model = register_model(ctx, job, exp, dataset)
        ctx.progress(92, "Conversion TensorFlow Lite", force=True)
        try:
            convert_to_tflite(ctx, model, cfg_all.get("quantization", "dynamic"))
        except Exception as exc:
            ctx.log(f"Conversion TFLite échouée : {exc}", "error")
        result["model_id"] = model["id"]
        db.update_job(job["id"], result_model_id=model["id"])
    return result


def run_search(ctx: JobContext, job: dict) -> dict:
    cfg_all = job.get("config") or {}
    search = cfg_all.get("search") or {}
    dataset, prep = _ensure_prepared(ctx, job, weight=10)
    lang = _check_language(job, dataset)
    job = {**job, "language_code": lang}
    base_cfg = merge_config(cfg_all.get("model"))
    data = prepare(prep, cfg_all, seed=int(base_cfg["seed"]))
    for w in data.report["warnings"]:
        ctx.log(w, "warning")

    max_epochs = int(search.get("max_epochs", 81))
    eta = int(search.get("eta", 3))
    brackets = hyperband_schedule(max_epochs, eta, search.get("max_trials"))
    total_budget = 0
    for b in brackets:
        prev = 0
        for rung in b.rungs:
            total_budget += rung.configs * (rung.epochs - prev)
            prev = rung.epochs
    ctx.log(f"Hyperband : {len(brackets)} bracket(s), "
            f"{sum(b.initial_configs for b in brackets)} configuration(s), budget {total_budget} epochs")
    db.update_job(job["id"], language_code=lang, total_epochs=total_budget)

    rng = random.Random(int(search.get("seed", base_cfg["seed"])))
    seen: set = set()
    done = {"epochs": 0}
    finished: list[dict] = []

    def score(e: dict) -> tuple:
        acc = e.get("best_val_accuracy")
        loss = e.get("best_val_loss")
        return (acc if acc is not None else -1, -(loss if loss is not None else 1e9))

    for bracket in brackets:
        configs = sample_unique(search.get("space") or {}, bracket.initial_configs, rng, base_cfg, seen)
        exps = [db.create_experiment(job, {**cfg_all, "model": c}, budget_epochs=bracket.rungs[0].epochs, rung=0)
                for c in configs]
        cfg_of = {e["id"]: c for e, c in zip(exps, configs)}
        survivors = exps
        prev_epochs = 0
        for i, rung in enumerate(bracket.rungs):
            for e in survivors:
                ctx.check_cancel()
                start_done = done["epochs"]
                span = rung.epochs - prev_epochs

                def progress_of(epoch, start_done=start_done, prev=prev_epochs):
                    return 10 + 80 * min(1.0, (start_done + epoch - prev) / max(total_budget, 1))

                db.update_experiment(e["id"], rung=i)
                _train_rung(ctx, data, e, merge_config(cfg_of[e["id"]]), rung.epochs, progress_of)
                done["epochs"] = start_done + span
            refreshed = sorted((db.get_experiment(e["id"]) for e in survivors), key=score, reverse=True)
            if i + 1 < len(bracket.rungs):
                keep = bracket.rungs[i + 1].configs
                for e in refreshed[keep:]:
                    db.update_experiment(e["id"], status="pruned", finished_at=_now())
                    ctx.log(f"{e['code']} élagué au palier {i} (val_acc={e.get('best_val_accuracy')})",
                            experiment_id=e["id"])
                survivors = refreshed[:keep]
            else:
                survivors = refreshed
            prev_epochs = rung.epochs
        for e in survivors:
            finalize_experiment(ctx, data, e, merge_config(cfg_of[e["id"]]), dataset)
            finished.append(db.get_experiment(e["id"]))

    ranked = sorted(finished, key=score, reverse=True)
    best = ranked[0] if ranked else None
    result = {"experiments": [e["code"] for e in finished], "best_experiment": best and best["code"],
              "brackets": [[(r.configs, r.epochs) for r in b.rungs] for b in brackets]}
    if best:
        ctx.log(f"Meilleure expérience : {best['code']} (val_acc={best.get('best_val_accuracy')})")
        result["metrics"] = (best.get("metrics") or {}).get("test") or (best.get("metrics") or {}).get("validation")
        if cfg_all.get("auto_register", True):
            model = register_model(ctx, job, best, dataset)
            ctx.progress(93, "Conversion TensorFlow Lite", force=True)
            try:
                convert_to_tflite(ctx, model, cfg_all.get("quantization", "dynamic"))
            except Exception as exc:
                ctx.log(f"Conversion TFLite échouée : {exc}", "error")
            result["model_id"] = model["id"]
            db.update_job(job["id"], result_model_id=model["id"])
    return result


def run_evaluate(ctx: JobContext, job: dict) -> dict:
    """Registers a finished experiment in the model registry, then converts it."""
    exp_id = (job.get("config") or {}).get("experiment_id")
    exp = db.get_experiment(exp_id) if exp_id else None
    if not exp or exp["status"] != "completed":
        raise ValueError("Seule une expérience terminée (completed) peut être enregistrée.")
    if exp.get("model_id"):
        raise ValueError("Cette expérience est déjà enregistrée dans le registre.")
    dataset = db.get_dataset(exp["dataset_id"]) if exp.get("dataset_id") else None
    if not dataset:
        raise ValueError("Le dataset de cette expérience n'existe plus.")
    model = register_model(ctx, job, exp, dataset)
    db.update_job(job["id"], result_model_id=model["id"], language_code=exp["language_code"])
    report = convert_to_tflite(ctx, model, (job.get("config") or {}).get("quantization", "dynamic"))
    return {"model_id": model["id"], "tflite": report.get("benchmark")}


def run_convert(ctx: JobContext, job: dict) -> dict:
    cfg = job.get("config") or {}
    model = db.get_model(cfg.get("model_id") or job.get("model_id") or "")
    if not model:
        raise ValueError("Modèle introuvable.")
    report = convert_to_tflite(ctx, model, cfg.get("quantization", "dynamic"))
    return {"model_id": model["id"], "tflite": report.get("benchmark"),
            "size_bytes": report["size_bytes"], "mobile_compatible": report["mobile_compatible"]}


HANDLERS = {
    "analyze": run_analyze,
    "preprocess": run_preprocess,
    "train": run_train,
    "search": run_search,
    "evaluate": run_evaluate,
    "convert": run_convert,
}
