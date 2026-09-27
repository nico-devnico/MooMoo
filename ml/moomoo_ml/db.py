"""Database access for the worker (direct Postgres, server side only)."""

from __future__ import annotations

import json
import threading
from contextlib import contextmanager
from typing import Any, Iterator

import psycopg
from psycopg.rows import dict_row
from psycopg.types.json import Jsonb
from psycopg.types.string import TextLoader

from . import config


class DbUnavailable(RuntimeError):
    pass


_local = threading.local()


def _connect() -> psycopg.Connection:
    if not config.DB_URL:
        raise DbUnavailable(
            "SUPABASE_DB_URL is not set (ml/.env or backend/.env): the worker "
            "cannot reach the job queue."
        )
    # prepare_threshold=None: the Supabase pooler does not keep prepared statements.
    conn = psycopg.connect(
        config.DB_URL,
        autocommit=True,
        row_factory=dict_row,
        prepare_threshold=None,
        connect_timeout=15,
    )
    # Ids travel as plain strings (logs, JSON results, artifact paths).
    conn.adapters.register_loader("uuid", TextLoader)
    return conn


def connection() -> psycopg.Connection:
    """One connection per thread, reopened if the pooler dropped it."""
    conn = getattr(_local, "conn", None)
    if conn is None or conn.closed or conn.broken:
        conn = _connect()
        _local.conn = conn
    return conn


def _adapt(value: Any) -> Any:
    if isinstance(value, (dict, list)):
        return Jsonb(value)
    return value


def execute(sql: str, params: dict | tuple | None = None) -> list[dict]:
    if isinstance(params, dict):
        params = {k: _adapt(v) for k, v in params.items()}
    elif isinstance(params, tuple):
        params = tuple(_adapt(v) for v in params)
    try:
        cur = connection().execute(sql, params)
    except psycopg.OperationalError:
        _local.conn = None
        cur = connection().execute(sql, params)
    return cur.fetchall() if cur.description else []


def one(sql: str, params: dict | tuple | None = None) -> dict | None:
    rows = execute(sql, params)
    return rows[0] if rows else None


@contextmanager
def transaction() -> Iterator[psycopg.Connection]:
    conn = connection()
    with conn.transaction():
        yield conn


# ---------------------------------------------------------------------------
# Jobs
# ---------------------------------------------------------------------------
def claim_next_job(worker_id: str) -> dict | None:
    return one(
        """
        UPDATE public.training_jobs j
        SET status = 'running', worker_id = %(w)s, heartbeat_at = now(),
            started_at = coalesce(j.started_at, now()), attempts = j.attempts + 1,
            error_message = NULL
        WHERE j.id = (
          SELECT id FROM public.training_jobs
          WHERE status = 'queued'
          ORDER BY created_at
          FOR UPDATE SKIP LOCKED
          LIMIT 1
        )
        RETURNING j.*
        """,
        {"w": worker_id},
    )


def requeue_stale_jobs(stale_seconds: float, max_attempts: int) -> list[dict]:
    """Jobs left 'running' by a crashed worker: retry (with resume) or fail."""
    failed = execute(
        """
        UPDATE public.training_jobs
        SET status = 'failed', finished_at = now(),
            error_message = 'Worker interrompu trop de fois (' || attempts || ' tentatives)'
        WHERE status IN ('running', 'cancelling')
          AND coalesce(heartbeat_at, started_at, created_at) < now() - make_interval(secs => %(s)s)
          AND attempts >= %(m)s
        RETURNING id
        """,
        {"s": stale_seconds, "m": max_attempts},
    )
    requeued = execute(
        """
        UPDATE public.training_jobs
        SET status = CASE WHEN status = 'cancelling' THEN 'cancelled' ELSE 'queued' END,
            worker_id = NULL,
            finished_at = CASE WHEN status = 'cancelling' THEN now() ELSE NULL END,
            message = 'Reprise après interruption du worker'
        WHERE status IN ('running', 'cancelling')
          AND coalesce(heartbeat_at, started_at, created_at) < now() - make_interval(secs => %(s)s)
        RETURNING id
        """,
        {"s": stale_seconds},
    )
    return failed + requeued


def heartbeat(job_id: str) -> str | None:
    row = one(
        "UPDATE public.training_jobs SET heartbeat_at = now() WHERE id = %s RETURNING status",
        (job_id,),
    )
    return row["status"] if row else None


def job_status(job_id: str) -> str | None:
    row = one("SELECT status FROM public.training_jobs WHERE id = %s", (job_id,))
    return row["status"] if row else None


def update_job(job_id: str, **fields: Any) -> None:
    if not fields:
        return
    sets = ", ".join(f"{k} = %({k})s" for k in fields)
    execute(
        f"UPDATE public.training_jobs SET {sets}, heartbeat_at = now() WHERE id = %(id)s",
        {**fields, "id": job_id},
    )


