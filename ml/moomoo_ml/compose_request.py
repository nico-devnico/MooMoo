"""Request contract for POST /compose-landmarks.

Accepts the payloads sent by Flutter and Express (`clips`, `media`, `urls`,
`text`, `word`, `video_url`, `media_url`) and resolves words against the LSFB
catalogue shipped with the app, then against `public.signs` when Postgres is
reachable. Placeholder hosts are never invented.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable

from pydantic import BaseModel, ConfigDict, Field

from . import config

CATALOGUE_PATH = config.PROJECT_ROOT / "assets" / "dictionnaire" / "dataset_gifs_links.json"
_MAX_PHRASE_TOKENS = 4


class ComposeInputError(Exception):
    def __init__(
        self,
        detail: str,
        *,
        field: str | None = None,
        status: int = 422,
        code: str = "invalid_request",
        missing: list[dict] | None = None,
    ):
        super().__init__(detail)
        self.detail = detail
        self.field = field
        self.status = status
        self.code = code
        self.missing = missing or []


class ComposeLandmarksRequest(BaseModel):
    """Body documented in Swagger. Types stay loose so aliases and numeric
    strings reach `resolve_compose_request`, which names the invalid field."""

    model_config = ConfigDict(
        extra="ignore",
        json_schema_extra={
            "example": {
                "clips": [
                    {
                        "word": "à côté",
                        "url": "https://www.corpus-lsfb.be/img/pictures/signe_f179359556f2bee76ed4299418313818.gif",
                    }
                ],
                "fps": 15,
                "blend_frames": 6,
                "include_face": False,
            }
        },
    )

    clips: list[Any] | None = None
    media: list[Any] | None = None
    urls: list[Any] | None = None
    text: str | None = None
    word: str | None = None
    url: str | None = None
    video_url: str | None = None
    media_url: str | None = None
    fps: Any = None
    gap_frames: Any = None
    blend_frames: Any = None
    max_frames_per_clip: Any = None
    include_face: Any = None
    sign_id: str | None = Field(default=None)


def coerce_include_face(value: Any, *, default: bool = False) -> bool:
    """`"false"` is false. A non-empty string must never become True via bool()."""
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        if value == 1:
            return True
        if value == 0:
            return False
        raise ComposeInputError(
            "include_face doit être un booléen (true ou false).",
            field="include_face",
        )
    if isinstance(value, str):
        token = value.strip().lower()
        if token in ("1", "true", "yes", "on"):
            return True
        if token in ("0", "false", "no", "off", ""):
            return False
    raise ComposeInputError(
        "include_face doit être un booléen (true ou false), "
        "pas la chaîne opposée interprétée comme vraie.",
        field="include_face",
    )


def _parse_number(
    value: Any,
    *,
    field: str,
    default: float | int | None,
    minimum: float,
    maximum: float,
    integer: bool,
) -> float | int | None:
    if value is None or value == "":
        return default
    if isinstance(value, bool):
        raise ComposeInputError(f"{field} doit être un nombre.", field=field)
    try:
        if integer:
            if isinstance(value, float) and not value.is_integer():
                raise ValueError(field)
            if isinstance(value, str) and "." in value.strip():
                as_float = float(value.strip())
                if not as_float.is_integer():
                    raise ValueError(field)
            number: float | int = int(value)
        else:
            number = float(value)
    except (TypeError, ValueError):
        kind = "un entier" if integer else "un nombre"
        raise ComposeInputError(
            f"{field} doit être {kind} compris entre {minimum:g} et {maximum:g}.",
            field=field,
        ) from None
    if number < minimum or number > maximum:
        raise ComposeInputError(
            f"{field} doit être compris entre {minimum:g} et {maximum:g}.",
            field=field,
        )
    return number


def _norm(text: str) -> str:
    return " ".join(text.casefold().split())


class SignCatalogue:
    """Index of the embedded LSFB dictionary (`gif_url` is the real media)."""

    def __init__(self, path: Path = CATALOGUE_PATH):
        self.path = path
        self._index: dict[str, dict] | None = None

    def _load(self) -> dict[str, dict]:
        if self._index is not None:
            return self._index
        index: dict[str, dict] = {}
        if self.path.is_file():
            try:
                raw = json.loads(self.path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                raw = []
            if isinstance(raw, list):
                for item in raw:
                    if not isinstance(item, dict):
                        continue
                    url = str(item.get("gif_url") or item.get("video_url") or "").strip()
                    if not url.startswith(("http://", "https://")):
                        continue
                    gloss = str(item.get("glose") or "").strip()
                    name = str(item.get("nom_signe") or gloss).strip()
                    entry = {"word": name or gloss, "url": url, "sign_id": f"lsfb:{gloss}" if gloss else None}
                    keys = [gloss, name, *(item.get("translations") or [])]
                    for key in keys:
                        if isinstance(key, str) and key.strip():
                            index.setdefault(_norm(key), entry)
        self._index = index
        return index

    def find(self, word: str) -> dict | None:
        hit = self._load().get(_norm(word))
        return dict(hit) if hit else None


CATALOGUE = SignCatalogue()


def _public_storage_url(raw: str) -> str | None:
    text = raw.strip()
    if text.startswith(("http://", "https://")):
        return text
    if not text or ".." in text or "\\" in text or text.startswith("/"):
        return None
    base = (config.SUPABASE_URL or "").rstrip("/")
    if not base:
        return None
    return f"{base}/storage/v1/object/public/sign-videos/{text.lstrip('/')}"


def lookup_db_sign(word: str) -> dict | None:
    """One validated sign row, or None when the database is unavailable."""
    if not config.DB_URL or not word.strip():
        return None
    try:
        from . import db

        row = db.one(
            """
            SELECT id::text AS id, word, video_url
            FROM public.signs
            WHERE NULLIF(btrim(video_url), '') IS NOT NULL
              AND lower(word) = lower(%(w)s)
            ORDER BY is_validated DESC, view_count DESC NULLS LAST
            LIMIT 1
            """,
            {"w": word.strip()},
        )
    except Exception:
        return None
    if not row:
        return None
    url = _public_storage_url(str(row.get("video_url") or ""))
    if not url:
        return None
    return {"word": str(row.get("word") or word).strip(), "url": url, "sign_id": row.get("id")}


def _lookup_word(word: str, catalogue: SignCatalogue, db_lookup: Callable[[str], dict | None]) -> dict | None:
    hit = catalogue.find(word)
    if hit:
        return hit
    return db_lookup(word)


def _gloss_text(
    text: str,
    catalogue: SignCatalogue,
    db_lookup: Callable[[str], dict | None],
) -> tuple[list[dict], list[str]]:
    tokens = [t for t in text.split() if t]
    found: list[dict] = []
    unknown: list[str] = []
    i = 0
    while i < len(tokens):
        matched = None
        upper = min(_MAX_PHRASE_TOKENS, len(tokens) - i)
        for length in range(upper, 0, -1):
            phrase = " ".join(tokens[i:i + length])
            hit = _lookup_word(phrase, catalogue, db_lookup)
            if hit:
                matched = (length, hit)
                break
        if matched:
            found.append(matched[1])
            i += matched[0]
        else:
            unknown.append(tokens[i])
            i += 1
    return found, unknown


def _clip_from_item(item: Any, index: int) -> tuple[dict | None, str | None]:
    """Return (clip with url, word still to resolve) or raise on a bad item."""
    field = f"clips[{index}]"
    if isinstance(item, str):
        text = item.strip()
        if text.startswith(("http://", "https://")):
            return {"word": "", "url": text, "sign_id": None}, None
        if text:
            return None, text
        raise ComposeInputError(
            f"{field} est vide. Indiquez une URL http(s) ou un mot du dictionnaire.",
            field=field,
        )
    if not isinstance(item, dict):
        raise ComposeInputError(
            f"{field} doit être un objet {{word, url}} ou une URL.",
            field=field,
        )
    url = str(item.get("url") or item.get("video_url") or item.get("media_url") or "").strip()
    word = str(item.get("word") or item.get("label") or "").strip()
    sign_id = item.get("sign_id") or item.get("id")
    if url.startswith(("http://", "https://")):
        return {"word": word, "url": url, "sign_id": sign_id}, None
    if url:
        raise ComposeInputError(
            f"{field}.url doit être une URL http(s) absolue.",
            field=f"{field}.url",
        )
    if word:
        return None, word
    raise ComposeInputError(
        f"{field} n'a ni URL ni mot. Ajoutez url, video_url ou word.",
        field=field,
    )


def resolve_compose_request(
    payload: dict,
    *,
    catalogue: SignCatalogue | None = None,
    db_lookup: Callable[[str], dict | None] | None = None,
) -> dict:
    """Normalize a decoded JSON object into compose_landmarks kwargs + clips."""
    catalogue = catalogue or CATALOGUE
    db_lookup = db_lookup or lookup_db_sign
    if not isinstance(payload, dict):
        raise ComposeInputError(
            "Le corps doit être un objet JSON avec clips ou text.",
            field="body",
        )

    fps = _parse_number(payload.get("fps"), field="fps", default=15.0, minimum=1, maximum=60, integer=False)
    gap = _parse_number(
        payload.get("gap_frames"), field="gap_frames", default=None, minimum=0, maximum=120, integer=True,
    )
    blend = _parse_number(
        payload.get("blend_frames"), field="blend_frames", default=None, minimum=0, maximum=120, integer=True,
    )
    max_frames = _parse_number(
        payload.get("max_frames_per_clip"),
        field="max_frames_per_clip",
        default=160,
        minimum=1,
        maximum=400,
        integer=True,
    )
    include_face = coerce_include_face(payload.get("include_face"), default=False)

    raw = payload.get("clips")
    if raw is None:
        raw = payload.get("media")
    if raw is None:
        raw = payload.get("urls")

    clips: list[dict] = []
    pending_words: list[str] = []
    if raw is not None:
        if not isinstance(raw, list):
            raise ComposeInputError("clips doit être une liste.", field="clips")
        if len(raw) == 0 and not (payload.get("text") or payload.get("word")):
            raise ComposeInputError(
                "La liste clips est vide. Envoyez au moins un clip {word, url} ou un champ text.",
                field="clips",
            )
        for index, item in enumerate(raw):
            ready, word = _clip_from_item(item, index)
            if ready:
                clips.append(ready)
            elif word:
                pending_words.append(word)

    text = payload.get("text")
    if isinstance(text, str) and text.strip() and not clips and not pending_words:
        found, unknown = _gloss_text(text, catalogue, db_lookup)
        clips.extend(found)
        pending_words.extend(unknown)
    elif isinstance(text, str) and text.strip() and pending_words:
        found, unknown = _gloss_text(text, catalogue, db_lookup)
        # Explicit clips win; text only fills words that still need a media URL.
        by_word = {_norm(c["word"]): c for c in found}
        still = []
        for word in pending_words:
            hit = by_word.get(_norm(word)) or _lookup_word(word, catalogue, db_lookup)
            if hit:
                clips.append(hit)
            else:
                still.append(word)
        pending_words = still + unknown
    else:
        resolved = []
        still = []
        for word in pending_words:
            hit = _lookup_word(word, catalogue, db_lookup)
            if hit:
                resolved.append(hit)
            else:
                still.append(word)
        clips.extend(resolved)
        pending_words = still

    lone_word = str(payload.get("word") or "").strip()
    lone_url = str(payload.get("url") or payload.get("video_url") or payload.get("media_url") or "").strip()
    if not clips and not pending_words and (lone_word or lone_url):
        if lone_url.startswith(("http://", "https://")):
            clips.append({"word": lone_word, "url": lone_url, "sign_id": payload.get("sign_id")})
        elif lone_url:
            raise ComposeInputError("url doit être une URL http(s) absolue.", field="url")
        elif lone_word:
            hit = _lookup_word(lone_word, catalogue, db_lookup)
            if hit:
                clips.append(hit)
            else:
                pending_words.append(lone_word)

    if not clips and not pending_words:
        raise ComposeInputError(
            "Envoyez clips (liste non vide de {word, url}) ou text (phrase du dictionnaire).",
            field="body",
        )

    missing = [
        {
            "word": word,
            "url": "",
            "sign_id": None,
            "reason": "absent du dictionnaire",
            "code": "unknown_word",
        }
        for word in pending_words
    ]
    if not clips:
        names = ", ".join(pending_words)
        raise ComposeInputError(
            f"Mots absents du dictionnaire : {names}. "
            "Vérifiez l'orthographe ou envoyez l'URL vidéo du signe.",
            field="text" if payload.get("text") else "word",
            status=404,
            code="unknown_word",
            missing=missing,
        )

    return {
        "clips": clips,
        "fps": float(fps),
        "gap_frames": None if gap is None else int(gap),
        "blend_frames": None if blend is None else int(blend),
        "max_frames_per_clip": int(max_frames),
        "include_face": include_face,
        "unresolved": missing,
    }
