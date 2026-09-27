/**
 * Lists real accounts and removes the throwaway accounts left by the smoke tests.
 * Usage: cd backend && node scripts/cleanup_test_users.mjs [--delete]
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

const TEST_EMAIL = 'moomoo_(smoke|api|admin|user|test|diag)_<digits>@example.com';
const TEST_PATTERN = '^moomoo_(smoke|api|admin|user|test|diag)_[0-9]+@example\\.com$';

const client = new pg.Client({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false },
});
await client.connect();

const { rows: testUsers } = await client.query(
  'SELECT id, email FROM public.profiles WHERE email ~ $1 ORDER BY email',
  [TEST_PATTERN],
);
const { rows: realUsers } = await client.query(
  `SELECT id, email, display_name, is_admin, created_at FROM public.profiles
   WHERE email IS NULL OR email !~ $1
   ORDER BY created_at`,
  [TEST_PATTERN],
);

console.log(`=== real accounts (${realUsers.length}) ===`);
for (const u of realUsers) {
  console.log(
    `  ${(u.email || '(no email)').padEnd(34)} ${String(u.display_name || '-').padEnd(18)} admin=${u.is_admin}`,
  );
}
console.log(`\n=== throwaway test accounts (${testUsers.length}) matching ${TEST_EMAIL} ===`);

if (!process.argv.includes('--delete')) {
  console.log('dry run — re-run with --delete to remove them');
  await client.end();
  process.exit(0);
}

const ids = testUsers.map((u) => u.id);
if (ids.length) {
  await client.query('DELETE FROM public.training_jobs WHERE requested_by = ANY($1::uuid[])', [ids]);
  await client.query('DELETE FROM public.contributions WHERE contributor_id = ANY($1::uuid[])', [ids]);
  await client.query('DELETE FROM auth.users WHERE id = ANY($1::uuid[])', [ids]);
}
console.log(`deleted ${ids.length} test account(s)`);

await client.end();
