import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/sign.dart';
import '../../../domain/learning/lesson_builder.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/skeletons.dart';
import '../learning/widgets/practice_view.dart';

/// Standalone practice for one dictionary sign: camera check + XP on success.
class SignPracticeScreen extends ConsumerStatefulWidget {
  const SignPracticeScreen({super.key, required this.signId});

  final String signId;

  @override
  ConsumerState<SignPracticeScreen> createState() => _SignPracticeScreenState();
}

class _SignPracticeScreenState extends ConsumerState<SignPracticeScreen> {
  int? _lastXp;
  bool _awarding = false;

  Future<void> _onResult(Sign sign, bool success) async {
    if (_awarding) return;
    _awarding = true;
    try {
      final result = await ref.read(learningRepositoryProvider).awardSignPracticeXp(
            signId: sign.id,
            success: success,
          );
      if (!mounted) return;
      setState(() => _lastXp = result.xpEarned);
      ref.invalidate(learnerSummaryProvider);
      if (success && result.xpEarned > 0) {
        AppSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.practiceXpEarned(result.xpEarned),
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Practice UI still works offline / before migration is applied.
      if (success) {
        AppSnackbar.show(
          context,
          message: AppLocalizations.of(context)!.practiceSuccessNoXp,
          type: AppSnackbarType.info,
        );
      }
    } finally {
      _awarding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(signDetailProvider(widget.signId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dictPractice)),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.l),
          child: Skeleton(child: SkeletonBlock(height: 320)),
        ),
        error: (e, _) => Center(child: Text(l10n.errorGeneric)),
        data: (sign) {
          if (sign == null) {
            return Center(child: Text(l10n.errorGeneric));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.m,
                  AppSpacing.l,
                  AppSpacing.s,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sign.word, style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.practiceSignHint(sign.word),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    if (_lastXp != null && _lastXp! > 0) ...[
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        l10n.practiceXpEarned(_lastXp!),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: PracticeView(
                  step: PracticeStep(sign, number: 1, total: 1),
                  onResult: (ok) => _onResult(sign, ok),
                  onReset: () => setState(() => _lastXp = null),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
