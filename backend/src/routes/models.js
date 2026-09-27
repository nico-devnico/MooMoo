import { Router } from 'express';
import {
  dbForUser,
  dbPreferService,
  supabaseAdmin,
  supabaseAnon,
} from '../supabase.js';
import { requireAuth } from '../middleware/auth.js';

export const modelsRouter = Router();

function readClient(req) {
  if (supabaseAdmin) return supabaseAdmin;
  if (req.accessToken) return dbForUser(req.accessToken);
  return supabaseAnon;
}

modelsRouter.get('/', async (req, res, next) => {
  try {
    const { data, error } = await readClient(req)
      .from('ml_models')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) {
      if (String(error.message).includes('ml_models') || error.code === 'PGRST205') {
        return res.json({
          ok: true,
          models: [],
          warning:
            "Table public.ml_models absente — appliquer supabase/migrations/20260324000002_ai_models_schema.sql",
        });
      }
      throw Object.assign(new Error(error.message), { status: 400 });
    }
    res.json({ ok: true, models: data || [] });
  } catch (e) {
    next(e);
  }
});

modelsRouter.get('/active', async (req, res, next) => {
  try {
    let q = readClient(req).from('ml_models').select('*').eq('stage', 'production');
    if (req.query.language) q = q.eq('language_code', String(req.query.language));
    const { data, error } = await q
      .order('promoted_at', { ascending: false, nullsFirst: false })
      .limit(1)
      .maybeSingle();
    if (error) {
      if (String(error.message).includes('ml_models') || error.code === 'PGRST205') {
        return res.json({
          ok: true,
          model: null,
          warning: 'Table ml_models absente — migration AI non appliquée',
        });
      }
      throw Object.assign(new Error(error.message), { status: 400 });
    }
    res.json({ ok: true, model: data });
  } catch (e) {
    next(e);
  }
});

modelsRouter.get('/jobs', requireAuth, async (req, res, next) => {
  try {
    const client = dbPreferService(req.accessToken);
    const { data, error } = await client
      .from('training_jobs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(30);
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    res.json({ ok: true, jobs: data || [] });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /retrain — met un entraînement en file d'attente.
 * Le worker ML (python -m moomoo_ml.worker) consomme training_jobs : aucun
 * appel direct au service Python, la fermeture du client n'interrompt rien.
 */
modelsRouter.post('/retrain', requireAuth, async (req, res, next) => {
  try {
    const client = dbForUser(req.accessToken);
    const datasetId = req.body?.datasetId;
    const datasetName = typeof req.body?.dataset === 'string' ? req.body.dataset.trim() : '';
    if (!datasetId && !datasetName) {
      throw Object.assign(
        new Error('datasetId requis : enregistrer d\'abord un dataset dans Admin > Modèles'),
        { status: 400, code: 'dataset_required' },
      );
    }
    // Older clients send the dataset name: take the latest registered one.
    let lookup = client.from('ml_datasets').select('id, name, language_code');
    lookup = datasetId
      ? lookup.eq('id', datasetId)
      : lookup.eq('name', datasetName).order('created_at', { ascending: false }).limit(1);
    const { data: dataset, error: dsError } = await lookup.maybeSingle();
    if (dsError) throw Object.assign(new Error(dsError.message), { status: 400 });
    if (!dataset) {
      throw Object.assign(new Error('Dataset introuvable'), { status: 404, code: 'not_found' });
    }
    const kind = req.body?.search ? 'search' : 'train';
    const { data, error } = await client
      .from('training_jobs')
      .insert({
        kind,
        model_id: req.body?.modelId || null,
        requested_by: req.user.id,
        dataset: dataset.name,
        dataset_id: dataset.id,
        language_code: dataset.language_code,
        config: req.body?.config || {},
        status: 'queued',
        progress: 0,
      })
      .select()
      .single();
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    res.status(201).json({ ok: true, job: data });
  } catch (e) {
    next(e);
  }
});

modelsRouter.get('/:id/metrics', async (req, res, next) => {
  try {
    const { data, error } = await readClient(req)
      .from('model_metrics')
      .select('*')
      .eq('model_id', req.params.id)
      .order('recorded_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (error) throw Object.assign(new Error(error.message), { status: 400 });
    res.json({ ok: true, metrics: data });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /:id/stage — transition dans le registre (validated, staging,
 * production, archived). Les règles vivent dans promote_ml_model : la
 * production ne se remplace jamais sans passer par le staging.
 */
modelsRouter.post('/:id/stage', requireAuth, async (req, res, next) => {
  try {
    const stage = String(req.body?.stage || '');
    const { data, error } = await dbForUser(req.accessToken).rpc('promote_ml_model', {
      p_model_id: req.params.id,
      p_stage: stage,
    });
    if (error) {
      const status = error.code === '42501' ? 403 : 400;
      throw Object.assign(new Error(error.message), { status, code: 'stage_refused' });
    }
    res.json({ ok: true, model: data });
  } catch (e) {
    next(e);
  }
});

/** Ancienne route conservée : équivaut à une promotion en production. */
modelsRouter.post('/:id/activate', requireAuth, async (req, res, next) => {
  try {
    const { data, error } = await dbForUser(req.accessToken).rpc('promote_ml_model', {
      p_model_id: req.params.id,
      p_stage: 'production',
    });
    if (error) throw Object.assign(new Error(error.message), { status: 400, code: 'stage_refused' });
    res.json({ ok: true, model: data });
  } catch (e) {
    next(e);
  }
});
