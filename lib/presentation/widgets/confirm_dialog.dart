import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Asks a yes/no question and resolves to `true` only on explicit confirmation.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(message),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}
