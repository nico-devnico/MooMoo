"""Turn a dataset folder into a list of samples with label and signer.

Supported layouts, detected automatically:
  - metadata file at the root (labels.csv / metadata.csv / annotations.csv /
    labels.json) with path, label and optionally signer and split columns;
  - root/<label>/<file>                      one media file per sample;
  - root/<split>/<label>/<file>              split folders are ignored as labels;
  - root/<label>/<sample>/<frame images>     a folder of frames is one sample;
  - signer ids from path components such as "signer03", "subject_2", "P07".

Labels are never guessed for an unlabeled dataset: they only come from the
admin-provided label_mapping (relative path or folder prefix -> label).
"""

from __future__ import annotations

import csv
import json
import re
from dataclasses import dataclass, field
from pathlib import Path

IMAGE_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
GIF_EXT = {".gif"}
VIDEO_EXT = {".mp4", ".avi", ".mov", ".mkv", ".webm", ".m4v", ".mpg", ".mpeg"}
MEDIA_EXT = IMAGE_EXT | GIF_EXT | VIDEO_EXT

SPLIT_NAMES = {"train", "training", "val", "valid", "validation", "dev", "test", "testing"}
METADATA_FILES = ("labels.csv", "metadata.csv", "annotations.csv", "labels.json", "metadata.json")

SIGNER_RE = re.compile(
    r"(?:^|[_\-\s.])(?:signer|subject|participant|person|speaker|user|p|s)[_\-]?(\d{1,4})(?=$|[_\-\s.])",
    re.IGNORECASE,
)
PATH_COLUMNS = ("path", "file", "filename", "file_name", "video", "media", "relative_path")
LABEL_COLUMNS = ("label", "gloss", "sign", "class", "word", "category")
SIGNER_COLUMNS = ("signer", "signer_id", "participant", "subject", "person", "speaker")
SPLIT_COLUMNS = ("split", "subset", "partition")


@dataclass
class Sample:
    rel: str
    kind: str  # image | frames | gif | video
    files: list[Path]
    label: str | None = None
    signer: str | None = None
    split_hint: str | None = None
    meta: dict = field(default_factory=dict)


def media_kind(path: Path) -> str | None:
    ext = path.suffix.lower()
    if ext in IMAGE_EXT:
        return "image"
    if ext in GIF_EXT:
        return "gif"
    if ext in VIDEO_EXT:
        return "video"
    return None


def normalize_label(label: str) -> str:
    return re.sub(r"\s+", " ", str(label)).strip()


def find_signer(parts: list[str]) -> str | None:
    for part in parts:
        m = SIGNER_RE.search(Path(part).stem if "." in part else part)
        if m:
            return f"signer-{int(m.group(1))}"
    return None


def _mapping_label(rel: str, mapping: dict[str, str]) -> str | None:
    rel_norm = rel.replace("\\", "/").strip("/")
    best, best_len = None, -1
    for key, label in mapping.items():
        k = key.replace("\\", "/").strip("/")
        if (rel_norm == k or rel_norm.startswith(k + "/")) and len(k) > best_len:
            best, best_len = label, len(k)
    return normalize_label(best) if best else None


def _pick(row: dict, names: tuple[str, ...]) -> str | None:
    lower = {k.strip().lower(): v for k, v in row.items() if k}
    for name in names:
        value = lower.get(name)
        if value not in (None, ""):
            return str(value).strip()
    return None


def _read_metadata(root: Path) -> list[dict] | None:
    for name in METADATA_FILES:
        path = root / name
        if not path.exists():
            continue
        if path.suffix == ".csv":
            with open(path, newline="", encoding="utf-8-sig") as fh:
                sample = fh.read(4096)
                fh.seek(0)
                try:
                    dialect = csv.Sniffer().sniff(sample, delimiters=",;\t")
                except csv.Error:
                    dialect = csv.excel
                return list(csv.DictReader(fh, dialect=dialect))
        data = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            data = data.get("samples") or data.get("items") or [
                {"path": k, "label": v} for k, v in data.items()
            ]
        return list(data)
    return None


