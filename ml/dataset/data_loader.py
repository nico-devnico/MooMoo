"""Chargement, split stratifié et pipelines tf.data pour ASL."""

from __future__ import annotations

import random
from pathlib import Path
from typing import Iterator

import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

import config

# ±10° approx. (factor of 2π) — poignet légèrement incliné en live.
_ROTATE = tf.keras.layers.RandomRotation(factor=0.03, fill_mode="nearest")


def collect_filepaths(
    train_dir: Path = config.TRAIN_DIR,
    max_per_class: int = config.MAX_PER_CLASS,
    seed: int = config.RANDOM_SEED,
) -> tuple[list[str], list[int]]:
    """Collecte stratifiée des chemins d'images et labels."""
    rng = random.Random(seed)
    paths: list[str] = []
    labels: list[int] = []

    for cls in config.CLASSES:
        folder = train_dir / cls
        if not folder.is_dir():
            raise FileNotFoundError(f"Dossier classe manquant : {folder}")
        files = sorted(
            p for p in folder.iterdir()
            if p.suffix.lower() in {".jpg", ".jpeg", ".png"}
        )
        if max_per_class and len(files) > max_per_class:
            files = rng.sample(files, max_per_class)
        idx = config.CLASS_TO_IDX[cls]
        for f in files:
            paths.append(str(f))
            labels.append(idx)

    return paths, labels


def stratified_splits(
    paths: list[str],
    labels: list[int],
    val_split: float = config.VAL_SPLIT,
    test_split: float = config.TEST_SPLIT,
    seed: int = config.RANDOM_SEED,
) -> dict[str, tuple[list[str], list[int]]]:
    """Train / val / test stratifiés."""
    paths = np.array(paths)
    labels = np.array(labels)

    train_paths, temp_paths, train_y, temp_y = train_test_split(
        paths,
        labels,
        test_size=val_split + test_split,
        stratify=labels,
        random_state=seed,
    )
    relative_test = test_split / (val_split + test_split)
    val_paths, test_paths, val_y, test_y = train_test_split(
        temp_paths,
        temp_y,
        test_size=relative_test,
        stratify=temp_y,
        random_state=seed,
    )
    return {
        "train": (train_paths.tolist(), train_y.tolist()),
        "val": (val_paths.tolist(), val_y.tolist()),
        "test": (test_paths.tolist(), test_y.tolist()),
    }