def finish_job(job_id: str, status: str, *, error: str | None = None,
               result: dict | None = None, message: str | None = None) -> None:
    execute(
        """
        UPDATE public.training_jobs
        SET status = %(st)s, finished_at = now(), heartbeat_at = now(),
            progress = CASE WHEN %(st)s = 'done' THEN 100 ELSE progress END,
            error_message = %(err)s,
            result = coalesce(%(res)s, result),
            message = coalesce(%(msg)s, message)
        WHERE id = %(id)s
        """,
        {"st": status, "err": error, "res": _adapt(result), "msg": message, "id": job_id},
    )


def log(job_id: str, message: str, level: str = "info", experiment_id: str | None = None) -> None:
    execute(
        "INSERT INTO public.training_logs (job_id, experiment_id, level, message) VALUES (%s, %s, %s, %s)",
        (job_id, experiment_id, level, message[:4000]),
    )


# ---------------------------------------------------------------------------
# Datasets
# ---------------------------------------------------------------------------
def get_dataset(dataset_id: str) -> dict | None:
    return one("SELECT * FROM public.ml_datasets WHERE id = %s", (dataset_id,))


def update_dataset(dataset_id: str, **fields: Any) -> None:
    sets = ", ".join(f"{k} = %({k})s" for k in fields)
    execute(
        f"UPDATE public.ml_datasets SET {sets} WHERE id = %(id)s",
        {**fields, "id": dataset_id},
    )


# ---------------------------------------------------------------------------
# Experiments
# ---------------------------------------------------------------------------
def create_experiment(job: dict, config_: dict, *, budget_epochs: int | None = None,
                      rung: int | None = None) -> dict:
    return one(
        """
        INSERT INTO public.ml_experiments
          (job_id, dataset_id, language_code, config, status, budget_epochs, rung, total_epochs)
        VALUES (%(job)s, %(ds)s, %(lang)s, %(cfg)s, 'queued', %(b)s, %(r)s, %(b)s)
        RETURNING *
        """,
        {
            "job": job["id"],
            "ds": job.get("dataset_id"),
            "lang": job.get("language_code") or "UNKNOWN",
            "cfg": config_,
            "b": budget_epochs,
            "r": rung,
        },
    )


def update_experiment(experiment_id: str, **fields: Any) -> None:
    sets = ", ".join(f"{k} = %({k})s" for k in fields)
    execute(
        f"UPDATE public.ml_experiments SET {sets} WHERE id = %(id)s",
        {**fields, "id": experiment_id},
    )


def get_experiment(experiment_id: str) -> dict | None:
    return one("SELECT * FROM public.ml_experiments WHERE id = %s", (experiment_id,))


def record_epoch(experiment_id: str, epoch: int, logs: dict, lr: float | None,
                 duration_s: float) -> None:
    execute(
        """
        INSERT INTO public.ml_epoch_metrics
          (experiment_id, epoch, loss, accuracy, val_loss, val_accuracy, learning_rate, duration_s)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (experiment_id, epoch) DO UPDATE SET
          loss = EXCLUDED.loss, accuracy = EXCLUDED.accuracy,
          val_loss = EXCLUDED.val_loss, val_accuracy = EXCLUDED.val_accuracy,
          learning_rate = EXCLUDED.learning_rate, duration_s = EXCLUDED.duration_s,
          recorded_at = now()
        """,
        (
            experiment_id,
            epoch,
            _num(logs.get("loss")),
            _num(logs.get("accuracy")),
            _num(logs.get("val_loss")),
            _num(logs.get("val_accuracy")),
            _num(lr),
            duration_s,
        ),
    )


def epoch_history(experiment_id: str) -> list[dict]:
    return execute(
        "SELECT * FROM public.ml_epoch_metrics WHERE experiment_id = %s ORDER BY epoch",
        (experiment_id,),
    )


# ---------------------------------------------------------------------------
# Model registry
# ---------------------------------------------------------------------------
def insert_model(**fields: Any) -> dict:
    cols = ", ".join(fields)
    vals = ", ".join(f"%({k})s" for k in fields)
    return one(
        f"INSERT INTO public.ml_models ({cols}) VALUES ({vals}) RETURNING *",
        fields,
    )


def update_model(model_id: str, **fields: Any) -> None:
    sets = ", ".join(f"{k} = %({k})s" for k in fields)
    execute(
        f"UPDATE public.ml_models SET {sets}, updated_at = now() WHERE id = %(id)s",
        {**fields, "id": model_id},
    )


def get_model(model_id: str) -> dict | None:
    return one("SELECT * FROM public.ml_models WHERE id = %s", (model_id,))


def production_model(language_code: str | None) -> dict | None:
    if language_code:
        return one(
            "SELECT * FROM public.ml_models WHERE stage = 'production' AND language_code = %s",
            (language_code,),
        )
    return one(
        "SELECT * FROM public.ml_models WHERE stage = 'production' ORDER BY promoted_at DESC NULLS LAST LIMIT 1"
    )


def _num(value: Any) -> float | None:
    if value is None:
        return None
    try:
        f = float(value)
    except (TypeError, ValueError):
        return None
    return f if f == f and f not in (float("inf"), float("-inf")) else None


def to_json(value: Any) -> str:
    return json.dumps(value, default=str)
