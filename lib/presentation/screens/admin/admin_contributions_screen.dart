import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/contribution.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/adaptive_card_list.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_snackbar.dart';
import 'admin_shell.dart';

class AdminContributionsScreen extends ConsumerStatefulWidget {
  const AdminContributionsScreen({super.key});

  @override
  ConsumerState<AdminContributionsScreen> createState() =>
      _AdminContributionsScreenState();
}

class _AdminContributionsScreenState extends ConsumerState<AdminContributionsScreen> {
  String? _statusFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contributionsAsync = ref.watch(adminContributionsProvider(_statusFilter));

    return AdminShell(
      selectedIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminModeration, style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.s),
                Text(l10n.adminModerationSubtitle, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.m),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: l10n.statusPending,
                        selected: _statusFilter == 'pending',
                        onSelected: () => setState(() => _statusFilter = 'pending'),
                      ),
                      _FilterChip(
                        label: l10n.statusApproved,
                        selected: _statusFilter == 'approved',
                        onSelected: () => setState(() => _statusFilter = 'approved'),
                      ),
                      _FilterChip(
                        label: l10n.statusRejected,
                        selected: _statusFilter == 'rejected',
                        onSelected: () => setState(() => _statusFilter = 'rejected'),
                      ),
                      _FilterChip(
                        label: l10n.filterAll,
                        selected: _statusFilter == null,
                        onSelected: () => setState(() => _statusFilter = null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminContributionsProvider(_statusFilter)),
              child: contributionsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: AppEmptyState(
                            title: l10n.adminNoContributions,
                            message: l10n.adminNoContributionsMessage,
                            imagePath: null,
                          ),
                        ),
                      ],
                    );
                  }
                  return AdaptiveCardList(
                    itemCount: items.length,
                    maxColumns: 2,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ContributionCard(
                        contribution: item,
                        onApprove: () => _review(item, 'approved'),
                        onReject: () => _review(item, 'rejected'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: AppLoader()),
                error: (e, _) => AppEmptyState(
                  title: l10n.errorGeneric,
                  message: e.toString(),
                  imagePath: null,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(adminContributionsProvider(_statusFilter)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _review(Contribution contribution, String status) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'approved' ? l10n.approveContribution : l10n.rejectContribution),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: l10n.reviewerNote,
            hintText: l10n.reviewerNoteHint,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(status == 'approved' ? l10n.approve : l10n.reject),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(adminRepositoryProvider).reviewContribution(
            contributionId: contribution.id,
            status: status,
            reviewerId: user.id,
            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
          );
      ref.invalidate(adminContributionsProvider(_statusFilter));
      ref.invalidate(adminStatsProvider);
      ref.invalidate(adminSignsProvider(const AdminSignsFilter()));
      if (mounted) {
        AppSnackbar.show(
          context,
          message: status == 'approved' ? l10n.contributionApproved : l10n.contributionRejected,
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: '${l10n.errorGeneric}: $e', type: AppSnackbarType.error);
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final Contribution contribution;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ContributionCard({
    required this.contribution,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = switch (contribution.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final statusLabel = switch (contribution.status) {
      'approved' => l10n.statusApproved,
      'rejected' => l10n.statusRejected,
      _ => l10n.statusPending,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(contribution.word, style: AppTextStyles.h3),
              ),
              AppBadge(label: statusLabel, color: statusColor),
            ],
          ),
          if (contribution.description != null && contribution.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text(contribution.description!, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.s),
          Text(
            contribution.submittedAt != null
                ? l10n.submittedAt(_formatDate(contribution.submittedAt!))
                : l10n.submittedAtUnknown,
            style: AppTextStyles.bodySmall,
          ),
          if (contribution.reviewerNote != null && contribution.reviewerNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text('${l10n.reviewerNote}: ${contribution.reviewerNote}', style: AppTextStyles.bodySmall),
          ],
          if (contribution.status == 'pending') ...[
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(l10n.reject),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.approve),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
