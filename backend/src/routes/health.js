import { Router } from 'express';
import { hasDirectDb, query } from '../pgdb.js';
import { ML_SERVICE_URL } from '../supabase.js';
import { optionalAuth } from '../middleware/auth.js';
import { getRoles } from '../lib/roles.js';

export const healthRouter = Router();

/**
 * Public liveness probe. Configuration (keys present, ML host, queue state)
 * is only returned to an administrator's token.
 */
healthRouter.get('/', optionalAuth, async (req, res) => {
  const out = {
    ok: true,
    service: 'moomoo-backend',
    timestamp: new Date().toISOString(),
  };

  let isAdmin = false;
  if (req.accessToken && req.user) {
    try {
      isAdmin = (await getRoles(req.accessToken)).includes('admin');
    } catch {
      isAdmin = false;
    }
  }

  if (hasDirectDb()) {
    try {
      const { rows } = await query(
        `SELECT
           (SELECT count(*) FROM public.training_jobs WHERE status = 'queued')::int AS queued,
           (SELECT count(*) FROM public.training_jobs WHERE status IN ('running','cancelling'))::int AS running,
           (SELECT max(heartbeat_at) FROM public.training_jobs) AS last_worker_heartbeat`,
      );
      out.database = 'ok';
      if (isAdmin) out.mlQueue = rows[0];
    } catch (e) {
      console.error('[health] database:', e.message);
      out.database = 'error';
    }
  }

  if (isAdmin) {
    out.serviceRole = Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY);
    out.directDb = hasDirectDb();
    out.mlUrl = ML_SERVICE_URL;
  }
  res.json(out);
});
