// Lists public tables with their columns, row counts and RLS policies.
import 'dotenv/config';
import { getPool } from '../src/pgdb.js';

const pool = getPool();
const { rows: tables } = await pool.query(`
  select c.relname as table, c.relrowsecurity as rls
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r' order by 1`);
for (const t of tables) {
  const { rows: cols } = await pool.query(
    `select column_name, data_type from information_schema.columns
     where table_schema='public' and table_name=$1 order by ordinal_position`, [t.table]);
  const { rows: [{ n }] } = await pool.query(`select count(*)::int as n from public."${t.table}"`);
  const { rows: pols } = await pool.query(
    `select policyname, cmd from pg_policies where schemaname='public' and tablename=$1`, [t.table]);
  console.log(`\n# ${t.table} (rows=${n}, rls=${t.rls})`);
  console.log('  cols:', cols.map((c) => c.column_name).join(', '));
  console.log('  policies:', pols.map((p) => `${p.cmd}:${p.policyname}`).join(' | ') || '-');
}
await pool.end();
