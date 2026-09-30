// Proxy média public (GIF dictionnaire LSFB, etc.) : contourne CORS navigateur,
// met en cache disque et renvoie le vrai fichier distant (pas de données fictives).
import { createHash } from 'node:crypto';
import {
  createReadStream,
  existsSync,
  mkdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import { join } from 'node:path';
import { lookup } from 'node:dns/promises';
import net from 'node:net';
import { Router } from 'express';
import { isPrivateAddress, MediaFetchError } from '../lib/media_fetch.js';

export const mediaRouter = Router();

const CACHE_DIR = join(process.cwd(), 'cache', 'media');
const MAX_BYTES = 15 * 1024 * 1024;
const TIMEOUT_MS = 60000;

function cacheKey(url) {
  return createHash('sha256').update(url).digest('hex');
}

function ensureCacheDir() {
  if (!existsSync(CACHE_DIR)) mkdirSync(CACHE_DIR, { recursive: true });
}

async function assertPublicHost(url) {
  const host = url.hostname.replace(/^\[|\]$/g, '');
  const addresses = net.isIP(host)
    ? [{ address: host }]
    : await lookup(host, { all: true }).catch(() => []);
  if (!addresses.length) {
    throw new MediaFetchError('dns', `Hôte introuvable : ${host}`);
  }
  if (addresses.some((a) => isPrivateAddress(a.address))) {
    throw new MediaFetchError('private_host', 'Adresse privée ou locale refusée');
  }
}

async function downloadPublicImage(rawUrl) {
  let url = new URL(rawUrl);
  await assertPublicHost(url);

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      signal: controller.signal,
      redirect: 'follow',
      headers: { 'User-Agent': 'MooMoo-MediaProxy/1.0', Accept: 'image/*,*/*' },
    });
    if (res.status === 401 || res.status === 403) {
      throw new MediaFetchError('forbidden', `Accès refusé (HTTP ${res.status})`);
    }
    if (!res.ok) {
      throw new MediaFetchError('http', `La source a répondu HTTP ${res.status}`);
    }
    const contentType = (res.headers.get('content-type') || '')
      .split(';')[0]
      .trim()
      .toLowerCase();
    if (!contentType.startsWith('image/')) {
      throw new MediaFetchError(
        'not_media',
        contentType === 'text/html'
          ? 'Page web, pas un fichier média'
          : `Type inattendu : ${contentType || 'inconnu'}`,
      );
    }
    const declared = Number(res.headers.get('content-length') || 0);
    if (declared > MAX_BYTES) {
      throw new MediaFetchError('too_large', `Fichier trop volumineux (> ${MAX_BYTES / 1048576} Mo)`);
    }
    const buffer = Buffer.from(await res.arrayBuffer());
    if (buffer.length > MAX_BYTES) {
      throw new MediaFetchError('too_large', `Fichier trop volumineux (> ${MAX_BYTES / 1048576} Mo)`);
    }
    return { buffer, contentType };
  } catch (e) {
    if (e instanceof MediaFetchError) throw e;
    throw new MediaFetchError(
      'network',
      e.name === 'AbortError' ? 'Délai dépassé' : `Téléchargement impossible : ${e.message}`,
    );
  } finally {
    clearTimeout(timer);
  }
}

/** GET /api/media/proxy?url=https://… */
mediaRouter.get('/proxy', async (req, res) => {
  const raw = String(req.query.url || '').trim();
  if (!raw) {
    return res.status(400).json({
      ok: false,
      error: 'missing_url',
      message: 'Paramètre url manquant.',
    });
  }

  let parsed;
  try {
    parsed = new URL(raw);
  } catch {
    return res.status(400).json({
      ok: false,
      error: 'bad_url',
      message: 'URL invalide.',
    });
  }
  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    return res.status(400).json({
      ok: false,
      error: 'bad_scheme',
      message: 'Seules les URL http(s) sont acceptées.',
    });
  }

  ensureCacheDir();
  const key = cacheKey(raw);
  const metaPath = join(CACHE_DIR, `${key}.json`);
  const binPath = join(CACHE_DIR, `${key}.bin`);

  try {
    if (existsSync(binPath) && existsSync(metaPath)) {
      const meta = JSON.parse(readFileSync(metaPath, 'utf8'));
      const size = statSync(binPath).size;
      const ctype = meta.contentType || 'application/octet-stream';
      res.setHeader('Content-Type', ctype);
      res.setHeader('Content-Length', String(size));
      res.setHeader('Cache-Control', 'public, max-age=604800, immutable');
      // Nom de fichier avec extension pour les clients qui se basent sur l'URL.
      res.setHeader(
        'Content-Disposition',
        `inline; filename="sign.${ctype.includes('gif') ? 'gif' : ctype.includes('webp') ? 'webp' : 'img'}"`,
      );
      res.setHeader('X-Media-Cache', 'HIT');
      return createReadStream(binPath).pipe(res);
    }

    const media = await downloadPublicImage(raw);
    writeFileSync(binPath, media.buffer);
    writeFileSync(
      metaPath,
      JSON.stringify({
        url: raw,
        contentType: media.contentType,
        cachedAt: new Date().toISOString(),
        bytes: media.buffer.length,
      }),
      'utf8',
    );

    res.setHeader('Content-Type', media.contentType);
    res.setHeader('Content-Length', String(media.buffer.length));
    res.setHeader('Cache-Control', 'public, max-age=604800, immutable');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="sign.${media.contentType.includes('gif') ? 'gif' : media.contentType.includes('webp') ? 'webp' : 'img'}"`,
    );
    res.setHeader('X-Media-Cache', 'MISS');
    return res.send(media.buffer);
  } catch (e) {
    const status = e instanceof MediaFetchError
      ? (e.code === 'forbidden' ? 403 : e.code === 'too_large' ? 413 : 422)
      : 502;
    console.error('[media/proxy]', e.message || e);
    return res.status(status).json({
      ok: false,
      error: e.code || 'proxy_failed',
      message: e.message || 'Téléchargement du média impossible.',
    });
  }
});
