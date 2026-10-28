import { Router } from 'express';
import multer from 'multer';
import {
  originalMediaUrl,
  rewriteComposeMediaUrl,
} from '../lib/compose_media.js';
import { MediaFetchError } from '../lib/media_fetch.js';
import { ML_SERVICE_URL, supabaseAdmin, dbForUser, supabaseAnon } from '../supabase.js';
import { ensurePublicMediaCached } from './media.js';
export const inferRouter = Router();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 12 * 1024 * 1024 },
});

async function forwardToMl(path, form) {
  const started = Date.now();
  let mlRes;
  try {
    mlRes = await fetch(`${ML_SERVICE_URL}${path}`, {
      method: 'POST',
      body: form,
    });
  } catch (e) {
    console.error(`[infer] ML service unreachable (${ML_SERVICE_URL}):`, e.message);
    return {
      errorStatus: 503,
      body: {
        ok: false,
        error: 'ml_unavailable',
        message: 'La reconnaissance des signes est momentanément indisponible. Réessayez plus tard.',
      },
    };
  }

  const payload = await mlRes.json().catch(() => ({}));
  if (!mlRes.ok) {
    console.error('[infer] ML service error', mlRes.status, payload.detail || payload.message);
    return {
      errorStatus: mlRes.status >= 500 ? 502 : mlRes.status,
      body: {
        ok: false,
        error: 'ml_error',
        message: mlRes.status >= 500
          ? 'La reconnaissance des signes est momentanément indisponible. Réessayez plus tard.'
          : "Cette capture n'a pas pu être analysée. Vérifiez que la main est bien visible et réessayez.",
      },
    };
  }

  return { payload, started };
}

/** Épellation ASL temps réel : image ou clip vidéo → lettre + phrase. */
inferRouter.post('/spell', upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(422).json({
        ok: false,
        error: 'no_input',
        message: 'Une image ou une courte vidéo de la main est requise.',
      });
    }

    const name = req.file.originalname || 'frame.jpg';
    const mime = req.file.mimetype
      || (/\.(mp4|webm|mov|avi|mkv)$/i.test(name) ? 'video/mp4' : 'image/jpeg');
    const form = new FormData();
    form.append(
      'file',
      new Blob([req.file.buffer], { type: mime }),
      name,
    );
    if (req.body?.session_id) form.append('session_id', String(req.body.session_id));
    if (req.body?.threshold) form.append('threshold', String(req.body.threshold));
    if (req.body?.reset) form.append('reset', String(req.body.reset));
    if (req.body?.single_shot) form.append('single_shot', String(req.body.single_shot));
    if (req.body?.hand_detected != null && req.body?.hand_detected !== '') {
      form.append('hand_detected', String(req.body.hand_detected));
    }
    if (req.body?.live) form.append('live', String(req.body.live));

    const result = await forwardToMl('/infer/spell', form);
    if (result.errorStatus) {
      return res.status(result.errorStatus).json(result.body);
    }

    const { payload, started } = result;
    res.json({
      ok: true,
      prediction: {
        label: payload.label,
        confidence: payload.confidence,
        top: payload.top,
        latency_ms: payload.latency_ms ?? Date.now() - started,
        text: payload.text ?? '',
        committed: payload.committed ?? null,
        accepted: payload.accepted ?? false,
        mode: 'fingerspell',
        hand_detected: payload.hand_detected ?? true,
        frames_scored: payload.frames_scored,
        source: payload.source,
      },
      session_id: payload.session_id,
      model: payload.model,
      dataset: payload.dataset || 'asl_alphabet',
    });
  } catch (e) {
    next(e);
  }
});
function composeError(status, error, message, field) {
  return {
    errorStatus: status,
    body: {
      ok: false,
      error,
      message,
      ...(field ? { field } : {}),
    },
  };
}

/** `"false"` stays false. undefined means the value is not a boolean. */
export function parseIncludeFace(value) {
  if (value === undefined || value === null || value === '') return false;
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') {
    if (value === 1) return true;
    if (value === 0) return false;
    return undefined;
  }
  const token = String(value).trim().toLowerCase();
  if (['1', 'true', 'yes', 'on'].includes(token)) return true;
  if (['0', 'false', 'no', 'off'].includes(token)) return false;
  return undefined;
}

