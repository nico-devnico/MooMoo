# Supabase (MooMoo)

## Migrations

Fichiers dans `migrations/`, appliqués dans l’ordre des timestamps :

| Fichier | Contenu |
|---------|---------|
| `20260324000000_profiles_trigger.sql` | Table `profiles`, trigger `on_auth_user_created`, RLS de base |
| `20260324000001_core_admin_schema.sql` | `is_admin`, `is_current_user_admin()`, contributions, signs, RLS admin |
| `20260324000002_ai_models_schema.sql` | `ml_models`, `model_metrics`, `training_jobs`, `set_active_ml_model()`, seeds WASL/LSFB |
| `20260324000003_fix_live_profiles.sql` | Colonnes manquantes sur une base déjà en production |
| `20260324000004_reference_tables_rls.sql` | Politiques de lecture sur `sign_languages` / `sign_categories` |
| `20260324000005_protect_profile_privileges.sql` | Empêche un utilisateur de se donner `is_admin` |

### Appliquer

Le point d’accès direct `db.<ref>.supabase.co` n’est joignable qu’en IPv6 ; sur un
réseau IPv4 il faut passer par le pooler. Renseigner dans `backend/.env` :

```
SUPABASE_DB_URL=postgresql://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres
```

puis :

```bash
cd backend
npm run migrate
```

Le script rejoue uniquement les migrations absentes de
`supabase_migrations.schema_migrations`, donc il est sûr de le relancer.
`node scripts/find_pooler.mjs <ref> <password>` retrouve la région si besoin.

Alternative : CLI officiel (`supabase link --project-ref <ref>` puis `supabase db push`),
ou copier les SQL dans le SQL Editor du dashboard.

### Vérifier

```bash
cd backend
node ../scripts/supabase_smoke_test.mjs   # auth + toutes les tables lues par l’app
node scripts/admin_flow_test.mjs          # parcours admin complet (API sur :3001)
node scripts/inspect_schema.mjs profiles  # colonnes + politiques d’une table
```

### Premier administrateur

```bash
cd backend
node scripts/set_admin.mjs <email> true
```

Ensuite les promotions se font depuis l’écran Administration.

Le client Flutter n’embarque **jamais** la `service_role` key — uniquement l’URL
et la clé anon. Les écritures admin passent par les politiques RLS avec le JWT
de l’administrateur.
