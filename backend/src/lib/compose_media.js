/**
 * Media URLs for text→sign composition.
 *
 * FastAPI often cannot reach corpus-lsfb.be (timeouts / campus firewalls),
 * while Express already caches those GIFs for the Flutter UI via
 * `/api/media/proxy`. Compose therefore rewrites external dictionary media
 * to that local proxy so ML downloads from 127.0.0.1 and reuses the disk cache.
 */

export function apiPublicBase() {
  const raw = process.env.PUBLIC_API_URL || `http://127.0.0.1:${process.env.PORT || 3001}`;
  return String(raw).trim().replace(/\/+$/, '');
}

export function originalMediaUrl(raw) {
  const text = String(raw || '').trim();
  if (!text) return '';
  try {
    const parsed = new URL(text);
    if (parsed.pathname.includes('/api/media/proxy')) {
      return String(parsed.searchParams.get('url') || '').trim() || text;
    }
  } catch {
    return text;
  }
  return text;
}

/** GIF / LSFB corpus clips need the disk-backed proxy; direct MP4 hosts stay as-is. */
export function needsComposeMediaProxy(raw) {
  const text = String(raw || '').trim();
  if (!text) return false;
  let parsed;
  try {
    parsed = new URL(text);
  } catch {
    return false;
  }
  if (parsed.pathname.includes('/api/media/proxy')) return true;
  const host = parsed.hostname.toLowerCase();
  const path = parsed.pathname.toLowerCase();
  const nested = String(parsed.searchParams.get('url') || '').toLowerCase();
  return (
    host.includes('corpus-lsfb')
    || path.endsWith('.gif')
    || path.endsWith('.webp')
    || path.endsWith('.apng')
    || nested.includes('.gif')
    || nested.includes('corpus-lsfb')
  );
}

/**
 * Absolute proxy URL on this API process. Idempotent for URLs already proxied.
 */
export function rewriteComposeMediaUrl(raw) {
  const text = String(raw || '').trim();
  if (!text) return text;
  const origin = originalMediaUrl(text);
  if (!needsComposeMediaProxy(origin) && !needsComposeMediaProxy(text)) {
    return text;
  }
  return `${apiPublicBase()}/api/media/proxy?url=${encodeURIComponent(origin)}`;
}
