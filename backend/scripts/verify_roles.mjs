/**
 * Read-only check after the roles, suspension and purge migrations.
 * Usage: cd backend && node scripts/verify_roles.mjs
 */
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
for (const p of [resolve(root, '.env'), resolve(root, 'backend', '.env')]) {
  if (!existsSync(p)) continue;
  for (const line of readFileSync(p, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].trim();
  }
}

const client = new pg.Client({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false },
});
await client.connect();

const { rows: roles } = await client.query(
  `SELECT p.email, p.is_admin, p.status, coalesce(array_agg(r.role) FILTER (WHERE r.role IS NOT NULL), '{}') AS roles
   FROM public.profiles p
   LEFT JOIN public.user_roles r ON r.user_id = p.id
   GROUP BY p.email, p.is_admin, p.status
   ORDER BY p.email`,
);
console.log('profiles');
for (const row of roles) {
  console.log(`  ${row.email} admin=${row.is_admin} status=${row.status} roles=${row.roles}`);
}

const { rows: policies } = await client.query(
  `SELECT tablename, policyname FROM pg_policies
   WHERE schemaname = 'public'
     AND policyname IN ('public_read_signs', 'read_contributions')`,
);
console.log(`legacy policies left: ${policies.length}`);

const { rows: counts } = await client.query(
  `SELECT
     (SELECT count(*) FROM public.ml_models) AS models,
     (SELECT count(*) FROM public.model_metrics) AS metrics`,
);
console.log(`ml_models=${counts[0].models} model_metrics=${counts[0].metrics}`);

const { rows: dead } = await client.query(
  `SELECT table_name FROM information_schema.tables
   WHERE table_schema = 'public' AND table_name IN ('ai_models', 'translation_cache')`,
);
console.log(`dead tables left: ${dead.map((r) => r.table_name).join(', ') || 'none'}`);

await client.end();
