"""Cached landmarks -> split, augmented tensors ready for training."""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from .augmentation import AugmentConfig, augment_training_set
from .preprocessing.extract import load_index
from .preprocessing.features import Layout, to_model_input
from .split import split_entries

DEFAULT_SEQUENCE_LENGTH = 30


@dataclass
class PreparedData:
    x_train: np.ndarray
    y_train: np.ndarray
    x_val: np.ndarray
    y_val: np.ndarray
    x_test: np.ndarray
    y_test: np.ndarray
    labels: list[str]
    layout: Layout
    sequence_length: int
    preprocessing: dict
    report: dict = field(default_factory=dict)

    @property
    def input_shape(self) -> tuple[int, int]:
        return (self.sequence_length, self.layout.size)

    @property
    def num_classes(self) -> int:
        return len(self.labels)


def prepare(prep_summary: dict, cfg: dict, *, seed: int = 42) -> PreparedData:
    entries, folder = load_index(prep_summary)
    if not entries:
        raise ValueError("Aucun échantillon exploitable après prétraitement.")
    layout = Layout(include_face=bool(prep_summary["layout"]["include_face"]))
    length = int(cfg.get("sequence_length", DEFAULT_SEQUENCE_LENGTH))
    normalize = bool(cfg.get("normalize", True))

    min_per_class = int(cfg.get("min_samples_per_class", 2))
    counts: dict[str, int] = {}
    for e in entries:
        counts[e["label"]] = counts.get(e["label"], 0) + 1
    dropped = sorted(k for k, v in counts.items() if v < min_per_class)
    entries = [e for e in entries if e["label"] not in dropped]
    labels = sorted({e["label"] for e in entries})
    if len(labels) < 2:
        raise ValueError(
            "Au moins 2 classes avec suffisamment d'exemples sont nécessaires "
            f"(min {min_per_class} par classe)."
        )
    label_index = {lab: i for i, lab in enumerate(labels)}

    x = np.stack([
        to_model_input(np.load(folder / e["file"]), layout, length, do_normalize=normalize)
        for e in entries
    ])
    y = np.array([label_index[e["label"]] for e in entries], dtype=np.int32)

    splits, split_report = split_entries(
        entries, cfg.get("split"), seed=seed, strategy=cfg.get("split_strategy", "auto")
    )
    x_train, y_train = x[splits["train"]], y[splits["train"]]
    x_val, y_val = x[splits["val"]], y[splits["val"]]
    x_test, y_test = x[splits["test"]], y[splits["test"]]
    if len(x_val) == 0 and len(x_train) > 4:
        # Tiny datasets: carve a validation set out of train rather than none.
        n_val = max(1, len(x_train) // 10)
        x_val, y_val = x_train[-n_val:], y_train[-n_val:]
        x_train, y_train = x_train[:-n_val], y_train[:-n_val]
        split_report.setdefault("warnings", []).append(
            "Validation vide : 10 % de l'entraînement utilisé comme validation."
        )

    aug_cfg = AugmentConfig.from_dict(cfg.get("augmentation"))
    real_train = len(x_train)
    x_train, y_train, aug_report = augment_training_set(x_train, y_train, aug_cfg, layout, seed)

    warnings = list(split_report.get("warnings", []))
    signers = {e["signer"] for e in entries if e.get("signer")}
    if aug_report.get("added"):
        warnings.append(
            f"{aug_report['added']} séquence(s) augmentée(s) ajoutée(s) à l'entraînement "
            f"({real_train} réelles) : l'augmentation ne remplace pas de nouveaux signataires."
        )
        if len(signers) < 3:
            warnings.append(
                "Diversité réelle faible (moins de 3 signataires) : les exemples augmentés "
                "restent des variations des mêmes personnes."
            )
    if dropped:
        warnings.append(f"{len(dropped)} classe(s) écartée(s) (moins de {min_per_class} exemples).")

    return PreparedData(
        x_train=x_train.astype(np.float32), y_train=y_train,
        x_val=x_val.astype(np.float32), y_val=y_val,
        x_test=x_test.astype(np.float32), y_test=y_test,
        labels=labels,
        layout=layout,
        sequence_length=length,
        preprocessing={
            "sequence_length": length,
            "normalize": normalize,
            "trim_inactive": True,
            "fill_gaps_max": 4,
            "layout": layout.describe(),
            "max_frames": prep_summary.get("max_frames"),
            "extractor": "mediapipe.holistic",
        },
        report={
            "split": split_report,
            "augmentation": aug_report,
            "real_train_samples": real_train,
            "classes_dropped": dropped,
            "signers": len(signers),
            "warnings": warnings,
        },
    )
