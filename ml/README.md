# MooMoo ML (Python / FastAPI)

## Install

```bash
cd ml
python -m venv .venv
# Windows:
.venv\Scripts\activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Santé |
| GET | `/datasets` | WASL / LSFB |
| POST | `/infer` | multipart `file` + `hint` optionnel |
| POST | `/train` | `{ job_id, dataset }` |
| GET | `/train/{job_id}` | Statut job |

Aucun entraînement GPU réel — stub prêt pour brancher WASL/LSFB.