def list_media_files(root: Path) -> list[Path]:
    return sorted(
        p for p in root.rglob("*")
        if p.is_file() and p.suffix.lower() in MEDIA_EXT and not any(
            part.startswith(".") or part == "__MACOSX" for part in p.relative_to(root).parts
        )
    )


def discover_samples(root: Path, *, is_structured: bool = True, is_labeled: bool = True,
                     label_mapping: dict[str, str] | None = None,
                     media_format: str = "auto") -> list[Sample]:
    mapping = label_mapping or {}
    files = list_media_files(root)
    samples: list[Sample] = []

    metadata = _read_metadata(root) if is_labeled else None
    if metadata:
        by_rel = {p.relative_to(root).as_posix(): p for p in files}
        for row in metadata:
            rel = _pick(row, PATH_COLUMNS)
            if not rel:
                continue
            rel = rel.replace("\\", "/").lstrip("./")
            path = by_rel.get(rel) or (root / rel if (root / rel).exists() else None)
            if path is None:
                continue
            if path.is_dir():
                frames = sorted(p for p in path.iterdir() if p.suffix.lower() in IMAGE_EXT)
                if not frames:
                    continue
                kind, sample_files = "frames", frames
            else:
                kind = media_kind(path)
                if kind is None:
                    continue
                sample_files = [path]
            label = _mapping_label(rel, mapping) or _pick(row, LABEL_COLUMNS)
            samples.append(Sample(
                rel=rel,
                kind=kind,
                files=sample_files,
                label=normalize_label(label) if label else None,
                signer=_pick(row, SIGNER_COLUMNS) or find_signer(rel.split("/")),
                split_hint=(_pick(row, SPLIT_COLUMNS) or "").lower() or None,
            ))
        return _filter_format(samples, media_format)

    # Group images by folder to detect frame sequences.
    images_by_dir: dict[Path, list[Path]] = {}
    for path in files:
        if media_kind(path) == "image":
            images_by_dir.setdefault(path.parent, []).append(path)

    consumed: set[Path] = set()
    for folder, imgs in images_by_dir.items():
        rel_parts = folder.relative_to(root).parts
        parts = list(rel_parts)
        if parts and parts[0].lower() in SPLIT_NAMES:
            parts = parts[1:]
        # label/sample/frames: the folder is a sample when it sits below a label dir.
        if is_structured and len(parts) >= 2 and len(imgs) >= 2:
            rel = folder.relative_to(root).as_posix()
            samples.append(_make_sample(rel, "frames", sorted(imgs), list(rel_parts),
                                        is_structured, is_labeled, mapping))
            consumed.update(imgs)

    for path in files:
        if path in consumed:
            continue
        kind = media_kind(path)
        rel = path.relative_to(root).as_posix()
        samples.append(_make_sample(rel, kind, [path], list(path.relative_to(root).parts),
                                    is_structured, is_labeled, mapping))
    return _filter_format(samples, media_format)


def _make_sample(rel: str, kind: str, sample_files: list[Path], parts: list[str],
                 is_structured: bool, is_labeled: bool, mapping: dict[str, str]) -> Sample:
    split_hint = None
    folder_parts = parts[:-1] if kind != "frames" else parts
    if folder_parts and folder_parts[0].lower() in SPLIT_NAMES:
        split_hint = folder_parts[0].lower()
        folder_parts = folder_parts[1:]
    label = _mapping_label(rel, mapping)
    if label is None and is_labeled and is_structured and folder_parts:
        label = normalize_label(folder_parts[0])
    return Sample(
        rel=rel,
        kind=kind,
        files=sample_files,
        label=label,
        signer=find_signer(parts),
        split_hint=split_hint,
    )


def _filter_format(samples: list[Sample], media_format: str) -> list[Sample]:
    if media_format in ("auto", "mixed"):
        return samples
    allowed = {"images": {"image", "frames"}, "gif": {"gif"}, "video": {"video"}}[media_format]
    return [s for s in samples if s.kind in allowed]
