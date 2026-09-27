# Architecture MooMoo

```
Flutter (Supabase Auth + REST)
        │
        ▼
 Node Express :3001  ──►  Supabase (Postgres / Auth)
        │
        ▼
 Python FastAPI :8000  (WASL / LSFB stub inference)
```

## Lancer

```bash
# Terminal 1 — ML
cd ml
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000

# Terminal 2 — API
cd backend
copy .env.example .env
npm install
npm start

# Terminal 3 — App
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3001
# Android émulateur: http://10.0.2.2:3001
```

## Migrations SQL (obligatoire pour admin / modèles)

Dans le SQL Editor Supabase, exécuter dans l’ordre :

1. `supabase/migrations/20260324000000_profiles_trigger.sql`
2. `supabase/migrations/20260324000001_core_admin_schema.sql`
3. `supabase/migrations/20260324000002_ai_models_schema.sql`
4. `supabase/migrations/20260324000003_fix_live_profiles.sql`

Ou : `supabase db push` si le CLI est lié.

Sans `SUPABASE_SERVICE_ROLE_KEY` dans `backend/.env`, les routes admin qui écrivent (`activate`, `retrain`, `set is_admin`) renvoient 503.
