import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/learning.dart';
import '../../../data/models/sign_language.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/skeletons.dart';
import 'widgets/learning_widgets.dart';

/// Width of the lesson path column. Wide enough for the zig-zag to read as a
/// path, narrow enough that the eye follows it without scanning sideways.
const double _pathWidth = 560;
const double _sidebarWidth = 320;

class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageAsync = ref.watch(learningLanguageProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: languageAsync.when(
          data: (language) => language == null
              ? AppEmptyState(
                  icon: AppIcons.learning,
                  title: l10n.learnNoCourseTitle,
                  message: l10n.learnNoCourseMessage,
                )
              : _LearningBody(language: language),
          loading: () => const _LearningSkeleton(),
          error: (error, _) => AppEmptyState(
            icon: AppIcons.error,
            title: l10n.errorGeneric,
            message: error.toString(),
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(learningLanguageProvider),
          ),
        ),
      ),
    );
  }
}

class _LearningBody extends ConsumerWidget {
  const _LearningBody({required this.language});

  final SignLanguage language;

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(learningPathProvider(language.id))
      ..invalidate(learningProgressProvider)
      ..invalidate(learnerSummaryProvider);
    await ref.read(learningPathProvider(language.id).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = context.hasSideNavigation;
    final summary = ref.watch(learnerSummaryProvider).value ?? const LearnerSummary();
    final canEdit = ref.watch(canEditLearningProvider).value ?? false;

    final header = _CourseHeader(
      language: language,
      summary: summary,
      showStats: !isWide,
    );
    final path = _LessonPath(language: language, canEdit: canEdit);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: AppSpacing.l,
          bottom: AppSpacing.xxxl + AppSpacing.xl,
        ),
        child: PageContainer(
          width: isWide ? ContentWidth.dashboard : ContentWidth.reading,
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: _pathWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              header,
                              const SizedBox(height: AppSpacing.xl),
                              path,
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                    SizedBox(
                      width: _sidebarWidth,
                      child: _Sidebar(summary: summary, canEdit: canEdit),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: AppSpacing.l),
                    DailyGoalCard(
                      summary: summary,
                      onTap: () => context.pushNamed(AppRoutes.progressName),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    path,
                    if (canEdit) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: AppButton(
                          label: AppLocalizations.of(context)!.learnManagePath,
                          icon: AppIcons.edit,
                          variant: AppButtonVariant.outline,
                          fullWidth: false,
                          onPressed: () => context.pushNamed(AppRoutes.learningManageName),
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

class _CourseHeader extends ConsumerWidget {
  const _CourseHeader({
    required this.language,
    required this.summary,
    required this.showStats,
  });

  final SignLanguage language;
  final LearnerSummary summary;
  final bool showStats;

  Future<void> _changeLanguage(BuildContext context, WidgetRef ref, SignLanguage next) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null || next.id == language.id) return;
    try {
      await ref.read(learningRepositoryProvider).setLearningLanguage(userId, next.code);
      ref.invalidate(userProfileProvider);
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.showError(context, AppLocalizations.of(context)!.errorGeneric);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languages = ref.watch(signLanguagesProvider).value ?? const <SignLanguage>[];

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.learning,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          header: true,
          child: Text(
            l10n.learnCourseTitle(language.code),
            style: AppTextStyles.h2,
          ),
        ),
      ],
    );

    final switcher = languages.length < 2
        ? null
        : PopupMenuButton<SignLanguage>(
            tooltip: l10n.learnChangeCourse,
            onSelected: (next) => _changeLanguage(context, ref, next),
            itemBuilder: (context) => [
              for (final l in languages)
                CheckedPopupMenuItem(
                  value: l,
                  checked: l.id == language.id,
                  child: Text('${l.code} · ${l.name}'),
                ),
            ],
            child: Container(
              constraints: const BoxConstraints(minHeight: kMinTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusCircular,
                border: Border.all(color: AppColors.border(context)),
                color: AppColors.surface(context),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.language, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    language.code,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary(context)),
                ],
              ),
            ),
          );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.m,
      children: [
        title,
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ?switcher,
            if (showStats) ...[
              StreakPill(summary: summary),
              XpPill(summary: summary),
            ],
          ],
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.summary, required this.canEdit});

  final LearnerSummary summary;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            StreakPill(summary: summary),
            const SizedBox(width: AppSpacing.s),
            XpPill(summary: summary),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        DailyGoalCard(summary: summary),
        const SizedBox(height: AppSpacing.m),
        _SidebarLink(
          icon: AppIcons.progress,
          label: l10n.learnViewProgress,
          onTap: () => context.pushNamed(AppRoutes.progressName),
        ),
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.m),
          _SidebarLink(
            icon: AppIcons.edit,
            label: l10n.learnManagePath,
            onTap: () => context.pushNamed(AppRoutes.learningManageName),
          ),
        ],
      ],
    );
  }
}

