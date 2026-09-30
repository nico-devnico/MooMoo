import { Router } from 'express';
import { ML_SERVICE_URL } from '../supabase.js';

export const fingerspellRouter = Router();

async function mlGet(path) {
  const res = await fetch(`${ML_SERVICE_URL}${path}`);
  const body = await res.json().catch(() => ({}));
  return { status: res.status, body };
}

async function mlPost(path) {
  const res = await fetch(`${ML_SERVICE_URL}${path}`, { method: 'POST' });
  const body = await res.json().catch(() => ({}));
  return { status: res.status, body };
}

/** Liste des modèles d'épellation + métriques pour graphiques. */
fingerspellRouter.get('/models', async (_req, res, next) => {
  try {
    const { status, body } = await mlGet('/fingerspell/models');
    return res.status(status).json(body);
  } catch (e) {
    console.error('[fingerspell] ML unreachable:', e.message);
    return res.status(503).json({
      ok: false,
      error: 'ml_unavailable',
      message: 'Le service ML est indisponible.',
    });
  }
});

fingerspellRouter.get('/models/:id', async (req, res, next) => {
  try {
    const { status, body } = await mlGet(`/fingerspell/models/${encodeURIComponent(req.params.id)}`);
    return res.status(status).json(body);
  } catch (e) {
    return res.status(503).json({
      ok: false,
      error: 'ml_unavailable',
      message: 'Le service ML est indisponible.',
    });
  }
});

fingerspellRouter.post('/models/:id/activate', async (req, res, next) => {
  try {
    const { status, body } = await mlPost(
      `/fingerspell/models/${encodeURIComponent(req.params.id)}/activate`,
    );
    return res.status(status).json(body);
  } catch (e) {
    return res.status(503).json({
      ok: false,
      error: 'ml_unavailable',
      message: 'Le service ML est indisponible.',
    });
  }
});

/** État d'un entraînement fingerspell (idle / running / succeeded / failed). */
fingerspellRouter.get('/train/status', async (_req, res) => {
  try {
    const { status, body } = await mlGet('/fingerspell/train/status');
    return res.status(status).json(body);
  } catch (e) {
    return res.status(503).json({
      ok: false,
      error: 'ml_unavailable',
      message: 'Le service ML est indisponible.',
    });
  }
});

/** Relance l'entraînement ASL dataset → nouvelle version registre. */
fingerspellRouter.post('/train', async (req, res) => {
  try {
    const form = new FormData();
    if (req.body?.max_per_class != null) {
      form.append('max_per_class', String(req.body.max_per_class));
    }
    if (req.body?.epochs != null) {
      form.append('epochs', String(req.body.epochs));
    }
    const upstream = await fetch(`${ML_SERVICE_URL}/fingerspell/train`, {
      method: 'POST',
      body: form,
    });
    const body = await upstream.json().catch(() => ({}));
    return res.status(upstream.status).json(body);
  } catch (e) {
    return res.status(503).json({
      ok: false,
      error: 'ml_unavailable',
      message: 'Le service ML est indisponible.',
    });
  }
});
