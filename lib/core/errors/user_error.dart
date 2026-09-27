import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_client.dart';
import '../../l10n/app_localizations.dart';

/// What went wrong, from the user's point of view.
enum UserErrorKind {
  network,
  serviceUnavailable,
  maintenance,
  sessionExpired,
  permission,
  notFound,
  conflict,
  tooLarge,
  unsupportedFormat,
  invalidData,
  unknown,
}

/// Raised by the app itself for failures that are already user-level, such as
/// a picked file that is too large, so they map to a precise message.
class UserFacingException implements Exception {
  const UserFacingException(this.kind, [this.detail]);

  final UserErrorKind kind;

  /// Technical context, only ever shown to administrators.
  final String? detail;

  @override
  String toString() => detail ?? kind.name;
}

UserErrorKind classifyError(Object error) {
  if (error is UserFacingException) return error.kind;
  if (error is TimeoutException) return UserErrorKind.network;
  if (error is ApiUnreachableException) return UserErrorKind.serviceUnavailable;
  if (error is ApiException) {
    if (error.code == 'maintenance') return UserErrorKind.maintenance;
    return _fromStatus(error.status) ?? UserErrorKind.unknown;
  }
  if (error is AuthException) {
    final status = int.tryParse(error.statusCode ?? '');
    if (status == 401 || status == 403) return UserErrorKind.sessionExpired;
    if (_looksLikeNetwork(error.message)) return UserErrorKind.network;
    return UserErrorKind.unknown;
  }
  if (error is StorageException) {
    final raw = error.message.toLowerCase();
    if (raw.contains('maximum allowed size') || raw.contains('too large') || raw.contains('payload')) {
      return UserErrorKind.tooLarge;
    }
    if (raw.contains('mime') || raw.contains('invalid_mime_type')) {
      return UserErrorKind.unsupportedFormat;
    }
    if (raw.contains('row-level security') || raw.contains('unauthorized')) {
      return UserErrorKind.permission;
    }
    if (_looksLikeNetwork(raw)) return UserErrorKind.network;
    return _fromStatus(int.tryParse(error.statusCode ?? '')) ?? UserErrorKind.unknown;
  }
  if (error is PostgrestException) {
    switch (error.code) {
      case '42501':
        return UserErrorKind.permission;
      case '23505':
        return UserErrorKind.conflict;
      case 'PGRST116':
        return UserErrorKind.notFound;
      case 'PGRST301':
      case 'PGRST303':
        return UserErrorKind.sessionExpired;
    }
    final code = error.code ?? '';
    if (code.startsWith('22') || code.startsWith('23')) return UserErrorKind.invalidData;
    if (error.message.toLowerCase().contains('row-level security')) {
      return UserErrorKind.permission;
    }
    if (_looksLikeNetwork(error.message)) return UserErrorKind.network;
    return UserErrorKind.unknown;
  }
  // SocketException (dart:io) and ClientException (package:http) are matched
  // by name so this file stays usable on the web.
  final type = error.runtimeType.toString();
  if (type.contains('SocketException') ||
      type.contains('ClientException') ||
      type.contains('HandshakeException') ||
      _looksLikeNetwork(error.toString())) {
    return UserErrorKind.network;
  }
  return UserErrorKind.unknown;
}

UserErrorKind? _fromStatus(int? status) => switch (status) {
      null => null,
      401 => UserErrorKind.sessionExpired,
      403 => UserErrorKind.permission,
      404 => UserErrorKind.notFound,
      409 => UserErrorKind.conflict,
      413 => UserErrorKind.tooLarge,
      415 => UserErrorKind.unsupportedFormat,
      400 || 422 => UserErrorKind.invalidData,
      502 || 503 || 504 => UserErrorKind.serviceUnavailable,
      _ => null,
    };

bool _looksLikeNetwork(String raw) {
  final s = raw.toLowerCase();
  return s.contains('failed to fetch') ||
      s.contains('failed host lookup') ||
      s.contains('connection refused') ||
      s.contains('connection closed') ||
      s.contains('network is unreachable') ||
      s.contains('xmlhttprequest error');
}

String userErrorKindMessage(UserErrorKind kind, AppLocalizations l10n) => switch (kind) {
      UserErrorKind.network => l10n.errNetwork,
      UserErrorKind.serviceUnavailable => l10n.errServiceUnavailable,
      UserErrorKind.maintenance => l10n.errMaintenance,
      UserErrorKind.sessionExpired => l10n.errSessionExpired,
      UserErrorKind.permission => l10n.errPermission,
      UserErrorKind.notFound => l10n.errNotFound,
      UserErrorKind.conflict => l10n.errConflict,
      UserErrorKind.tooLarge => l10n.errTooLarge,
      UserErrorKind.unsupportedFormat => l10n.errUnsupportedFormat,
      UserErrorKind.invalidData => l10n.errInvalidData,
      UserErrorKind.unknown => l10n.errUnknown,
    };

/// A message a user can act on, never exposing internals (tables, SQL,
/// hosts, stack traces). Pass [technical] only for administrators: the raw
/// error is then appended to help them diagnose.
String userErrorMessage(
  Object error,
  AppLocalizations l10n, {
  String? fallback,
  bool technical = false,
}) {
  final kind = classifyError(error);
  // The API only sends messages written for users (see backend lib/errors.js).
  final apiMessage = error is ApiException && !error.message.startsWith('HTTP ')
      ? error.message
      : null;
  final message = apiMessage ??
      (kind == UserErrorKind.unknown && fallback != null
          ? fallback
          : userErrorKindMessage(kind, l10n));
  if (!technical) return message;
  return '$message\n${l10n.errTechnicalDetail(_technicalText(error))}';
}

String _technicalText(Object error) {
  if (error is PostgrestException) {
    return [error.code, error.message, error.details, error.hint]
        .where((p) => p != null && '$p'.isNotEmpty)
        .join(' · ');
  }
  if (error is StorageException) return '${error.statusCode ?? ''} ${error.message}'.trim();
  if (error is ApiException) {
    return '${error.status} ${error.code ?? ''} ${error.detail ?? error.message}'.trim();
  }
  return error.toString();
}
