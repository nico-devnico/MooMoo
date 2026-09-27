// Dictionary and settings schema: columns, policies, constraints (read-only).
import 'dotenv/config';
import { getPool } from '../src/pgdb.js';

const pool = getPool();
const tables = ['signs', 'sign_categories', 'sign_languages', 'app_settings', 'contributions'];
for (const t of tables) {
  const cols = await pool.query(
    `select column_name, data_type, is_nullable, column_default from information_schema.columns
     where table_schema='public' and table_name=$1 order by ordinal_position`, [t]);
  console.log(`\n== ${t} ==`);
  if (!cols.rowCount) { console.log('(absente)'); continue; }
  for (const c of cols.rows) console.log(' ', c.column_name, c.data_type, c.is_nullable, c.column_default ?? '');
  const pols = await pool.query(
    `select policyname, cmd, permissive, qual, with_check from pg_policies where schemaname='public' and tablename=$1`, [t]);
  for (const p of pols.rows) console.log('  policy', p.cmd, p.permissive, p.policyname, '|', p.qual, '|', p.with_check);
  const cons = await pool.query(
    `select conname, pg_get_constraintdef(oid) def from pg_constraint where conrelid = ('public.'||$1)::regclass and contype in ('u','c')`, [t]);
  for (const c of cons.rows) console.log('  constraint', c.conname, c.def);
}
const langs = await pool.query('select id, code, name from public.sign_languages order by id');
console.log('\nlangues:', JSON.stringify(langs.rows));
const counts = await pool.query('select (select count(*) from public.signs) signs, (select count(*) from public.sign_categories) cats');
console.log('comptes:', JSON.stringify(counts.rows[0]));
const buckets = await pool.query('select id, public, file_size_limit, allowed_mime_types from storage.buckets');
console.log('buckets:', JSON.stringify(buckets.rows));
const storage = await pool.query(
  "select policyname, cmd, qual, with_check from pg_policies where schemaname='storage' and tablename='objects'");
for (const p of storage.rows) console.log('storage', p.cmd, p.policyname, '|', p.qual, '|', p.with_check);
await pool.end();
