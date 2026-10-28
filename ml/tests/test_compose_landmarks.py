"""Contract tests for POST /compose-landmarks.

Network and MediaPipe are mocked except for the catalogue lookup and the
optional real LSFB clip at the end of the module.
"""

from __future__ import annotations

from contextlib import asynccontextmanager

import numpy as np
import pytest
from fastapi.testclient import TestClient

import main as ml_main
from moomoo_ml.compose import compose_landmarks
from moomoo_ml.compose_request import coerce_include_face
from moomoo_ml.preprocessing.features import Layout

REAL_GIF = (
    "https://www.corpus-lsfb.be/img/pictures/"
    "signe_f179359556f2bee76ed4299418313818.gif"
)


@pytest.fixture
def client(monkeypatch):
    @asynccontextmanager
    async def _noop(_app):
        yield

    monkeypatch.setattr(ml_main.app.router, "lifespan_context", _noop)
    monkeypatch.setattr("moomoo_ml.compose_request.lookup_db_sign", lambda word: None)
    with TestClient(ml_main.app) as http:
        yield http


def _frames(include_face: bool = False):
    layout = Layout(include_face=include_face)
    seq = np.zeros((3, layout.size), dtype=np.float32)
    seq[:, 0] = 0.4
    return seq


def test_include_face_string_false_is_false():
    assert coerce_include_face("false") is False
    assert coerce_include_face("False") is False
    assert coerce_include_face("0") is False
    assert coerce_include_face(False) is False
    assert coerce_include_face("true") is True
    assert bool("false") is True


def test_valid_clips_return_landmarks(client, monkeypatch):
    seen = {}

    def fake(payload, **kwargs):
        seen["clips"] = payload["clips"]
        seen.update(kwargs)
        frames = _frames(kwargs["include_face"])
        return {
            "ok": True,
            "fps": kwargs["fps"],
            "frames": frames.tolist(),
            "frame_count": int(frames.shape[0]),
            "segments": [
                {"word": clip.get("word"), "start_frame": i, "frames": 3, "sign_id": clip.get("sign_id")}
                for i, clip in enumerate(payload["clips"])
            ],
            "missing": [],
            "layout": {"include_face": kwargs["include_face"]},
        }

    monkeypatch.setattr("moomoo_ml.compose.compose_landmarks", fake)
    res = client.post("/compose-landmarks", json={
        "clips": [
            {"word": "à côté", "url": REAL_GIF, "sign_id": "lsfb:A-COTE"},
            {"word": "à la fin", "video_url": REAL_GIF},
        ],
        "fps": 15,
        "blend_frames": 6,
        "include_face": True,
    })
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["ok"] is True
    assert body["frame_count"] == 3
    assert len(body["frames"][0]) > 10
    assert len(seen["clips"]) == 2
    assert seen["clips"][1]["url"] == REAL_GIF
    assert "example.com" not in res.text


def test_empty_body(client):
    res = client.post(
        "/compose-landmarks",
        content=b"",
        headers={"Content-Type": "application/json"},
    )
    assert res.status_code == 422
    body = res.json()
    assert body["ok"] is False
    assert body["error"] == "invalid_request"
    assert body["field"] == "body"
    assert "clips" in body["message"]


def test_empty_clips(client):
    res = client.post("/compose-landmarks", json={"clips": []})
    assert res.status_code == 422
    body = res.json()
    assert body["field"] == "clips"
    assert "vide" in body["message"].lower()


def test_clip_without_url(client):
    res = client.post("/compose-landmarks", json={"clips": [{"label": ""}]})
    assert res.status_code == 422
    body = res.json()
    assert body["error"] == "invalid_request"
    assert body["field"].startswith("clips[")
    assert "url" in body["message"].lower() or "mot" in body["message"].lower()


def test_malformed_json(client):
    res = client.post(
        "/compose-landmarks",
        content=b'{"clips":',
        headers={"Content-Type": "application/json"},
    )
    assert res.status_code == 422
    body = res.json()
    assert body["ok"] is False
    assert body["error"] == "invalid_request"
    assert body["field"] == "body"


def test_invalid_number(client):
    res = client.post("/compose-landmarks", json={
        "clips": [{"word": "à côté", "url": REAL_GIF}],
        "fps": "abc",
    })
    assert res.status_code == 422
    body = res.json()
    assert body["field"] == "fps"
    assert "fps" in body["message"]


