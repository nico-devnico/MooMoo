from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
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
    """No recognition model is loaded yet.

    Answer 503 rather than inventing a label: the app shows a clear
    "translation unavailable" state instead of a wrong word to a deaf user.
    """
    raw = await file.read() if file is not None else b""
    return JSONResponse(
        status_code=503,
        content={
            "ok": False,
            "error": "model_not_loaded",
            "detail": "No sign recognition model is loaded on this worker.",
            "dataset": dataset or "WASL",
            "model_version": model_version,
            "bytes_received": len(raw),
        },
    )


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
