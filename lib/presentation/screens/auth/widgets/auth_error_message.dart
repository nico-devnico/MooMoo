import '../../../../core/errors/user_error.dart';
import '../../../../l10n/app_localizations.dart';

/// Turns an auth failure into something a user can act on.
///
/// Supabase answers HTTP 422 for both an address that is already taken and a
/// password that fails the server policy; the raw body is not presentable, so
/// the known cases are matched here and everything else falls back to a
/// generic message.
String authErrorMessage(Object error, AppLocalizations l10n) {
  final raw = error.toString().toLowerCase();

  if (raw.contains('user_already_exists') ||
      raw.contains('already registered') ||
      raw.contains('already been registered')) {
    return l10n.authEmailAlreadyUsed;
  }
  if (raw.contains('weak_password') || raw.contains('password should')) {
    return l10n.authWeakPassword;
  }
  if (raw.contains('invalid login') || raw.contains('invalid_credentials')) {
    return l10n.authInvalidCredentials;
  }
  if (raw.contains('email not confirmed')) {
    return l10n.authEmailNotConfirmed;
  }
  if (raw.contains('rate limit') || raw.contains('over_email_send_rate')) {
    return l10n.authRateLimited;
  }
  if (raw.contains('signup') && raw.contains('disabled')) {
    return l10n.authSignupDisabled;
  }
  if (raw.contains('failed to fetch') ||
      raw.contains('clientexception') ||
      raw.contains('network') ||
      raw.contains('socket') ||
      raw.contains('connection refused')) {
    return l10n.authNetworkError;
  }

  return userErrorMessage(error, l10n, fallback: l10n.authUnknownError);
}
