"""Media -> frames -> MediaPipe Holistic -> raw landmark sequences, with a disk cache."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Callable, Iterator

import numpy as np

from .. import config
from ..datasets.analyzer import file_fingerprint
from ..datasets.discovery import Sample
from .features import (
    FACE_POINTS,
    HAND_POINTS,
    POSE_POINTS,
    Layout,
    hands_present,
)

DEFAULT_MAX_FRAMES = 96


def iter_frames(sample: Sample, max_frames: int) -> Iterator[np.ndarray]:
    """RGB uint8 frames, evenly subsampled to at most [max_frames]."""
    if sample.kind == "video":
        import cv2

        cap = cv2.VideoCapture(str(sample.files[0]))
        try:
            total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
            keep = _keep_indices(total, max_frames) if total > 0 else None
            i = 0
            while True:
                ok, frame = cap.read()
                if not ok:
                    break
                if keep is None or i in keep:
                    yield cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                i += 1
        finally:
            cap.release()
        return

    from PIL import Image, ImageSequence

    if sample.kind == "gif":
        with Image.open(sample.files[0]) as im:
            frames = [np.asarray(f.convert("RGB")) for f in ImageSequence.Iterator(im)]
        keep = _keep_indices(len(frames), max_frames)
        for i, f in enumerate(frames):
            if i in keep:
                yield f
        return

    paths = sample.files
    keep = _keep_indices(len(paths), max_frames)
    for i, p in enumerate(paths):
        if i in keep:
            with Image.open(p) as im:
                yield np.asarray(im.convert("RGB"))


def _keep_indices(total: int, max_frames: int) -> set[int]:
    if total <= max_frames:
        return set(range(total))
    return set(np.linspace(0, total - 1, num=max_frames).round().astype(int).tolist())


def results_to_vector(results, layout: Layout) -> np.ndarray:
    vec = np.zeros(layout.size, dtype=np.float32)
    if results.pose_landmarks:
        vec[layout.pose] = np.array(
            [[p.x, p.y, p.z, p.visibility] for p in results.pose_landmarks.landmark],
            dtype=np.float32,
        ).reshape(-1)[: POSE_POINTS * 4]
    if results.left_hand_landmarks:
        vec[layout.left_hand] = np.array(
            [[p.x, p.y, p.z] for p in results.left_hand_landmarks.landmark], dtype=np.float32
        ).reshape(-1)[: HAND_POINTS * 3]
    if results.right_hand_landmarks:
        vec[layout.right_hand] = np.array(
            [[p.x, p.y, p.z] for p in results.right_hand_landmarks.landmark], dtype=np.float32
        ).reshape(-1)[: HAND_POINTS * 3]
    if layout.include_face and results.face_landmarks:
        pts = np.array([[p.x, p.y, p.z] for p in results.face_landmarks.landmark], dtype=np.float32)
        vec[layout.face] = pts[:FACE_POINTS].reshape(-1)
    return vec


class HolisticExtractor:
    """Wraps one MediaPipe Holistic graph; reuse it across samples."""

    def __init__(self, layout: Layout, model_complexity: int = 1):
        import mediapipe as mp

        self._mp = mp
        self.layout = layout
        self.model_complexity = model_complexity
        self._video = None
        self._static = None

    def _graph(self, static: bool):
        holistic = self._mp.solutions.holistic
        if static:
            if self._static is None:
                self._static = holistic.Holistic(
                    static_image_mode=True,
                    model_complexity=self.model_complexity,
                    refine_face_landmarks=False,
                )
            return self._static
        # Tracking state must not leak between samples: new graph per sequence.
        if self._video is not None:
            self._video.close()
        self._video = holistic.Holistic(
            static_image_mode=False,
            model_complexity=self.model_complexity,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5,
        )
        return self._video

    def extract(self, sample: Sample, max_frames: int = DEFAULT_MAX_FRAMES) -> np.ndarray:
        graph = self._graph(static=sample.kind == "image")
        frames = [results_to_vector(graph.process(f), self.layout)
                  for f in iter_frames(sample, max_frames)]
        if not frames:
            return np.zeros((0, self.layout.size), dtype=np.float32)
        return np.stack(frames)

    def extract_frames(self, frames: list[np.ndarray]) -> np.ndarray:
        graph = self._graph(static=len(frames) == 1)
        return np.stack([results_to_vector(graph.process(f), self.layout) for f in frames])

    def close(self) -> None:
        for g in (self._video, self._static):
            if g is not None:
                g.close()


def cache_dir(dataset_id: str, prep: dict) -> Path:
    key = hashlib.sha1(json.dumps(
        {"face": prep.get("include_face", False), "max_frames": prep.get("max_frames", DEFAULT_MAX_FRAMES),
         "complexity": prep.get("model_complexity", 1)},
        sort_keys=True,
    ).encode()).hexdigest()[:10]
    path = config.CACHE_DIR / "features" / dataset_id / key
    path.mkdir(parents=True, exist_ok=True)
    return path


def extract_dataset(samples: list[Sample], root: Path, dataset_id: str, prep: dict, *,
                    progress: Callable[[float, str], None] | None = None,
                    should_stop: Callable[[], bool] | None = None) -> dict:
    """Extracts every sample once (cached on disk) and writes index.json."""
    layout = Layout(include_face=bool(prep.get("include_face", False)))
    max_frames = int(prep.get("max_frames", DEFAULT_MAX_FRAMES))
    require_hands = bool(prep.get("require_hands", True))
    out_dir = cache_dir(dataset_id, prep)
    index_path = out_dir / "index.json"
    previous = {}
    if index_path.exists():
        previous = {e["rel"]: e for e in json.loads(index_path.read_text(encoding="utf-8"))["samples"]}

    extractor = HolisticExtractor(layout, int(prep.get("model_complexity", 1)))
    entries, rejected = [], []
    try:
        for i, sample in enumerate(samples):
            if should_stop and should_stop():
                raise InterruptedError("prétraitement annulé")
            name = hashlib.sha1(sample.rel.encode()).hexdigest()[:20] + ".npy"
            npy = out_dir / name
            fingerprint = previous.get(sample.rel, {}).get("fingerprint") or file_fingerprint(sample.files[0])
            if npy.exists():
                seq = np.load(npy)
            else:
                try:
                    seq = extractor.extract(sample, max_frames)
                except Exception as exc:
                    rejected.append({"rel": sample.rel, "reason": f"extraction: {exc}"[:200]})
                    continue
                np.save(npy, seq)

            hand_frames = int(hands_present(seq, layout).sum()) if len(seq) else 0
            if len(seq) == 0 or not np.any(seq):
                rejected.append({"rel": sample.rel, "reason": "aucun landmark détecté"})
            elif require_hands and hand_frames == 0:
                rejected.append({"rel": sample.rel, "reason": "aucune main détectée"})
            else:
                entries.append({
                    "rel": sample.rel,
                    "file": name,
                    "label": sample.label,
                    "signer": sample.signer,
                    "split_hint": sample.split_hint,
                    "frames": int(len(seq)),
                    "hand_ratio": round(hand_frames / max(len(seq), 1), 3),
                    "fingerprint": fingerprint,
                })
            if progress and (i % 5 == 0 or i == len(samples) - 1):
                progress((i + 1) / max(len(samples), 1) * 100,
                         f"Landmarks {i + 1}/{len(samples)}")
    finally:
        extractor.close()

    summary = {
        "dir": str(out_dir),
        "layout": layout.describe(),
        "max_frames": max_frames,
        "require_hands": require_hands,
        "samples": len(entries),
        "rejected": len(rejected),
        "rejected_examples": rejected[:50],
        "classes": sorted({e["label"] for e in entries}),
        "mean_frames": round(float(np.mean([e["frames"] for e in entries])), 2) if entries else 0,
        "mean_hand_ratio": round(float(np.mean([e["hand_ratio"] for e in entries])), 3) if entries else 0,
    }
    index_path.write_text(json.dumps({"summary": summary, "samples": entries}, ensure_ascii=False),
                          encoding="utf-8")
    return summary


def load_index(prep_summary: dict) -> tuple[list[dict], Path]:
    out_dir = Path(prep_summary["dir"])
    data = json.loads((out_dir / "index.json").read_text(encoding="utf-8"))
    return data["samples"], out_dir
