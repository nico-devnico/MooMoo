import { dbForUser } from '../supabase.js';

/** Roles of the caller, read under their own JWT (public.user_roles). */
export async function getRoles(accessToken) {
  const { data, error } = await dbForUser(accessToken).rpc('current_user_roles');
  if (error) {
    const err = new Error(`Lecture des rôles impossible : ${error.message}`);
    err.status = 503;
    err.code = 'roles_unavailable';
    throw err;
  }
  return Array.isArray(data) ? data : [];
}

/**
 * Express middleware: the caller must hold one of `allowed` (admin always
 * passes). Row level security enforces the same rules on every query.
 */
export function requireRole(...allowed) {
  return async (req, res, next) => {
    try {
      const roles = await getRoles(req.accessToken);
      req.roles = roles;
      req.isAdmin = roles.includes('admin');
      if (req.isAdmin || roles.some((r) => allowed.includes(r))) return next();
      return res.status(403).json({
        ok: false,
        error: 'forbidden',
        message: "Vous n'avez pas les droits nécessaires pour cette action.",
      });
    } catch (e) {
      next(e);
    }
  };
}
