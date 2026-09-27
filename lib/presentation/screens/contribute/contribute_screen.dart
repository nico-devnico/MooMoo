import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/contribution.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/contribution_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';

class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({super.key});

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
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

    final word = _wordController.text.trim();
    final video = _videoController.text.trim();
    if (word.isEmpty || video.isEmpty) {
      AppSnackbar.show(context, message: l10n.requiredField, type: AppSnackbarType.error);
      return;
    }

    setState(() => _submitting = true);
    try {
      final contribution = Contribution(
        id: const Uuid().v4(),
        contributorId: user.id,
        word: word,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        videoUrl: video,
        status: 'pending',
        submittedAt: DateTime.now(),
      );
      await ref.read(contributionRepositoryProvider).submitContribution(contribution);
      _wordController.clear();
      _descriptionController.clear();
      _videoController.clear();
      ref.invalidate(myContributionsProvider);
      if (mounted) {
        AppSnackbar.show(context, message: l10n.contributionSubmitted, type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: '${l10n.errorGeneric}: $e', type: AppSnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contributionsAsync = ref.watch(myContributionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myContributions)),
      body: PageContainer(
        width: ContentWidth.reading,
        verticalPadding: AppSpacing.l,
        child: ListView(
            children: [
              Text(l10n.contributeFormTitle, style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.s),
              Text(l10n.contributeFormSubtitle, style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.l),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _wordController,
                      label: l10n.signWord,
                      hintText: l10n.signWordHint,
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
                      hintText: 'https://...',
                    ),
                    const SizedBox(height: AppSpacing.l),
                    AppButton(
                      label: l10n.submitContribution,
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.mySubmissions, style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.m),
              contributionsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return AppEmptyState(
                      title: l10n.noContributionsYet,
                      message: l10n.noContributionsYetMessage,
                      imagePath: null,
                    );
                  }
                  return Column(
                    children: items.map((c) {
                      final color = switch (c.status) {
                        'approved' => AppColors.success,
                        'rejected' => AppColors.error,
                        _ => AppColors.warning,
                      };
                      final label = switch (c.status) {
                        'approved' => l10n.statusApproved,
                        'rejected' => l10n.statusRejected,
                        _ => l10n.statusPending,
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.m),
                        child: AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.word, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                    if (c.description != null)
                                      Text(c.description!, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              AppBadge(label: label, color: color),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: AppLoader()),
                error: (e, _) => Text('${l10n.errorGeneric}: $e'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.back),
              ),
            ],
        ),
      ),
    );
  }
}
