/**
 * Live app <-> Supabase test, run against the real project:
 *   1. service role key sanity (role claim only, the key is never printed);
 *   2. admin API account creation/deletion, with the configured service key
 *      AND with it removed (direct SQL fallback), on a throw-away API instance;
 *   3. user-side writes under RLS with a real user JWT: preferences,
 *      translation history (+ counter trigger), favorites, sign views,
 *      ML training queue as admin.
 * Every row it creates is deleted at the end, even on failure.
 *
 *   cd backend && node scripts/live_persistence_test.mjs
 */
import 'dotenv/config';
import { spawn } from 'node:child_process';
import { createClient } from '@supabase/supabase-js';
import { createAuthUser, deleteAuthUser, getPool, query } from '../src/pgdb.js';
import { SUPABASE_ANON_KEY, SUPABASE_URL } from '../src/supabase.js';

const stamp = Date.now();
const password = `Live-${stamp}-Pw!`;
const results = [];
const cleanup = [];

async function check(name, fn) {
  try {
    const detail = await fn();
    results.push(true);
    console.log(`OK   ${name}${detail ? ` — ${detail}` : ''}`);
  } catch (e) {
    results.push(false);
    console.log(`FAIL ${name} — ${e.message}`);
  }
}

function assert(cond, message) {
  if (!cond) throw new Error(message);
}

async function signIn(email) {
  const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error) throw new Error(`connexion ${email} : ${error.message}`);
  return { client, token: data.session.access_token, userId: data.user.id };
}

function startApi(port, env) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, ['src/index.js'], {
      env: { ...process.env, PORT: String(port), ...env },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let out = '';
    const timer = setTimeout(() => reject(new Error(`API :${port} n'a pas démarré\n${out}`)), 15000);
    const onData = (d) => {
      out += d;
      if (out.includes('listening')) {
        clearTimeout(timer);
        resolve({ child, logs: () => out });
      }
    };
    child.stdout.on('data', onData);
    child.stderr.on('data', onData);
    child.on('exit', (code) => reject(new Error(`API :${port} arrêtée (${code})\n${out}`)));
  });
}

