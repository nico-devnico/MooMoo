import { Router } from 'express';

export const healthRouter = Router();

healthRouter.get('/', (_req, res) => {
  res.json({
    ok: true,
    service: 'moomoo-backend',
    timestamp: new Date().toISOString(),
    serviceRole: Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),
    mlUrl: process.env.ML_SERVICE_URL || 'http://127.0.0.1:8000',
  });
});
