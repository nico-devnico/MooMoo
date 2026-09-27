import pg from 'pg';

/**
 * Direct Postgres access (SUPABASE_DB_URL, role `postgres`).
 *
 * Server-side only. It covers the few operations RLS cannot express, mainly
 * writing to auth.users, when SUPABASE_SERVICE_ROLE_KEY is not configured.
 * Every caller must have checked the admin rights of the requester first.
 */
const DB_URL = process.env.SUPABASE_DB_URL || '';

let pool = null;

export function hasDirectDb() {
  return Boolean(DB_URL);
}

export function getPool() {
  if (!DB_URL) {
    throw Object.assign(
      new Error(
        'Aucun accès serveur à la base : configurer SUPABASE_DB_URL (ou ' +
          'SUPABASE_SERVICE_ROLE_KEY) dans backend/.env puis redémarrer l\'API.',
      ),
      { status: 503, code: 'missing_server_db' },
    );
  }
  if (!pool) {
    pool = new pg.Pool({
      connectionString: DB_URL,
      ssl: { rejectUnauthorized: false },
      max: 5,
      idleTimeoutMillis: 30_000,
    });
    pool.on('error', (e) => console.warn('[pg] idle client error:', e.message));
  }
  return pool;
}

export async function query(text, params = []) {
  return getPool().query(text, params);
}

export async function withTransaction(fn) {
  const client = await getPool().connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (e) {
    await client.query('ROLLBACK').catch(() => {});
    throw e;
  } finally {
    client.release();
  }
}

/**
 * Creates a confirmed email/password account exactly as GoTrue would: a row in
 * auth.users plus its `email` identity. The on_auth_user_created trigger then
 * creates the profile.
 */
export async function createAuthUser({ email, password, displayName }) {
  return withTransaction(async (c) => {
    const exists = await c.query(
      'SELECT 1 FROM auth.users WHERE lower(email) = lower($1) AND deleted_at IS NULL',
      [email],
    );
    if (exists.rowCount) {
      throw Object.assign(new Error('Un compte existe déjà avec cet email'), {
        status: 409,
        code: 'email_exists',
      });
    }

    const { rows } = await c.query(
      `INSERT INTO auth.users (
         instance_id, id, aud, role, email, encrypted_password,
         email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
         created_at, updated_at, confirmation_token, recovery_token,
         email_change_token_new, email_change
       ) VALUES (
         '00000000-0000-0000-0000-000000000000', gen_random_uuid(),
         'authenticated', 'authenticated', lower($1),
         extensions.crypt($2, extensions.gen_salt('bf')),
         now(), '{"provider":"email","providers":["email"]}'::jsonb,
         jsonb_build_object('display_name', $3::text),
         now(), now(), '', '', '', ''
       ) RETURNING id`,
      [email, password, displayName],
    );
    const id = rows[0].id;

    await c.query(
      `INSERT INTO auth.identities (
         provider_id, user_id, identity_data, provider,
         last_sign_in_at, created_at, updated_at
       ) VALUES (
         $1::text, $1::uuid,
         jsonb_build_object('sub', $1::text, 'email', lower($2::text),
                            'email_verified', true, 'phone_verified', false),
         'email', now(), now(), now()
       )`,
      [id, email],
    );
    return id;
  });
}

/** Deletes an auth account; profiles and user data follow through FK cascades. */
export async function deleteAuthUser(userId) {
  const { rowCount } = await query('DELETE FROM auth.users WHERE id = $1', [userId]);
  if (!rowCount) {
    throw Object.assign(new Error('Utilisateur introuvable'), {
      status: 404,
      code: 'not_found',
    });
  }
}
