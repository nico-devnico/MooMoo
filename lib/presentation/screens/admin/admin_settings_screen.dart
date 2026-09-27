import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../domain/providers/ml_model_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/skeletons.dart';
import 'admin_shell.dart';
import 'general_settings_panel.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(adminStatsProvider);
    final activeModelAsync = ref.watch(activeMlModelProvider);
    const unavailable = '—';

    return AdminShell(
      selectedIndex: 6,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.l,
          AppSpacing.l,
          AppSpacing.xxl,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.adminSettings, style: AppTextStyles.h2),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    l10n.adminSettingsSubtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const GeneralSettingsPanel(),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingsPanel(
                    icon: AppIcons.database,
                    title: l10n.adminPlatformInfo,
                    child: Column(
                      children: [
                        _InfoRow(label: l10n.adminBackend, value: 'Supabase'),
                        _InfoRow(
                          label: l10n.admxApiUrl,
                          value: ApiConfig.baseUrl,
                        ),
                        _AsyncInfoRow(
                          label: l10n.admxActiveModel,
                          value: activeModelAsync.whenData(
                            (m) => m?.displayLabel ?? l10n.admxNoActiveModel,
                          ),
                          fallback: unavailable,
                        ),
                        _AsyncInfoRow(
                          label: l10n.adminStatUsers,
                          value: statsAsync.whenData((s) => '${s.usersCount}'),
                          fallback: unavailable,
                        ),
                        _AsyncInfoRow(
                          label: l10n.adminStatSigns,
                          value: statsAsync.whenData((s) => '${s.signsCount}'),
                          fallback: unavailable,
                        ),
                        _AsyncInfoRow(
                          label: l10n.adminStatPending,
                          value: statsAsync.whenData(
                            (s) => '${s.pendingContributionsCount}',
                          ),
                          fallback: unavailable,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _SettingsPanel(
                    icon: AppIcons.admin,
                    title: l10n.adminRlsNoteTitle,
                    child: Text(
                      l10n.adminRlsNoteBody,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _SettingsPanel(
                    icon: AppIcons.roles,
                    title: l10n.adminHowToGrant,
                    child: Text(
                      l10n.adminHowToGrantBody,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusM,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return _RowFrame(
      label: label,
      last: last,
      value: SelectableText(
        value,
        textAlign: TextAlign.end,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AsyncInfoRow extends StatelessWidget {
  const _AsyncInfoRow({
    required this.label,
    required this.value,
    required this.fallback,
    this.last = false,
  });

  final String label;
  final AsyncValue<String> value;
  final String fallback;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (v) => _InfoRow(label: label, value: v, last: last),
      error: (_, _) => _InfoRow(label: label, value: fallback, last: last),
      loading: () => _RowFrame(
        label: label,
        last: last,
        value: const Skeleton(
          child: Align(
            alignment: Alignment.centerRight,
            child: SkeletonBlock(width: 72, height: 14),
          ),
        ),
      ),
    );
  }
}

class _RowFrame extends StatelessWidget {
  const _RowFrame({
    required this.label,
    required this.value,
    required this.last,
  });

  final String label;
  final Widget value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s + 4),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Flexible(child: value),
        ],
      ),
    );
  }
}
