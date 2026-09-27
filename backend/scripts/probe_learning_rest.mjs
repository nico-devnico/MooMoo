/**
 * Sends the learning-path PostgREST queries used by the Flutter app with the
 * anon key, to catch embedding / syntax errors (rows are hidden by RLS).
 * Usage: cd backend && node scripts/probe_learning_rest.mjs
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

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_ANON_KEY;
if (!url || !key) {
  console.error('SUPABASE_URL / SUPABASE_ANON_KEY manquants');
  process.exit(1);
}

const signList =
  'id,sign_language_id,category_id,word,description,difficulty_level,video_url,thumbnail_url,is_validated,view_count';
const lessonCols = 'id,unit_id,title,description,order_index,xp_reward,lesson_signs(count)';
const queries = {
  path: `learning_units?select=id,sign_language_id,title,description,icon_name,order_index,is_published,learning_lessons(${lessonCols})&sign_language_id=eq.1&is_published=eq.true&order=order_index`,
  lesson: `learning_lessons?select=id,title,xp_reward,learning_units!inner(sign_language_id),lesson_signs(order_index,signs(${signList},landmark_data))&id=eq.00000000-0000-0000-0000-000000000000`,
  lessonSigns: `lesson_signs?select=order_index,signs(${signList})&lesson_id=eq.00000000-0000-0000-0000-000000000000&order=order_index`,
  distractors: `signs?select=${signList}&sign_language_id=eq.1&is_validated=eq.true&id=not.in.(00000000-0000-0000-0000-000000000000)&limit=24`,
};

let failed = 0;
for (const [name, path] of Object.entries(queries)) {
  const res = await fetch(`${url}/rest/v1/${path}`, {
    headers: { apikey: key, Authorization: `Bearer ${key}` },
  });
  const body = await res.text();
  const ok = res.ok;
  if (!ok) failed++;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${name} ${res.status} ${ok ? '' : body}`);
}
process.exit(failed ? 1 : 0);
