/**
 * Prints the auth.users / auth.identities columns and the privileges of the
 * connection role, to check that direct-SQL account management is possible.
 * Usage: cd backend && node scripts/inspect_auth.mjs
 */
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
for (const p of [resolve(root, 'backend', '.env')]) {
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

for (const table of ['users', 'identities']) {
  const { rows } = await client.query(
    `SELECT column_name, data_type, is_nullable, column_default, is_generated
     FROM information_schema.columns
     WHERE table_schema = 'auth' AND table_name = $1
     ORDER BY ordinal_position`,
    [table],
  );
  console.log(`\n=== auth.${table} ===`);
  for (const c of rows) {
    console.log(
      `  ${c.column_name.padEnd(30)} ${c.data_type.padEnd(26)} ${c.is_nullable === 'YES' ? 'null' : 'NOT NULL'}` +
        `${c.column_default ? ` default ${c.column_default}` : ''}${c.is_generated === 'ALWAYS' ? ' GENERATED' : ''}`,
    );
  }
}

const who = await client.query(
  `SELECT current_user,
          has_table_privilege('auth.users', 'INSERT') AS can_insert,
          has_table_privilege('auth.users', 'DELETE') AS can_delete,
          (SELECT extnamespace::regnamespace::text FROM pg_extension WHERE extname = 'pgcrypto') AS pgcrypto_schema,
          (SELECT count(*) FROM auth.users) AS users`,
);
console.log('\n', who.rows[0]);
await client.end();
