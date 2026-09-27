"""Worker <-> Supabase integration: a real analyze job through worker.process().

Opt-in (writes to the configured database, then deletes its rows):
    set MOOMOO_DB_TESTS=1 && python -m pytest tests/test_worker_db.py -q
"""

import os

import pytest

from moomoo_ml import config

pytestmark = pytest.mark.skipif(
    os.environ.get("MOOMOO_DB_TESTS") != "1" or not config.DB_URL,
    reason="MOOMOO_DB_TESTS=1 and SUPABASE_DB_URL required",
)


@pytest.fixture
def rows():
    from moomoo_ml import db

    created = {"jobs": [], "datasets": []}
    yield created
    for job_id in created["jobs"]:
        db.execute("DELETE FROM public.training_logs WHERE job_id = %s", (job_id,))
        db.execute("DELETE FROM public.training_jobs WHERE id = %s", (job_id,))
    for ds_id in created["datasets"]:
        db.execute("DELETE FROM public.ml_datasets WHERE id = %s", (ds_id,))


def _job(rows, tmp_path, status="running"):
    from moomoo_ml import db
    from tests.test_datasets import _structured

    _structured(tmp_path)
    ds = db.one(
        """INSERT INTO public.ml_datasets (name, language_code, source_type, uri)
           VALUES ('pytest-worker', 'LSFB', 'local', %s) RETURNING *""",
        (str(tmp_path),),
    )
    rows["datasets"].append(ds["id"])
    job = db.one(
        """INSERT INTO public.training_jobs
             (kind, dataset, dataset_id, language_code, status, progress, attempts, worker_id, started_at)
           VALUES ('analyze', 'pytest-worker', %s, 'LSFB', %s, 0, 1, 'pytest', now()) RETURNING *""",
        (ds["id"], status),
    )
    rows["jobs"].append(job["id"])
    return ds, job


def test_analyze_job_round_trip(rows, tmp_path):
    from moomoo_ml import db, worker

    ds, job = _job(rows, tmp_path)
    worker.process(job)

    done = db.one("SELECT * FROM public.training_jobs WHERE id = %s", (job["id"],))
    assert done["status"] == "done", done["error_message"]
    assert float(done["progress"]) == 100
    assert done["result"]["classes"] == 3 and done["result"]["trainable"] is True

    analyzed = db.get_dataset(ds["id"])
    assert analyzed["status"] == "analyzed"
    assert analyzed["analysis"]["classes"] == {"bonjour": 4, "oui": 4, "merci": 3}
    assert analyzed["analysis"]["invalid_count"] == 1

    logs = db.execute("SELECT level, message FROM public.training_logs WHERE job_id = %s", (job["id"],))
    assert any("classes" in l["message"] for l in logs)
    assert any(l["level"] == "warning" for l in logs)


def test_cancel_request_is_honoured(rows, tmp_path):
    from moomoo_ml import db, worker

    _, job = _job(rows, tmp_path, status="cancelling")
    worker.process(job)
    final = db.one("SELECT status FROM public.training_jobs WHERE id = %s", (job["id"],))
    assert final["status"] == "cancelled"
