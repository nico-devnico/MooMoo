import { Router } from 'express';
import { dbForUser, dbPreferService, supabaseAdmin } from '../supabase.js';
import { createAuthUser, deleteAuthUser, hasDirectDb } from '../pgdb.js';

export const adminRouter = Router();

/** Rôles reconnus par public.user_roles (contrainte CHECK côté base). */
const KNOWN_ROLES = ['admin', 'teacher', 'sign_expert'];

/** Colonnes de profil renvoyées par la liste admin. Jamais `select('*')`. */
const USER_COLUMNS =
  'id,email,display_name,avatar_url,bio,is_admin,is_deaf,status,' +
  'suspended_at,suspended_reason,suspended_by,preferred_sign_language,created_at';

function badRequest(message, code = 'validation') {
  return Object.assign(new Error(message), { status: 400, code });
}

function serverAccessRequired(action) {
  return Object.assign(
    new Error(
      `${action} exige un accès serveur à la base : SUPABASE_DB_URL ou ` +
        'SUPABASE_SERVICE_ROLE_KEY dans backend/.env, puis redémarrer l\'API.',
    ),
    { status: 503, code: 'missing_server_db' },
  );
}

/** A present but wrong/expired service key must not break account admin. */
function isServiceKeyError(error) {
  const status = Number(error?.status || 0);
  return status === 401 || status === 403 ||
    /invalid (api key|jwt)|not allowed|unauthori[sz]ed|forbidden|bad_jwt/i.test(String(error?.message || ''));
}

/** Valide et dédoublonne une liste de rôles reçue du client. */
function normalizeRoles(input) {
  if (input == null) return [];
  if (!Array.isArray(input)) throw badRequest('roles doit être un tableau');
  const roles = [...new Set(input.map((r) => String(r).trim()))].filter(Boolean);
  const unknown = roles.filter((r) => !KNOWN_ROLES.includes(r));
  if (unknown.length) {
    throw badRequest(
      `rôle(s) inconnu(s) : ${unknown.join(', ')} (attendu : ${KNOWN_ROLES.join(', ')})`,
      'unknown_role',
    );
  }
  return roles;
}

/** Rôles courants d'un utilisateur, triés. */
async function rolesOf(client, userId) {
  const { data, error } = await client
    .from('user_roles')
    .select('role')
    .eq('user_id', userId);
  if (error) throw Object.assign(new Error(error.message), { status: 400 });
  return (data || []).map((r) => r.role).sort();
}

/**
 * Nombre d'admins effectifs hors [excludeId].
 *
 * Le compte se fait sur profiles.is_admin et non sur user_roles, parce qu'un
 * premier admin peut avoir été amorcé directement en SQL sans passer par la
 * table de rôles : ce serait le pire moment pour l'oublier.
 */
async function otherAdminCount(client, excludeId) {
  const { count, error } = await client
    .from('profiles')
    .select('id', { count: 'exact', head: true })
    .eq('is_admin', true)
    .neq('id', excludeId);
  if (error) throw Object.assign(new Error(error.message), { status: 400 });
  return count ?? 0;
}

async function assertAdmin(req) {
  const db = dbForUser(req.accessToken);
  const { data, error } = await db
    .from('profiles')
    .select('id, is_admin')
    .eq('id', req.user.id)
    .maybeSingle();

  if (error) {
    // Column missing: fall back to user metadata role
    if (String(error.message).includes('is_admin')) {
      const role =
        req.user.app_metadata?.role || req.user.user_metadata?.role;
      if (role === 'admin') return true;
      const err = new Error(
        `Colonne profiles.is_admin absente (${error.message}). Appliquer les migrations SQL.`,
      );
      err.status = 503;
      err.code = 'schema_outdated';
      throw err;
    }
    const err = new Error(error.message);
    err.status = 400;
    throw err;
  }

  const metaAdmin =
    req.user.app_metadata?.role === 'admin' ||
    req.user.user_metadata?.role === 'admin';
  if (!data?.is_admin && !metaAdmin) {
    const err = new Error('Accès admin refusé');
    err.status = 403;
    err.code = 'forbidden';
    throw err;
  }
  return true;
}

function db() {
  return supabaseAdmin || null;
}