def _decode_image(path: tf.Tensor, label: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
    raw = tf.io.read_file(path)
    img = tf.io.decode_image(raw, channels=config.CHANNELS, expand_animations=False)
    img = tf.image.convert_image_dtype(img, tf.float32)  # [0, 1]
    img = tf.image.resize(img, [config.IMG_SIZE, config.IMG_SIZE])
    # Remettre en [0, 255] : Rescaling(1/255) est dans le modèle
    img = img * 255.0
    return img, label


def _augment(img: tf.Tensor, label: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
    """Augmentation orientée caméra live (fermeture du gap import ↔ webcam).

    Les images importées sont des crops nets type dataset ; le live a
    luminosité irrégulière, flou, JPEG, main légèrement décentrée.
    Pas de flip horizontal : un signe miroir n'est pas le même label.
    """
    # Photométrie large (webcam / pièce / neon).
    img = tf.image.random_brightness(img, max_delta=55.0)
    img = tf.image.random_contrast(img, lower=0.65, upper=1.40)
    img = tf.image.random_saturation(img, lower=0.70, upper=1.35)
    img = tf.image.random_hue(img, max_delta=0.04)
    # Gamma soft (ombres / sur-exposition).
    if tf.random.uniform([]) < 0.50:
        gamma = tf.random.uniform([], 0.70, 1.35)
        img01 = tf.clip_by_value(img / 255.0, 0.0, 1.0)
        img = tf.pow(img01, gamma) * 255.0

    # Petite rotation : poignet pas toujours droit face caméra.
    if tf.random.uniform([]) < 0.55:
        img = _ROTATE(img)

    # Translation / zoom (main pas parfaitement cadrée après crop peau).
    if tf.random.uniform([]) < 0.80:
        pad = tf.random.uniform([], minval=3, maxval=18, dtype=tf.int32)
        img = tf.image.resize_with_crop_or_pad(
            img, config.IMG_SIZE + pad, config.IMG_SIZE + pad
        )
        img = tf.image.random_crop(img, [config.IMG_SIZE, config.IMG_SIZE, config.CHANNELS])

    # Flou / compression webcam (YUV → JPEG → resize 256 → 64).
    if tf.random.uniform([]) < 0.55:
        side = tf.random.uniform([], minval=28, maxval=52, dtype=tf.int32)
        small = tf.image.resize(img, [side, side], method=tf.image.ResizeMethod.BILINEAR)
        img = tf.image.resize(
            small, [config.IMG_SIZE, config.IMG_SIZE], method=tf.image.ResizeMethod.BILINEAR
        )
    if tf.random.uniform([]) < 0.35:
        # Flou boîte 3×3 approximé par average pool.
        x = img[None, ...]
        x = tf.nn.avg_pool2d(x, ksize=3, strides=1, padding="SAME")
        img = x[0]

    # Ombre / vignette partielle (éclairage latéral).
    if tf.random.uniform([]) < 0.40:
        yy, xx = tf.meshgrid(
            tf.linspace(-1.0, 1.0, config.IMG_SIZE),
            tf.linspace(-1.0, 1.0, config.IMG_SIZE),
            indexing="ij",
        )
        cx = tf.random.uniform([], -0.45, 0.45)
        cy = tf.random.uniform([], -0.45, 0.45)
        rad = tf.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
        shade = tf.clip_by_value(1.15 - 0.55 * rad, 0.55, 1.15)
        img = img * shade[..., None]

    # Bruit capteur.
    if tf.random.uniform([]) < 0.55:
        noise = tf.random.normal(tf.shape(img), mean=0.0, stddev=12.0)
        img = img + noise

    img = tf.clip_by_value(img, 0.0, 255.0)
    return img, label


def make_dataset(
    paths: list[str],
    labels: list[int],
    batch_size: int = config.BATCH_SIZE,
    shuffle: bool = False,
    augment: bool = False,
    seed: int = config.RANDOM_SEED,
) -> tf.data.Dataset:
    ds = tf.data.Dataset.from_tensor_slices((paths, np.array(labels, dtype=np.int32)))
    if shuffle:
        ds = ds.shuffle(buffer_size=min(len(paths), 10_000), seed=seed, reshuffle_each_iteration=True)
    ds = ds.map(_decode_image, num_parallel_calls=tf.data.AUTOTUNE)
    if augment and config.AUGMENT:
        ds = ds.map(_augment, num_parallel_calls=tf.data.AUTOTUNE)
    ds = ds.batch(batch_size).prefetch(tf.data.AUTOTUNE)
    return ds


def load_holdout_test_images(
    test_dir: Path = config.TEST_DIR,
) -> tuple[np.ndarray, list[str], list[int | None]]:
    """Charge le dossier asl_alphabet_test (1 image / classe, sans 'del')."""
    images = []
    names = []
    labels: list[int | None] = []
    for p in sorted(test_dir.glob("*_test.jpg")):
        stem = p.stem.replace("_test", "")
        raw = tf.io.read_file(str(p))
        img = tf.io.decode_jpeg(raw, channels=config.CHANNELS)
        img = tf.image.resize(img, [config.IMG_SIZE, config.IMG_SIZE])
        img = tf.cast(img, tf.float32)
        images.append(img.numpy())
        names.append(stem)
        labels.append(config.CLASS_TO_IDX.get(stem))
    return np.stack(images, axis=0), names, labels


def iter_class_counts(labels: list[int]) -> Iterator[tuple[str, int]]:
    counts = np.bincount(labels, minlength=config.NUM_CLASSES)
    for i, c in enumerate(counts):
        yield config.IDX_TO_CLASS[i], int(c)
