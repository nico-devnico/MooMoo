import assert from 'node:assert/strict';
import http from 'node:http';
import test from 'node:test';
import express from 'express';

import { rewriteComposeMediaUrl } from '../lib/compose_media.js';
import { errorHandler } from '../lib/errors.js';
import { inferRouter, parseIncludeFace, prepareComposeRequest } from './infer.js';
import { mlServiceBase } from '../supabase.js';

const REAL_GIF = 'https://www.corpus-lsfb.be/img/pictures/signe_f179359556f2bee76ed4299418313818.gif';
const PROXY_GIF = rewriteComposeMediaUrl(REAL_GIF);

function appWith(fetchImpl) {
  const previous = globalThis.fetch;
  globalThis.fetch = fetchImpl;
  const app = express();
  app.use(express.json());
  app.use('/api/infer', inferRouter);
  app.use(errorHandler);
  return {
    app,
    restore() {
      globalThis.fetch = previous;
    },
  };
}

function listen(app) {
  return new Promise((resolve) => {
    const server = app.listen(0, '127.0.0.1', () => resolve(server));
  });
}

function post(server, path, { json, raw, headers } = {}) {
  const body = raw !== undefined ? raw : JSON.stringify(json ?? {});
  return new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: '127.0.0.1',
        port: server.address().port,
        path,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
          ...headers,
        },
      },
      (res) => {
        const chunks = [];
        res.on('data', (chunk) => chunks.push(chunk));
        res.on('end', () => {
          const text = Buffer.concat(chunks).toString('utf8');
          let parsed = {};
          try {
            parsed = text ? JSON.parse(text) : {};
          } catch {
            parsed = { raw: text };
          }
          resolve({ status: res.statusCode, body: parsed });
        });
      },
    );
    req.on('error', reject);
    req.end(body);
  });
}

test('mlServiceBase keeps the host and drops only a mistaken /api/infer suffix', () => {
  assert.equal(mlServiceBase('http://127.0.0.1:8000'), 'http://127.0.0.1:8000');
  assert.equal(mlServiceBase('http://127.0.0.1:8000/'), 'http://127.0.0.1:8000');
  assert.equal(mlServiceBase('http://127.0.0.1:8000/api/infer'), 'http://127.0.0.1:8000');
  assert.equal(mlServiceBase('http://127.0.0.1:8000/api/infer/'), 'http://127.0.0.1:8000');
  assert.equal(mlServiceBase('http://ml.internal:8000/v1'), 'http://ml.internal:8000/v1');
});

test('parseIncludeFace does not treat the string false as true', () => {
  assert.equal(parseIncludeFace('false'), false);
  assert.equal(parseIncludeFace('False'), false);
  assert.equal(parseIncludeFace(false), false);
  assert.equal(parseIncludeFace('true'), true);
  assert.equal(parseIncludeFace('maybe'), undefined);
});

