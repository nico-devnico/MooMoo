// Realtime publication, storage policies and contribution insert policies (read-only).
import 'dotenv/config';
import { getPool } from '../src/pgdb.js';

const pool = getPool();
const pub = await pool.query(
  "select schemaname, tablename from pg_publication_tables where pubname = 'supabase_realtime'");
console.log('realtime:', pub.rows.map((r) => `${r.schemaname}.${r.tablename}`).join(', ') || '(vide)');
const pubExists = await pool.query("select 1 from pg_publication where pubname = 'supabase_realtime'");
console.log('publication existe:', pubExists.rowCount > 0);
const storage = await pool.query(
  "select policyname, cmd, qual, with_check from pg_policies where schemaname='storage' and tablename='objects'");
for (const p of storage.rows) console.log('storage', p.cmd, p.policyname, '|', p.qual, '|', p.with_check);
const contrib = await pool.query(
  "select policyname, cmd, permissive, with_check from pg_policies where schemaname='public' and tablename='contributions'");
for (const p of contrib.rows) console.log('contrib', p.cmd, p.permissive, p.policyname, '|', p.with_check);
const buckets = await pool.query('select id, public from storage.buckets');
console.log('buckets:', buckets.rows.map((b) => `${b.id}(${b.public ? 'public' : 'privé'})`).join(', '));
await pool.end();
