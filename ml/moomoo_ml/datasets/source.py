"""Resolve a dataset source (local folder, local archive or URL) to a folder."""

from __future__ import annotations

import hashlib
import shutil
import tarfile
import zipfile
from pathlib import Path
from typing import Callable
from urllib.parse import urlparse

import requests

from .. import config

ARCHIVE_SUFFIXES = (".zip", ".tar", ".tar.gz", ".tgz")


class DatasetSourceError(ValueError):
    pass


def _is_archive(path: Path) -> bool:
    name = path.name.lower()
    return any(name.endswith(s) for s in ARCHIVE_SUFFIXES)


def _safe_extract(archive: Path, target: Path) -> None:
    """Extracts while refusing entries that would escape [target] (zip slip)."""
    target.mkdir(parents=True, exist_ok=True)
    root = target.resolve()
    if archive.name.lower().endswith(".zip"):
        with zipfile.ZipFile(archive) as zf:
            for member in zf.namelist():
                if not (root / member).resolve().is_relative_to(root):
                    raise DatasetSourceError(f"Entrée d'archive dangereuse : {member}")
            zf.extractall(target)
    else:
        with tarfile.open(archive) as tf:
            for member in tf.getmembers():
                if not (root / member.name).resolve().is_relative_to(root):
                    raise DatasetSourceError(f"Entrée d'archive dangereuse : {member.name}")
                if member.issym() or member.islnk():
                    raise DatasetSourceError(f"Lien interdit dans l'archive : {member.name}")
            tf.extractall(target)


def _single_child_dir(folder: Path) -> Path:
    """Archives often wrap everything in one top folder: descend into it."""
    entries = [p for p in folder.iterdir() if not p.name.startswith((".", "__MACOSX"))]
    if len(entries) == 1 and entries[0].is_dir():
        return entries[0]
    return folder


def resolve_source(source_type: str, uri: str,
                   progress: Callable[[str], None] | None = None) -> Path:
    uri = uri.strip()
    if source_type == "local":
        path = Path(uri).expanduser()
        if not path.is_absolute():
            path = (config.DATA_DIR / path).resolve()
        if not path.exists():
            raise DatasetSourceError(
                f"Chemin introuvable sur la machine du worker : {path}"
            )
        if path.is_dir():
            return path
        if _is_archive(path):
            target = config.CACHE_DIR / "extracted" / hashlib.sha1(str(path).encode()).hexdigest()[:16]
            if not target.exists():
                if progress:
                    progress(f"Extraction de {path.name}")
                _safe_extract(path, target)
            return _single_child_dir(target)
        raise DatasetSourceError("Le chemin local doit être un dossier ou une archive zip/tar")

    if source_type == "url":
        parsed = urlparse(uri)
        if parsed.scheme not in ("http", "https"):
            raise DatasetSourceError("Seules les URL http(s) sont acceptées")
        key = hashlib.sha1(uri.encode()).hexdigest()[:16]
        download_dir = config.CACHE_DIR / "downloads" / key
        download_dir.mkdir(parents=True, exist_ok=True)
        filename = Path(parsed.path).name or "dataset.zip"
        archive = download_dir / filename
        if not archive.exists():
            if progress:
                progress(f"Téléchargement de {uri}")
            tmp = archive.with_suffix(archive.suffix + ".part")
            with requests.get(uri, stream=True, timeout=60) as r:
                r.raise_for_status()
                with open(tmp, "wb") as fh:
                    for chunk in r.iter_content(chunk_size=1 << 20):
                        fh.write(chunk)
            shutil.move(tmp, archive)
        if not _is_archive(archive):
            raise DatasetSourceError(
                "L'URL doit pointer vers une archive zip/tar contenant le dataset"
            )
        target = download_dir / "extracted"
        if not target.exists():
            if progress:
                progress(f"Extraction de {filename}")
            _safe_extract(archive, target)
        return _single_child_dir(target)

    raise DatasetSourceError(f"Type de source inconnu : {source_type}")
