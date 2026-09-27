"""Configurable LSTM classifier.

Default architecture (MooMoo reference):
    Input[T, F] -> LSTM(128) -> LSTM(256) -> LSTM(128) -> Dense(classes, softmax)
"""

from __future__ import annotations

import copy
from typing import Any

DEFAULT_MODEL_CONFIG: dict[str, Any] = {
    "lstm_units": [128, 256, 128],
    "dropout": 0.2,
    "recurrent_dropout": 0.0,
    "dense_units": [],
    "dense_activation": "relu",
    "dense_dropout": 0.3,
    "layer_norm": False,
    "optimizer": "adam",
    "learning_rate": 1e-3,
    "weight_decay": 1e-4,
    "loss": "categorical_crossentropy",
    "label_smoothing": 0.0,
    "batch_size": 32,
    "epochs": 100,
    "class_weight": "balanced",
    "early_stopping_patience": 15,
    "reduce_lr_patience": 6,
    "reduce_lr_factor": 0.5,
    "min_learning_rate": 1e-6,
    "seed": 42,
}

OPTIMIZERS = ("adam", "adamw", "rmsprop", "sgd", "nadam")
LOSSES = ("categorical_crossentropy", "sparse_categorical_crossentropy", "categorical_focal_crossentropy")


def merge_config(cfg: dict | None) -> dict:
    merged = copy.deepcopy(DEFAULT_MODEL_CONFIG)
    for k, v in (cfg or {}).items():
        if v is not None:
            merged[k] = v
    return validate_config(merged)


def validate_config(cfg: dict) -> dict:
    units = cfg["lstm_units"]
    if isinstance(units, int):
        units = [units]
    units = [int(u) for u in units]
    if not units or any(u < 4 or u > 2048 for u in units):
        raise ValueError("lstm_units : 1 à N couches de 4 à 2048 unités")
    cfg["lstm_units"] = units
    cfg["dense_units"] = [int(u) for u in (cfg.get("dense_units") or []) if int(u) > 0]
    for key in ("dropout", "recurrent_dropout", "dense_dropout", "label_smoothing"):
        cfg[key] = float(cfg[key])
        if not 0 <= cfg[key] < 1:
            raise ValueError(f"{key} doit être dans [0, 1)")
    cfg["learning_rate"] = float(cfg["learning_rate"])
    if not 1e-6 <= cfg["learning_rate"] <= 1:
        raise ValueError("learning_rate hors de [1e-6, 1]")
    cfg["batch_size"] = int(cfg["batch_size"])
    cfg["epochs"] = int(cfg["epochs"])
    if cfg["batch_size"] < 1 or cfg["epochs"] < 1:
        raise ValueError("batch_size et epochs doivent être >= 1")
    if cfg["optimizer"] not in OPTIMIZERS:
        raise ValueError(f"optimizer inconnu (attendu : {', '.join(OPTIMIZERS)})")
    if cfg["loss"] not in LOSSES:
        raise ValueError(f"loss inconnue (attendu : {', '.join(LOSSES)})")
    return cfg


def architecture_summary(cfg: dict, input_shape: tuple[int, int], num_classes: int) -> dict:
    layers = [{"type": "Input", "shape": list(input_shape)}]
    for i, u in enumerate(cfg["lstm_units"]):
        layers.append({"type": "LSTM", "units": u,
                       "return_sequences": i < len(cfg["lstm_units"]) - 1,
                       "dropout": cfg["dropout"]})
        if cfg.get("layer_norm"):
            layers.append({"type": "LayerNormalization"})
    for u in cfg["dense_units"]:
        layers.append({"type": "Dense", "units": u, "activation": cfg["dense_activation"]})
        if cfg["dense_dropout"]:
            layers.append({"type": "Dropout", "rate": cfg["dense_dropout"]})
    layers.append({"type": "Dense", "units": num_classes, "activation": "softmax"})
    return {"family": "lstm", "layers": layers,
            "text": " -> ".join(
                f"{l['type']}({l.get('units', '') or l.get('shape', '')})".replace("()", "")
                for l in layers)}


def build_model(cfg: dict, input_shape: tuple[int, int], num_classes: int):
    import tensorflow as tf
    from tensorflow import keras

    tf.random.set_seed(int(cfg.get("seed", 42)))
    inputs = keras.Input(shape=input_shape, name="landmarks")
    x = inputs
    n = len(cfg["lstm_units"])
    for i, units in enumerate(cfg["lstm_units"]):
        x = keras.layers.LSTM(
            units,
            return_sequences=i < n - 1,
            dropout=cfg["dropout"],
            recurrent_dropout=cfg["recurrent_dropout"],
            name=f"lstm_{i + 1}",
        )(x)
        if cfg.get("layer_norm"):
            x = keras.layers.LayerNormalization(name=f"ln_{i + 1}")(x)
    for i, units in enumerate(cfg["dense_units"]):
        x = keras.layers.Dense(units, activation=cfg["dense_activation"], name=f"dense_{i + 1}")(x)
        if cfg["dense_dropout"]:
            x = keras.layers.Dropout(cfg["dense_dropout"], name=f"dropout_{i + 1}")(x)
    outputs = keras.layers.Dense(num_classes, activation="softmax", name="probabilities")(x)
    model = keras.Model(inputs, outputs, name="moomoo_sign_lstm")

    lr = cfg["learning_rate"]
    opt = {
        "adam": lambda: keras.optimizers.Adam(lr),
        "adamw": lambda: keras.optimizers.AdamW(lr, weight_decay=cfg["weight_decay"]),
        "rmsprop": lambda: keras.optimizers.RMSprop(lr),
        "sgd": lambda: keras.optimizers.SGD(lr, momentum=0.9, nesterov=True),
        "nadam": lambda: keras.optimizers.Nadam(lr),
    }[cfg["optimizer"]]()

    if cfg["loss"] == "sparse_categorical_crossentropy":
        loss = keras.losses.SparseCategoricalCrossentropy()
    elif cfg["loss"] == "categorical_focal_crossentropy":
        loss = keras.losses.CategoricalFocalCrossentropy(label_smoothing=cfg["label_smoothing"])
    else:
        loss = keras.losses.CategoricalCrossentropy(label_smoothing=cfg["label_smoothing"])

    model.compile(optimizer=opt, loss=loss, metrics=["accuracy"])
    return model


def uses_sparse_labels(cfg: dict) -> bool:
    return cfg["loss"] == "sparse_categorical_crossentropy"