class _SidebarLink extends StatelessWidget {
  const _SidebarLink({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      onTap: onTap,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(AppIcons.chevron, size: 18, color: AppColors.textSecondary(context)),
        ],
      ),
    );
  }
}

class _LessonPath extends ConsumerWidget {
  const _LessonPath({required this.language, required this.canEdit});

  final SignLanguage language;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pathAsync = ref.watch(learningPathProvider(language.id));
    final progressAsync = ref.watch(learningProgressProvider);

    if (pathAsync.hasError) {
      return AppEmptyState(
        icon: AppIcons.error,
        title: l10n.errorGeneric,
        message: pathAsync.error.toString(),
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(learningPathProvider(language.id)),
      );
    }

    final units = pathAsync.value;
    final progress = progressAsync.value;
    if (units == null || (progress == null && !progressAsync.hasError)) {
      return const _PathSkeleton();
    }

    if (units.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.learning,
        title: l10n.learnNoCourseTitle,
        message: canEdit ? l10n.learnNoCourseEditorMessage : l10n.learnNoCourseMessage,
        actionLabel: canEdit ? l10n.learnManagePath : l10n.learnOpenDictionary,
        onAction: () => canEdit
            ? context.pushNamed(AppRoutes.learningManageName)
            : context.goNamed(AppRoutes.dictionaryName),
      );
    }

    final lessonProgress = progress ?? const <String, LessonProgress>{};
    final states = resolveLessonStates(units, lessonProgress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < units.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xxl),
          _UnitBanner(unit: units[i], number: i + 1),
          const SizedBox(height: AppSpacing.xl),
          for (var j = 0; j < units[i].lessons.length; j++)
            _PathNodeRow(
              index: j,
              child: _LessonNode(
                lesson: units[i].lessons[j],
                state: states[units[i].lessons[j].id]!,
                progress: lessonProgress[units[i].lessons[j].id],
              ),
            ),
        ],
      ],
    );
  }
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({required this.unit, required this.number});

  final LearningUnit unit;
  final int number;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      header: true,
      label: '${l10n.learnUnitLabel(number)}, ${unit.title}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.radiusL,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.learnUnitLabel(number).toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    unit.title,
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                  ),
                  if (unit.description != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      unit.description!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.fromName(unit.iconName, fallback: AppIcons.lesson),
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal offsets of consecutive nodes, as a fraction of the half-width.
/// Repeats every eight lessons, which draws the gentle S-curve of the path.
const List<double> _zigzag = [0, 0.4, 0.62, 0.4, 0, -0.4, -0.62, -0.4];

class _PathNodeRow extends StatelessWidget {
  const _PathNodeRow({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Align(
        alignment: Alignment(_zigzag[index % _zigzag.length], 0),
        child: child,
      ),
    );
  }
}

class _NodeStyle {
  const _NodeStyle({
    required this.fill,
    required this.ledge,
    required this.iconColor,
    required this.icon,
    this.border,
  });

  final Color fill;
  final Color ledge;
  final Color iconColor;
  final IconData icon;
  final Color? border;
}

class _LessonNode extends StatelessWidget {
  const _LessonNode({required this.lesson, required this.state, this.progress});

  final LearningLesson lesson;
  final LessonState state;
  final LessonProgress? progress;

  static const double _size = 76;
  static const double _ledge = 6;

  _NodeStyle _style(BuildContext context) {
    final perfect = progress?.isPerfect ?? false;
    switch (state) {
      case LessonState.completed:
        return perfect
            ? const _NodeStyle(
                fill: AppColors.warning,
                ledge: AppColors.warningLedge,
                iconColor: Colors.white,
                icon: AppIcons.pointsActive,
              )
            : const _NodeStyle(
                fill: AppColors.success,
                ledge: AppColors.successLedge,
                iconColor: Colors.white,
                icon: AppIcons.checkBold,
              );
      case LessonState.current:
        return const _NodeStyle(
          fill: AppColors.primary,
          ledge: AppColors.primaryLedge,
          iconColor: Colors.white,
          icon: AppIcons.play,
        );
      case LessonState.locked:
        return _NodeStyle(
          fill: AppColors.neutral(context),
          ledge: AppColors.border(context),
          iconColor: AppColors.textSecondary(context),
          icon: AppIcons.locked,
        );
      case LessonState.empty:
        return _NodeStyle(
          fill: AppColors.surface(context),
          ledge: AppColors.border(context),
          iconColor: AppColors.textSecondary(context),
          icon: AppIcons.fromName('time'),
          border: AppColors.border(context),
        );
    }
  }

  String _stateLabel(AppLocalizations l10n) {
    switch (state) {
      case LessonState.completed:
        return (progress?.isPerfect ?? false) ? l10n.learnStatePerfect : l10n.learnStateCompleted;
      case LessonState.current:
        return l10n.learnStateCurrent;
      case LessonState.locked:
        return l10n.learnStateLocked;
      case LessonState.empty:
        return l10n.learnLessonEmpty;
    }
  }

  void _onTap(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (state) {
      case LessonState.locked:
        AppSnackbar.showInfo(context, l10n.learnLessonLocked);
      case LessonState.empty:
        AppSnackbar.showInfo(context, l10n.learnLessonEmpty);
      case LessonState.completed:
      case LessonState.current:
        _showLessonSheet(context, lesson, state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = _style(context);
    final isCurrent = state == LessonState.current;
    final stateLabel = _stateLabel(l10n);

    return Semantics(
      button: true,
      label: '${lesson.title}, $stateLabel, ${l10n.learnLessonSigns(lesson.signCount)}',
      excludeSemantics: true,
      child: SizedBox(
        width: 160,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _onTap(context),
                child: Container(
                  width: _size,
                  height: _size + _ledge,
                  alignment: Alignment.topCenter,
                  decoration: BoxDecoration(
                    color: style.ledge,
                    borderRadius: BorderRadius.circular(_size),
                  ),
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      color: style.fill,
                      shape: BoxShape.circle,
                      border: style.border == null
                          ? null
                          : Border.all(color: style.border!, width: 2),
                    ),
                    child: Icon(style.icon, color: style.iconColor, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              lesson.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: state == LessonState.locked || state == LessonState.empty
                    ? AppColors.textSecondary(context)
                    : null,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                stateLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lesson summary with the start button: a bottom sheet on phones, a dialog on
/// larger screens where a sheet would stretch across the whole window.
void _showLessonSheet(BuildContext context, LearningLesson lesson, LessonState state) {
  final content = _LessonSummary(lesson: lesson, state: state);

  if (context.hasTopNavigation) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(padding: const EdgeInsets.all(AppSpacing.l), child: content),
        ),
      ),
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
      child: content,
    ),
  );
}

class _LessonSummary extends StatelessWidget {
  const _LessonSummary({required this.lesson, required this.state});

  final LearningLesson lesson;
  final LessonState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReview = state == LessonState.completed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(lesson.title, style: AppTextStyles.h3),
        if (lesson.description != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            lesson.description!,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            _MetaChip(icon: AppIcons.signLanguage, label: l10n.learnLessonSigns(lesson.signCount)),
            _MetaChip(icon: AppIcons.pointsActive, label: l10n.learnXpAmount(lesson.xpReward)),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        AppButton(
          label: isReview ? l10n.learnReview : l10n.learnStart,
          icon: isReview ? AppIcons.refresh : AppIcons.play,
          stretchOnLargeScreens: true,
          onPressed: () {
            Navigator.of(context).pop();
            context.pushNamed(AppRoutes.lessonName, pathParameters: {'id': lesson.id});
          },
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.neutral(context),
        borderRadius: AppRadius.radiusCircular,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PathSkeleton extends StatelessWidget {
  const _PathSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: AppLocalizations.of(context)!.loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SkeletonBlock(height: 104, radius: AppRadius.l),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < 5; i++)
            _PathNodeRow(
              index: i,
              child: const SizedBox(
                width: 160,
                child: Column(
                  children: [
                    SkeletonBlock.circle(size: _LessonNode._size),
                    SizedBox(height: AppSpacing.s),
                    SkeletonBlock(width: 96, height: 14),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LearningSkeleton extends StatelessWidget {
  const _LearningSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppSpacing.l),
      child: PageContainer.reading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Skeleton(
              child: Row(
                children: const [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 80, height: 12),
                      SizedBox(height: AppSpacing.s),
                      SkeletonBlock(width: 180, height: 26),
                    ],
                  ),
                  Spacer(),
                  SkeletonBlock(width: 72, height: 40, radius: AppRadius.circular),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            const Skeleton(child: SkeletonBlock(height: 108, radius: AppRadius.l)),
            const SizedBox(height: AppSpacing.xl),
            const _PathSkeleton(),
          ],
        ),
      ),
    );
  }
}
