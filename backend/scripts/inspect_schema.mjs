/**
 * Prints the live public schema: tables, key columns, policies and triggers.
 * Usage: cd backend && node scripts/inspect_schema.mjs [table ...]
 */
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..', '..');

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

const only = process.argv.slice(2);

const tables = await client.query(
  `SELECT c.relname AS table, c.relrowsecurity AS rls,
          (SELECT count(*) FROM pg_policy p WHERE p.polrelid = c.oid) AS policies
   FROM pg_class c
   JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND c.relkind = 'r'
   ORDER BY c.relname`,
);

console.log('=== public tables ===');
for (const t of tables.rows) {
  console.log(
    `${t.table.padEnd(28)} rls=${t.rls ? 'on ' : 'off'} policies=${t.policies}`,
  );
}

for (const table of only) {
  const cols = await client.query(
    `SELECT column_name, data_type, is_nullable, column_default
     FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = $1
     ORDER BY ordinal_position`,
    [table],
  );
  console.log(`\n=== ${table} ===`);
  if (!cols.rowCount) {
    console.log('(table absente)');
    continue;
  }
  for (const c of cols.rows) {
    console.log(
      `  ${c.column_name.padEnd(26)} ${c.data_type.padEnd(28)} ` +
        `${c.is_nullable === 'YES' ? 'null' : 'not null'}` +
        `${c.column_default ? ` default ${c.column_default}` : ''}`,
    );
  }

  const pol = await client.query(
    `SELECT policyname, cmd, qual, with_check
     FROM pg_policies WHERE schemaname = 'public' AND tablename = $1
     ORDER BY policyname`,
    [table],
  );
  for (const p of pol.rows) {
    console.log(
      `  policy ${p.policyname} [${p.cmd}] using=${p.qual || '-'} check=${p.with_check || '-'}`,
    );
  }
}

const fns = await client.query(
  `SELECT p.proname
   FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public'
   ORDER BY p.proname`,
);
console.log(`\n=== public functions ===\n  ${fns.rows.map((r) => r.proname).join(', ')}`);

const trg = await client.query(
  `SELECT tgname FROM pg_trigger WHERE NOT tgisinternal ORDER BY tgname`,
);
console.log(`\n=== triggers ===\n  ${trg.rows.map((r) => r.tgname).join(', ')}`);

await client.end();
