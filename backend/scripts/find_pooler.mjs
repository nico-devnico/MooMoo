/**
 * Finds the pooler host for a Supabase project when the direct
 * db.<ref>.supabase.co host is IPv6-only and unreachable.
 *
 * Usage: node scripts/find_pooler.mjs <project-ref> <db-password>
 */
import pg from 'pg';

const [ref, password] = process.argv.slice(2);
if (!ref || !password) {
  console.error('Usage: node scripts/find_pooler.mjs <project-ref> <db-password>');
  process.exit(2);
}

const regions = [
  'eu-west-3',
  'eu-west-1',
  'eu-west-2',
  'eu-central-1',
  'eu-central-2',
  'eu-north-1',
  'us-east-1',
  'us-east-2',
  'us-west-1',
  'us-west-2',
  'ca-central-1',
  'sa-east-1',
  'ap-south-1',
  'ap-southeast-1',
  'ap-southeast-2',
  'ap-northeast-1',
  'ap-northeast-2',
];
const prefixes = ['aws-0', 'aws-1'];

async function probe(host) {
  const client = new pg.Client({
    host,
    port: 5432,
    user: `postgres.${ref}`,
    password,
    database: 'postgres',
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 8000,
  });
  try {
    await client.connect();
    const { rows } = await client.query('select current_database() db, version()');
    await client.end();
    return { ok: true, info: rows[0].db };
  } catch (e) {
    try {
      await client.end();
    } catch {
      /* already closed */
    }
    return { ok: false, error: e.message };
  }
}

const hosts = prefixes.flatMap((p) =>
  regions.map((r) => `${p}-${r}.pooler.supabase.com`),
);

for (const host of hosts) {
  const r = await probe(host);
  if (r.ok) {
    console.log(`FOUND ${host} (database=${r.info})`);
    console.log(
      `SUPABASE_DB_URL=postgresql://postgres.${ref}:<password>@${host}:5432/postgres`,
    );
    process.exit(0);
  }
  if (!/Tenant or user not found|ENOTFOUND|timeout|ETIMEDOUT/i.test(r.error)) {
    console.log(`${host}: ${r.error}`);
  }
}

console.error('No pooler host matched. Check the region in the Supabase dashboard.');
process.exit(1);
