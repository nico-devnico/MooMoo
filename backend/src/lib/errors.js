/**
 * What an API client may see of a failure.
 *
 * Messages from Postgres, Supabase, the ML service or Node itself name tables,
 * columns, hosts and configuration: they are logged here and only returned to
 * administrators. Everyone else gets a generic message for the HTTP status,
 * unless the error was built with `userError()` (a message written for users).
 */

const GENERIC = {
  400: 'La demande est invalide. Vérifiez les informations saisies.',
  401: 'Votre session a expiré. Reconnectez-vous.',
  403: "Vous n'avez pas les droits nécessaires pour cette action.",
  404: 'Élément introuvable.',
  409: 'Cet élément existe déjà.',
  413: 'Le fichier est trop volumineux.',
  415: "Ce format de fichier n'est pas pris en charge.",
  422: 'La demande est invalide. Vérifiez les informations saisies.',
  429: 'Trop de tentatives. Patientez un peu avant de réessayer.',
  502: 'Le service est momentanément indisponible. Réessayez plus tard.',
  503: 'Le service est momentanément indisponible. Réessayez plus tard.',
  500: 'Une erreur inattendue est survenue. Réessayez plus tard.',
};

export function genericMessage(status) {
  return GENERIC[status] || (status >= 500 ? GENERIC[500] : GENERIC[400]);
}

/** An error whose message is safe to show to any user. */
export function userError(status, message, code = 'error') {
  return Object.assign(new Error(message), { status, code, expose: true });
}

/** Wraps an upstream (database, storage…) failure without exposing it. */
export function upstreamError(error, status = 400, code) {
  return Object.assign(new Error(error?.message || String(error)), {
    status,
    code: code || error?.code || 'upstream_error',
    details: error?.details || error?.hint || undefined,
  });
}

/** Final Express error handler. */
export function errorHandler(err, req, res, _next) {
  const status = Number(err.status) || 500;
  console.error(`[api] ${req.method} ${req.originalUrl} → ${status}`, err.stack || err.message);
  const body = {
    ok: false,
    error: err.expose || status < 500 ? err.code || 'error' : 'internal_error',
    message: err.expose ? err.message : genericMessage(status),
  };
  if (req.isAdmin) {
    body.detail = err.message;
    if (err.details) body.details = err.details;
  }
  res.status(status).json(body);
}
