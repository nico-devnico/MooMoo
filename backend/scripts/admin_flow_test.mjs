/**
 * Exercises the admin surface end to end against the live database, using only
 * the admin's own JWT (no service role key). Requires the Node API on :3001.
 *
 * Usage: cd backend && node scripts/admin_flow_test.mjs
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

const API = process.env.API_URL || 'http://127.0.0.1:3001';
const results = [];

function log(name, ok, detail) {
  results.push({ name, ok });
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${name}${detail ? ` — ${detail}` : ''}`);
}

async function api(path, { method = 'GET', token, body } = {}) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, json };
}

const db = new pg.Client({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false },
});

async function main() {
  await db.connect();

  const stamp = Date.now();
  const admin = { email: `moomoo_admin_${stamp}@example.com`, password: 'TestPass123!' };
  const plain = { email: `moomoo_user_${stamp}@example.com`, password: 'TestPass123!' };

  const created = [];
  for (const u of [admin, plain]) {
    const r = await api('/api/auth/signup', {
      method: 'POST',
      body: { email: u.email, password: u.password, displayName: 'Flow test' },
    });
    u.id = r.json?.user?.id;
    u.token = r.json?.session?.access_token;
    created.push(u.id);
  }
  log('signup x2', created.every(Boolean), created.join(', '));

  // Bootstrap the first admin the way a real operator would: straight in SQL.
  await db.query('UPDATE public.profiles SET is_admin = true WHERE id = $1', [admin.id]);
  log('bootstrap admin in SQL', true, admin.email);

  const forbidden = await api('/api/admin/stats', { token: plain.token });
  log('non-admin blocked on /api/admin/stats', forbidden.status === 403, `HTTP ${forbidden.status}`);

  const stats = await api('/api/admin/stats', { token: admin.token });
  log(
    'admin stats',
    stats.status === 200 && !!stats.json.stats,
    stats.status === 200 ? JSON.stringify(stats.json.stats) : JSON.stringify(stats.json),
  );

  const users = await api('/api/admin/users?limit=5', { token: admin.token });
  log(
    'admin users list',
    users.status === 200 && Array.isArray(users.json.users),
    `${users.json.users?.length ?? 0} row(s)`,
  );

  const promote = await api(`/api/admin/users/${plain.id}/admin`, {
    method: 'PATCH',
    token: admin.token,
    body: { isAdmin: true },
  });
  const promoted = await db.query('SELECT is_admin FROM public.profiles WHERE id = $1', [plain.id]);
  log(
    'admin promotes another user (no service role)',
    promote.status === 200 && promoted.rows[0]?.is_admin === true,
    `HTTP ${promote.status} is_admin=${promoted.rows[0]?.is_admin}`,
  );

  const demote = await api(`/api/admin/users/${plain.id}/admin`, {
    method: 'PATCH',
    token: admin.token,
    body: { isAdmin: false },
  });
  log('admin revokes admin', demote.status === 200, `HTTP ${demote.status}`);

  const contributions = await api('/api/admin/contributions?status=pending', {
    token: admin.token,
  });
  log(
    'admin contributions queue',
    contributions.status === 200,
    `${contributions.json.contributions?.length ?? 0} pending`,
  );

  const signs = await api('/api/admin/signs', { token: admin.token });
  log('admin signs list', signs.status === 200, `${signs.json.signs?.length ?? 0} row(s)`);

  const models = await api('/api/models');
  const modelId = models.json.models?.[0]?.id;
  const previouslyActive = models.json.models?.find((m) => m.is_active)?.id;
  log('models list', models.status === 200 && !!modelId, `${models.json.models?.length ?? 0} model(s)`);

  const metrics = await api(`/api/models/${modelId}/metrics`);
  log(
    'model metrics',
    metrics.status === 200 && !!metrics.json.metrics,
    metrics.json.metrics
      ? `accuracy=${metrics.json.metrics.accuracy} latency=${metrics.json.metrics.latency_ms}`
      : 'none',
  );

  // Activate the model that is currently inactive, so the call really changes state.
  const inactive = models.json.models?.find((m) => !m.is_active) || models.json.models?.[0];
  const activate = await api(`/api/models/${inactive.id}/activate`, {
    method: 'POST',
    token: admin.token,
  });
  const activeRow = await db.query('SELECT id FROM public.ml_models WHERE is_active = true');
  log(
    'admin activates model',
    activate.status === 200 && activeRow.rows[0]?.id === inactive.id,
    `HTTP ${activate.status} active=${activeRow.rows[0]?.id}`,
  );

  const retrain = await api('/api/models/retrain', {
    method: 'POST',
    token: admin.token,
    body: { dataset: 'WASL+LSFB', modelId: inactive.id },
  });
  log(
    'admin queues retraining job',
    retrain.status === 201 && !!retrain.json.job?.id,
    `HTTP ${retrain.status} status=${retrain.json.job?.status}`,
  );

  const jobs = await api('/api/models/jobs', { token: admin.token });
  log('admin job history', jobs.status === 200, `${jobs.json.jobs?.length ?? 0} job(s)`);

  const jobsForbidden = await api('/api/models/jobs', { token: plain.token });
  log(
    'non-admin sees no jobs',
    jobsForbidden.status !== 200 || (jobsForbidden.json.jobs || []).length === 0,
    `HTTP ${jobsForbidden.status} ${(jobsForbidden.json.jobs || []).length} job(s)`,
  );

  // Cleanup: training job rows reference the users we are about to delete.
  await db.query('DELETE FROM public.training_jobs WHERE requested_by = ANY($1::uuid[])', [created]);
  await db.query('DELETE FROM auth.users WHERE id = ANY($1::uuid[])', [created]);
  if (previouslyActive) {
    // idx_ml_models_single_active is a non-deferrable partial unique index, so
    // clearing and setting has to happen in two statements.
    await db.query('UPDATE public.ml_models SET is_active = false WHERE is_active = true');
    await db.query('UPDATE public.ml_models SET is_active = true WHERE id = $1', [previouslyActive]);
  }
  log('cleanup test users and restore active model', true, `${created.length} deleted`);

  const failed = results.filter((r) => !r.ok);
  console.log(`\npassed=${results.length - failed.length} failed=${failed.length}`);
  if (failed.length) console.log(`failing: ${failed.map((f) => f.name).join(', ')}`);
  await db.end();
  process.exit(failed.length ? 1 : 0);
}

main().catch(async (e) => {
  console.error(e);
  await db.end().catch(() => {});
  process.exit(1);
});