def test_include_face_false_string_is_forwarded_as_false(client, monkeypatch):
    seen = {}

    def fake(payload, **kwargs):
        seen.update(kwargs)
        frames = _frames(False)
        return {
            "ok": True,
            "fps": 15,
            "frames": frames.tolist(),
            "frame_count": 3,
            "segments": [],
            "missing": [],
        }

    monkeypatch.setattr("moomoo_ml.compose.compose_landmarks", fake)
    res = client.post("/compose-landmarks", json={
        "clips": [{"word": "à côté", "url": REAL_GIF}],
        "include_face": "false",
    })
    assert res.status_code == 200, res.text
    assert seen["include_face"] is False


def test_inaccessible_video_url(client, monkeypatch):
    import urllib.error
    import urllib.request

    class _Extractor:
        def __init__(self, layout):
            self.layout = layout

        def extract(self, sample, max_frames=160):
            raise AssertionError("pas d'extraction si le téléchargement échoue")

        def close(self):
            return None

    def refuse(url, timeout=45):
        raise urllib.error.URLError("connexion refusée")

    monkeypatch.setattr("moomoo_ml.compose.HolisticExtractor", _Extractor)
    monkeypatch.setattr(urllib.request, "urlopen", refuse)
    res = client.post("/compose-landmarks", json={
        "clips": [{"word": "à côté", "url": "http://127.0.0.1:9/absent.mp4"}],
        "max_frames_per_clip": 4,
    })
    assert res.status_code == 502, res.text
    body = res.json()
    assert body["ok"] is False
    assert body["error"] == "download_failed"
    assert body["missing"][0]["code"] == "download_failed"


def test_unknown_dictionary_word(client):
    res = client.post("/compose-landmarks", json={"text": "zzzz-moomoo-absent-28"})
    assert res.status_code == 404, res.text
    body = res.json()
    assert body["error"] == "unknown_word"
    assert "zzzz-moomoo-absent-28" in body["message"]
    assert body["missing"][0]["code"] == "unknown_word"
    assert "example.com" not in res.text


def test_text_uses_real_catalogue_url(client, monkeypatch):
    seen = {}

    def fake(payload, **kwargs):
        seen["clips"] = payload["clips"]
        frames = _frames(False)
        return {"ok": True, "fps": 15, "frames": frames.tolist(), "frame_count": 3,
                "segments": [], "missing": []}

    monkeypatch.setattr("moomoo_ml.compose.compose_landmarks", fake)
    res = client.post("/compose-landmarks", json={"text": "à côté"})
    assert res.status_code == 200, res.text
    assert seen["clips"][0]["url"] == REAL_GIF
    assert seen["clips"][0]["sign_id"] == "lsfb:A-COTE"


def test_accessible_video_without_landmarks(client, monkeypatch, tmp_path):
    def fake_download(url, timeout_s=45):
        path = tmp_path / "clip.gif"
        path.write_bytes(b"GIF89a")
        return path

    class _Extractor:
        def __init__(self, layout):
            self.layout = layout

        def extract(self, sample, max_frames=160):
            return np.zeros((5, self.layout.size), dtype=np.float32)

        def close(self):
            return None

    monkeypatch.setattr("moomoo_ml.compose.download_temp", fake_download)
    monkeypatch.setattr("moomoo_ml.compose.HolisticExtractor", _Extractor)
    res = client.post("/compose-landmarks", json={
        "clips": [{"word": "à côté", "url": REAL_GIF}],
        "max_frames_per_clip": 5,
    })
    assert res.status_code == 422, res.text
    body = res.json()
    assert body["error"] == "no_landmarks"
    assert body["frames"] == []
    assert body["missing"][0]["code"] == "no_landmarks"


