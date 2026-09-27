import { Router } from 'express';
import { supabaseAnon, dbForUser, getServiceDb, supabaseAdmin } from '../supabase.js';
import { genericMessage, userError } from '../lib/errors.js';

export const authRouter = Router();

/**
 * Supabase Auth messages ("Invalid login credentials", "User already
 * registered"â€¦) are user-level and the app maps them to translated text, so
 * they are passed through. The raw error object is not.
 */
function mapAuthError(error) {
  const status = Number(error?.status);
  return userError(
    status >= 400 && status < 500 ? status : 400,
    error?.message || 'Authentification impossible.',
    error?.code || 'auth_error',
  );
}

/** POST /api/auth/signup { email, password, displayName, isDeaf? } */
authRouter.post('/signup', async (req, res, next) => {
  try {
    const { email, password, displayName, isDeaf = false } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({
        ok: false,
        error: 'validation',
        message: 'Adresse e-mail et mot de passe requis.',
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
        // Auth succeeded; the client completes the profile on first sign-in.
        return res.status(201).json({
          ok: true,
          warning: 'profile_incomplete',
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
        ? 'Compte crÃ©Ã© et session active'
        : 'Compte crÃ©Ã© â€” confirmez votre e-mail si requis',
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
        message: 'Adresse e-mail et mot de passe requis.',
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

/** POST /api/auth/ensure-profile â€” Bearer JWT */
authRouter.post('/ensure-profile', async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      return res.status(401).json({ ok: false, error: 'unauthorized', message: genericMessage(401) });
    }

    const { data: userData, error } = await supabaseAnon.auth.getUser(token);
    if (error || !userData.user) {
      return res.status(401).json({ ok: false, error: 'unauthorized', message: genericMessage(401) });
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
      console.error('[ensure-profile]', pe.message);
      return res.status(400).json({
        ok: false,
        error: 'profile_upsert_failed',
        message: 'Votre profil n\'a pas pu Ãªtre enregistrÃ©. RÃ©essayez plus tard.',
      });
    }

    res.json({ ok: true, profile: data });
  } catch (e) {
    next(e);
  }
});

/** GET /api/auth/me â€” Bearer JWT */
authRouter.get('/me', async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      return res.status(401).json({ ok: false, error: 'unauthorized', message: genericMessage(401) });
    }
    const { data: userData, error } = await supabaseAnon.auth.getUser(token);
    if (error || !userData.user) {
      return res.status(401).json({ ok: false, error: 'unauthorized', message: genericMessage(401) });
    }
    const db = dbForUser(token);
    const { data: profile, error: pe } = await db
      .from('profiles')
      .select('*')
      .eq('id', userData.user.id)
      .maybeSingle();
    if (pe) {
      console.error('[me]', pe.message);
      return res.status(400).json({ ok: false, error: 'profile_unavailable', message: genericMessage(400) });
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
