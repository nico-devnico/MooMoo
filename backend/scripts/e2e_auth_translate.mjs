/**
 * E2E : santé → signup → login → me → spell (crop main) → cleanup.
 * Prérequis : ML :8000, API :3001
 */
import { readFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const API = process.env.API_URL || 'http://127.0.0.1:3001';
const ML = process.env.ML_URL || 'http://127.0.0.1:8000';
const __dir = dirname(fileURLToPath(import.meta.url));
const root = join(__dir, '../..');

const email = `moomoo_e2e_${Date.now()}@example.com`;
const password = 'TestPass123!';
let token = null;
let passed = 0;
let failed = 0;
const lines = [];

function log(msg) {
  console.log(msg);
  lines.push(msg);
}

async function check(name, fn) {
  try {
    const detail = await fn();
    log(`OK   ${name}${detail ? ` — ${detail}` : ''}`);
    passed++;
    return true;
  } catch (e) {
    log(`FAIL ${name} — ${e.message}`);
    failed++;
    return false;
  }
}

function holdoutPath() {
  const p = join(
    root,
    'ml/dataset/asl_alphabet_test/asl_alphabet_test/A_test.jpg',
  );
  return existsSync(p) ? p : null;
}

async function run() {
  log('=== MooMoo E2E auth → traduction ===');
  log(`API=${API}  ML=${ML}`);
  log('');

  await check('ml.health', async () => {
    const r = await fetch(`${ML}/health`);
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const j = await r.json();
    return j.service || j.status || 'up';
  });

  await check('ml.fingerspell.warmup', async () => {
    const r = await fetch(`${ML}/health`);
    const j = await r.json();
    const fs = j.fingerspell;
    if (fs && fs.available === false) throw new Error(fs.detail || 'unavailable');
    return fs ? `runtime=${fs.runtime || 'ok'}` : 'no-fingerspell-field';
  });

  await check('api.health', async () => {
    const r = await fetch(`${API}/health`);
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const j = await r.json();
    return `database=${j.database ?? 'n/a'}`;
  });

  await check('api.signup', async () => {
    const r = await fetch(`${API}/api/auth/signup`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        displayName: 'E2E Translate',
        isDeaf: false,
      }),
    });
    const j = await r.json();
    if (!r.ok) throw new Error(`${r.status} ${j.message || JSON.stringify(j)}`);
    token = j.session?.access_token || null;
    return `user=${j.user?.id?.slice?.(0, 8) || '?'} session=${Boolean(token)}`;
  });

  await check('api.login', async () => {
    const r = await fetch(`${API}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const j = await r.json();
    if (!r.ok) throw new Error(`${r.status} ${j.message || JSON.stringify(j)}`);
    token = j.session?.access_token || token;
    return `session=${Boolean(token)}`;
  });

  await check('api.me', async () => {
    if (!token) throw new Error('no token');
    const r = await fetch(`${API}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const j = await r.json();
    if (!r.ok) throw new Error(`${r.status} ${j.message || JSON.stringify(j)}`);
    return `profile=${j.profile?.id?.slice?.(0, 8) || '?'}`;
  });

  const imgPath = holdoutPath();
  await check('api.infer.spell.hand_crop', async () => {
    if (!imgPath) throw new Error('holdout A_test.jpg manquant');
    const buf = readFileSync(imgPath);
    const form = new FormData();
    form.append('file', new Blob([buf], { type: 'image/jpeg' }), 'hand.jpg');
    form.append('reset', 'true');
    form.append('single_shot', 'true');
    form.append('threshold', '0.35');
    const r = await fetch(`${API}/api/infer/spell`, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: form,
    });
    const j = await r.json();
    if (!r.ok) throw new Error(`${r.status} ${j.message || JSON.stringify(j)}`);
    const label = j.prediction?.label || j.label;
    const conf = j.prediction?.confidence ?? j.confidence;
    const text = j.prediction?.text ?? j.text;
    if (!label) throw new Error('pas de label');
    return `label=${label} conf=${Number(conf).toFixed(3)} text=${text || ''} ms=${j.prediction?.latency_ms ?? '?'}`;
  });

  await check('ml.infer.spell.direct', async () => {
    if (!imgPath) throw new Error('holdout manquant');
    const buf = readFileSync(imgPath);
    const form = new FormData();
    form.append('file', new Blob([buf], { type: 'image/jpeg' }), 'hand.jpg');
    form.append('single_shot', 'true');
    form.append('reset', 'true');
    const r = await fetch(`${ML}/infer/spell`, { method: 'POST', body: form });
    const j = await r.json();
    if (!r.ok) throw new Error(`${r.status} ${JSON.stringify(j)}`);
    return `label=${j.label} conf=${Number(j.confidence).toFixed(3)} latency=${j.latency_ms}ms`;
  });

  await cleanup();
  log('');
  log(`passed=${passed} failed=${failed}`);
  process.exit(failed ? 1 : 0);
}

async function cleanup() {
  try {
    await import('dotenv/config');
    const { hasDirectDb, query, getPool } = await import('../src/pgdb.js');
    if (!hasDirectDb()) {
      log('cleanup ignoré — pas de DB directe');
      return;
    }
    const { rowCount } = await query('delete from auth.users where email = $1', [email]);
    await getPool().end();
    log(`cleanup: ${rowCount} compte(s) supprimé(s)`);
  } catch (e) {
    log(`cleanup ignoré — ${e.message}`);
  }
}

run();
