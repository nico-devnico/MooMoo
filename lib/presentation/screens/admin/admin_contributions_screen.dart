import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/contribution.dart';
import '../../../data/models/sign.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/workspace_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/sign_media.dart';
import '../../widgets/skeletons.dart';
import 'admin_shell.dart';
import '../../../domain/providers/error_text.dart';

const double _listMaxWidth = 820;
const double _thumbSize = 88;

class AdminContributionsScreen extends ConsumerStatefulWidget {
  const AdminContributionsScreen({super.key, this.workspace = Workspace.admin});

  final Workspace workspace;

  @override
  ConsumerState<AdminContributionsScreen> createState() =>
      _AdminContributionsScreenState();
}

class _AdminContributionsScreenState
    extends ConsumerState<AdminContributionsScreen> {
  String? _statusFilter = 'pending';
  final Set<String> _busyIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contributionsAsync = ref.watch(
      adminContributionsProvider(_statusFilter),
    );

    final filters = [
      ('pending', l10n.statusPending),
      ('approved', l10n.statusApproved),
      ('rejected', l10n.statusRejected),
      (null, l10n.filterAll),
    ];

    return AdminShell(
      workspace: widget.workspace,
      selectedIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.m,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.adminModeration,
                        style: AppTextStyles.h2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      l10n.adminModerationSubtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        for (final f in filters)
                          ChoiceChip(
                            label: Text(f.$2),
                            selected: _statusFilter == f.$1,
                            onSelected: (_) =>
                                setState(() => _statusFilter = f.$1),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(adminContributionsProvider(_statusFilter).future),
              child: contributionsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.l),
                      children: [
                        AppEmptyState(
                          icon: AppIcons.moderation,
                          title: l10n.adminNoContributions,
                          message: l10n.adminNoContributionsMessage,
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.s,
                      AppSpacing.l,
                      AppSpacing.xxl,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.m),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _listMaxWidth,
                          ),
                          child: _ContributionTile(
                            contribution: item,
                            busy: _busyIds.contains(item.id),
                            onPreview: () => _preview(item),
                            onApprove: () => _review(item, 'approved'),
                            onReject: () => _review(item, 'rejected'),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.s,
                    AppSpacing.l,
                    AppSpacing.l,
                  ),
                  children: [_ContributionsSkeleton(label: l10n.loading)],
                ),
                error: (e, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.l),
                  children: [
                    AppEmptyState(
                      icon: AppIcons.error,
                      title: l10n.errorGeneric,
                      message: ref.userErrorText(e, l10n),
                      actionLabel: l10n.retry,
                      onAction: () => ref.invalidate(
                        adminContributionsProvider(_statusFilter),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _preview(Contribution contribution) {
    return showDialog<void>(
      context: context,
      builder: (context) => _MediaPreviewDialog(contribution: contribution),
    );
  }

  Future<void> _review(Contribution contribution, String status) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final note = await showDialog<String>(
      context: context,
      builder: (context) => _ReviewDialog(approve: status == 'approved'),
    );
    // null : dialogue annulé ; chaîne vide : validé sans commentaire.
    if (note == null || !mounted) return;

    setState(() => _busyIds.add(contribution.id));
    try {
      await ref
          .read(adminRepositoryProvider)
          .reviewContribution(
            contributionId: contribution.id,
            status: status,
            reviewerId: user.id,
            note: note.isEmpty ? null : note,
          );
      ref
        ..invalidate(adminContributionsProvider)
        ..invalidate(adminStatsProvider)
        ..invalidate(adminSignsProvider)
        ..invalidate(expertOverviewProvider);
      if (mounted) {
        AppSnackbar.show(
          context,
          message: status == 'approved'
              ? l10n.contributionApproved
              : l10n.contributionRejected,
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: ref.userErrorText(e, l10n),
          type: AppSnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(contribution.id));
    }
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.approve});

  final bool approve;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _noteController.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        widget.approve ? l10n.approveContribution : l10n.rejectContribution,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 360, maxWidth: 480),
        child: TextField(
          controller: _noteController,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.reviewerNote,
            hintText: l10n.reviewerNoteHint,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          style: widget.approve
              ? null
              : FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(widget.approve ? l10n.approve : l10n.reject),
        ),
      ],
    );
  }
}

