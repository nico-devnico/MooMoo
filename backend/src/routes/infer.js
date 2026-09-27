import { Router } from 'express';
import multer from 'multer';
import { ML_SERVICE_URL, supabaseAdmin, dbForUser, supabaseAnon } from '../supabase.js';

export const inferRouter = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 12 * 1024 * 1024 },
});

inferRouter.post('/', upload.single('file'), async (req, res, next) => {
  try {
    let model = null;
    try {
      const client =
        supabaseAdmin ||
        (req.accessToken ? dbForUser(req.accessToken) : supabaseAnon);
      const { data } = await client
        .from('ml_models')
        .select('id, name, version, dataset, status')
        .eq('is_active', true)
        .maybeSingle();
      model = data;
    } catch (e) {
      console.warn('[infer] model lookup:', e.message);
    }

    const hint = req.body?.hint || null;
    const form = new FormData();
    if (req.file) {
      form.append(
        'file',
        new Blob([req.file.buffer], { type: req.file.mimetype || 'application/octet-stream' }),
        req.file.originalname || 'frame.gif',
      );
    }
    if (hint) form.append('hint', String(hint));
    if (model?.dataset) form.append('dataset', model.dataset);
    if (model?.version) form.append('model_version', model.version);

    const started = Date.now();
    let mlRes;
    try {
      mlRes = await fetch(`${ML_SERVICE_URL}/infer`, {
        method: 'POST',
        body: form,
      });
    } catch (e) {
      return res.status(503).json({
        ok: false,
        error: 'ml_unavailable',
        message: `Service Python injoignable (${ML_SERVICE_URL}): ${e.message}`,
        model,
      });
    }

    const payload = await mlRes.json().catch(() => ({}));
    if (!mlRes.ok) {
      return res.status(mlRes.status).json({
        ok: false,
        error: payload.error || 'ml_error',
        message: payload.detail || payload.message || 'Inference failed',
        model,
      });
    }

    res.json({
      ok: true,
      prediction: {
        label: payload.label,
        confidence: payload.confidence,
        latency_ms: payload.latency_ms ?? Date.now() - started,
      },
      model,
      dataset: payload.dataset,
    });
  } catch (e) {
    next(e);
  }
});
