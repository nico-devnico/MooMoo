import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/contribution.dart';
import '../../../domain/providers/app_settings_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/contribution_provider.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/skeletons.dart';
import '../../../domain/providers/error_text.dart';

class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({super.key});

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _wordController.dispose();
    _descriptionController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      AppSnackbar.show(context, message: l10n.loginToSave, type: AppSnackbarType.error);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final description = _descriptionController.text.trim();
      final contribution = Contribution(
        id: const Uuid().v4(),
        contributorId: user.id,
        signLanguageId: ref.read(learningLanguageProvider).value?.id,
        word: _wordController.text.trim(),
        description: description.isEmpty ? null : description,
        videoUrl: _videoController.text.trim(),
        status: 'pending',
        submittedAt: DateTime.now(),
      );
      await ref.read(contributionRepositoryProvider).submitContribution(contribution);
      if (!mounted) return;
      _formKey.currentState?.reset();
      _wordController.clear();
      _descriptionController.clear();
      _videoController.clear();
      ref.invalidate(myContributionsProvider);
      AppSnackbar.show(context, message: l10n.contributionSubmitted, type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: ref.userErrorText(e, l10n), type: AppSnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateRequired(String? value, AppLocalizations l10n) {
    return (value ?? '').trim().isEmpty ? l10n.requiredField : null;
  }

  String? _validateUrl(String? value, AppLocalizations l10n) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return l10n.requiredField;
    final uri = Uri.tryParse(text);
    final valid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : l10n.dictInvalidUrl;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(learningLanguageProvider).value;
    final secondary = AppColors.textSecondary(context);
    final contributionsOpen =
        ref.watch(appSettingsProvider).value?.contributionsEnabled ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myContributions),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(AppIcons.back),
                tooltip: l10n.back,
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myContributionsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: AppSpacing.l, bottom: AppSpacing.xxxl),
            child: PageContainer(
              width: ContentWidth.reading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.contributeFormTitle, style: AppTextStyles.h2),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    l10n.contributeFormSubtitle,
                    style: AppTextStyles.bodyMedium.copyWith(color: secondary),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  if (!contributionsOpen)
                    AppPanel(
                      child: Row(
                        children: [
                          Icon(AppIcons.info, color: secondary),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Text(
                              l10n.contributionsClosed,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                  AppPanel(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (language != null) ...[
                            Row(
                              children: [
                                Icon(AppIcons.language, size: 18, color: secondary),
                                const SizedBox(width: AppSpacing.s),
                                Expanded(
                                  child: Text(
                                    l10n.dictLanguage(language.name),
                                    style: AppTextStyles.bodySmall.copyWith(color: secondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.l),
                          ],
                          AppTextField(
                            controller: _wordController,
                            label: l10n.signWord,
                            hintText: l10n.signWordHint,
                            validator: (v) => _validateRequired(v, l10n),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          AppTextField(
                            controller: _descriptionController,
                            label: l10n.signDescription,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          AppTextField(
                            controller: _videoController,
                            label: l10n.signVideoUrl,
                            hintText: l10n.dictVideoUrlHint,
                            prefixIcon: AppIcons.video,
                            keyboardType: TextInputType.url,
                            validator: (v) => _validateUrl(v, l10n),
                          ),
                          const SizedBox(height: AppSpacing.l),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AppButton(
                              label: l10n.submitContribution,
                              icon: AppIcons.upload,
                              isLoading: _submitting,
                              onPressed: _submitting ? null : _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Semantics(
                    header: true,
                    child: Text(l10n.mySubmissions, style: AppTextStyles.h3),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  const _SubmissionList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmissionList extends ConsumerWidget {
  const _SubmissionList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contributionsAsync = ref.watch(myContributionsProvider);

    return contributionsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return AppEmptyState(
            icon: AppIcons.upload,
            title: l10n.noContributionsYet,
            message: l10n.noContributionsYetMessage,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.m),
                child: _SubmissionTile(contribution: c),
              ),
          ],
        );
      },
      loading: () => Skeleton(
        label: l10n.loading,
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.m),
                child: _SubmissionTileSkeleton(),
              ),
          ],
        ),
      ),
      error: (e, _) => AppEmptyState(
        icon: AppIcons.error,
        title: l10n.errorGeneric,
        message: ref.userErrorText(e, l10n),
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(myContributionsProvider),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.contribution});

  final Contribution contribution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = contribution;
    final secondary = AppColors.textSecondary(context);

    final (label, icon, color, background) = switch (c.status) {
      'approved' => (l10n.statusApproved, AppIcons.success, AppColors.successLedge, AppColors.successSoft),
      'rejected' => (l10n.statusRejected, AppIcons.blocked, AppColors.error, AppColors.errorSoft),
      _ => (l10n.statusPending, AppIcons.history, AppColors.warningLedge, AppColors.warningSoft),
    };

    final submittedAt = c.submittedAt;
    final date = submittedAt == null
        ? null
        : DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(submittedAt.toLocal());
    final note = c.reviewerNote?.trim();

    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Semantics(
        container: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.word,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (c.description != null && c.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      c.description!,
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (date != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.dictSubmittedOn(date),
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                    ),
                  ],
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(
                        color: AppColors.neutral(context),
                        borderRadius: AppRadius.radiusS,
                      ),
                      child: Text(
                        '${l10n.reviewerNote} : $note',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadius.radiusCircular,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
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

class _SubmissionTileSkeleton extends StatelessWidget {
  const _SubmissionTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: AppRadius.radiusL,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 140, height: 16),
                SizedBox(height: AppSpacing.s),
                SkeletonBlock(height: 12),
                SizedBox(height: AppSpacing.s),
                SkeletonBlock(width: 110, height: 12),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.m),
          SkeletonBlock(width: 92, height: 28, radius: AppRadius.circular),
        ],
      ),
    );
  }
}
