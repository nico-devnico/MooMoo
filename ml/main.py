"""MooMoo ML service (FastAPI).

Training is NOT done here: the API only serves inference and status. Long
jobs are queued in public.training_jobs and run by `python -m moomoo_ml.worker`.
"""

from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, Form, Request, UploadFile
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse, Response
from contextlib import asynccontextmanager

from moomoo_ml import config, db
from moomoo_ml.compose_request import ComposeLandmarksRequest
from moomoo_ml.datasets.discovery import media_kind


@asynccontextmanager
async def _lifespan(_app: FastAPI):
    # Précharge le modèle d'épellation pour que le 1er appel client ne timeout pas.
    try:
        from moomoo_ml.fingerspell import registry
        from moomoo_ml.fingerspell.predictor import get_predictor

        registry.ensure_layout()
        warmup_ms = get_predictor().warmup()
        print(f"[fingerspell] modèle prêt (warmup {warmup_ms:.1f} ms)")
    except Exception as exc:
        print(f"[fingerspell] préchargement impossible : {exc}")
    yield


app = FastAPI(title="MooMoo ML", version="1.0.0", lifespan=_lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_cache = None


def _models():
    global _cache
    if _cache is None:
        from moomoo_ml.inference import ModelCache

        _cache = ModelCache()
    return _cache


def _module_available(name: str) -> bool:
    """True when [name] can actually be imported (find_spec lies for some wheels)."""
    if importlib.util.find_spec(name) is not None:
        return True
    try:
        importlib.import_module(name)
        return True
    except Exception:
        return False


def _unavailable(code: str, detail: str, status: int = 503, **extra) -> JSONResponse:
    body = {"ok": False, "error": code, "detail": detail, "message": detail, **extra}
    return JSONResponse(status_code=status, content=body)


@app.exception_handler(RequestValidationError)
async def _compose_validation(request: Request, exc: RequestValidationError):
    """Keep FastAPI's default 422 for every route except composition."""
    if request.url.path.rstrip("/") != "/compose-landmarks":
        return JSONResponse(status_code=422, content={"detail": jsonable_encoder(exc.errors())})
    parts: list[str] = []
    for err in exc.errors():
        loc = [
            str(item)
            for item in err.get("loc", [])
            if item != "body" and not isinstance(item, int)
        ]
        parts.append(".".join(loc) if loc else "body")
    field = parts[0] if parts else "body"
    detail = (
        "JSON invalide ou incomplet. Envoyez un objet avec clips "
        "(liste de {word, url}) ou text (phrase du dictionnaire)."
    )
    return _unavailable("invalid_request", detail, 422, field=field)


@app.get("/")
def root():
    """Avoid noisy 404s when a browser opens the ML port."""
    return RedirectResponse(url="/docs", status_code=307)


@app.get("/favicon.ico")
def favicon():
    return Response(status_code=204)


@app.get("/health")
def health():
    status = {
        "ok": True,
        "service": "moomoo-ml",
        "artifacts_dir": str(config.ARTIFACTS_DIR),
        "runtimes": {name: _module_available(name)
                     for name in ("tensorflow", "mediapipe", "cv2")},
    }
    # Modèle d'épellation ASL (lettres → phrases), hors registre production.
    try:
        from moomoo_ml.fingerspell.predictor import default_model_dir, get_predictor
        from moomoo_ml.fingerspell import registry

        pred = get_predictor()
        status["fingerspell"] = {
            "available": True,
            "runtime": pred.runtime,
            "classes": len(pred.labels),
            "model_dir": str(default_model_dir()),
            "active": registry.active_id(),
            "dataset_dir": str(registry.DATASET_DIR),
        }
    except Exception as exc:
        status["fingerspell"] = {"available": False, "detail": str(exc)}
    try:
        row = db.one(
            """SELECT
                 count(*) FILTER (WHERE status = 'queued') AS queued,
                 count(*) FILTER (WHERE status IN ('running', 'cancelling')) AS running,
                 max(heartbeat_at) AS last_heartbeat
               FROM public.training_jobs"""
        )
        status["queue"] = {k: (str(v) if k == "last_heartbeat" and v else v) for k, v in row.items()}
        status["database"] = "ok"
    except Exception as exc:
        status["database"] = f"indisponible : {exc}"
    return status


@app.post("/infer/spell")
async def infer_spell(
    file: UploadFile = File(...),
    session_id: Optional[str] = Form(None),
    threshold: Optional[float] = Form(0.55),
    reset: Optional[str] = Form(None),
    single_shot: Optional[str] = Form(None),
    hand_detected: Optional[str] = Form(None),
    live: Optional[str] = Form(None),
):
    """Épellation : image/clip → lettre + phrase.

    `hand_detected=false` → un seul « space » jusqu'au retour de la main.
    `live=true` → même sensibilité que l'import (hold=1).
    """
    from moomoo_ml.fingerspell.predictor import FingerspellUnavailable
    from moomoo_ml.fingerspell.service import classify_media

    data = await file.read()
    if not data:
        return _unavailable("no_input", "Média vide.", 422)

    hd_raw = (hand_detected or "").strip().lower()
    hd: bool | None
    if hd_raw in ("0", "false", "no", "off"):
        hd = False
    elif hd_raw in ("1", "true", "yes", "on"):
        hd = True
    else:
        hd = None

    try:
        result = classify_media(
            data,
            filename=file.filename or "frame.jpg",
            session_id=session_id or None,
            threshold=float(threshold or 0.55),
            reset=str(reset or "").lower() in ("1", "true", "yes"),
            single_shot=str(single_shot or "").lower() in ("1", "true", "yes"),
            hand_detected=hd,
            live=str(live or "").lower() in ("1", "true", "yes"),
        )
    except FingerspellUnavailable as exc:
        return _unavailable("fingerspell_unavailable", str(exc))
    except Exception as exc:
        return _unavailable("spell_failed", str(exc), 500)
    return result


@app.get("/fingerspell/models")
def fingerspell_models():
    """Liste les versions d'épellation et celle active."""
    from moomoo_ml.fingerspell import registry

    try:
        models = registry.list_versions()
        return {"ok": True, "active": registry.active_id(), "models": models}
    except Exception as exc:
        return _unavailable("fingerspell_registry", str(exc), 500)


@app.get("/fingerspell/models/{model_id}")
def fingerspell_model_detail(model_id: str):
    from moomoo_ml.fingerspell import registry

    try:
        return {"ok": True, "model": registry.describe(model_id)}
    except FileNotFoundError as exc:
        return _unavailable("not_found", str(exc), 404)
    except Exception as exc:
        return _unavailable("fingerspell_registry", str(exc), 500)


@app.post("/fingerspell/models/{model_id}/activate")
def fingerspell_activate(model_id: str):
    """Active une version d'épellation (recharge le prédicteur en mémoire)."""
    from moomoo_ml.fingerspell import registry
    from moomoo_ml.fingerspell.predictor import reload_predictor

    try:
        model = registry.set_active(model_id)
        pred = reload_predictor()
        pred.warmup()
        return {"ok": True, "model": model, "runtime": pred.runtime}
    except FileNotFoundError as exc:
        return _unavailable("not_found", str(exc), 404)
    except Exception as exc:
        return _unavailable("activate_failed", str(exc), 500)


@app.get("/fingerspell/train/status")
def fingerspell_train_status():
    """État du dernier / de l'entraînement fingerspell en cours."""
    from moomoo_ml.fingerspell import train_job

    return {"ok": True, **train_job.status()}


@app.post("/fingerspell/train")
def fingerspell_train(
    max_per_class: Optional[int] = Form(None),
    epochs: Optional[int] = Form(None),
):
    """Relance l'entraînement ASL (dataset/) en arrière-plan puis publie une version."""
    from moomoo_ml.fingerspell import train_job

    result = train_job.start(max_per_class=max_per_class, epochs=epochs)
    if not result.get("ok"):
        return JSONResponse(result, status_code=409)
    return result


_COMPOSE_STATUS = {
    "invalid_request": 422,
    "invalid_url": 422,
    "invalid_clip": 422,
    "unsupported_media": 422,
    "no_landmarks": 422,
    "unknown_word": 404,
    "not_found": 404,
    "download_failed": 502,
    "compose_failed": 500,
}


@app.post("/compose-landmarks")
async def compose_landmarks(payload: ComposeLandmarksRequest):
    """Text→sign: dictionary clips → Holistic landmarks → one sequence.

    Accepts `clips` (also `media` / `urls`), each item being `{word, url}` or
    an http(s) string. `url` may also be sent as `video_url` or `media_url`.
    `text` or `word` without a URL is resolved against the LSFB catalogue
    (`assets/dictionnaire/dataset_gifs_links.json`) then `public.signs`.

    `include_face` accepts a real boolean. The string `"false"` stays false.
    Returns `{frames, fps, segments, missing}` for `SignLandmarks.parse`.
    """
    from moomoo_ml.compose import compose_landmarks as _compose
    from moomoo_ml.compose_request import ComposeInputError, resolve_compose_request

    raw = payload.model_dump()
    try:
        job = resolve_compose_request(raw)
    except ComposeInputError as exc:
        return _unavailable(
            exc.code,
            exc.detail,
            exc.status,
            field=exc.field,
            missing=exc.missing,
        )

    if not _module_available("mediapipe"):
        return _unavailable(
            "mediapipe_missing",
            "MediaPipe n'est pas installé dans l'environnement ML. "
            "Installez les deps (`pip install -r requirements.txt`) puis relancez uvicorn.",
            503,
        )

    print(
        f"[compose] clips={len(job['clips'])} fps={job['fps']} "
        f"include_face={job['include_face']} unresolved={len(job['unresolved'])}"
    )
    try:
        result = _compose(
            {"clips": job["clips"]},
            fps=job["fps"],
            gap_frames=job["gap_frames"],
            blend_frames=job["blend_frames"],
            max_frames_per_clip=job["max_frames_per_clip"],
            include_face=job["include_face"],
        )
    except ValueError as exc:
        return _unavailable("invalid_request", str(exc), 422)
    except Exception as exc:
        print(f"[compose] internal error: {type(exc).__name__}: {exc}")
        return _unavailable("compose_failed", "La composition des landmarks a échoué.", 500)

    if job["unresolved"]:
        result.setdefault("missing", []).extend(job["unresolved"])
    if not result.get("ok"):
        status = _COMPOSE_STATUS.get(result.get("error") or "", 422)
        result.setdefault("message", result.get("detail") or "Impossible de composer la séquence.")
        print(f"[compose] failed error={result.get('error')} status={status}")
        return JSONResponse(status_code=status, content=result)
    return result


@app.post("/infer")
async def infer(
    file: Optional[UploadFile] = File(None),
    landmarks: Optional[str] = Form(None),
    language: Optional[str] = Form(None),
    hint: Optional[str] = Form(None),
    dataset: Optional[str] = Form(None),
    model_version: Optional[str] = Form(None),
):
    """Classifies a sign with the production model of [language].

    Input: either `landmarks` (JSON [frames, features], MediaPipe layout) or a
    video/GIF `file`. A single still image is not a sign and is refused.
    """
    import numpy as np

    from moomoo_ml.inference import NoProductionModel, landmarks_from_media

    # Image fixe → épellation ASL (lettres), pas le modèle de signes en mouvement.
    if file is not None:
        suffix = Path(file.filename or "clip.mp4").suffix.lower() or ".mp4"
        kind = media_kind(Path("x" + suffix))
        if kind == "image":
            from moomoo_ml.fingerspell.predictor import FingerspellUnavailable
            from moomoo_ml.fingerspell.service import classify_frame

            data = await file.read()
            try:
                spelled = classify_frame(data, session_id=None, threshold=0.55)
            except FingerspellUnavailable as exc:
                return _unavailable("fingerspell_unavailable", str(exc))
            return {
                "ok": True,
                "label": spelled["label"],
                "confidence": spelled["confidence"],
                "top": spelled["top"],
                "latency_ms": spelled["latency_ms"],
                "runtime": spelled["runtime"],
                "text": spelled["text"],
                "committed": spelled["committed"],
                "mode": "fingerspell",
                "dataset": "asl_alphabet",
                "model": spelled["model"],
                "language": language,
            }

    try:
        model = _models().get(language)
    except NoProductionModel as exc:
        return _unavailable("no_production_model", str(exc))
    except db.DbUnavailable as exc:
        return _unavailable("model_registry_unavailable", str(exc))

    if landmarks:
        try:
            raw = np.asarray(json.loads(landmarks), dtype=np.float32)
        except (ValueError, TypeError):
            return _unavailable("invalid_landmarks", "landmarks doit être un tableau JSON [frames, features]", 422)
    elif file is not None:
        suffix = Path(file.filename or "clip.mp4").suffix.lower() or ".mp4"
        kind = media_kind(Path("x" + suffix))
        if kind not in ("video", "gif"):
            return _unavailable(
                "sequence_required",
                "Un signe est un mouvement : envoyer une vidéo, un GIF ou une séquence de landmarks.",
                422,
            )
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            tmp.write(await file.read())
            path = Path(tmp.name)
        try:
            raw = landmarks_from_media(path, kind, model.layout, model.max_frames)
        finally:
            path.unlink(missing_ok=True)
    else:
        return _unavailable("no_input", "Aucune entrée : fichier vidéo/GIF ou landmarks attendus.", 422)

    if raw.ndim != 2 or raw.shape[0] == 0 or not raw.any():
        return _unavailable("no_landmarks", "Aucun geste détecté dans la séquence.", 422)
    try:
        prediction = model.classify(raw)
    except ValueError as exc:
        return _unavailable("invalid_landmarks", str(exc), 422)

    row = model.row
    return {
        "ok": True,
        **prediction,
        "dataset": row.get("dataset"),
        "model_version": row.get("version"),
        "language": row.get("language_code"),
        "model": {"id": row["id"], "name": row["name"], "version": row["version"],
                  "dataset": row.get("dataset")},
    }
