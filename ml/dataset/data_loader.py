"""Chargement, split stratifié et pipelines tf.data pour ASL."""

from __future__ import annotations

import random
from pathlib import Path
from typing import Iterator

import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

import config


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
    """Augmentation légère : ne pas retourner horizontalement (signe ≠ miroir)."""
    img = tf.image.random_brightness(img, max_delta=25.0)
    img = tf.image.random_contrast(img, lower=0.85, upper=1.15)
    # Légère translation via crop/pad
    if tf.random.uniform([]) < 0.5:
        img = tf.image.resize_with_crop_or_pad(
            img, config.IMG_SIZE + 6, config.IMG_SIZE + 6
        )
        img = tf.image.random_crop(img, [config.IMG_SIZE, config.IMG_SIZE, config.CHANNELS])
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
