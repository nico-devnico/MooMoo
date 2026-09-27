import { supabaseAnon } from '../supabase.js';
import { getRoles } from './roles.js';

const CACHE_MS = 5000;
let cached = null;
let cachedAt = 0;

export async function getAppSettings({ fresh = false } = {}) {
  if (!fresh && cached && Date.now() - cachedAt < CACHE_MS) return cached;
  const { data, error } = await supabaseAnon.from('app_settings').select('*').eq('id', true).maybeSingle();
  if (error) throw Object.assign(new Error(error.message), { status: 503, code: 'settings_unavailable' });
  cached = data || { maintenance_enabled: false, contributions_enabled: true };
  cachedAt = Date.now();
  return cached;
}

/**
 * During maintenance only administrators reach the API. Needs optionalAuth or
 * requireAuth upstream so req.accessToken is set.
 */
export async function maintenanceGuard(req, res, next) {
  try {
    const settings = await getAppSettings();
    if (!settings.maintenance_enabled) return next();
    if (req.accessToken) {
      const roles = req.roles || (await getRoles(req.accessToken).catch(() => []));
      if (roles.includes('admin')) return next();
    }
    return res.status(503).json({
      ok: false,
      error: 'maintenance',
      message: settings.maintenance_message || 'Application en maintenance',
    });
  } catch (e) {
    next(e);
  }
}
