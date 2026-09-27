/**
 * Connection tests against Supabase, using the anon key the Flutter app uses.
 * Covers auth (signup/login), every table the app reads or writes, the admin
 * helper function, and the admin-only paths when a service role key is present.
 *
 * Usage: node scripts/supabase_smoke_test.mjs
 */
import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');

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

const URL = process.env.SUPABASE_URL || 'https://pckgblyvjgztogjykrvw.supabase.co';
const ANON =
  process.env.SUPABASE_ANON_KEY || 'sb_publishable_QwdkQxxJWh9MpnXdvADCGA_BLS5lHY8';
const SERVICE = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

const results = [];

function log(name, ok, detail) {
  results.push({ name, ok });
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${name}${detail ? ` — ${detail}` : ''}`);
}

async function req(path, { method = 'GET', token = ANON, body, prefer } = {}) {
  const headers = {
    apikey: ANON,
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
  if (prefer) headers.Prefer = prefer;
  const res = await fetch(`${URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = text;
  }
  return { status: res.status, json };
}

const short = (v) => JSON.stringify(v).slice(0, 160);

// Tables the Flutter app reads, with the columns it actually selects.
const READ_TABLES = [
  ['sign_languages', 'id,code,name'],
  ['sign_categories', '*'],
  ['signs', '*'],
  ['contributions', '*'],
  ['ml_models', '*'],
  ['model_metrics', '*'],
  ['favorites', '*'],
  ['notifications', '*'],
  ['translation_sessions', '*'],
  ['translation_entries', '*'],
  ['user_progress', '*'],
];

async function main() {
  console.log(`Supabase: ${URL}`);
  console.log(`Service role: ${SERVICE ? 'present' : 'absent'}\n`);

  const email = `moomoo_smoke_${Date.now()}@example.com`;
  const password = 'TestPass123!';

  const signup = await req('/auth/v1/signup', {
    method: 'POST',
    body: { email, password, data: { display_name: 'Smoke User' } },
  });
  log('auth.signup', signup.status === 200, `HTTP ${signup.status}`);

  const userId = signup.json?.user?.id || signup.json?.id;
  let token = signup.json?.access_token;

  const login = await req('/auth/v1/token?grant_type=password', {
    method: 'POST',
    body: { email, password },
  });
  log('auth.login', login.status === 200 && !!login.json?.access_token, `HTTP ${login.status}`);
  if (login.json?.access_token) token = login.json.access_token;

  // The signup trigger must have created the profile row.
  const ownProfile = await req(
    `/rest/v1/profiles?select=id,email,display_name,is_admin&id=eq.${userId}`,
    { token },
  );
  const row = Array.isArray(ownProfile.json) ? ownProfile.json[0] : null;
  log(
    'profiles.trigger_created_row',
    ownProfile.status === 200 && !!row,
    row ? `display_name=${row.display_name} is_admin=${row.is_admin}` : short(ownProfile.json),
  );

  log(
    'profiles.is_admin_column',
    ownProfile.status === 200 && row && 'is_admin' in row,
    ownProfile.status === 200 ? 'present' : short(ownProfile.json),
  );

  const upsert = await req('/rest/v1/profiles', {
    method: 'POST',
    token,
    prefer: 'resolution=merge-duplicates,return=representation',
    body: {
      id: userId,
      email,
      display_name: 'Smoke User',
      is_deaf: false,
      updated_at: new Date().toISOString(),
    },
  });
  log('profiles.upsert', upsert.status >= 200 && upsert.status < 300, `HTTP ${upsert.status}`);

  const isAdminRpc = await req('/rest/v1/rpc/is_current_user_admin', {
    method: 'POST',
    token,
    body: {},
  });
  log(
    'rpc.is_current_user_admin',
    isAdminRpc.status === 200 && isAdminRpc.json === false,
    `returned ${short(isAdminRpc.json)}`,
  );

  for (const [table, select] of READ_TABLES) {
    const r = await req(`/rest/v1/${table}?select=${select}&limit=5`, { token });
    const rows = Array.isArray(r.json) ? r.json.length : 0;
    log(`${table}.select`, r.status === 200, r.status === 200 ? `${rows} row(s)` : short(r.json));
  }

  // Reference data must actually reach the client, not just return 200 empty.
  const langs = await req('/rest/v1/sign_languages?select=code&limit=10', { token });
  log(
    'sign_languages.readable',
    langs.status === 200 && Array.isArray(langs.json) && langs.json.length > 0,
    langs.status === 200 ? `codes=${short(langs.json)}` : short(langs.json),
  );

  // Writing a contribution is the main authenticated write path of the app.
  const contribution = await req('/rest/v1/contributions', {
    method: 'POST',
    token,
    prefer: 'return=representation',
    body: {
      contributor_id: userId,
      word: `smoke-${Date.now()}`,
      video_url: 'https://example.com/smoke.mp4',
      status: 'pending',
    },
  });
  log(
    'contributions.insert',
    contribution.status >= 200 && contribution.status < 300,
    contribution.status >= 200 && contribution.status < 300
      ? 'inserted'
      : short(contribution.json),
  );

  // A non-admin must not be able to grant themselves admin.
  const escalate = await req(`/rest/v1/profiles?id=eq.${userId}`, {
    method: 'PATCH',
    token,
    prefer: 'return=representation',
    body: { is_admin: true },
  });
  const escalated =
    Array.isArray(escalate.json) && escalate.json[0]?.is_admin === true;
  log('rls.self_promotion_blocked', !escalated, escalated ? 'ESCALATION POSSIBLE' : 'blocked');

  // Optional: admin writes go through RLS with the admin's own JWT, the service
  // role is only a server-side shortcut.
  if (SERVICE) {
    const r = await fetch(`${URL}/rest/v1/profiles?select=id&limit=1`, {
      headers: { apikey: SERVICE, Authorization: `Bearer ${SERVICE}` },
    });
    log('service_role.read', r.status === 200, `HTTP ${r.status}`);
  } else {
    console.log('SKIP service_role.read — SUPABASE_SERVICE_ROLE_KEY absent (optional)');
  }

  const failed = results.filter((r) => !r.ok);
  console.log(`\npassed=${results.length - failed.length} failed=${failed.length}`);
  if (failed.length) console.log(`failing: ${failed.map((f) => f.name).join(', ')}`);
  process.exit(failed.length ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
