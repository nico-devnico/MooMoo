import { supabaseAnon } from '../supabase.js';

export async function optionalAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  req.accessToken = token || null;
  req.user = null;
  if (!token) return next();
  try {
    const { data, error } = await supabaseAnon.auth.getUser(token);
    if (!error && data?.user) req.user = data.user;
  } catch {
    // ignore invalid token
  }
  next();
}

export async function requireAuth(req, res, next) {
  await optionalAuth(req, res, () => {
    if (!req.user || !req.accessToken) {
      return res.status(401).json({
        ok: false,
        error: 'unauthorized',
        message: 'JWT Supabase requis (Authorization: Bearer <access_token>)',
      });
    }
    next();
  });
}
