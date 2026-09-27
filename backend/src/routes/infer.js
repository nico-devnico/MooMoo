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
    const client =
      supabaseAdmin || (req.accessToken ? dbForUser(req.accessToken) : supabaseAnon);

    let language = req.body?.language ? String(req.body.language) : null;
    if (!language && req.user) {
      const { data: profile } = await client
        .from('profiles')
        .select('preferred_sign_language')
        .eq('id', req.user.id)
        .maybeSingle();
      language = profile?.preferred_sign_language || null;
    }

    let model = null;
    try {
      let q = client
        .from('ml_models')
        .select('id, name, version, dataset, language_code, stage')
        .eq('stage', 'production');
      if (language) q = q.eq('language_code', language);
      const { data } = await q.limit(1).maybeSingle();
      model = data;
    } catch (e) {
      console.warn('[infer] model lookup:', e.message);
    }

    const form = new FormData();
    if (req.file) {
      form.append(
        'file',
        new Blob([req.file.buffer], { type: req.file.mimetype || 'application/octet-stream' }),
        req.file.originalname || 'clip.mp4',
      );
    }
    if (req.body?.landmarks) {
      const lm = req.body.landmarks;
      form.append('landmarks', typeof lm === 'string' ? lm : JSON.stringify(lm));
    }
    if (language) form.append('language', language);

    const started = Date.now();
    let mlRes;
    try {
      mlRes = await fetch(`${ML_SERVICE_URL}/infer`, {
        method: 'POST',
        body: form,
      });
    } catch (e) {
      console.error(`[infer] ML service unreachable (${ML_SERVICE_URL}):`, e.message);
      return res.status(503).json({
        ok: false,
        error: 'ml_unavailable',
        message: 'La reconnaissance des signes est momentanément indisponible. Réessayez plus tard.',
      });
    }

    const payload = await mlRes.json().catch(() => ({}));
    if (!mlRes.ok) {
      console.error('[infer] ML service error', mlRes.status, payload.detail || payload.message);
      return res.status(mlRes.status >= 500 ? 502 : mlRes.status).json({
        ok: false,
        error: 'ml_error',
        message: mlRes.status >= 500
          ? 'La reconnaissance des signes est momentanément indisponible. Réessayez plus tard.'
          : "Cette vidéo n'a pas pu être analysée. Vérifiez qu'elle montre bien les mains et réessayez.",
      });
    }

    res.json({
      ok: true,
      prediction: {
        label: payload.label,
        confidence: payload.confidence,
        top: payload.top,
        latency_ms: payload.latency_ms ?? Date.now() - started,
      },
      model: payload.model || model,
      language: payload.language || language,
      dataset: payload.dataset,
    });
  } catch (e) {
    next(e);
  }
});
