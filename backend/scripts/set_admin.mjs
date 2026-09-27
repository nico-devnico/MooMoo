/**
 * Grants or revokes the admin flag for an account. Bootstrap the very first
 * admin with this, then manage the others from the admin UI.
 *
 * Usage: cd backend && node scripts/set_admin.mjs <email> [true|false]
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

const [email, flag = 'true'] = process.argv.slice(2);
if (!email) {
  console.error('Usage: node scripts/set_admin.mjs <email> [true|false]');
  process.exit(2);
}

const client = new pg.Client({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false },
});
await client.connect();

const { rows } = await client.query(
  `UPDATE public.profiles SET is_admin = $2, updated_at = now()
   WHERE lower(email) = lower($1)
   RETURNING id, email, display_name, is_admin`,
  [email, flag === 'true'],
);

if (!rows.length) {
  console.error(`No account found for ${email}`);
  await client.end();
  process.exit(1);
}

console.log(`${rows[0].email} (${rows[0].display_name || '-'}) is_admin=${rows[0].is_admin}`);
await client.end();
