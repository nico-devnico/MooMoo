"""ML worker: consumes public.training_jobs, independently of the API and the UI.

Run:  cd ml && .venv\\Scripts\\python -m moomoo_ml.worker
Closing the admin browser or restarting the API does not stop a job; a crashed
worker's job is picked up again and training resumes from its last checkpoint.
"""

from __future__ import annotations

import argparse
import logging
import os
import signal
import socket
import threading
import time
import traceback

from . import config, db
from .context import Cancelled, JobContext
from .jobs import HANDLERS

logger = logging.getLogger("moomoo_ml")


class Heartbeat(threading.Thread):
    """Keeps heartbeat_at fresh even during a long epoch."""

    def __init__(self, job_id: str):
        super().__init__(daemon=True)
        self.job_id = job_id
        self._stop = threading.Event()

    def run(self) -> None:
        while not self._stop.wait(config.HEARTBEAT_SECONDS):
            try:
                db.heartbeat(self.job_id)
            except Exception as exc:
                logger.warning("heartbeat failed: %s", exc)

    def stop(self) -> None:
        self._stop.set()


def process(job: dict) -> None:
    ctx = JobContext(job)
    handler = HANDLERS.get(job["kind"])
    beat = Heartbeat(job["id"])
    beat.start()
    started = time.perf_counter()
    try:
        if handler is None:
            raise ValueError(f"Type de job inconnu : {job['kind']}")
        ctx.log(f"Début du job {job['kind']} (tentative {job['attempts']})")
        result = handler(ctx, job) or {}
        result["duration_s"] = round(time.perf_counter() - started, 1)
        if ctx.should_stop():
            db.finish_job(job["id"], "cancelled", message="Annulé", result=result)
            ctx.log("Job annulé")
        else:
            db.finish_job(job["id"], "done", result=result, message="Terminé")
            ctx.log(f"Job terminé en {result['duration_s']} s")
    except (Cancelled, InterruptedError):
        db.finish_job(job["id"], "cancelled", message="Annulé par un administrateur")
        ctx.log("Job annulé par un administrateur", "warning")
    except Exception as exc:
        detail = traceback.format_exc(limit=6)
        logger.error("job %s failed: %s", job["id"], detail)
        db.finish_job(job["id"], "failed", error=str(exc)[:2000], message="Échec")
        ctx.log(f"Échec : {exc}", "error")
        ctx.log(detail[-3500:], "debug")
    finally:
        beat.stop()


def run(once: bool = False) -> None:
    worker_id = f"{socket.gethostname()}:{os.getpid()}"
    stop = threading.Event()

    def _graceful(*_):
        logger.info("Arrêt demandé : fin après le job en cours.")
        stop.set()

    signal.signal(signal.SIGINT, _graceful)
    if hasattr(signal, "SIGTERM"):
        signal.signal(signal.SIGTERM, _graceful)

    logger.info("Worker %s démarré (artefacts : %s)", worker_id, config.ARTIFACTS_DIR)
    last_recovery = 0.0
    while not stop.is_set():
        try:
            if time.monotonic() - last_recovery > 60:
                recovered = db.requeue_stale_jobs(config.STALE_JOB_SECONDS, config.MAX_JOB_ATTEMPTS)
                if recovered:
                    logger.info("%d job(s) orphelin(s) repris ou clos", len(recovered))
                last_recovery = time.monotonic()
            job = db.claim_next_job(worker_id)
        except db.DbUnavailable:
            raise
        except Exception as exc:
            logger.warning("file d'attente indisponible : %s", exc)
            time.sleep(10)
            continue
        if job is None:
            if once:
                return
            stop.wait(config.WORKER_POLL_SECONDS)
            continue
        logger.info("Job %s (%s) pris en charge", job["id"], job["kind"])
        process(job)
        if once:
            return


def main() -> None:
    parser = argparse.ArgumentParser(description="MooMoo ML worker")
    parser.add_argument("--once", action="store_true", help="traite au plus un job puis s'arrête")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
    run(once=args.once)


if __name__ == "__main__":
    main()
