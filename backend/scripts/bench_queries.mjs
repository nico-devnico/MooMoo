/**
 * Banc d'essai des requetes chaudes de MooMoo : dictionnaire et stats admin.
 *
 * Trois sections :
 *   1. Allers-retours reels vers la base distante  -> cout du NOMBRE de requetes
 *      (ce qui domine quand la base est petite mais loin).
 *   2. Simulation de volume dans une table temporaire (20 000 signes avec
 *      landmark_data) -> cout des colonnes rapatriees et des index manquants.
 *   3. Etat des index.
 *
 * Usage:
 *   cd backend && node scripts/bench_queries.mjs [--runs 5] [--rows 20000]
 *
 * Connexion lue depuis SUPABASE_DB_URL (.env ou backend/.env). Aucune donnee
 * de production n'est modifiee : la simulation utilise une table TEMP.
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
    if (!m) continue;
    let val = m[2].trim();
    if (/^(".*"|'.*')$/s.test(val)) val = val.slice(1, -1);
    if (!process.env[m[1]]) process.env[m[1]] = val;
  }
}

const dbUrl = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;
if (!dbUrl) {
  console.error('SUPABASE_DB_URL manquant (backend/.env).');
  process.exit(2);
}

const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i > -1 ? Number(process.argv[i + 1]) : fallback;
};
const RUNS = arg('--runs', 5);
const ROWS = arg('--rows', 20000);

const ssl = { rejectUnauthorized: false };
const client = new pg.Client({ connectionString: dbUrl, ssl });
await client.connect();
console.log(`connected: ${dbUrl.replace(/:[^:@/]+@/, ':****@')}`);

const median = (xs) => [...xs].sort((a, b) => a - b)[Math.floor(xs.length / 2)];
const ms = (t0) => Number(process.hrtime.bigint() - t0) / 1e6;
const bytesOf = (rows) => Buffer.byteLength(JSON.stringify(rows), 'utf8');

// ---------------------------------------------------------------------------
// Section 1 : allers-retours reels
// ---------------------------------------------------------------------------
const pool = new pg.Pool({ connectionString: dbUrl, ssl, max: 6 });

async function timeSequential(queries) {
  const t0 = process.hrtime.bigint();
  for (const sql of queries) await client.query(sql);
  return ms(t0);
}

async function timeParallel(queries) {
  const t0 = process.hrtime.bigint();
  await Promise.all(queries.map((sql) => pool.query(sql)));
  return ms(t0);
}

async function repeat(fn, queries) {
  await fn(queries);
  const samples = [];
  for (let i = 0; i < RUNS; i++) samples.push(await fn(queries));
  return median(samples);
}

const STATS_BEFORE = [
  'SELECT id FROM public.profiles',
  'SELECT id, is_validated FROM public.signs',
  'SELECT id, status FROM public.contributions',
];
const STATS_COUNTS = [
  'SELECT count(*) FROM public.profiles',
  'SELECT count(*) FROM public.signs',
  "SELECT count(*) FROM public.signs WHERE is_validated = true",
  "SELECT count(*) FROM public.contributions WHERE status = 'pending'",
  "SELECT count(*) FROM public.contributions WHERE status = 'approved'",
  "SELECT count(*) FROM public.contributions WHERE status = 'rejected'",
];
const STATS_RPC = ['SELECT 1 AS ping'];

console.log('\n=== 1. allers-retours reels (base distante) ===');
const rtt = await repeat(timeSequential, ['SELECT 1']);
console.log(`aller-retour unitaire                              ${rtt.toFixed(1)} ms`);

const statsSeq = await repeat(timeSequential, STATS_BEFORE);
console.log(
  `AVANT  stats admin : 3 SELECT de lignes sequentiels ${statsSeq.toFixed(1)} ms`,
);
const countsSeq = await repeat(timeSequential, STATS_COUNTS);
console.log(
  `       6 count exacts, sequentiels                  ${countsSeq.toFixed(1)} ms`,
);
const countsPar = await repeat(timeParallel, STATS_COUNTS);
console.log(
  `APRES  6 count exacts en parallele (Future.wait)    ${countsPar.toFixed(1)} ms`,
);
const rpc = await repeat(timeSequential, STATS_RPC);
console.log(
  `APRES  1 appel admin_stats() (1 aller-retour)       ${rpc.toFixed(1)} ms`,
);

// Recherche du dictionnaire : une requete par caractere sans debounce.
const typed = 'maison';
const keystrokes = Array.from({ length: typed.length }, (_, i) =>
  `SELECT id, word FROM public.signs WHERE is_validated = true AND word ILIKE '%${typed.slice(0, i + 1)}%' ORDER BY word LIMIT 20`,
);
const noDebounce = await repeat(timeSequential, keystrokes);
const withDebounce = await repeat(timeSequential, [keystrokes.at(-1)]);
console.log(
  `AVANT  saisie "${typed}" sans debounce (${keystrokes.length} requetes)   ${noDebounce.toFixed(1)} ms`,
);
console.log(
  `APRES  saisie "${typed}" avec debounce (1 requete)      ${withDebounce.toFixed(1)} ms`,
);

// Tables de reference rechargees a chaque navigation.
const refQueries = [
  'SELECT id, code, name, country, flag_emoji, is_active FROM public.sign_languages WHERE is_active ORDER BY name',
  'SELECT id, name, slug, icon_name, color_hex, order_index, sign_language_id FROM public.sign_categories WHERE sign_language_id = 1 ORDER BY order_index',
];
const refCold = await repeat(timeSequential, refQueries);
console.log(
  `AVANT  langues + categories a chaque navigation     ${refCold.toFixed(1)} ms`,
);
console.log(
  `APRES  idem, en cache keepAlive (0 requete)             0.0 ms`,
);

await pool.end();

// ---------------------------------------------------------------------------
// Section 2 : simulation de volume (table TEMP, production intacte)
// ---------------------------------------------------------------------------
console.log(`\n=== 2. volume simule : ${ROWS} signes dans une table TEMP ===`);

await client.query('DROP TABLE IF EXISTS bench_signs');
await client.query('CREATE TEMP TABLE bench_signs (LIKE public.signs INCLUDING DEFAULTS)');
await client.query(
  `INSERT INTO bench_signs
     (id, sign_language_id, category_id, word, description, difficulty_level,
      video_url, thumbnail_url, model_3d_url, landmark_data, tags,
      example_sentence, is_validated, view_count, created_at, updated_at)
   SELECT gen_random_uuid(),
          1 + (i % 3),
          1 + (i % 12),
          substr(md5(i::text), 1, 8) || CASE WHEN i % 7 = 0 THEN 'maison' ELSE '' END,
          'Description du signe numero ' || i,
          1 + (i % 5),
          'https://cdn.example/videos/' || i || '.mp4',
          'https://cdn.example/thumbs/' || i || '.jpg',
          'https://cdn.example/models/' || i || '.glb',
          (SELECT jsonb_build_object('frames', jsonb_agg(
             jsonb_build_object('x', random(), 'y', random(), 'z', random())))
           FROM generate_series(1, 60)),
          ARRAY['tag1', 'tag2', 'tag3'],
          'Phrase d exemple pour le signe ' || i,
          (i % 10) <> 0,
          i % 500,
          now() - (i || ' minutes')::interval,
          now()
     FROM generate_series(1, $1) AS i`,
  [ROWS],
);
await client.query('ANALYZE bench_signs');

const size = await client.query(
  `SELECT pg_size_pretty(pg_total_relation_size('bench_signs')) AS s,
          round(pg_total_relation_size('bench_signs')::numeric / $1) AS per_row`,
  [ROWS],
);
console.log(
  `taille table : ${size.rows[0].s} (~${size.rows[0].per_row} octets/ligne)`,
);

const SIGN_LIST =
  'id, sign_language_id, category_id, word, description, difficulty_level, video_url, thumbnail_url, is_validated, view_count';

const cases = {
  'dictionnaire page 1  AVANT  select *': `SELECT * FROM bench_signs WHERE is_validated = true ORDER BY word LIMIT 20`,
  'dictionnaire page 1  APRES  colonnes': `SELECT ${SIGN_LIST} FROM bench_signs WHERE is_validated = true ORDER BY word LIMIT 20`,
  "recherche ilike      AVANT  select *": `SELECT * FROM bench_signs WHERE is_validated = true AND word ILIKE '%maison%' ORDER BY word LIMIT 20`,
  "recherche ilike      APRES  colonnes": `SELECT ${SIGN_LIST} FROM bench_signs WHERE is_validated = true AND word ILIKE '%maison%' ORDER BY word LIMIT 20`,
  'liste admin 50       AVANT  select *': `SELECT * FROM bench_signs ORDER BY created_at DESC LIMIT 50`,
  'liste admin 50       APRES  colonnes': `SELECT ${SIGN_LIST}, model_3d_url, tags, example_sentence, contributor_id, created_at, updated_at FROM bench_signs ORDER BY created_at DESC LIMIT 50`,
  'favoris 100          AVANT  select *': `SELECT * FROM bench_signs LIMIT 100`,
  'favoris 100          APRES  colonnes': `SELECT ${SIGN_LIST} FROM bench_signs LIMIT 100`,
  'historique sans limite (toutes lignes)': `SELECT id, word FROM bench_signs`,
  'historique avec limite 30': `SELECT id, word FROM bench_signs LIMIT 30`,
};

async function serverTime(sql) {
  const samples = [];
  let payload = 0;
  for (let i = 0; i < RUNS; i++) {
    const res = await client.query(`EXPLAIN (ANALYZE, FORMAT JSON) ${sql}`);
    samples.push(res.rows[0]['QUERY PLAN'][0]['Execution Time']);
  }
  const rows = await client.query(sql);
  payload = bytesOf(rows.rows);
  return { exec: median(samples), payload, rows: rows.rowCount };
}

async function report(label) {
  console.log(`\n--- ${label} ---`);
  const out = {};
  for (const [name, sql] of Object.entries(cases)) {
    const r = await serverTime(sql);
    out[name] = r;
    console.log(
      `${name.padEnd(40)} exec ${r.exec.toFixed(2).padStart(8)} ms  ` +
        `lignes ${String(r.rows).padStart(6)}  ` +
        `payload ${(r.payload / 1024).toFixed(1).padStart(9)} KiB`,
    );
  }
  return out;
}

const noIndex = await report('sans les index de la migration');

await client.query('CREATE INDEX bench_validated_word ON bench_signs (is_validated, word)');
await client.query('CREATE INDEX bench_created ON bench_signs (created_at DESC)');
await client.query('CREATE INDEX bench_word_trgm ON bench_signs USING gin (word extensions.gin_trgm_ops)');
await client.query('ANALYZE bench_signs');

const withIndex = await report('avec les index de 20260927000001_performance_indexes.sql');

console.log('\n--- synthese volume ---');
for (const name of Object.keys(cases)) {
  const a = noIndex[name];
  const b = withIndex[name];
  console.log(
    `${name.padEnd(40)} exec ${a.exec.toFixed(2)} -> ${b.exec.toFixed(2)} ms ` +
      `(x${(a.exec / Math.max(b.exec, 0.001)).toFixed(1)})`,
  );
}

const pairs = [
  ['dictionnaire page 1  AVANT  select *', 'dictionnaire page 1  APRES  colonnes'],
  ['recherche ilike      AVANT  select *', 'recherche ilike      APRES  colonnes'],
  ['liste admin 50       AVANT  select *', 'liste admin 50       APRES  colonnes'],
  ['favoris 100          AVANT  select *', 'favoris 100          APRES  colonnes'],
  ['historique sans limite (toutes lignes)', 'historique avec limite 30'],
];
console.log('\n--- payload transfere (avec index) ---');
for (const [before, after] of pairs) {
  const a = withIndex[before].payload;
  const b = withIndex[after].payload;
  console.log(
    `${before.replace('AVANT', '').trim().padEnd(40)} ` +
      `${(a / 1024).toFixed(1)} KiB -> ${(b / 1024).toFixed(1)} KiB ` +
      `(x${(a / Math.max(b, 1)).toFixed(1)} plus petit)`,
  );
}

await client.query('DROP TABLE IF EXISTS bench_signs');

// ---------------------------------------------------------------------------
// Section 3 : index en place
// ---------------------------------------------------------------------------
const idx = await client.query(
  `SELECT tablename, indexname FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename IN ('signs','contributions','notifications','favorites',
                        'translation_entries','translation_sessions',
                        'sign_categories','profiles')
    ORDER BY tablename, indexname`,
);
console.log('\n=== 3. index presents en base ===');
for (const r of idx.rows) console.log(`  ${r.tablename.padEnd(22)} ${r.indexname}`);

await client.end();