function readBoundedNumber(body, key, { integer, min, max }) {
  if (!body || body[key] === undefined || body[key] === null || body[key] === '') {
    return { value: undefined };
  }
  if (typeof body[key] === 'boolean') {
    return { error: `${key} doit être un nombre compris entre ${min} et ${max}.` };
  }
  const n = typeof body[key] === 'number' ? body[key] : Number(String(body[key]).trim());
  if (!Number.isFinite(n) || (integer && !Number.isInteger(n)) || n < min || n > max) {
    const kind = integer ? 'un entier' : 'un nombre';
    return { error: `${key} doit être ${kind} compris entre ${min} et ${max}.` };
  }
  return { value: n };
}

function clipUrl(item) {
  if (typeof item === 'string') return item.trim();
  if (!item || typeof item !== 'object') return '';
  return String(item.url || item.video_url || item.media_url || '').trim();
}

function clipWord(item) {
  if (!item || typeof item !== 'object') return '';
  return String(item.word || item.label || '').trim();
}

/**
 * Validate the Express body and build the JSON FastAPI actually expects.
 * Word-only clips and `text` are forwarded so the ML service can resolve
 * real dictionary URLs.
 */
export function prepareComposeRequest(body) {
  const source = body && typeof body === 'object' && !Array.isArray(body) ? body : {};
  const rawClips = source.clips ?? source.media ?? source.urls;
  const text = typeof source.text === 'string' ? source.text.trim() : '';
  const word = typeof source.word === 'string' ? source.word.trim() : '';
  const loneUrl = clipUrl({
    url: source.url,
    video_url: source.video_url,
    media_url: source.media_url,
  });

  if (rawClips != null && !Array.isArray(rawClips)) {
    return composeError(422, 'invalid_request', 'clips doit être une liste.', 'clips');
  }
  const clips = Array.isArray(rawClips) ? rawClips : [];
  if (clips.length === 0 && !text && !word && !loneUrl) {
    return composeError(
      422,
      'invalid_request',
      rawClips
        ? 'La liste clips est vide. Envoyez au moins un clip {word, url} ou un champ text.'
        : 'Envoyez clips (liste non vide de {word, url}) ou text (phrase du dictionnaire).',
      rawClips ? 'clips' : 'body',
    );
  }

  for (let i = 0; i < clips.length; i += 1) {
    const item = clips[i];
    const url = clipUrl(item);
    const label = clipWord(item);
    if (typeof item === 'string') {
      if (!url) {
        return composeError(422, 'invalid_clip', `clips[${i}] est vide.`, `clips[${i}]`);
      }
      continue;
    }
    if (!item || typeof item !== 'object' || Array.isArray(item)) {
      return composeError(
        422,
        'invalid_clip',
        `clips[${i}] doit être un objet {word, url} ou une URL.`,
        `clips[${i}]`,
      );
    }
    if (!url && !label) {
      return composeError(
        422,
        'invalid_clip',
        `clips[${i}] n'a ni URL ni mot. Ajoutez url, video_url ou word.`,
        `clips[${i}]`,
      );
    }
    if (url && !/^https?:\/\//i.test(url)) {
      return composeError(
        422,
        'invalid_clip',
        `clips[${i}].url doit être une URL http(s) absolue.`,
        `clips[${i}].url`,
      );
    }
  }

  const numbers = [
    ['fps', { integer: false, min: 1, max: 60 }],
    ['gap_frames', { integer: true, min: 0, max: 120 }],
    ['blend_frames', { integer: true, min: 0, max: 120 }],
    ['max_frames_per_clip', { integer: true, min: 1, max: 400 }],
  ];
  const numeric = {};
  for (const [key, bounds] of numbers) {
    const parsed = readBoundedNumber(source, key, bounds);
    if (parsed.error) {
      return composeError(422, 'invalid_request', parsed.error, key);
    }
    if (parsed.value !== undefined) numeric[key] = parsed.value;
  }
  if (numeric.blend_frames === undefined && numeric.gap_frames !== undefined) {
    numeric.blend_frames = numeric.gap_frames;
  }

  let includeFace;
  if (source.include_face !== undefined && source.include_face !== null && source.include_face !== '') {
    includeFace = parseIncludeFace(source.include_face);
    if (includeFace === undefined) {
      return composeError(
        422,
        'invalid_request',
        'include_face doit être un booléen (true ou false).',
        'include_face',
      );
    }
  }

  const forward = {};
  if (clips.length) {
    forward.clips = clips.map((item) => {
      if (typeof item === 'string') {
        return rewriteComposeMediaUrl(item.trim());
      }
      const url = clipUrl(item);
      const label = clipWord(item);
      const signId = item.sign_id || item.id;
      return {
        ...(label ? { word: label } : {}),
        ...(url ? { url: rewriteComposeMediaUrl(url) } : {}),
        ...(signId ? { sign_id: signId } : {}),
      };
    });
  }
  if (text) forward.text = text;
  if (word) forward.word = word;
  if (loneUrl) forward.url = rewriteComposeMediaUrl(loneUrl);
  Object.assign(forward, numeric);
  if (includeFace !== undefined) forward.include_face = includeFace;
  return { payload: forward };
}