class _MediaPreviewDialog extends StatelessWidget {
  const _MediaPreviewDialog({required this.contribution});

  final Contribution contribution;

  @override
  Widget build(BuildContext context) {
    final sign = Sign(
      id: contribution.id,
      word: contribution.word,
      signLanguageId: contribution.signLanguageId,
      description: contribution.description,
      videoUrl: contribution.videoUrl.isEmpty ? null : contribution.videoUrl,
      thumbnailUrl: contribution.thumbnailUrl,
      landmarkData: contribution.landmarkData,
    );

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(contribution.word, style: AppTextStyles.h3),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    constraints: const BoxConstraints(
                      minWidth: kMinTouchTarget,
                      minHeight: kMinTouchTarget,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(AppIcons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              SizedBox(height: 360, child: SignMedia(sign: sign)),
              if (contribution.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: AppSpacing.m),
                Text(
                  contribution.description!,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.s),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    MaterialLocalizations.of(context).closeButtonLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  const _ContributionTile({
    required this.contribution,
    required this.busy,
    required this.onPreview,
    required this.onApprove,
    required this.onReject,
  });

  final Contribution contribution;
  final bool busy;
  final VoidCallback onPreview;
  final VoidCallback onApprove;
  final VoidCallback onReject;

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
    final secondary = AppColors.textSecondary(context);

    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(
                url: contribution.thumbnailUrl,
                tooltip: l10n.admxViewMedia,
                onTap: onPreview,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          contribution.word,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AppBadge(label: statusLabel, color: statusColor),
                      ],
                    ),
                    if (contribution.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        contribution.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      contribution.submittedAt != null
                          ? l10n.submittedAt(
                              _formatDate(contribution.submittedAt!),
                            )
                          : l10n.submittedAtUnknown,
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                    ),
                    if (contribution.reviewerNote?.isNotEmpty ?? false) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${l10n.reviewerNote} : ${contribution.reviewerNote}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              TextButton.icon(
                onPressed: onPreview,
                icon: const Icon(AppIcons.play, size: 18),
                label: Text(l10n.admxViewMedia),
              ),
              if (contribution.status == 'pending') ...[
                OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(AppIcons.close, size: 18),
                  label: Text(l10n.reject),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(0, kMinTouchTarget),
                  ),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : onApprove,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.check, size: 18),
                  label: Text(l10n.approve),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, kMinTouchTarget),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.url,
    required this.tooltip,
    required this.onTap,
  });

  final String? url;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(
        AppIcons.video,
        color: AppColors.textSecondary(context),
        size: 28,
      ),
    );

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: AppColors.neutral(context),
          borderRadius: AppRadius.radiusM,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: _thumbSize,
              child: url == null
                  ? placeholder
                  : CachedNetworkImage(
                      imageUrl: url!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const SizedBox.shrink(),
                      errorWidget: (_, _, _) => placeholder,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reprend la forme de [_ContributionTile] : vignette, texte, rangée d'actions.
class _ContributionsSkeleton extends StatelessWidget {
  const _ContributionsSkeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _listMaxWidth),
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.m),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: AppRadius.radiusL,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBlock(
                            width: _thumbSize,
                            height: _thumbSize,
                            radius: AppRadius.m,
                          ),
                          SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.s,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    SkeletonBlock(width: 120, height: 18),
                                    SkeletonBlock(
                                      width: 80,
                                      height: 26,
                                      radius: AppRadius.circular,
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.s),
                                SkeletonParagraph(lines: 2),
                                SizedBox(height: AppSpacing.s),
                                SkeletonBlock(width: 140, height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.m),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.s,
                        children: [
                          SkeletonBlock(
                            width: 120,
                            height: 40,
                            radius: AppRadius.circular,
                          ),
                          SkeletonBlock(
                            width: 104,
                            height: 40,
                            radius: AppRadius.circular,
                          ),
                          SkeletonBlock(
                            width: 116,
                            height: 40,
                            radius: AppRadius.circular,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
