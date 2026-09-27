"""Job context: progress, logs and cancellation, backed by the DB or by nothing."""

from __future__ import annotations

import logging
import time
from typing import Callable

logger = logging.getLogger("moomoo_ml")


class Cancelled(Exception):
    pass


class JobContext:
    """Reports to the training_jobs row of [job]. Throttles DB writes."""

    def __init__(self, job: dict):
        from . import db

        self._db = db
        self.job = job
        self.job_id = job["id"]
        self._last_status_check = 0.0
        self._cancelled = False
        self._last_progress_write = 0.0

    def log(self, message: str, level: str = "info", experiment_id: str | None = None) -> None:
        getattr(logger, "warning" if level == "warning" else "error" if level == "error" else "info")(
            "[%s] %s", self.job_id[:8], message
        )
        try:
            self._db.log(self.job_id, message, level, experiment_id)
        except Exception as exc:  # logging must never kill a training run
            logger.warning("log write failed: %s", exc)

    def progress(self, percent: float, message: str | None = None, *, force: bool = False,
                 **fields) -> None:
        now = time.monotonic()
        if not force and now - self._last_progress_write < 1.5 and not fields:
            return
        self._last_progress_write = now
        update = {"progress": round(max(0.0, min(100.0, percent)), 2)}
        if message:
            update["message"] = message[:500]
        update.update(fields)
        self._db.update_job(self.job_id, **update)

    def should_stop(self) -> bool:
        if self._cancelled:
            return True
        now = time.monotonic()
        if now - self._last_status_check > 3:
            self._last_status_check = now
            status = self._db.job_status(self.job_id)
            self._cancelled = status in ("cancelling", "cancelled", None)
        return self._cancelled

    def check_cancel(self) -> None:
        if self.should_stop():
            raise Cancelled()


class NullContext:
    """Same interface, no database: for tests and command-line runs."""

    def __init__(self, job: dict | None = None, printer: Callable[[str], None] | None = None):
        self.job = job or {"id": "local"}
        self.job_id = self.job["id"]
        self._print = printer or (lambda m: None)

    def log(self, message: str, level: str = "info", experiment_id: str | None = None) -> None:
        self._print(f"[{level}] {message}")

    def progress(self, percent: float, message: str | None = None, *, force: bool = False,
                 **fields) -> None:
        if message:
            self._print(f"[{percent:5.1f}%] {message}")

    def should_stop(self) -> bool:
        return False

    def check_cancel(self) -> None:
        return None
