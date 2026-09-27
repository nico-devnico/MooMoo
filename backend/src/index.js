import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { SERVICE_ROLE, ML_SERVICE_URL } from './supabase.js';
import { authRouter } from './routes/auth.js';
import { adminRouter } from './routes/admin.js';
import { modelsRouter } from './routes/models.js';
import { inferRouter } from './routes/infer.js';
import { healthRouter } from './routes/health.js';
import { requireAuth, optionalAuth } from './middleware/auth.js';

const PORT = Number(process.env.PORT || 3001);

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN || true }));
app.use(express.json({ limit: '15mb' }));

app.use('/health', healthRouter);
app.use('/api/auth', authRouter);
app.use('/api/admin', requireAuth, adminRouter);
app.use('/api/models', optionalAuth, modelsRouter);
app.use('/api/infer', optionalAuth, inferRouter);

app.use((err, _req, res, _next) => {
  const status = err.status || 500;
  console.error('[api]', err.message);
  res.status(status).json({
    ok: false,
    error: err.code || 'internal_error',
    message: err.message,
    details: err.details || undefined,
  });
});

const server = app.listen(PORT, () => {
  console.log(`MooMoo API listening on http://127.0.0.1:${PORT}`);
  console.log(`Service role: ${SERVICE_ROLE ? 'configured' : 'absent'}`);
  console.log(`ML service: ${ML_SERVICE_URL}`);
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(
      `Le port ${PORT} est déjà utilisé : une autre instance de l'API tourne sans doute déjà.\n` +
        `  - vérifier   : netstat -ano | findstr :${PORT}\n` +
        `  - arrêter    : taskkill /PID <pid> /F\n` +
        `  - ou changer : PORT=3002 npm start`,
    );
    process.exit(1);
  }
  throw err;
});