adminRouter.get('/stats', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const client = db() || dbForUser(req.accessToken);
    const [users, signs, contributions] = await Promise.all([
      client.from('profiles').select('id', { count: 'exact', head: true }),
      client.from('signs').select('id, is_validated'),
      client.from('contributions').select('id, status'),
    ]);
    if (users.error) throw Object.assign(new Error(users.error.message), { status: 400 });
    if (signs.error) throw Object.assign(new Error(signs.error.message), { status: 400 });
    if (contributions.error) {
      throw Object.assign(new Error(contributions.error.message), { status: 400 });
    }
    const signsList = signs.data || [];
    const contribList = contributions.data || [];
    res.json({
      ok: true,
      stats: {
        usersCount: users.count ?? 0,
        signsCount: signsList.length,
        validatedSignsCount: signsList.filter((s) => s.is_validated).length,
        pendingContributionsCount: contribList.filter((c) => c.status === 'pending').length,
        approvedContributionsCount: contribList.filter((c) => c.status === 'approved').length,
        rejectedContributionsCount: contribList.filter((c) => c.status === 'rejected').length,
      },
    });
  } catch (e) {
    next(e);
  }
});

adminRouter.get('/users', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const client = db() || dbForUser(req.accessToken);
    const limit = Math.min(Number(req.query.limit || 50), 200);
    const offset = Number(req.query.offset || 0);

    let query = client.from('profiles').select(USER_COLUMNS, { count: 'exact' });
    const search = String(req.query.q || '').trim();
    if (search) {
      const escaped = search.replaceAll(',', ' ').replaceAll('%', '');
      query = query.or(
        `display_name.ilike.%${escaped}%,email.ilike.%${escaped}%`,
      );
    }
    if (req.query.status) query = query.eq('status', req.query.status);

    const { data, error, count } = await query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);
    if (error) throw Object.assign(new Error(error.message), { status: 400 });

    const users = data || [];
    // Une seule requête pour tous les rôles de la page, pas une par profil.
    let roles = [];
    if (users.length) {
      const { data: roleRows, error: roleError } = await client
        .from('user_roles')
        .select('user_id, role')
        .in('user_id', users.map((u) => u.id));
      if (roleError) {
        throw Object.assign(new Error(roleError.message), { status: 400 });
      }
      roles = roleRows || [];
    }

    res.json({
      ok: true,
      total: count ?? users.length,
      users: users.map((u) => ({
        ...u,
        roles: roles.filter((r) => r.user_id === u.id).map((r) => r.role).sort(),
      })),
    });
  } catch (e) {
    next(e);
  }
});

/**
 * Bascule le rôle admin. Conservée pour compatibilité, mais elle écrit
 * désormais dans user_roles : le trigger sync_profile_admin_flag se charge de
 * profiles.is_admin, de sorte qu'il n'existe qu'un seul endroit où un rôle est
 * accordé.
 */
adminRouter.patch('/users/:id/admin', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const client = dbPreferService(req.accessToken);
    const makeAdmin = Boolean(req.body?.isAdmin);
    const targetId = req.params.id;

    if (!makeAdmin && targetId === req.user.id) {
      throw Object.assign(
        new Error('Un admin ne peut pas retirer son propre rôle admin'),
        { status: 400, code: 'self_demote' },
      );
    }
    if (!makeAdmin && (await otherAdminCount(client, targetId)) === 0) {
      throw Object.assign(
        new Error('Impossible de retirer le dernier admin du système'),
        { status: 409, code: 'last_admin' },
      );
    }

    const { error } = makeAdmin
      ? await client.from('user_roles').upsert(
          { user_id: targetId, role: 'admin', granted_by: req.user.id },
          { onConflict: 'user_id,role' },
        )
      : await client
          .from('user_roles')
          .delete()
          .eq('user_id', targetId)
          .eq('role', 'admin');
    if (error) throw Object.assign(new Error(error.message), { status: 400 });

    res.json({ ok: true, roles: await rolesOf(client, targetId) });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /users — crée un compte.
 *
 * Seule opération, avec la suppression, qui ne peut pas se faire sous RLS :
 * écrire dans auth.users passe obligatoirement par l'API admin Supabase.
 */
adminRouter.post('/users', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const email = String(req.body?.email || '').trim().toLowerCase();
    const password = String(req.body?.password || '');
    const displayName = String(req.body?.displayName || '').trim();
    const roles = normalizeRoles(req.body?.roles);

    if (!email || !password) throw badRequest('email et password requis');
    if (password.length < 8) {
      throw badRequest('le mot de passe doit faire au moins 8 caractères');
    }

    const name = displayName || email.split('@')[0];
    let service = db();
    let userId;
    if (service) {
      const { data, error } = await service.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { display_name: name },
      });
      if (error && !(isServiceKeyError(error) && hasDirectDb())) {
        throw Object.assign(new Error(error.message), { status: 400 });
      }
      if (error) {
        console.warn('[admin] service role rejected, using direct database:', error.message);
        service = null;
      } else {
        userId = data.user.id;
      }
    }
    if (!userId) {
      if (!hasDirectDb()) throw serverAccessRequired('La création de compte');
      userId = await createAuthUser({ email, password, displayName: name });
    }

    // Without the service key the admin's JWT does the rest. The profile row
    // already exists (on_auth_user_created trigger) and RLS only lets admins
    // UPDATE other profiles, so no upsert there.
    const writer = service || dbForUser(req.accessToken);
    const profile = {
      email,
      display_name: name,
      is_deaf: Boolean(req.body?.isDeaf),
      updated_at: new Date().toISOString(),
    };
    try {
      const { error: profileError } = service
        ? await service.from('profiles').upsert({ id: userId, ...profile }, { onConflict: 'id' })
        : await writer.from('profiles').update(profile).eq('id', userId);
      if (profileError) {
        throw Object.assign(new Error(profileError.message), { status: 400 });
      }

      if (roles.length) {
        const { error: roleError } = await writer.from('user_roles').upsert(
          roles.map((role) => ({
            user_id: userId,
            role,
            granted_by: req.user.id,
          })),
          { onConflict: 'user_id,role' },
        );
        if (roleError) {
          throw Object.assign(new Error(roleError.message), { status: 400 });
        }
      }
    } catch (err) {
      // Never leave a half-created account behind.
      if (service) await service.auth.admin.deleteUser(userId).catch(() => {});
      else await deleteAuthUser(userId).catch(() => {});
      throw err;
    }

    res.status(201).json({ ok: true, user: { id: userId, email }, roles });
  } catch (e) {
    next(e);
  }
});

