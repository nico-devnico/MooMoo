import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/user_error.dart';
import '../../l10n/app_localizations.dart';
import 'admin_provider.dart';

extension UserErrorText on WidgetRef {
  /// User-level message for [error]; administrators also get the technical
  /// detail to diagnose it.
  String userErrorText(Object error, AppLocalizations l10n, {String? fallback}) {
    return userErrorMessage(
      error,
      l10n,
      fallback: fallback,
      technical: read(isAdminProvider),
    );
  }
}