async function api(port, method, path, token, body) {
  const r = await fetch(`http://127.0.0.1:${port}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await r.json().catch(() => ({}));
  return { status: r.status, json };
}

function jwtRole(key) {
  const parts = key.split('.');
  if (parts.length !== 3) return key.startsWith('sb_secret_') ? 'secret (nouveau format)' : 'format inconnu';
  try {
    return JSON.parse(Buffer.from(parts[1], 'base64url').toString()).role || 'sans rôle';
  } catch {
    return 'illisible';
  }
}

async function adminUserCycle(label, port, adminToken) {
  const email = `live_${label}_${stamp}@example.com`;
  let createdId = null;
  await check(`[${label}] POST /api/admin/users`, async () => {
    const { status, json } = await api(port, 'POST', '/api/admin/users', adminToken, {
      email, password, displayName: `Live ${label}`, roles: ['teacher'],
    });
    assert(status === 201, `${status} ${json.message || JSON.stringify(json)}`);
    createdId = json.user.id;
    cleanup.push(() => deleteAuthUser(createdId).catch(() => {}));
    return `id=${createdId}`;
  });
  if (!createdId) return;
  await check(`[${label}] compte créé : profil + rôle + connexion`, async () => {
    const { rows: [p] } = await query('select display_name, is_admin from public.profiles where id=$1', [createdId]);
    const { rows: roles } = await query('select role from public.user_roles where user_id=$1', [createdId]);
    assert(p?.display_name === `Live ${label}`, 'profil absent');
    assert(roles.map((r) => r.role).join() === 'teacher', `rôles=${roles.map((r) => r.role)}`);
    await signIn(email);
    return 'connexion OK';
  });
  await check(`[${label}] DELETE /api/admin/users/:id`, async () => {
    const { status, json } = await api(port, 'DELETE', `/api/admin/users/${createdId}`, adminToken);
    assert(status === 200, `${status} ${json.message || JSON.stringify(json)}`);
    const { rows } = await query('select 1 from auth.users where id=$1 union all select 1 from public.profiles where id=$1', [createdId]);
    assert(rows.length === 0, 'compte encore présent');
    return 'auth.users + profil supprimés';
  });
}

async function run() {
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
  await check('clé service role', async () => {
    if (!serviceKey) return 'absente (le repli SQL sera utilisé)';
    const role = jwtRole(serviceKey);
    const probe = createClient(SUPABASE_URL, serviceKey, { auth: { persistSession: false } });
    const { error } = await probe.auth.admin.listUsers({ page: 1, perPage: 1 });
    return `rôle=${role}, API admin ${error ? `REFUSÉE (${error.message}) → repli SQL` : 'acceptée'}`;
  });

  // Temporary admin, created and promoted through SQL like a bootstrap admin.
  const adminEmail = `live_admin_${stamp}@example.com`;
  const adminId = await createAuthUser({ email: adminEmail, password, displayName: 'Live admin' });
  cleanup.push(() => deleteAuthUser(adminId).catch(() => {}));
  await query("insert into public.user_roles (user_id, role) values ($1, 'admin')", [adminId]);
  const admin = await signIn(adminEmail);

  for (const [label, port, env] of [
    ['service', 3091, {}],
    ['sql', 3092, { SUPABASE_SERVICE_ROLE_KEY: '' }],
  ]) {
    let server;
    try {
      server = await startApi(port, env);
      await adminUserCycle(label, port, admin.token);
    } catch (e) {
      results.push(false);
      console.log(`FAIL [${label}] ${e.message}`);
    } finally {
      server?.child.kill();
    }
  }

  // Regular user writes under RLS.
  const userEmail = `live_user_${stamp}@example.com`;
  const userId = await createAuthUser({ email: userEmail, password, displayName: 'Live user' });
  cleanup.push(() => deleteAuthUser(userId).catch(() => {}));
  const user = await signIn(userEmail);

  await check('profil créé automatiquement + notification de bienvenue', async () => {
    const { data: p, error } = await user.client.from('profiles').select('id').eq('id', userId).single();
    assert(!error && p, error?.message || 'profil absent');
    const { count } = await user.client.from('notifications').select('id', { count: 'exact', head: true });
    return `notifications=${count}`;
  });

  await check('préférences (vue, 3D) enregistrées sur le compte', async () => {
    const { error } = await user.client.from('profiles').update({
      preferred_view: 'landmarks', three_d_camera_controls: false,
      three_d_zoom_enabled: false, selected_character_id: 'nico', theme: 'dark',
    }).eq('id', userId);
    assert(!error, error?.message);
    const { rows: [p] } = await query(
      'select preferred_view, three_d_camera_controls, three_d_zoom_enabled, selected_character_id, theme from public.profiles where id=$1',
      [userId]);
    assert(p.preferred_view === 'landmarks' && p.three_d_camera_controls === false &&
      p.three_d_zoom_enabled === false && p.selected_character_id === 'nico' && p.theme === 'dark',
    JSON.stringify(p));
    return JSON.stringify(p);
  });

  await check('historique de traduction (session + entrées + compteur)', async () => {
    const { data: s, error } = await user.client.from('translation_sessions')
      .insert({ user_id: userId, session_type: 'text_to_sign', title: 'bonjour' }).select('id').single();
    assert(!error, error?.message);
    for (const text of ['bonjour', 'merci']) {
      const { error: e } = await user.client.from('translation_entries').insert({
        session_id: s.id, user_id: userId, direction: 'text_to_sign', source_text: text,
        sign_ids: [], confidence_score: null, inference_time_ms: null, model_version: null,
      });
      assert(!e, e?.message);
    }
    const { error: closeError } = await user.client.from('translation_sessions')
      .update({ status: 'completed', ended_at: new Date().toISOString() }).eq('id', s.id);
    assert(!closeError, closeError?.message);
    const { data: hist } = await user.client.from('translation_sessions')
      .select('total_entries,status,translation_entries(source_text)').eq('id', s.id).single();
    assert(hist.total_entries === 2, `total_entries=${hist.total_entries}`);
    return `total_entries=${hist.total_entries} status=${hist.status}`;
  });

  // A temporary validated sign, removed at the end.
  const { rows: [lang] } = await query("select id from public.sign_languages order by code limit 1");
  const { rows: [sign] } = await query(
    "insert into public.signs (sign_language_id, word, is_validated) values ($1, $2, true) returning id",
    [lang.id, `live-test-${stamp}`]);
  cleanup.unshift(() => query('delete from public.signs where id=$1', [sign.id]));

  await check('favori ajouté / retiré', async () => {
    const { error } = await user.client.from('favorites').insert({ user_id: userId, sign_id: sign.id });
    assert(!error, error?.message);
    const { error: delError } = await user.client.from('favorites').delete().match({ user_id: userId, sign_id: sign.id });
    assert(!delError, delError?.message);
    return 'OK';
  });

  await check('consultation de signe → view_count + user_progress', async () => {
    for (let i = 0; i < 2; i++) {
      const { error } = await user.client.rpc('record_sign_view', { p_sign_id: sign.id });
      assert(!error, error?.message);
    }
    const { rows: [p] } = await query(
      'select times_viewed from public.user_progress where user_id=$1 and sign_id=$2', [userId, sign.id]);
    const { rows: [s] } = await query('select view_count from public.signs where id=$1', [sign.id]);
    assert(p?.times_viewed === 2 && s.view_count === 2, `progress=${p?.times_viewed} views=${s.view_count}`);
    return 'times_viewed=2 view_count=2';
  });

  await check('contribution : soumission, auto-approbation refusée, revue notifiée', async () => {
    const base = { contributor_id: userId, sign_language_id: lang.id, video_url: `${userId}/live.mp4` };
    const { error: forged } = await user.client.from('contributions')
      .insert({ ...base, word: `forged-${stamp}`, status: 'approved' });
    assert(forged, 'un utilisateur a pu insérer une contribution déjà approuvée');
    const { data: c, error } = await user.client.from('contributions')
      .insert({ ...base, word: `live-${stamp}` }).select('id,status').single();
    assert(!error, error?.message);
    cleanup.unshift(() => query('delete from public.contributions where id=$1', [c.id]));
    assert(c.status === 'pending', `status=${c.status}`);
    const { data: reviewed, error: reviewError } = await admin.client.from('contributions')
      .update({ status: 'rejected', reviewer_id: adminId, reviewer_note: 'Vidéo floue', reviewed_at: new Date().toISOString() })
      .eq('id', c.id).select('id');
    assert(!reviewError && reviewed?.length === 1, reviewError?.message || 'revue sans effet');
    const { data: notes } = await user.client.from('notifications')
      .select('title,body').eq('type', 'contribution').contains('payload', { contribution_id: c.id });
    assert(notes?.length === 1 && notes[0].body === 'Vidéo floue', JSON.stringify(notes));
    return notes[0].title;
  });

  await check('file ML : admin crée dataset + job, utilisateur refusé', async () => {
    const { data: ds, error } = await admin.client.from('ml_datasets').insert({
      name: `live-${stamp}`, language_code: 'LSFB', source_type: 'local', uri: 'C:/inexistant',
      created_by: adminId,
    }).select('id').single();
    assert(!error, error?.message);
    cleanup.unshift(() => query('delete from public.ml_datasets where id=$1', [ds.id]));
    const { data: job, error: jobError } = await admin.client.from('training_jobs').insert({
      kind: 'analyze', dataset: `live-${stamp}`, dataset_id: ds.id, language_code: 'LSFB',
      requested_by: adminId, status: 'cancelled', progress: 0,
    }).select('id').single();
    assert(!jobError, jobError?.message);
    cleanup.unshift(() => query('delete from public.training_jobs where id=$1', [job.id]));
    const { error: denied } = await user.client.from('ml_datasets').insert({
      name: 'x', language_code: 'LSFB', source_type: 'local', uri: 'x',
    });
    assert(denied, 'un non-admin a pu créer un dataset');
    const { error: stageError } = await user.client.rpc('promote_ml_model', {
      p_model_id: '00000000-0000-0000-0000-000000000000', p_stage: 'production',
    });
    assert(stageError, 'un non-admin a pu promouvoir un modèle');
    return 'RLS OK';
  });
}

try {
  await run();
} catch (e) {
  results.push(false);
  console.log(`FAIL préparation — ${e.message}`);
} finally {
  for (const fn of cleanup) await fn();
  // Also sweeps accounts left by an interrupted previous run of this script.
  const ownAccounts = '^live_(admin|user|service|sql)_[0-9]+@example\\.com$';
  await query('delete from auth.users where email ~ $1', [ownAccounts]);
  const { rows } = await query(
    'select count(*)::int as n from auth.users where email ~ $1', [ownAccounts]);
  console.log(`\nnettoyage : ${rows[0].n} compte(s) de test restant(s)`);
  const passed = results.filter(Boolean).length;
  console.log(`passed=${passed} failed=${results.length - passed}`);
  await getPool().end();
  process.exit(results.every(Boolean) && rows[0].n === 0 ? 0 : 1);
}
