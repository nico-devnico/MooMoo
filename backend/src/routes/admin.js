import { Router } from 'express';
import { dbForUser, supabaseAdmin } from '../supabase.js';

export const adminRouter = Router();

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
    const { data, error } = await client
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(Number(req.query.limit || 50));
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    res.json({ ok: true, users: data });
  } catch (e) {
    next(e);
  }
});

adminRouter.patch('/users/:id/admin', async (req, res, next) => {
  try {
    await assertAdmin(req);
    // Works without a service role: the "Admins can update any profile" policy
    // plus the protect_profile_privileges trigger allow it for admins only.
    const client = db() || dbForUser(req.accessToken);
    const { error } = await client
      .from('profiles')
      .update({
        is_admin: Boolean(req.body?.isAdmin),
        updated_at: new Date().toISOString(),
      })
      .eq('id', req.params.id);
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    res.json({ ok: true });
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