def test_two_real_catalogue_clips_are_concatenated(monkeypatch):
    """Compose function itself, with the real dictionary URLs and synthetic landmarks."""

    def fake_download(url, timeout_s=45):
        from pathlib import Path
        import tempfile
        tmp = tempfile.NamedTemporaryFile(prefix="moomoo_compose_", suffix=".gif", delete=False)
        tmp.write(b"GIF89a")
        tmp.close()
        assert url.startswith("https://www.corpus-lsfb.be/")
        return Path(tmp.name)

    class _Extractor:
        def __init__(self, layout):
            self.layout = layout

        def extract(self, sample, max_frames=160):
            from moomoo_ml.preprocessing.features import Layout
            assert isinstance(self.layout, Layout)
            seq = np.zeros((4, self.layout.size), dtype=np.float32)
            seq[:, :] = 0.2
            # Shoulders so alignment has an anchor.
            pose = seq[:, self.layout.pose].reshape(4, 33, 4)
            pose[:, 11, :2] = [0.6, 0.4]
            pose[:, 12, :2] = [0.4, 0.4]
            seq[:, self.layout.pose] = pose.reshape(4, -1)
            return seq

        def close(self):
            return None

    monkeypatch.setattr("moomoo_ml.compose.download_temp", fake_download)
    monkeypatch.setattr("moomoo_ml.compose.HolisticExtractor", _Extractor)
    result = compose_landmarks(
        {"clips": [
            {"word": "à côté", "url": REAL_GIF},
            {"word": "à côté", "url": REAL_GIF},
        ]},
        fps=15,
        blend_frames=2,
        max_frames_per_clip=4,
        include_face=False,
    )
    assert result["ok"] is True
    assert result["frame_count"] == 4 + 2 + 4
    assert result["segments"][0]["word"] == "à côté"
    assert result["segments"][1]["start_frame"] == 6


def test_mediapipe_missing_is_503(client, monkeypatch):
    monkeypatch.setattr(ml_main, "_module_available", lambda name: False)
    res = client.post("/compose-landmarks", json={
        "clips": [{"word": "à côté", "url": REAL_GIF}],
    })
    assert res.status_code == 503
    assert res.json()["error"] == "mediapipe_missing"


def test_download_prefers_local_media_proxy(monkeypatch, tmp_path):
    """Corpus hosts are fetched via Express /api/media/proxy (disk cache)."""
    from moomoo_ml import compose as compose_mod

    calls: list[str] = []

    def fake_once(url, *, timeout_s):
        calls.append(url)
        if "/api/media/proxy" not in url:
            raise compose_mod.ComposeMediaError("download_failed", "timeout corpus")
        path = tmp_path / "clip.gif"
        path.write_bytes(b"GIF89a")
        return path

    monkeypatch.setattr(compose_mod, "_download_once", fake_once)
    path = compose_mod.download_temp(REAL_GIF, timeout_s=5)
    assert path.exists()
    assert calls[0].startswith("http://127.0.0.1:3001/api/media/proxy?url=")
    assert REAL_GIF in calls[0] or "corpus-lsfb" in calls[0]
    assert all("/api/media/proxy" in u or u == REAL_GIF for u in calls)


def test_local_gif_reaches_mediapipe(client):
    """HTTP → download → MediaPipe on a GIF served by a local test server."""
    pytest.importorskip("mediapipe")
    pytest.importorskip("cv2")
    import io
    import threading
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

    from PIL import Image

    buffer = io.BytesIO()
    frames = [Image.new("RGB", (96, 96), color) for color in ("white", "black", "white")]
    frames[0].save(buffer, format="GIF", save_all=True, append_images=frames[1:], duration=80, loop=0)
    payload = buffer.getvalue()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-Type", "image/gif")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def log_message(self, *_args):
            return None

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    port = server.server_address[1]
    try:
        res = client.post("/compose-landmarks", json={
            "clips": [{"word": "local", "url": f"http://127.0.0.1:{port}/clip.gif"}],
            "max_frames_per_clip": 3,
            "include_face": False,
        })
    finally:
        server.shutdown()
        server.server_close()

    body = res.json()
    # A blank GIF is a real file. MediaPipe correctly reports that it has no signer.
    assert res.status_code == 422, body
    assert body["ok"] is False
    assert body["error"] == "no_landmarks"
    assert body["missing"][0]["code"] == "no_landmarks"
    assert body["frames"] == []


def test_real_lsfb_gif_produces_landmarks():
    """End-to-end extraction on a real dictionary GIF when the corpus is reachable."""
    pytest.importorskip("mediapipe")
    pytest.importorskip("cv2")
    import socket

    sock = socket.socket()
    sock.settimeout(5)
    try:
        sock.connect(("www.corpus-lsfb.be", 443))
    except OSError as exc:
        pytest.skip(f"corpus-lsfb.be injoignable depuis cette machine : {exc}")
    finally:
        sock.close()

    result = compose_landmarks(
        {"clips": [{"word": "à côté", "url": REAL_GIF, "sign_id": "lsfb:A-COTE"}]},
        fps=15,
        blend_frames=0,
        max_frames_per_clip=6,
        include_face=False,
    )
    assert result["ok"] is True, result.get("missing")
    assert result["frame_count"] >= 1
    assert result["segments"][0]["url"] == REAL_GIF
    assert any(result["frames"][0])
