/**
 * Exercises the learning-path SQL (RLS, complete_lesson, learner_summary)
 * inside a transaction that is always rolled back.
 * Usage: cd backend && node scripts/verify_learning.mjs
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

let failures = 0;
const check = (label, ok, detail = '') => {
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${label}${detail ? ` — ${detail}` : ''}`);
  if (!ok) failures++;
};

const actAs = async (userId) => {
  await client.query(`SELECT set_config('request.jwt.claims', $1, true)`, [
    JSON.stringify({ sub: userId, role: 'authenticated' }),
  ]);
  await client.query('SET LOCAL ROLE authenticated');
};
const asOwner = () => client.query('RESET ROLE');

try {
  await client.query('BEGIN');

  const { rows: users } = await client.query(
    `SELECT p.id, p.is_admin FROM profiles p ORDER BY p.is_admin DESC, p.created_at LIMIT 2`,
  );
  const admin = users.find((u) => u.is_admin);
  const learner = users.find((u) => !u.is_admin);
  check('admin and learner accounts found', Boolean(admin && learner));

  const { rows: [sign] } = await client.query(
    `INSERT INTO signs (sign_language_id, word, is_validated) VALUES (1, 'verif', true) RETURNING id`,
  );

  await actAs(admin.id);
  const { rows: [unit] } = await client.query(
    `INSERT INTO learning_units (sign_language_id, title) VALUES (1, 'Unité test') RETURNING id`,
  );
  const { rows: [lesson] } = await client.query(
    `INSERT INTO learning_lessons (unit_id, title, xp_reward) VALUES ($1, 'Leçon test', 10) RETURNING id`,
    [unit.id],
  );
  await client.query(`INSERT INTO lesson_signs (lesson_id, sign_id) VALUES ($1, $2)`, [lesson.id, sign.id]);
  check('admin can create unit, lesson and lesson_signs', true);
  await asOwner();

  await actAs(learner.id);
  const hidden = await client.query(`SELECT id FROM learning_units WHERE id = $1`, [unit.id]);
  check('draft unit hidden from learners', hidden.rowCount === 0);

  let blocked = false;
  try {
    await client.query('SAVEPOINT s1');
    await client.query(`INSERT INTO learning_units (sign_language_id, title) VALUES (1, 'x')`);
  } catch {
    blocked = true;
    await client.query('ROLLBACK TO SAVEPOINT s1');
  }
  check('learners cannot create units', blocked);

  blocked = false;
  try {
    await client.query('SAVEPOINT s2');
    await client.query(`SELECT complete_lesson($1, 1, 1)`, [lesson.id]);
  } catch {
    blocked = true;
    await client.query('ROLLBACK TO SAVEPOINT s2');
  }
  check('draft lesson cannot be completed by learners', blocked);
  await asOwner();

  await client.query(`UPDATE learning_units SET is_published = true WHERE id = $1`, [unit.id]);

  await actAs(learner.id);
  const visible = await client.query(
    `SELECT u.id, l.id AS lesson, s.sign_id FROM learning_units u
     JOIN learning_lessons l ON l.unit_id = u.id
     JOIN lesson_signs s ON s.lesson_id = l.id WHERE u.id = $1`,
    [unit.id],
  );
  check('published unit, lesson and signs readable', visible.rowCount === 1);

  const first = (await client.query(`SELECT complete_lesson($1, 4, 4, 120) AS r`, [lesson.id])).rows[0].r;
  check('perfect first run earns reward + 5', first.xp_earned === 15, JSON.stringify(first));
  check('streak starts at 1', first.summary.current_streak === 1);

  const second = (await client.query(`SELECT complete_lesson($1, 2, 4, 120) AS r`, [lesson.id])).rows[0].r;
  check('replay earns half', second.xp_earned === 3, JSON.stringify(second));
  check('total and today XP add up', second.summary.total_xp === 18 && second.summary.today_xp === 18);
  check('same-day replay keeps streak', second.summary.current_streak === 1);

  blocked = false;
  try {
    await client.query('SAVEPOINT s3');
    await client.query(`SELECT complete_lesson($1, 5, 4)`, [lesson.id]);
  } catch {
    blocked = true;
    await client.query('ROLLBACK TO SAVEPOINT s3');
  }
  check('impossible score rejected', blocked);

  blocked = false;
  try {
    await client.query('SAVEPOINT s4');
    await client.query(`UPDATE learner_stats SET total_xp = 99999 WHERE user_id = $1`, [learner.id]);
    const r = await client.query(`SELECT total_xp FROM learner_stats WHERE user_id = $1`, [learner.id]);
    blocked = r.rows[0].total_xp !== 99999;
  } catch {
    blocked = true;
    await client.query('ROLLBACK TO SAVEPOINT s4');
  }
  check('learners cannot write their own XP', blocked);

  const progress = (await client.query(`SELECT * FROM learning_progress()`)).rows;
  check(
    'learning_progress keeps best score',
    progress.length === 1 && progress[0].best_correct === 4 && progress[0].completions === 2,
    JSON.stringify(progress),
  );

  await client.query(`SELECT set_daily_goal(30)`);
  const goal = (await client.query(`SELECT learner_summary(120) AS r`)).rows[0].r;
  check('daily goal updated', goal.daily_goal_xp === 30);
  await asOwner();
} catch (error) {
  failures++;
  console.error('FAIL unexpected error:', error.message);
} finally {
  await client.query('ROLLBACK');
  await client.end();
}

console.log(failures ? `\n${failures} failure(s)` : '\nall checks passed (rolled back)');
process.exit(failures ? 1 : 0);
