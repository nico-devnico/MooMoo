import { Router } from 'express';
import { supabaseAnon, dbForUser, getServiceDb, supabaseAdmin } from '../supabase.js';

export const authRouter = Router();

function mapAuthError(error) {
  const msg = error?.message || String(error);
  const err = new Error(msg);
  err.status = 400;
  err.code = error?.code || 'auth_error';
  err.details = error;
  return err;
}

/** POST /api/auth/signup { email, password, displayName, isDeaf? } */
authRouter.post('/signup', async (req, res, next) => {
  try {
    const { email, password, displayName, isDeaf = false } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({
        ok: false,
        error: 'validation',
        message: 'email et password requis',
      });
    }

    const { data, error } = await supabaseAnon.auth.signUp({
      email,
      password,
      options: {
        data: { display_name: displayName || '' },
      },
    });
    if (error) throw mapAuthError(error);

    const user = data.user;
    const session = data.session;

    // Ensure profile row (trigger may have created it with null display_name)
    if (user) {
      const profilePayload = {
        id: user.id,
        email,
        display_name: displayName || email.split('@')[0],
        is_deaf: Boolean(isDeaf),
        updated_at: new Date().toISOString(),
      };

      let profileError = null;
      if (supabaseAdmin) {
        const { error: pe } = await supabaseAdmin
          .from('profiles')
          .upsert(profilePayload, { onConflict: 'id' });
        profileError = pe;
      } else if (session?.access_token) {
        const userDb = dbForUser(session.access_token);
        const { error: pe } = await userDb
          .from('profiles')
          .upsert(profilePayload, { onConflict: 'id' });
        profileError = pe;
      }

      if (profileError) {
        console.warn('[signup] profile upsert:', profileError.message);
        // Auth succeeded — surface profile warning but still return tokens
        return res.status(201).json({
          ok: true,
          warning: profileError.message,
          user,
          session,
        });
      }
    }

    res.status(201).json({
      ok: true,
      user,
      session,
      message: session
        ? 'Compte créé et session active'
        : 'Compte créé — confirmez votre e-mail si requis',
    });
  } catch (e) {
    next(e);
  }
});

/** POST /api/auth/login { email, password } */
authRouter.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({
        ok: false,
        error: 'validation',
        message: 'email et password requis',
      });
    }

    const { data, error } = await supabaseAnon.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw mapAuthError(error);

    // Soft ensure profile exists
    if (data.user && data.session) {
      const payload = {
        id: data.user.id,
        email: data.user.email,
        display_name:
          data.user.user_metadata?.display_name ||
          data.user.email?.split('@')[0],
        updated_at: new Date().toISOString(),
      };
      const db = supabaseAdmin || dbForUser(data.session.access_token);
      const { error: pe } = await db.from('profiles').upsert(payload, {
        onConflict: 'id',
      });
      if (pe) console.warn('[login] profile upsert:', pe.message);
    }

    res.json({ ok: true, user: data.user, session: data.session });
  } catch (e) {
    next(e);
  }
});

/** POST /api/auth/ensure-profile — Bearer JWT */
authRouter.post('/ensure-profile', async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      return res.status(401).json({ ok: false, error: 'unauthorized' });
    }

    const { data: userData, error } = await supabaseAnon.auth.getUser(token);
    if (error || !userData.user) {
      return res.status(401).json({ ok: false, error: 'unauthorized', message: error?.message });
    }

    const body = req.body || {};
    const payload = {
      id: userData.user.id,
      email: body.email || userData.user.email,
      display_name:
        body.displayName ||
        userData.user.user_metadata?.display_name ||
        userData.user.email?.split('@')[0],
      is_deaf: body.isDeaf ?? false,
      updated_at: new Date().toISOString(),
    };

    const db = supabaseAdmin || dbForUser(token);
    const { data, error: pe } = await db
      .from('profiles')
      .upsert(payload, { onConflict: 'id' })
      .select('*')
      .maybeSingle();

    if (pe) {
      return res.status(400).json({
        ok: false,
        error: 'profile_upsert_failed',
        message: pe.message,
        hint: pe.message.includes('is_admin')
          ? 'Appliquer la migration profiles (colonne is_admin)'
          : undefined,
      });
    }

    res.json({ ok: true, profile: data });
  } catch (e) {
    next(e);
  }
});

/** GET /api/auth/me — Bearer JWT */
authRouter.get('/me', async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      return res.status(401).json({ ok: false, error: 'unauthorized' });
    }
    const { data: userData, error } = await supabaseAnon.auth.getUser(token);
    if (error || !userData.user) {
      return res.status(401).json({ ok: false, message: error?.message });
    }
    const db = dbForUser(token);
    const { data: profile, error: pe } = await db
      .from('profiles')
      .select('*')
      .eq('id', userData.user.id)
      .maybeSingle();
    if (pe) {
      return res.status(400).json({ ok: false, message: pe.message });
    }
    res.json({
      ok: true,
      user: userData.user,
      profile: {
        ...profile,
        is_admin: profile?.is_admin ?? false,
      },
    });
  } catch (e) {
    next(e);
  }
});
