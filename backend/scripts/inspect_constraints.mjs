// Check/unique constraints and triggers of the given public tables.
import 'dotenv/config';
import { getPool } from '../src/pgdb.js';

const tables = process.argv.slice(2);
const pool = getPool();
for (const t of tables) {
  const { rows: cons } = await pool.query(
    `select conname, pg_get_constraintdef(oid) as def from pg_constraint
     where conrelid = ('public.' || $1)::regclass and contype in ('c','u','p','f')`, [t]);
  const { rows: trg } = await pool.query(
    `select tgname, pg_get_triggerdef(oid) as def from pg_trigger
     where tgrelid = ('public.' || $1)::regclass and not tgisinternal`, [t]);
  console.log(`\n# ${t}`);
  for (const c of cons) console.log('  ', c.conname, '=>', c.def);
  for (const g of trg) console.log('   trigger', g.def);
}
const { rows: fns } = await pool.query(
  `select p.proname, pg_get_functiondef(p.oid) as def from pg_proc p
   join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = any($1)`,
  [['increment_sign_view_count', 'update_session_total', 'handle_new_user']]);
for (const f of fns) console.log(`\n## ${f.proname}\n${f.def}`);
await pool.end();
