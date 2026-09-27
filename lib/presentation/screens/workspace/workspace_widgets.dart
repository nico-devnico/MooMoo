import 'package:flutter/material.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_panel.dart';

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(title, style: AppTextStyles.h2)),
              const SizedBox(height: AppSpacing.s),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        IconButton(
          tooltip: l10n.admxRefresh,
          constraints: const BoxConstraints(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget),
          onPressed: onRefresh,
          icon: const Icon(AppIcons.refresh),
        ),
      ],
    );
  }
}

class WorkspaceStatCard extends StatelessWidget {
  const WorkspaceStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      semanticLabel: '$label : $value',
      padding: const EdgeInsets.all(AppSpacing.m),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusM,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, maxLines: 1, style: AppTextStyles.h2.copyWith(height: 1.1)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive grid of stat cards (1 to 4 columns).
class WorkspaceStatGrid extends StatelessWidget {
  const WorkspaceStatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 230).floor().clamp(1, 4);
        final width = (constraints.maxWidth - AppSpacing.m * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.m,
          children: [for (final c in children) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}
