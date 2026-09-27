// Downloads a media file referenced by an import, refusing anything that is
// not a public http(s) resource of the expected type (SSRF protection).
import { lookup } from 'node:dns/promises';
import net from 'node:net';

const LIMITS = { video: 50 * 1024 * 1024, image: 5 * 1024 * 1024 };
const TIMEOUT_MS = 20000;
const MAX_REDIRECTS = 3;

const EXTENSIONS = {
  'video/mp4': 'mp4', 'video/webm': 'webm', 'video/quicktime': 'mov', 'video/ogg': 'ogv',
  'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/gif': 'gif',
};

export class MediaFetchError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

export function isPrivateAddress(address) {
  if (net.isIPv4(address)) {
    const [a, b] = address.split('.').map(Number);
    return a === 10 || a === 127 || a === 0 || (a === 169 && b === 254)
      || (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168)
      || (a === 100 && b >= 64 && b <= 127) || a >= 224;
  }
  const lower = address.toLowerCase();
  if (lower.startsWith('::ffff:')) return isPrivateAddress(lower.slice(7));
  return lower === '::1' || lower === '::' || lower.startsWith('fc') || lower.startsWith('fd')
    || lower.startsWith('fe80');
}

async function assertPublicHost(url) {
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    throw new MediaFetchError('bad_scheme', 'Seules les URL http(s) sont acceptées');
  }
  const host = url.hostname.replace(/^\[|\]$/g, '');
  const addresses = net.isIP(host) ? [{ address: host }] : await lookup(host, { all: true }).catch(() => []);
  if (!addresses.length) throw new MediaFetchError('dns', `Hôte introuvable : ${host}`);
  if (addresses.some((a) => isPrivateAddress(a.address))) {
    throw new MediaFetchError('private_host', 'Adresse privée ou locale refusée');
  }
}

/**
 * @param kind 'video' | 'image'
 * @returns {{ buffer: Buffer, contentType: string, extension: string }}
 */
export async function fetchMedia(rawUrl, kind) {
  let url = new URL(rawUrl);
  for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
    await assertPublicHost(url);
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    let res;
    try {
      res = await fetch(url, { redirect: 'manual', signal: controller.signal, headers: { 'User-Agent': 'MooMoo-Importer/1.0' } });
    } catch (e) {
      clearTimeout(timer);
      throw new MediaFetchError('network', e.name === 'AbortError' ? 'Délai dépassé' : `Téléchargement impossible : ${e.message}`);
    }
    if (res.status >= 300 && res.status < 400 && res.headers.get('location')) {
      clearTimeout(timer);
      url = new URL(res.headers.get('location'), url);
      continue;
    }
    try {
      if (res.status === 401 || res.status === 403) {
        throw new MediaFetchError('forbidden', `Accès refusé par la source (HTTP ${res.status})`);
      }
      if (!res.ok) throw new MediaFetchError('http', `La source a répondu HTTP ${res.status}`);
      const contentType = (res.headers.get('content-type') || '').split(';')[0].trim().toLowerCase();
      if (!contentType.startsWith(`${kind}/`)) {
        throw new MediaFetchError('not_media',
          contentType === 'text/html' ? 'Page web, pas un fichier média' : `Type inattendu : ${contentType || 'inconnu'}`);
      }
      const limit = LIMITS[kind];
      const declared = Number(res.headers.get('content-length') || 0);
      if (declared > limit) throw new MediaFetchError('too_large', `Fichier trop volumineux (> ${limit / 1048576} Mo)`);

      const chunks = [];
      let size = 0;
      for await (const chunk of res.body) {
        size += chunk.length;
        if (size > limit) {
          controller.abort();
          throw new MediaFetchError('too_large', `Fichier trop volumineux (> ${limit / 1048576} Mo)`);
        }
        chunks.push(chunk);
      }
      const extension = EXTENSIONS[contentType] || contentType.split('/')[1].replace(/[^a-z0-9]/g, '') || 'bin';
      return { buffer: Buffer.concat(chunks), contentType, extension };
    } finally {
      clearTimeout(timer);
    }
  }
  throw new MediaFetchError('redirects', 'Trop de redirections');
}
