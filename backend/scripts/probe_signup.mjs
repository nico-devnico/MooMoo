/**
 * Reproduces the Supabase signup call the Flutter client makes, and prints the
 * raw error body so a 422 can be told apart from a weak password, a disabled
 * signup or an already-registered address.
 *
 * Usage: cd backend && node scripts/probe_signup.mjs [email] [password]
 */
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..', '..');

for (const p of [resolve(root, '.env'), resolve(root, 'backend', '.env')]) {
  if (!existsSync(p)) continue;
  for (const line of readFileSync(p, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].trim();
  }
}

const URL = process.env.SUPABASE_URL;
const ANON = process.env.SUPABASE_ANON_KEY;

const [emailArg, passwordArg] = process.argv.slice(2);
const email = emailArg || `probe_${Date.now()}@example.com`;
const password = passwordArg || 'TestPass123!';

async function post(path, body) {
  const res = await fetch(`${URL}${path}`, {
    method: 'POST',
    headers: {
      apikey: ANON,
      Authorization: `Bearer ${ANON}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.text() };
}

console.log(`signup ${email} / ${password}`);
const signup = await post('/auth/v1/signup', {
  email,
  password,
  data: { display_name: 'Probe' },
});
console.log(`HTTP ${signup.status}`);
console.log(signup.body.slice(0, 600));

const settings = await fetch(`${URL}/auth/v1/settings`, {
  headers: { apikey: ANON, Authorization: `Bearer ${ANON}` },
});
console.log('\nauth settings:');
console.log((await settings.text()).slice(0, 600));
