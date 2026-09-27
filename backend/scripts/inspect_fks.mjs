/**
 * Lists foreign keys pointing to auth.users or public.profiles with their
 * ON DELETE rule: a NO ACTION rule there blocks account deletion.
 * Usage: cd backend && node scripts/inspect_fks.mjs
 */
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const envPath = resolve(root, 'backend', '.env');
if (existsSync(envPath)) {
  for (const line of readFileSync(envPath, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].trim();
  }
}

const client = new pg.Client({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false },
});
await client.connect();
const { rows } = await client.query(`
  SELECT con.conrelid::regclass::text AS tbl,
         a.attname AS col,
         con.confrelid::regclass::text AS ref,
         CASE con.confdeltype WHEN 'a' THEN 'NO ACTION' WHEN 'r' THEN 'RESTRICT'
              WHEN 'c' THEN 'CASCADE' WHEN 'n' THEN 'SET NULL' ELSE 'SET DEFAULT' END AS on_delete
  FROM pg_constraint con
  JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = ANY (con.conkey)
  WHERE con.contype = 'f'
    AND con.confrelid IN ('auth.users'::regclass, 'public.profiles'::regclass)
    AND con.connamespace = 'public'::regnamespace
  ORDER BY 1, 2`);
for (const r of rows) {
  console.log(`${r.tbl.padEnd(28)} ${r.col.padEnd(18)} -> ${r.ref.padEnd(16)} ${r.on_delete}`);
}
await client.end();