async function warmComposeMedia(payload) {
  const urls = [];
  for (const item of payload.clips || []) {
    const url = typeof item === 'string' ? item : item?.url;
    if (url) urls.push(url);
  }
  if (payload.url) urls.push(payload.url);

  for (const url of urls) {
    const origin = originalMediaUrl(url);
    try {
      const cached = await ensurePublicMediaCached(origin);
      console.info(
        `[infer/compose] media ${cached.hit ? 'cache-hit' : 'cache-miss'} `
        + `bytes=${cached.bytes} origin=${origin.slice(0, 80)}`,
      );
    } catch (e) {
      const message = e instanceof MediaFetchError
        ? e.message
        : `Impossible de préparer le média du dictionnaire (${e.message})`;
      const status = e instanceof MediaFetchError && e.code === 'not_found' ? 404 : 502;
      const err = new Error(message);
      err.status = status;
      err.code = e.code || 'download_failed';
      err.expose = true;
      throw err;
    }
  }
}

/** Texte → signes : médias du dictionnaire, landmarks Holistic, une séquence. */
inferRouter.post('/compose-landmarks', async (req, res, next) => {
  try {
    const prepared = prepareComposeRequest(req.body);
    if (prepared.errorStatus) {
      return res.status(prepared.errorStatus).json(prepared.body);
    }

    try {
      await warmComposeMedia(prepared.payload);
    } catch (e) {
      console.error(`[infer/compose] media warm failed:`, e.message);
      return res.status(e.status || 502).json({
        ok: false,
        error: e.code || 'download_failed',
        message: e.message
          || 'Impossible de télécharger la vidéo du dictionnaire (cache local ou source distante).',
      });
    }

    const target = `${ML_SERVICE_URL}/compose-landmarks`;
    const clipCount = prepared.payload.clips?.length || 0;
    let mlRes;
    try {
      mlRes = await fetch(target, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
        body: JSON.stringify(prepared.payload),
      });
    } catch (e) {
      console.error(`[infer/compose] ML injoignable (${ML_SERVICE_URL}):`, e.message);
      return res.status(503).json({
        ok: false,
        error: 'ml_unavailable',
        message: 'La composition des signes est momentanément indisponible. Réessayez plus tard.',
      });
    }

    const payload = await mlRes.json().catch(() => ({}));
    console.info(
      `[infer/compose] clips=${clipCount} include_face=${prepared.payload.include_face} `
      + `status=${mlRes.status} error=${payload.error || 'ok'}`,
    );
    if (!mlRes.ok || payload.ok === false) {
      const status = mlRes.ok ? 422 : (mlRes.status >= 500 ? 502 : mlRes.status);
      return res.status(status).json({
        ok: false,
        error: payload.error || 'compose_failed',
        message: payload.detail || payload.message
          || 'Impossible de composer la séquence de signes.',
        ...(payload.field ? { field: payload.field } : {}),
        missing: payload.missing || [],
      });
    }

    res.json({
      ok: true,
      fps: payload.fps,
      frames: payload.frames,
      frame_count: payload.frame_count,
      segments: payload.segments || [],
      missing: payload.missing || [],
      layout: payload.layout,
    });
  } catch (e) {
    next(e);
  }
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
    if (req.body?.session_id) form.append('session_id', String(req.body.session_id));

    const result = await forwardToMl('/infer', form);
    if (result.errorStatus) {
      return res.status(result.errorStatus).json(result.body);
    }

    const { payload, started } = result;
    res.json({
      ok: true,
      prediction: {
        label: payload.label,
        confidence: payload.confidence,
        top: payload.top,
        latency_ms: payload.latency_ms ?? Date.now() - started,
        text: payload.text,
        committed: payload.committed,
        mode: payload.mode,
      },
      session_id: payload.session_id,
      model: payload.model || model,
      language: payload.language || language,
      dataset: payload.dataset,
    });
  } catch (e) {
    next(e);
  }
});
