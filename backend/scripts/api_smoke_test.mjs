/**
 * Full stack smoke: ML health, Node health, signup/login via Node, infer.
 * Start services first: Python :8000, Node :3001
 */
const API = process.env.API_URL || 'http://127.0.0.1:3001';
const ML = process.env.ML_URL || 'http://127.0.0.1:8000';

async function check(name, fn) {
  try {
    const detail = await fn();
    console.log(`OK   ${name}`, detail ? `— ${detail}` : '');
    return true;
  } catch (e) {
    console.log(`FAIL ${name} — ${e.message}`);
    return false;
  }
}

const email = `moomoo_api_${Date.now()}@example.com`;
const password = 'TestPass123!';
let token = null;
let results = 0;
let fails = 0;

async function run() {
  if (!(await check('ml.health', async () => {
    const r = await fetch(`${ML}/health`);
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const j = await r.json();
    return j.service;
  }))) fails++; else results++;

  if (!(await check('api.health', async () => {
    const r = await fetch(`${API}/health`);
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const j = await r.json();
    return `database=${j.database ?? 'n/a'}`;
  }))) fails++; else results++;

  if (!(await check('api.signup', async () => {
    const r = await fetch(`${API}/api/auth/signup`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        displayName: 'API Smoke',
        isDeaf: false,
      }),
    });
    const j = await r.json();
    if (!r.ok) throw new Error(`${r.status} ${j.message || JSON.stringify(j)}`);
    token = j.session?.access_token || null;
    return `user=${j.user?.id} session=${Boolean(token)} warn=${j.warning || ''}`;
  }))) fails++; else results++;

  if (!(await check('api.login', async () => {
    const r = await fetch(`${API}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const j = await r.json();
    if (!r.ok) throw new Error(`${r.status} ${j.message || JSON.stringify(j)}`);
    token = j.session?.access_token || token;
    return `session=${Boolean(token)}`;
  }))) fails++; else results++;

  if (!(await check('api.me', async () => {
    if (!token) throw new Error('no token');
    const r = await fetch(`${API}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const j = await r.json();
    if (!r.ok) throw new Error(`${r.status} ${j.message || JSON.stringify(j)}`);
    return `profile=${j.profile?.id} is_admin=${j.profile?.is_admin}`;
  }))) fails++; else results++;

  if (!(await check('api.models', async () => {
    const r = await fetch(`${API}/api/models`);
    const j = await r.json();
    if (!r.ok) throw new Error(`${r.status} ${j.message || JSON.stringify(j)}`);
    return `count=${(j.models || []).length}`;
  }))) fails++; else results++;

  if (!(await check('api.infer', async () => {
    const form = new FormData();
    form.append('hint', 'merci');
    const r = await fetch(`${API}/api/infer`, { method: 'POST', body: form });
    const j = await r.json();
    // Until a real model is served, an explicit 503 is the expected answer.
    if (r.status === 503 && j.ok === false) return `unavailable (${j.error})`;
    if (!r.ok) throw new Error(`${r.status} ${j.message || JSON.stringify(j)}`);
    if (j.prediction?.label === 'merci') throw new Error('label echoes the hint');
    return `label=${j.prediction?.label} conf=${j.prediction?.confidence}`;
  }))) fails++; else results++;

  await removeTestAccount();
  console.log(`\npassed=${results} failed=${fails}`);
  process.exit(fails ? 1 : 0);
}

/** The signup check creates a real account: delete it when the database is reachable. */
async function removeTestAccount() {
  try {
    await import('dotenv/config');
    const { hasDirectDb, query, getPool } = await import('../src/pgdb.js');
    if (!hasDirectDb()) return;
    const { rowCount } = await query('delete from auth.users where email = $1', [email]);
    await getPool().end();
    console.log(`cleanup: ${rowCount} compte de test supprimé`);
  } catch (e) {
    console.log(`cleanup ignoré — ${e.message}`);
  }
}

run();
