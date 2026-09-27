from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import time
from typing import Optional

app = FastAPI(title="MooMoo ML", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DATASETS = {
    "WASL": {"format": "gif/image", "status": "ready", "samples": 0},
    "LSFB": {"format": "gif/image", "status": "ready", "samples": 0},
}

# In-memory training job status (Node owns DB rows; Python reports worker state)
_jobs: dict[str, dict] = {}


class TrainRequest(BaseModel):
    job_id: str
    dataset: str = "WASL+LSFB"


@app.get("/health")
def health():
    return {
        "ok": True,
        "service": "moomoo-ml",
        "datasets": list(DATASETS.keys()),
    }


@app.get("/datasets")
def list_datasets():
    return {"ok": True, "datasets": DATASETS}


@app.post("/infer")
async def infer(
    file: Optional[UploadFile] = File(None),
    hint: Optional[str] = Form(None),
    dataset: Optional[str] = Form("WASL"),
    model_version: Optional[str] = Form(None),
):
    """Stub inference — replace with real WASL/LSFB model later."""
    t0 = time.perf_counter()
    raw = await file.read() if file is not None else b""
    label = (hint or "").strip() or "bonjour"
    # Confidence slightly higher when a media blob is present
    confidence = 0.91 if (hint and hint.strip()) else (0.72 if raw else 0.55)
    latency_ms = (time.perf_counter() - t0) * 1000 + 12.0
    return {
        "ok": True,
        "label": label,
        "confidence": confidence,
        "latency_ms": round(latency_ms, 2),
        "dataset": dataset or "WASL",
        "model_version": model_version,
        "bytes_received": len(raw),
        "filename": file.filename if file else None,
    }


@app.post("/train")
def train(body: TrainRequest):
    _jobs[body.job_id] = {
        "job_id": body.job_id,
        "dataset": body.dataset,
        "status": "queued",
        "progress": 0.0,
        "message": "Job accepted (no GPU training in this stub)",
    }
    # Simulate immediate queue ack — a real worker would set running/done
    _jobs[body.job_id]["status"] = "queued"
    return {"ok": True, "job": _jobs[body.job_id]}


@app.get("/train/{job_id}")
def train_status(job_id: str):
    job = _jobs.get(job_id)
    if not job:
        return {"ok": False, "error": "not_found", "job_id": job_id}
    return {"ok": True, "job": job}