/** PATCH /users/:id — champs de profil éditables par un admin. */
adminRouter.patch('/users/:id', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const client = dbPreferService(req.accessToken);

    const patch = { updated_at: new Date().toISOString() };
    if (req.body?.displayName !== undefined) {
      patch.display_name = String(req.body.displayName).trim() || null;
    }
    if (req.body?.bio !== undefined) {
      patch.bio = String(req.body.bio).trim() || null;
    }
    if (req.body?.preferredSignLanguage !== undefined) {
      patch.preferred_sign_language = String(req.body.preferredSignLanguage).trim();
    }
    if (req.body?.isDeaf !== undefined) patch.is_deaf = Boolean(req.body.isDeaf);

    if (Object.keys(patch).length === 1) {
      throw badRequest(
        'aucun champ à modifier (displayName, bio, preferredSignLanguage, isDeaf)',
      );
    }

    const { data, error } = await client
      .from('profiles')
      .update(patch)
      .eq('id', req.params.id)
      .select(USER_COLUMNS)
      .maybeSingle();
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    if (!data) {
      throw Object.assign(new Error('Utilisateur introuvable'), {
        status: 404,
        code: 'not_found',
      });
    }
    res.json({ ok: true, user: data });
  } catch (e) {
    next(e);
  }
});

