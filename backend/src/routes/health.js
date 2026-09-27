import { Router } from 'express';
import { hasDirectDb, query } from '../pgdb.js';
import { ML_SERVICE_URL } from '../supabase.js';

export const healthRouter = Router();

healthRouter.get('/', async (_req, res) => {
  const out = {
    ok: true,
    service: 'moomoo-backend',
    timestamp: new Date().toISOString(),
    serviceRole: Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),
    directDb: hasDirectDb(),
    mlUrl: ML_SERVICE_URL,
  };
  if (hasDirectDb()) {
    try {
      const { rows } = await query(
        `SELECT
           (SELECT count(*) FROM public.training_jobs WHERE status = 'queued')::int AS queued,
           (SELECT count(*) FROM public.training_jobs WHERE status IN ('running','cancelling'))::int AS running,
           (SELECT max(heartbeat_at) FROM public.training_jobs) AS last_worker_heartbeat`,
      );
      out.database = 'ok';
      out.mlQueue = rows[0];
    } catch (e) {
      out.database = `error: ${e.message}`;
    }
  }
  res.json(out);
});
