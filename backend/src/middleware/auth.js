import { supabaseAnon } from '../supabase.js';

/**
 * A suspended account is banned in Supabase Auth (see migration
 * 20260928000015), but an access token issued before the ban stays valid until
 * it expires: the ban date is checked on every request.
 */
function isBanned(user) {
  const until = user?.banned_until ? Date.parse(user.banned_until) : NaN;
  return Number.isFinite(until) && until > Date.now();
}

export async function optionalAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  req.accessToken = token || null;
  req.user = null;
  req.suspended = false;
  if (!token) return next();
  try {
    const { data, error } = await supabaseAnon.auth.getUser(token);
    if (!error && data?.user) {
      if (isBanned(data.user)) {
        req.suspended = true;
        req.accessToken = null;
      } else {
        req.user = data.user;
      }
    } else if (error?.code === 'user_banned') {
      req.suspended = true;
      req.accessToken = null;
    }
  } catch {
    // ignore invalid token
  }
  next();
}

export async function requireAuth(req, res, next) {
  await optionalAuth(req, res, () => {
    if (req.suspended) {
      return res.status(403).json({
        ok: false,
        error: 'account_suspended',
        message: 'Votre compte a été suspendu. Contactez le support si vous pensez que c\'est une erreur.',
      });
    }
    if (!req.user || !req.accessToken) {
      return res.status(401).json({
        ok: false,
        error: 'unauthorized',
        message: 'Connectez-vous pour continuer.',
      });
    }
    next();
  });
}