test('prepareComposeRequest rejects an empty body, empty clips and a clip without a url', () => {
  const empty = prepareComposeRequest({});
  assert.equal(empty.errorStatus, 422);
  assert.equal(empty.body.field, 'body');

  const noClips = prepareComposeRequest({ clips: [] });
  assert.equal(noClips.errorStatus, 422);
  assert.equal(noClips.body.field, 'clips');

  const noUrl = prepareComposeRequest({ clips: [{}] });
  assert.equal(noUrl.errorStatus, 422);
  assert.equal(noUrl.body.error, 'invalid_clip');
  assert.match(noUrl.body.field, /^clips\[/);
});

test('prepareComposeRequest rejects an invalid number and rewrites LSFB GIFs to the media proxy', () => {
  const fps = prepareComposeRequest({
    clips: [{ word: 'à côté', url: REAL_GIF }],
    fps: 'abc',
  });
  assert.equal(fps.errorStatus, 422);
  assert.equal(fps.body.field, 'fps');

  const face = prepareComposeRequest({
    clips: [{ word: 'à côté', video_url: REAL_GIF }],
    include_face: 'false',
  });
  assert.equal(face.payload.include_face, false);
  assert.equal(face.payload.clips[0].url, PROXY_GIF);
  assert.match(face.payload.clips[0].url, /\/api\/media\/proxy\?url=/);
  assert.equal(face.payload.clips[0].video_url, undefined);
});

test('empty body, empty clips, clip without url and malformed JSON through Express', async () => {
  const { app, restore } = appWith(async () => {
    throw new Error('le service ML ne doit pas être appelé');
  });
  const server = await listen(app);
  try {
    const empty = await post(server, '/api/infer/compose-landmarks', { json: {} });
    assert.equal(empty.status, 422);
    assert.equal(empty.body.field, 'body');

    const noClips = await post(server, '/api/infer/compose-landmarks', { json: { clips: [] } });
    assert.equal(noClips.status, 422);
    assert.equal(noClips.body.field, 'clips');

    const noUrl = await post(server, '/api/infer/compose-landmarks', { json: { clips: [{ word: '' }] } });
    assert.equal(noUrl.status, 422);
    assert.equal(noUrl.body.error, 'invalid_clip');

    const broken = await post(server, '/api/infer/compose-landmarks', { raw: '{"clips":' });
    assert.equal(broken.status, 422);
    assert.equal(broken.body.error, 'invalid_request');
    assert.equal(broken.body.field, 'body');
    assert.match(broken.body.message, /JSON/);
  } finally {
    server.close();
    restore();
  }
});

test('ML unavailable returns 503 without a fake success', async () => {
  const { app, restore } = appWith(async () => {
    throw new Error('connect ECONNREFUSED 127.0.0.1:8000');
  });
  const server = await listen(app);
  try {
    const res = await post(server, '/api/infer/compose-landmarks', {
      json: { clips: [{ word: 'à côté', url: REAL_GIF }] },
    });
    assert.equal(res.status, 503);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.error, 'ml_unavailable');
    assert.equal(res.body.frames, undefined);
  } finally {
    server.close();
    restore();
  }
});

test('full client request reaches ML and returns landmarks Flutter can read', async () => {
  let forwardedUrl = '';
  let forwarded = null;
  const { app, restore } = appWith(async (url, opts) => {
    forwardedUrl = String(url);
    forwarded = JSON.parse(opts.body);
    return new Response(JSON.stringify({
      ok: true,
      fps: 15,
      frames: [[0.2, 0.4, 0.1], [0.3, 0.5, 0.2]],
      frame_count: 2,
      segments: [{ word: 'à côté', sign_id: 'lsfb:A-COTE', start_frame: 0, frames: 2 }],
      missing: [],
      layout: { include_face: false },
    }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  });
  const server = await listen(app);
  try {
    const res = await post(server, '/api/infer/compose-landmarks', {
      json: {
        clips: [{ word: 'à côté', url: REAL_GIF, sign_id: 'lsfb:A-COTE' }],
        fps: 15,
        blend_frames: 6,
        include_face: 'false',
      },
    });
    assert.equal(res.status, 200);
    assert.equal(res.body.ok, true);
    assert.equal(res.body.frame_count, 2);
    assert.equal(res.body.frames.length, 2);
    assert.equal(res.body.segments[0].word, 'à côté');
    assert.equal(forwarded.include_face, false);
    assert.equal(forwarded.clips[0].url, PROXY_GIF);
    assert.match(forwarded.clips[0].url, /127\.0\.0\.1:3001\/api\/media\/proxy/);
    assert.equal(forwardedUrl.endsWith('/compose-landmarks'), true);
    assert.equal(forwardedUrl.includes('/api/infer/compose-landmarks'), false);
  } finally {
    server.close();
    restore();
  }
});

test('upstream download and unknown-word errors stay explicit', async () => {
  const cases = [
    [{ error: 'download_failed', detail: 'Impossible de télécharger les vidéos du dictionnaire.', missing: [] }, 502],
    [{ error: 'unknown_word', detail: 'Mots absents du dictionnaire : zzzz.', missing: [{ word: 'zzzz' }] }, 404],
    [{ error: 'no_landmarks', detail: 'La vidéo est accessible mais aucun landmark n\'a été détecté.', missing: [] }, 422],
  ];
  for (const [payload, status] of cases) {
    const { app, restore } = appWith(async () => new Response(JSON.stringify({ ok: false, ...payload }), {
      status,
      headers: { 'Content-Type': 'application/json' },
    }));
    const server = await listen(app);
    try {
      const res = await post(server, '/api/infer/compose-landmarks', {
        json: { clips: [{ word: 'à côté', url: REAL_GIF }] },
      });
      assert.equal(res.status, status);
      assert.equal(res.body.ok, false);
      assert.equal(res.body.error, payload.error);
      assert.equal(res.body.message, payload.detail);
    } finally {
      server.close();
      restore();
    }
  }
});
