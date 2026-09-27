import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// A flat surface separated from the background by a hairline border instead
/// of a shadow. Panels sit next to each other with spacing, never on top of
/// one another.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.l),
    this.color,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.radiusL,
      side: BorderSide(color: borderColor ?? AppColors.border(context)),
    );

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        customBorder: shape,
        child: content,
      );
    }

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: color ?? AppColors.surface(context),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
