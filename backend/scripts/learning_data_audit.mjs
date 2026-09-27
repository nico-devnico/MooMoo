/**
 * Summarises the reference data the learning path is built from.
 * Usage: cd backend && node scripts/learning_data_audit.mjs
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

const client = new pg.Client({
  connectionString: process.env.SUPABASE_DB_URL,
  ssl: { rejectUnauthorized: false },
});
await client.connect();

const q = async (label, sql) => {
  const r = await client.query(sql);
  console.log(`\n=== ${label} ===`);
  console.table(r.rows);
};

await q('languages', 'SELECT id, code, name, is_active FROM sign_languages ORDER BY id');
await q(
  'categories',
  `SELECT c.id, c.slug, c.name, c.icon_name, c.sign_language_id, c.order_index,
          (SELECT count(*) FROM signs s WHERE s.category_id = c.id) AS signs,
          (SELECT count(*) FROM signs s WHERE s.category_id = c.id AND s.is_validated) AS validated
   FROM sign_categories c ORDER BY c.sign_language_id, c.order_index`,
);
await q(
  'signs by language',
  `SELECT sign_language_id, count(*) AS total,
          count(*) FILTER (WHERE is_validated) AS validated,
          count(*) FILTER (WHERE video_url IS NOT NULL) AS with_video,
          count(*) FILTER (WHERE thumbnail_url IS NOT NULL) AS with_thumb,
          count(*) FILTER (WHERE landmark_data IS NOT NULL) AS with_landmarks
   FROM signs GROUP BY sign_language_id`,
);
await q('user_progress rows', 'SELECT count(*) FROM user_progress');

await client.end();
