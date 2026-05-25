import 'package:flutter/material.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
      title: Text(title),
      content: Text(content),
      actionsPadding: const EdgeInsets.all(AppSpacing.m),
      actions: [
        if (cancelLabel != null)
          AppButton(
            label: cancelLabel!,
            onPressed: onCancel ?? () => Navigator.pop(context),
            variant: AppButtonVariant.ghost,
            fullWidth: false,
          ),
        if (confirmLabel != null)
          AppButton(
            label: confirmLabel!,
            onPressed: onConfirm,
            variant: isDestructive ? AppButtonVariant.primary : AppButtonVariant.primary,
            fullWidth: false,
          ),
      ],
    );
  }
}
