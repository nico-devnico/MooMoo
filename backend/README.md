# MooMoo Backend (Node / Express)

## Install & run

```bash
cd backend
cp .env.example .env
# Optionnel: SUPABASE_SERVICE_ROLE_KEY=... dans .env (jamais dans Flutter)
npm install
npm start
```

API: `http://127.0.0.1:3001`

## Routes

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | — | Santé |
| POST | `/api/auth/signup` | — | Inscription + ensure profile |
| POST | `/api/auth/login` | — | Connexion + ensure profile |
| POST | `/api/auth/ensure-profile` | JWT | Créer/mettre à jour profil |
| GET | `/api/auth/me` | JWT | User + profile |
| GET | `/api/admin/stats` | JWT admin | Stats |
| GET | `/api/admin/users` | JWT admin | Utilisateurs |
| PATCH | `/api/admin/users/:id/admin` | JWT admin | is_admin |
| GET | `/api/admin/contributions` | JWT admin | Modération |
| POST | `/api/admin/contributions/:id/review` | JWT admin | Approuver/rejeter |
| GET | `/api/admin/signs` | JWT admin | Signes |
| GET | `/api/models` | optional | Liste modèles |
| GET | `/api/models/active` | optional | Modèle actif |
| GET | `/api/models/jobs` | JWT admin | Jobs training |
| GET | `/api/models/:id/metrics` | optional | Métriques |
| POST | `/api/models/:id/activate` | JWT admin | Activer |
| POST | `/api/models/retrain` | JWT admin | Job réentraînement |
| POST | `/api/infer` | optional | Proxy → Python `/infer` |

Les écritures admin s’appuient sur les politiques RLS avec le JWT de
l’administrateur. `SUPABASE_SERVICE_ROLE_KEY` reste optionnelle : elle sert
seulement de raccourci côté serveur.

Le service Python doit tourner sur `ML_SERVICE_URL` (défaut `http://127.0.0.1:8000`).

## Scripts

```bash
npm run migrate                        # applique supabase/migrations/*.sql
npm run test:api                       # ML + API + auth + inférence
node scripts/admin_flow_test.mjs       # parcours admin complet
node ../scripts/supabase_smoke_test.mjs  # connexion Supabase, toutes les tables
node scripts/set_admin.mjs <email> true  # premier administrateur
node scripts/inspect_schema.mjs [table]  # colonnes + politiques
node scripts/cleanup_test_users.mjs      # comptes jetables des tests (--delete)
```

`SUPABASE_DB_URL` (chaîne de connexion Postgres) est requise pour les scripts
qui touchent au schéma. Elle vit dans `backend/.env`, jamais dans le dépôt.
