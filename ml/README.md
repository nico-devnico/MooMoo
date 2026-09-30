# MooMoo ML — sign recognition training platform

Media → frames → MediaPipe Holistic → landmarks → sequences `[T, 258]` →
split without leakage → controlled augmentation → LSTM → Random Search +
Hyperband → evaluation → model registry → TFLite.

Everything is driven from **Admin > Modèles** in the app. The app only writes
rows (`ml_datasets`, `training_jobs`) in Supabase; the **worker** below consumes
the queue and writes progress, per-epoch metrics, logs, experiments and models
back. Closing the browser or the app never interrupts a training.

## Install

```bash
cd ml
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -r requirements.txt
```

Configuration is read from `ml/.env`, then `backend/.env` (`SUPABASE_DB_URL`
is required; `SUPABASE_SERVICE_ROLE_KEY` is only used to mirror artifacts to
Storage).

## Run

```bash
# Worker: analysis, preprocessing, training, search, evaluation, TFLite
.venv\Scripts\python -m moomoo_ml.worker          # --once to process a single job

# Inference API (libère le port 8000 s'il est déjà pris — évite WinError 10048)
start_api.bat
# ou : powershell -File start_api.ps1
```

Si vous lancez uvicorn à la main et que le port est occupé :

```powershell
Get-NetTCPConnection -LocalPort 8000 | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force }
.venv\Scripts\python -m uvicorn main:app --host 127.0.0.1 --port 8000
```

Several workers can run at once (jobs are claimed with `FOR UPDATE SKIP LOCKED`).
A job whose worker died is re-queued after `ML_STALE_JOB_SECONDS` and resumes
from its last checkpoint.

## Datasets

Local folder, local archive (`.zip`, `.tar.gz`) or `http(s)` URL of an archive.
Recognised layouts:

- `label/file.mp4`, `split/label/file.mp4`, `label/sample/0001.jpg` (frame folders);
- a `labels.csv` / `metadata.csv` / `labels.json` with `path,label[,signer][,split]`;
- unlabeled data + a **label mapping** (`chemin ou dossier = label`) set in the admin.

Labels are never guessed. Signer ids are read from the metadata or from names
like `signer03`, `P12`, `user_4`; with 3+ signers the split is signer-independent.
One language per dataset, and a model never mixes languages.

## Artifacts

`ml/artifacts/<LANG>/<EXP-XXX>/`: `model.keras`, `model.tflite`, `labels.json`,
`preprocessing.json`, `metadata.json`, `metrics.json`, `history.json`,
`history.csv`, `confusion_matrix.json`, `training.log`, checkpoints.
Landmark cache: `ml/cache/features/<dataset>/`.

## Registry stages

`TRAINED → EVALUATED → VALIDATED → STAGING → PRODUCTION` (+ `ARCHIVED`), enforced
by the SQL function `promote_ml_model`: production is only reachable from
staging, and the previous production model of the same language is archived.

## Endpoints (FastAPI)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | State, queue, TensorFlow/MediaPipe availability |
| POST | `/infer` | `landmarks` (JSON `[frames, 258]`) or `file` (video/GIF) + `language` |

`/infer` answers 503 `no_production_model` until a model of that language is
promoted to production.

### Fingerspelling (ASL alphabet → phrase)

Still images are classified by the bundled CNN-BiLSTM in
`ml/models/fingerspell/` (trained from `ml/dataset/`). Use:

```bash
# One frame + session buffer (space / del / letters)
curl -F file=@frame.jpg -F session_id=demo http://127.0.0.1:8000/infer/spell

# List / activate versions (admin UI + API)
curl http://127.0.0.1:8000/fingerspell/models
curl -X POST http://127.0.0.1:8000/fingerspell/models/asl-lstm-v1/activate
```

Or `POST /api/infer/spell` and `/api/fingerspell/*` via the Node backend. The
Flutter translator captures frames in a loop while translation is on and
assembles the phrase live. Admins switch the active version from **Modèles →
Épellation**.

Training images live under `ml/dataset/asl_alphabet_train/` (gitignored).
Retrain with `cd ml/dataset && python train.py`, then register the new TFLite
under `ml/models/fingerspell/versions/<id>/`.

## Tests

```bash
.venv\Scripts\python -m pytest tests -q
```

TensorFlow tests (training, resume, cancellation, TFLite export) are skipped
when TensorFlow is not installed.
