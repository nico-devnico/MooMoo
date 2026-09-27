import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_card.dart';
import 'admin_shell.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(adminStatsProvider);

    return AdminShell(
      selectedIndex: 5,
      child: PageContainer(
        width: ContentWidth.reading,
        verticalPadding: AppSpacing.l,
        child: ListView(
        children: [
          Text(l10n.adminSettings, style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.s),
          Text(l10n.adminSettingsSubtitle, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminPlatformInfo, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.m),
                _InfoRow(label: l10n.version, value: '1.0.0'),
                _InfoRow(label: l10n.adminBackend, value: 'Supabase'),
                statsAsync.when(
                  data: (s) => _InfoRow(
                    label: l10n.adminStatUsers,
                    value: s.usersCount.toString(),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary.withValues(alpha: 0.9)),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        l10n.adminRlsNoteTitle,
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Text(l10n.adminRlsNoteBody, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminHowToGrant, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.s),
                Text(l10n.adminHowToGrantBody, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