/** DELETE /users/:id — supprime le compte auth et, en cascade, son profil. */
adminRouter.delete('/users/:id', async (req, res, next) => {
  try {
    await assertAdmin(req);
    if (req.params.id === req.user.id) {
      throw Object.assign(
        new Error('Un admin ne peut pas supprimer son propre compte'),
        { status: 400, code: 'self_delete' },
      );
    }

    let service = db();
    if (!service && !hasDirectDb()) {
      throw serverAccessRequired('La suppression de compte');
    }

    const reader = dbForUser(req.accessToken);
    const { data: target } = await reader
      .from('profiles')
      .select('is_admin')
      .eq('id', req.params.id)
      .maybeSingle();
    if (target?.is_admin && (await otherAdminCount(reader, req.params.id)) === 0) {
      throw Object.assign(
        new Error('Impossible de supprimer le dernier admin du système'),
        { status: 409, code: 'last_admin' },
      );
    }

    if (service) {
      const { error } = await service.auth.admin.deleteUser(req.params.id);
      if (error && !(isServiceKeyError(error) && hasDirectDb())) {
        throw Object.assign(new Error(error.message), { status: 400 });
      }
      if (error) {
        console.warn('[admin] service role rejected, using direct database:', error.message);
        service = null;
      }
    }
    if (!service) await deleteAuthUser(req.params.id);
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

adminRouter.post('/users/:id/suspend', async (req, res, next) => {
  try {
    await assertAdmin(req);
    if (req.params.id === req.user.id) {
      throw Object.assign(
        new Error('Un admin ne peut pas se suspendre lui-même'),
        { status: 400, code: 'self_suspend' },
      );
    }
    const reason = String(req.body?.reason || '').trim();
    if (!reason) throw badRequest('reason requis pour suspendre un compte');

    const client = dbPreferService(req.accessToken);
    const { data, error } = await client
      .from('profiles')
      .update({
        status: 'suspended',
        suspended_at: new Date().toISOString(),
        suspended_reason: reason,
        suspended_by: req.user.id,
        updated_at: new Date().toISOString(),
      })
      .eq('id', req.params.id)
      .select(USER_COLUMNS)
      .maybeSingle();
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    if (!data) {
      throw Object.assign(new Error('Utilisateur introuvable'), {
        status: 404,
        code: 'not_found',
      });
    }
    res.json({ ok: true, user: data });
  } catch (e) {
    next(e);
  }
});

adminRouter.post('/users/:id/unsuspend', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const client = dbPreferService(req.accessToken);
    const { data, error } = await client
      .from('profiles')
      .update({
        status: 'active',
        suspended_at: null,
        suspended_reason: null,
        suspended_by: null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', req.params.id)
      .select(USER_COLUMNS)
      .maybeSingle();
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    if (!data) {
      throw Object.assign(new Error('Utilisateur introuvable'), {
        status: 404,
        code: 'not_found',
      });
    }
    res.json({ ok: true, user: data });
  } catch (e) {
    next(e);
  }
});

/** PUT /users/:id/roles — remplace l'ensemble des rôles d'un utilisateur. */
adminRouter.put('/users/:id/roles', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const targetId = req.params.id;
    const roles = normalizeRoles(req.body?.roles);
    const client = dbPreferService(req.accessToken);

    // Se retirer soi-même le rôle admin, c'est se verrouiller dehors.
    if (targetId === req.user.id && !roles.includes('admin')) {
      throw Object.assign(
        new Error('Un admin ne peut pas retirer son propre rôle admin'),
        { status: 400, code: 'self_demote' },
      );
    }

    const current = await rolesOf(client, targetId);
    const losesAdmin = current.includes('admin') && !roles.includes('admin');
    if (losesAdmin && (await otherAdminCount(client, targetId)) === 0) {
      throw Object.assign(
        new Error('Impossible de retirer le dernier admin du système'),
        { status: 409, code: 'last_admin' },
      );
    }

    const toRemove = current.filter((r) => !roles.includes(r));
    if (toRemove.length) {
      const { error } = await client
        .from('user_roles')
        .delete()
        .eq('user_id', targetId)
        .in('role', toRemove);
      if (error) throw Object.assign(new Error(error.message), { status: 400 });
    }

    const toAdd = roles.filter((r) => !current.includes(r));
    if (toAdd.length) {
      const { error } = await client.from('user_roles').upsert(
        toAdd.map((role) => ({
          user_id: targetId,
          role,
          granted_by: req.user.id,
        })),
        { onConflict: 'user_id,role' },
      );
      if (error) throw Object.assign(new Error(error.message), { status: 400 });
    }

    res.json({ ok: true, roles: await rolesOf(client, targetId) });
  } catch (e) {
    next(e);
  }
});

adminRouter.get('/contributions', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const client = db() || dbForUser(req.accessToken);
    let q = client.from('contributions').select('*').order('submitted_at', {
      ascending: false,
    });
    if (req.query.status) q = q.eq('status', req.query.status);
    const { data, error } = await q;
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    res.json({ ok: true, contributions: data });
  } catch (e) {
    next(e);
  }
});

adminRouter.post('/contributions/:id/review', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const client = db() || dbForUser(req.accessToken);
    const status = req.body?.status;
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ ok: false, message: 'status approved|rejected requis' });
    }
    const now = new Date().toISOString();
    const { error } = await client
      .from('contributions')
      .update({
        status,
        reviewer_id: req.user.id,
        reviewer_note: req.body?.note || null,
        reviewed_at: now,
      })
      .eq('id', req.params.id);
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

adminRouter.get('/signs', async (req, res, next) => {
  try {
    await assertAdmin(req);
    const client = db() || dbForUser(req.accessToken);
    let q = client.from('signs').select('*').order('created_at', { ascending: false }).limit(50);
    if (req.query.q) q = q.ilike('word', `%${req.query.q}%`);
    const { data, error } = await q;
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    res.json({ ok: true, signs: data });
  } catch (e) {
    next(e);
  }
});
