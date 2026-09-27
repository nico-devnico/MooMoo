/**
 * Applies supabase/migrations/*.sql to a Postgres database, in filename order.
 *
 * Usage:
 *   cd backend && npm run migrate
 *
 * Connection string is read from SUPABASE_DB_URL (env, .env or backend/.env).
 * Get it from Supabase Dashboard > Project Settings > Database > Connection string (URI).
 *
 * Already-applied migrations are skipped via supabase_migrations.schema_migrations,
 * the same bookkeeping table the Supabase CLI uses.
 */
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..', '..');
const migrationsDir = resolve(root, 'supabase', 'migrations');

function loadDotEnv() {
  for (const p of [resolve(root, '.env'), resolve(root, 'backend', '.env')]) {
    if (!existsSync(p)) continue;
    for (const line of readFileSync(p, 'utf8').split(/\r?\n/)) {
      const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
      if (!m) continue;
      let val = m[2].trim();
      if (/^(".*"|'.*')$/s.test(val)) val = val.slice(1, -1);
      if (!process.env[m[1]]) process.env[m[1]] = val;
    }
  }
}

loadDotEnv();

const dbUrl = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;
if (!dbUrl) {
  console.error(
    'SUPABASE_DB_URL is missing.\n' +
      'Add it to backend/.env (never commit it):\n' +
      '  SUPABASE_DB_URL=postgresql://postgres.<ref>:<password>@<host>:5432/postgres',
  );
  process.exit(2);
}

const versionOf = (file) => basename(file).split('_')[0];

async function main() {
  const files = readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  const client = new pg.Client({
    connectionString: dbUrl,
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  console.log(`connected: ${dbUrl.replace(/:[^:@/]+@/, ':****@')}`);

  await client.query('CREATE SCHEMA IF NOT EXISTS supabase_migrations');
  await client.query(
    `CREATE TABLE IF NOT EXISTS supabase_migrations.schema_migrations (
       version text PRIMARY KEY,
       name text,
       statements text[],
       inserted_at timestamptz NOT NULL DEFAULT now()
     )`,
  );
  await client.query(
    'ALTER TABLE supabase_migrations.schema_migrations ADD COLUMN IF NOT EXISTS inserted_at timestamptz DEFAULT now()',
  );

  const { rows } = await client.query(
    'SELECT version FROM supabase_migrations.schema_migrations',
  );
  const applied = new Set(rows.map((r) => r.version));

  let ran = 0;
  for (const file of files) {
    const version = versionOf(file);
    if (applied.has(version)) {
      console.log(`skip    ${file} (already applied)`);
      continue;
    }
    const sql = readFileSync(resolve(migrationsDir, file), 'utf8');
    process.stdout.write(`apply   ${file} ... `);
    try {
      await client.query('BEGIN');
      await client.query(sql);
      await client.query(
        'INSERT INTO supabase_migrations.schema_migrations (version, name) VALUES ($1, $2) ON CONFLICT (version) DO NOTHING',
        [version, file],
      );
      await client.query('COMMIT');
      console.log('OK');
      ran += 1;
    } catch (e) {
      await client.query('ROLLBACK');
      console.log('FAILED');
      console.error(`  ${e.message}`);
      await client.end();
      process.exit(1);
    }
  }

  console.log(`\ndone: ${ran} applied, ${files.length - ran} skipped`);
  await client.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
