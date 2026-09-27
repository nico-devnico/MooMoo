import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { SERVICE_ROLE, ML_SERVICE_URL } from './supabase.js';
import { authRouter } from './routes/auth.js';
import { adminRouter } from './routes/admin.js';
import { modelsRouter } from './routes/models.js';
import { inferRouter } from './routes/infer.js';
import { healthRouter } from './routes/health.js';
import { dictionaryRouter } from './routes/dictionary.js';
import { requireAuth, optionalAuth } from './middleware/auth.js';
import { maintenanceGuard } from './lib/settings.js';
import { errorHandler, genericMessage } from './lib/errors.js';

const PORT = Number(process.env.PORT || 3001);

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN || true }));
app.disable('x-powered-by');
app.use(express.json({ limit: '15mb' }));

app.use('/health', healthRouter);
// Admin routes stay reachable during maintenance (they require the admin role).
// Login stays open so administrators can sign in; sign-up is closed.
app.use('/api/auth/signup', optionalAuth, maintenanceGuard);
app.use('/api/auth', authRouter);
app.use('/api/admin', requireAuth, adminRouter);
app.use('/api/dictionary', requireAuth, maintenanceGuard, dictionaryRouter);
app.use('/api/models', optionalAuth, maintenanceGuard, modelsRouter);
app.use('/api/infer', optionalAuth, maintenanceGuard, inferRouter);

app.use((_req, res) => {
  res.status(404).json({ ok: false, error: 'not_found', message: genericMessage(404) });
});
app.use(errorHandler);

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
