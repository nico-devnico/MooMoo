import { Router } from 'express';
import {
  dbForUser,
  dbPreferService,
  supabaseAdmin,
  supabaseAnon,
  ML_SERVICE_URL,
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
    const { data, error } = await readClient(req)
      .from('ml_models')
      .select('*')
      .eq('is_active', true)
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

modelsRouter.post('/retrain', requireAuth, async (req, res, next) => {
  try {
    const client = dbPreferService(req.accessToken);
    const dataset = req.body?.dataset || 'WASL+LSFB';
    const { data, error } = await client
      .from('training_jobs')
      .insert({
        model_id: req.body?.modelId || null,
        requested_by: req.user.id,
        dataset,
        status: 'queued',
        progress: 0,
      })
      .select()
      .single();
    if (error) throw Object.assign(new Error(error.message), { status: 400 });

    try {
      await fetch(`${ML_SERVICE_URL}/train`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ job_id: data.id, dataset }),
      });
    } catch (e) {
      console.warn('[retrain] ML notify failed:', e.message);
    }

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

modelsRouter.post('/:id/activate', requireAuth, async (req, res, next) => {
  try {
    const client = dbPreferService(req.accessToken);
    const { error } = await client.rpc('set_active_ml_model', {
      p_model_id: req.params.id,
    });
    if (error) {
      // The RPC refuses when auth.uid() is NULL (service role); RLS still guards
      // the direct update below.
      await client.from('ml_models').update({ is_active: false }).eq('is_active', true);
      const { error: e2 } = await client
        .from('ml_models')
        .update({ is_active: true, updated_at: new Date().toISOString() })
        .eq('id', req.params.id);
      if (e2) throw Object.assign(new Error(e2.message), { status: 400 });
    }
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});
