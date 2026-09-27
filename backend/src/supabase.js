import { createClient } from '@supabase/supabase-js';

export const SUPABASE_URL =
  process.env.SUPABASE_URL || 'https://pckgblyvjgztogjykrvw.supabase.co';
export const SUPABASE_ANON_KEY =
  process.env.SUPABASE_ANON_KEY ||
  'sb_publishable_QwdkQxxJWh9MpnXdvADCGA_BLS5lHY8';
export const SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
export const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://127.0.0.1:8000';

export const supabaseAnon = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

export const supabaseAdmin = SERVICE_ROLE
  ? createClient(SUPABASE_URL, SERVICE_ROLE, {
      auth: { persistSession: false, autoRefreshToken: false },
    })
  : null;

export function dbForUser(accessToken) {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function getServiceDb() {
  if (!supabaseAdmin) {
    const err = new Error(
      'SUPABASE_SERVICE_ROLE_KEY manquante : opération admin serveur impossible',
    );
    err.status = 503;
    err.code = 'missing_service_role';
    throw err;
  }
  return supabaseAdmin;
}

/** Prefer service role when available, else user-scoped client. */
export function dbPreferService(accessToken) {
  if (supabaseAdmin) return supabaseAdmin;
  if (!accessToken) {
    const err = new Error('Authentification requise');
    err.status = 401;
    throw err;
  }
  return dbForUser(accessToken);
}
