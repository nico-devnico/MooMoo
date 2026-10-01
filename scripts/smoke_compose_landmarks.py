import json
import urllib.request
from pathlib import Path

CAPTURES = Path(r"D:\projets\MooMoo\assets\captures")
CAPTURES.mkdir(parents=True, exist_ok=True)

health = json.loads(urllib.request.urlopen("http://127.0.0.1:8000/health", timeout=10).read().decode())
print("health", health.get("runtimes"))

url = "https://www.corpus-lsfb.be/img/pictures/signe_f179359556f2bee76ed4299418313818.gif"
body = json.dumps({"clips": [{"word": "bonjour", "url": url}], "max_frames_per_clip": 24}).encode()

def post(path):
    req = urllib.request.Request(
        path,
        data=body,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        return json.loads(resp.read().decode())

ml = post("http://127.0.0.1:8000/compose-landmarks")
api = post("http://127.0.0.1:3001/api/infer/compose-landmarks")
print("ml", ml.get("ok"), ml.get("frame_count"), ml.get("feature_dim"))
print("api", api.get("ok"), api.get("frame_count") or len(api.get("frames") or []))

txt = CAPTURES / "15_compose_landmarks_ok.txt"
txt.write_text(
    "\n".join(
        [
            "=== compose-landmarks smoke ===",
            f"ML mediapipe={health.get('runtimes', {}).get('mediapipe')}",
            f"ml ok={ml.get('ok')} frames={ml.get('frame_count')} dim={ml.get('feature_dim')}",
            f"api ok={api.get('ok')} frames={api.get('frame_count') or len(api.get('frames') or [])}",
            "PASSED compose landmarks end-to-end",
            "",
        ]
    ),
    encoding="utf-8",
)
print("wrote", txt)
