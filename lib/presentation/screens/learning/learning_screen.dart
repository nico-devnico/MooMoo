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
import '../../../domain/learning/mastery.dart';
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
import '../../../domain/providers/error_text.dart';

/// Largeur max de la colonne du parcours (assez large pour le zigzag en Z,
/// assez étroite pour que l'œil suive sans balayer latéralement).
const double _pathWidth = 560;

/// Largeur de la barre latérale (stats / objectif) sur grand écran.
const double _sidebarWidth = 320;

/// Écran d'apprentissage : charge la langue du parcours puis affiche le corps.
class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Langue d'apprentissage de l'utilisateur (FutureProvider).
    final languageAsync = ref.watch(learningLanguageProvider);

    return Scaffold(
      body: SafeArea(
        // La barre du bas gère déjà l'inset ; on ne double pas ici.
        bottom: false,
        child: languageAsync.when(
          // Aucune langue → état vide.
          data: (language) => language == null
              ? AppEmptyState(
                  icon: AppIcons.learning,
                  title: l10n.learnNoCourseTitle,
                  message: l10n.learnNoCourseMessage,
                )
              : _LearningBody(language: language),
          // Chargement initial.
          loading: () => const _LearningSkeleton(),
          // Erreur réseau / auth : message + bouton réessayer.
          error: (error, _) => AppEmptyState(
            icon: AppIcons.error,
            title: l10n.errorGeneric,
            message: ref.userErrorText(error, l10n),
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(learningLanguageProvider),
          ),
        ),
      ),
    );
  }
}

/// Corps de la page : en-tête fixe + parcours défilant (+ sidebar desktop).
class _LearningBody extends ConsumerWidget {
  const _LearningBody({required this.language});

  /// Langue du parcours affiché.
  final SignLanguage language;

  /// Invalide parcours, progrès et résumé, puis attend le rechargement du path.
  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(learningPathProvider(language.id))
      ..invalidate(learningProgressProvider)
      ..invalidate(learnerSummaryProvider);
    await ref.read(learningPathProvider(language.id).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Desktop / large : navigation latérale présente.
    final isWide = context.hasSideNavigation;
    // Résumé (XP, série, objectif) — valeur par défaut si encore en chargement.
    final summary = ref.watch(learnerSummaryProvider).value ?? const LearnerSummary();
    // Droit d'édition du parcours (éditeur / admin).
    final canEdit = ref.watch(canEditLearningProvider).value ?? false;

    // Seul le parcours défile : titre, stats et légende restent visibles
    // (comme la barre du haut d'un jeu).
    final header = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m, bottom: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CourseHeader(
            language: language,
            summary: summary,
            // Sur mobile : pastilles série / XP / objectif dans l'en-tête.
            showStats: !isWide,
            // Bouton éditer uniquement sur mobile (sinon il est dans la sidebar).
            canEdit: canEdit && !isWide,
          ),
          const SizedBox(height: AppSpacing.m),
          const _MasteryLegend(),
        ],
      ),
    );

    // Zone scrollable : pull-to-refresh + fondu sous l'en-tête.
    final path = RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ShaderMask(
        // Les leçons s'estompent sous l'en-tête au lieu d'être coupées net.
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black, Colors.black],
          stops: [0, 0.03, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          // Permet le pull-to-refresh même si le contenu est court.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppSpacing.l,
            bottom: AppSpacing.xxxl + AppSpacing.xl,
          ),
          child: _LessonPath(language: language, canEdit: canEdit),
        ),
      ),
    );

    // --- Mise en page mobile / tablette étroite ---
    if (!isWide) {
      return PageContainer.reading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(child: path),
          ],
        ),
      );
    }

    // --- Mise en page large : parcours à gauche, sidebar à droite ---
    return PageContainer(
      width: ContentWidth.dashboard,
      child: Row(
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
                    Expanded(child: path),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xxl),
          SizedBox(
            width: _sidebarWidth,
            // Sidebar indépendante (peut scroll si contenu long).
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: AppSpacing.m, bottom: AppSpacing.l),
              child: _Sidebar(summary: summary, canEdit: canEdit),
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête du cours : titre, sélecteur de langue, stats (mobile) et édition.
class _CourseHeader extends ConsumerWidget {
  const _CourseHeader({
    required this.language,
    required this.summary,
    required this.showStats,
    this.canEdit = false,
  });

  /// Langue actuellement suivie.
  final SignLanguage language;
  /// Résumé apprenant (série, XP, objectif).
  final LearnerSummary summary;
  /// Affiche les pastilles série / XP / objectif (true sur mobile).
  final bool showStats;
  /// Affiche le bouton d'édition du parcours.
  final bool canEdit;

  /// Change la langue d'apprentissage dans le profil, puis rafraîchit.
  Future<void> _changeLanguage(BuildContext context, WidgetRef ref, SignLanguage next) async {
    final userId = ref.read(currentUserProvider)?.id;
    // Pas d'utilisateur ou même langue → rien à faire.
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
      runSpacing: AppSpacing.s,
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
              DailyGoalPill(
                summary: summary,
                onTap: () => context.pushNamed(AppRoutes.progressName),
              ),
            ],
            if (canEdit)
              IconButton.outlined(
                tooltip: l10n.learnManagePath,
                icon: const Icon(AppIcons.edit, size: 20),
                onPressed: () => context.pushNamed(AppRoutes.learningManageName),
              ),
          ],
        ),
      ],
    );
  }
}

/// Barre latérale desktop : série, XP, objectif du jour, liens progression / édition.
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

/// Lien compact dans la sidebar (icône + libellé + chevron).
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

/// Construit le parcours (unités → routes en Z) à partir des providers.
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
        message: ref.userErrorText(pathAsync.error!, l10n),
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
          if (i > 0) const SizedBox(height: AppSpacing.xl),
          _UnitBanner(
            unit: units[i],
            number: i + 1,
            done: _playable(units[i]).where((l) => states[l.id] == LessonState.completed).length,
            total: _playable(units[i]).length,
          ),
          const SizedBox(height: AppSpacing.l),
          _UnitRoad(
            stops: _stopsFor(units[i], states, lessonProgress),
          ),
        ],
      ],
    );
  }

  /// Construit la liste des arrêts : leçon, puis exercice, puis leçon suivante
  /// de l'autre côté — la route bascule d'un bord à l'autre en formant un Z.
  static List<_Stop> _stopsFor(
    LearningUnit unit,
    Map<String, LessonState> states,
    Map<String, LessonProgress> progress,
  ) {
    final stops = <_Stop>[];
    var side = -1.0;
    for (final lesson in unit.lessons) {
      final state = states[lesson.id]!;
      final lessonProgress = progress[lesson.id];
      stops.add(_Stop.lesson(lesson, state, lessonProgress, side));
      if (lesson.signCount > 0) {
        stops.add(_Stop.practice(lesson, state, lessonProgress));
      }
      side = -side;
    }
    final playable = _playable(unit);
    if (playable.isNotEmpty) {
      stops.add(
        _Stop.trophy(
          earned: playable.every((l) => states[l.id] == LessonState.completed),
          dx: side,
        ),
      );
    }
    return stops;
  }

  /// Leçons jouables d'une unité (au moins un signe).
  static Iterable<LearningLesson> _playable(LearningUnit unit) =>
      unit.lessons.where((l) => l.signCount > 0);
}

/// Légende des couleurs d'anneaux, affichée une fois en haut (en-tête fixe).
class _MasteryLegend extends StatelessWidget {
  const _MasteryLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const levels = [
      MasteryLevel.fragile,
      MasteryLevel.learning,
      MasteryLevel.acquired,
      MasteryLevel.mastered,
    ];
    return Semantics(
      container: true,
      label: '${l10n.learnMasteryLegend}: ${levels.map((l) => l.label(l10n)).join(', ')}',
      excludeSemantics: true,
      child: Wrap(
        spacing: AppSpacing.m,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.learnMasteryLegend,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final level in levels)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: level.color, shape: BoxShape.circle),
                  child: Icon(level.icon, size: 11, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(level.label(l10n), style: AppTextStyles.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}

/// Récompense de fin d'unité : grise tant que des leçons restent, puis or.
class _UnitTrophy extends StatelessWidget {
  const _UnitTrophy({required this.earned});

  final bool earned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = earned ? l10n.learnUnitTrophyEarned : l10n.learnUnitTrophyLocked;
    void onTap() => AppSnackbar.showInfo(context, message);
    return Semantics(
      button: true,
      label: '${l10n.learnUnitTrophy}, $message',
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox(
        width: _Stop.wideWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Coin3D(
              size: _Stop.trophySize,
              depth: 9,
              fill: earned ? AppColors.gold : AppColors.neutral(context),
              ledge: earned ? AppColors.goldLedge : AppColors.border(context),
              icon: AppIcons.trophy,
              iconSize: 40,
              iconColor: earned ? Colors.white : AppColors.textSecondary(context),
              onTap: onTap,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              l10n.learnUnitTrophy,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: earned ? null : AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bannière d'unité en relief (dégradé + socle) avec barre de progression.
class _UnitBanner extends StatelessWidget {
  const _UnitBanner({
    required this.unit,
    required this.number,
    required this.done,
    required this.total,
  });

  final LearningUnit unit;
  final int number;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      header: true,
      label: '${l10n.learnUnitLabel(number)}, ${unit.title}, ${l10n.learnUnitProgress(done, total)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLedge,
          borderRadius: AppRadius.radiusL,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusL,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(AppColors.primary, Colors.white, 0.18)!,
              AppColors.primary,
            ],
          ),
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
                  if (total > 0) ...[
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: AppRadius.radiusCircular,
                            child: LinearProgressIndicator(
                              value: done / total,
                              minHeight: 8,
                              color: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          l10n.learnUnitProgress(done, total),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
      ),
    );
  }
}

/// Type d'arrêt sur la route du parcours.
enum _StopKind { lesson, practice, trophy }

/// Un arrêt sur la route : une leçon, l'exercice qui la suit, ou le trophée
/// d'unité. Connaît la position de son cercle pour que la route puisse s'y
/// brancher.
class _Stop {
  const _Stop._({
    required this.kind,
    required this.dx,
    this.lesson,
    this.state = LessonState.locked,
    this.progress,
    this.earned = false,
  });

  /// Arrêt « leçon » placé à gauche (dx=-1) ou à droite (dx=1).
  factory _Stop.lesson(
    LearningLesson lesson,
    LessonState state,
    LessonProgress? progress,
    double dx,
  ) =>
      _Stop._(kind: _StopKind.lesson, dx: dx, lesson: lesson, state: state, progress: progress);

  /// Arrêt « exercice » toujours au centre (dx=0).
  factory _Stop.practice(LearningLesson lesson, LessonState state, LessonProgress? progress) =>
      _Stop._(kind: _StopKind.practice, dx: 0, lesson: lesson, state: state, progress: progress);

  /// Trophée de fin d'unité.
  factory _Stop.trophy({required bool earned, required double dx}) =>
      _Stop._(kind: _StopKind.trophy, dx: dx, earned: earned);

  /// Largeur réservée aux pastilles leçon / trophée.
  static const double wideWidth = 160;
  /// Largeur réservée aux pastilles exercice.
  static const double practiceWidth = 120;
  /// Diamètre de la pastille exercice.
  static const double practiceSize = 54;
  /// Diamètre du trophée.
  static const double trophySize = 84;
  /// Hauteur réservée à la bulle « C'est parti ! » au-dessus de la leçon courante.
  static const double bubbleSpace = 52;
  /// Espace vertical entre deux arrêts.
  static const double gap = 10;

  final _StopKind kind;

  /// -1 = bord gauche de la route, 0 = milieu, 1 = bord droit.
  final double dx;
  final LearningLesson? lesson;
  final LessonState state;
  final LessonProgress? progress;
  /// True si le trophée est débloqué.
  final bool earned;

  /// True pour la leçon actuellement jouable.
  bool get isCurrentLesson => kind == _StopKind.lesson && state == LessonState.current;

  /// Arrêt déjà accessible : la route qui y mène est colorée.
  bool get isOpen => switch (kind) {
        _StopKind.lesson => state == LessonState.completed || state == LessonState.current,
        _StopKind.practice => state == LessonState.completed,
        _StopKind.trophy => earned,
      };

  double get width => kind == _StopKind.practice ? practiceWidth : wideWidth;

  /// Espace au-dessus du centre du cercle (bulle au-dessus de la leçon courante).
  double get above => switch (kind) {
        _StopKind.lesson => _LessonNode._ringSize / 2 + (isCurrentLesson ? bubbleSpace : 0),
        _StopKind.practice => practiceSize / 2 + 6,
        _StopKind.trophy => trophySize / 2 + 6,
      };

  /// Espace sous le centre : cercle + titre + éventuel libellé de maîtrise.
  double get below => switch (kind) {
        _StopKind.lesson => _LessonNode._ringSize / 2 + 64,
        _StopKind.practice => practiceSize / 2 + 34,
        _StopKind.trophy => trophySize / 2 + 44,
      };

  /// Distance du haut du widget au centre de son cercle.
  double get anchor => switch (kind) {
        _StopKind.lesson => _LessonNode._ringSize / 2,
        _StopKind.practice => (practiceSize + 8) / 2,
        _StopKind.trophy => (trophySize + 9) / 2,
      };
}

/// Route sinueuse d'une unité : arrêts en Z d'un bord à l'autre, reliés par
/// une route en relief colorée jusqu'à la progression de l'apprenant.
/// La route se dessine et les pastilles apparaissent à l'ouverture.
class _UnitRoad extends StatefulWidget {
  const _UnitRoad({required this.stops});

  final List<_Stop> stops;

  @override
  State<_UnitRoad> createState() => _UnitRoadState();
}

class _UnitRoadState extends State<_UnitRoad> with SingleTickerProviderStateMixin {
  /// Animation d'entrée : durée proportionnelle au nombre d'arrêts (bornée).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (500 + 110 * widget.stops.length).clamp(700, 1800)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Réduction des animations → affiche immédiatement l'état final.
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      // Lance l'intro une seule fois.
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.stops;
    if (stops.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Amplitude horizontale du Z (bornée pour ne pas coller aux bords).
        final amplitude = ((width - _Stop.wideWidth) / 2).clamp(0.0, 170.0);
        // Centres des pastilles (points d'ancrage de la route).
        final centres = <Offset>[];
        var y = 0.0;
        for (final stop in stops) {
          final cy = y + stop.above;
          centres.add(Offset(width / 2 + stop.dx * amplitude, cy));
          y = cy + stop.below + _Stop.gap;
        }
        final height = y;
        final count = stops.length;

        /// Apparition échelonnée (opacité + scale) d'un arrêt.
        Widget popIn(int index, Widget child) {
          final start = (index / count) * 0.6;
          final animation = CurvedAnimation(
            parent: _intro,
            curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutBack),
          );
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Opacity(
              opacity: animation.value.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.5 + 0.5 * animation.value, child: child),
            ),
            child: child,
          );
        }

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Couche route (derrière les pastilles).
              Positioned.fill(
                child: ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _intro,
                    builder: (context, _) => CustomPaint(
                      painter: _RoadPainter(
                        centres: centres,
                        open: [for (final s in stops) s.isOpen],
                        progress: Curves.easeInOutCubic.transform(_intro.value),
                        openColor: AppColors.primary,
                        openLedge: AppColors.primaryLedge,
                        closedColor: AppColors.neutral(context),
                        closedLedge: AppColors.border(context),
                        closedDash: AppColors.textSecondary(context).withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
              // Pastilles + bulle « C'est parti ! » pour la leçon courante.
              for (var i = 0; i < count; i++) ...[
                if (stops[i].isCurrentLesson)
                  Positioned(
                    left: centres[i].dx - _Stop.wideWidth / 2,
                    width: _Stop.wideWidth,
                    // Ancrée juste au-dessus du cercle (évite un overflow de hauteur fixe).
                    bottom: height - (centres[i].dy - stops[i].anchor) + 2,
                    child: popIn(i, const Center(child: _StartBubble())),
                  ),
                Positioned(
                  left: centres[i].dx - stops[i].width / 2,
                  width: stops[i].width,
                  top: centres[i].dy - stops[i].anchor,
                  child: popIn(i, _buildStop(stops[i])),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Choisit le widget d'arrêt selon le type.
  Widget _buildStop(_Stop stop) => switch (stop.kind) {
        _StopKind.lesson => _LessonNode(
            lesson: stop.lesson!,
            state: stop.state,
            progress: stop.progress,
          ),
        _StopKind.practice => _PracticeNode(
            lesson: stop.lesson!,
            state: stop.state,
            progress: stop.progress,
          ),
        _StopKind.trophy => _UnitTrophy(earned: stop.earned),
      };
}

/// Peint la route entre les arrêts : ombre douce, socle plus sombre pour la
/// profondeur, chaussée et marquage central en pointillés. Chaque tronçon est
/// coloré si l'arrêt d'arrivée est ouvert, gris sinon.
class _RoadPainter extends CustomPainter {
  _RoadPainter({
    required this.centres,
    required this.open,
    required this.progress,
    required this.openColor,
    required this.openLedge,
    required this.closedColor,
    required this.closedLedge,
    required this.closedDash,
  });

  final List<Offset> centres;
  final List<bool> open;
  final double progress;
  final Color openColor;
  final Color openLedge;
  final Color closedColor;
  final Color closedLedge;
  final Color closedDash;

  static const double _roadWidth = 22;
  static const double _depth = 6;

  /// Construit un segment cubique entre deux centres.
  /// Des tangentes verticales courtes gardent les diagonales droites, pour que
  /// chaque virage lise comme un coin de Z plutôt qu'un S mou.
  Path _segment(Offset a, Offset b) {
    final bend = (b.dy - a.dy) * 0.3;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, a.dy + bend, b.dx, b.dy - bend, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Pas assez de points ou animation pas démarrée.
    if (centres.length < 2 || progress <= 0) return;

    // Segments complets entre centres consécutifs.
    final segments = [
      for (var i = 0; i < centres.length - 1; i++) _segment(centres[i], centres[i + 1]),
    ];
    // Longueur de chaque segment (pour le tracé progressif).
    final lengths = [
      for (final s in segments) s.computeMetrics().fold<double>(0, (sum, m) => sum + m.length),
    ];
    // Portion encore à dessiner selon la progression d'intro.
    var remaining = lengths.fold<double>(0, (a, b) => a + b) * progress;

    // (chemin visible, tronçon allumé ?)
    final visible = <(Path, bool)>[];
    for (var i = 0; i < segments.length && remaining > 0; i++) {
      final metric = segments[i].computeMetrics().first;
      final take = remaining.clamp(0.0, lengths[i]);
      // open[i+1] : le tronçon mène à l'arrêt suivant.
      visible.add((metric.extractPath(0, take), open[i + 1]));
      remaining -= take;
    }

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    // 1) Ombre portée sous la route.
    final shadow = stroke(Colors.black.withValues(alpha: 0.10), _roadWidth + 6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (final (path, _) in visible) {
      canvas.drawPath(path.shift(const Offset(0, _depth + 6)), shadow);
    }
    // 2) Socle (ledge) décalé vers le bas pour l'effet 3D.
    for (final (path, lit) in visible) {
      canvas.drawPath(
        path.shift(const Offset(0, _depth)),
        stroke(lit ? openLedge : closedLedge, _roadWidth),
      );
    }
    // 3) Chaussée principale.
    for (final (path, lit) in visible) {
      canvas.drawPath(path, stroke(lit ? openColor : closedColor, _roadWidth));
    }
    // 4) Marquage central en pointillés.
    for (final (path, lit) in visible) {
      final dash = stroke(lit ? Colors.white.withValues(alpha: 0.75) : closedDash, 3.5);
      for (final metric in path.computeMetrics()) {
        for (var d = 14.0; d < metric.length - 14; d += 22) {
          canvas.drawPath(metric.extractPath(d, (d + 10).clamp(0, metric.length)), dash);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.centres != centres ||
      oldDelegate.open != open ||
      oldDelegate.openColor != openColor ||
      oldDelegate.closedColor != closedColor;
}

/// Bouton de jeu en relief : face brillante sur un socle plus sombre avec
/// ombre portée. L'appui (toucher, souris ou clavier) enfonce la face dans
/// le socle.
class _Coin3D extends StatefulWidget {
  const _Coin3D({
    required this.size,
    required this.fill,
    required this.ledge,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.depth = 8,
    this.iconSize = 30,
    this.border,
  });

  /// Diamètre de la face.
  final double size;
  /// Hauteur du socle (profondeur 3D).
  final double depth;
  /// Couleur de la face.
  final Color fill;
  /// Couleur du socle (plus sombre).
  final Color ledge;
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  /// Bordure optionnelle (ex. pastille exercice « prochaine »).
  final Color? border;
  final VoidCallback onTap;

  @override
  State<_Coin3D> createState() => _Coin3DState();
}

class _Coin3DState extends State<_Coin3D> {
  /// True pendant l'appui (enfonce la face dans le socle).
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final depth = widget.depth;
    // Décalage vertical de la face quand on appuie.
    final sink = _pressed ? depth - 2 : 0.0;
    // Reflet clair pour le dégradé radial.
    final highlight = Color.lerp(widget.fill, Colors.white, 0.28)!;

    return SizedBox(
      width: size,
      height: size + depth,
      child: Stack(
        children: [
          // Socle fixe + ombre portée.
          Positioned(
            top: depth,
            left: 0,
            right: 0,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.ledge,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _pressed ? 0.10 : 0.20),
                    blurRadius: _pressed ? 4 : 12,
                    offset: Offset(0, _pressed ? 2 : 7),
                  ),
                ],
              ),
            ),
          ),
          // Face cliquable qui s'enfonce à l'appui.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            top: sink,
            left: 0,
            right: 0,
            height: size,
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.45),
                    radius: 0.95,
                    colors: [highlight, widget.fill],
                  ),
                  border: widget.border == null
                      ? null
                      : Border.all(color: widget.border!, width: 3),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onTap,
                  onHighlightChanged: (value) => setState(() => _pressed = value),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: size * 0.12,
                        left: size * 0.2,
                        child: Container(
                          width: size * 0.34,
                          height: size * 0.16,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(size),
                          ),
                        ),
                      ),
                      Icon(widget.icon, color: widget.iconColor, size: widget.iconSize),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ouvre une leçon depuis la route, ou explique pourquoi elle est inaccessible.
void _openLesson(
  BuildContext context,
  LearningLesson lesson,
  LessonState state,
  LessonProgress? progress,
) {
  final l10n = AppLocalizations.of(context)!;
  switch (state) {
    case LessonState.locked:
      AppSnackbar.showInfo(context, l10n.learnLessonLocked);
    case LessonState.empty:
      AppSnackbar.showInfo(context, l10n.learnLessonEmpty);
    case LessonState.completed:
    case LessonState.current:
      _showLessonSheet(context, lesson, state, progress);
  }
}

/// Exercice pratique après une leçon (« reproduisez le signe appris »),
/// placé sur la route entre deux leçons.
class _PracticeNode extends StatelessWidget {
  const _PracticeNode({required this.lesson, required this.state, this.progress});

  final LearningLesson lesson;
  final LessonState state;
  final LessonProgress? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final done = state == LessonState.completed;
    final next = state == LessonState.current;
    final level = masteryLevelOf(progress);

    final Color fill;
    final Color ledge;
    final Color iconColor;
    Color? border;
    if (done) {
      fill = level.color;
      ledge = level.ledge;
      iconColor = Colors.white;
    } else if (next) {
      fill = AppColors.surface(context);
      ledge = AppColors.primaryLedge;
      iconColor = AppColors.primary;
      border = AppColors.primary;
    } else {
      fill = AppColors.neutral(context);
      ledge = AppColors.border(context);
      iconColor = AppColors.textSecondary(context);
    }

    final status = done
        ? level.label(l10n)
        : next
            ? l10n.learnPracticeAfterLesson
            : l10n.learnStateLocked;
    void onTap() => _openLesson(context, lesson, state, progress);

    return Semantics(
      button: true,
      label: '${l10n.learnPracticeStopLabel(lesson.title)}, $status',
      excludeSemantics: true,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Coin3D(
            size: _Stop.practiceSize,
            depth: 6,
            fill: fill,
            ledge: ledge,
            border: border,
            icon: AppIcons.practice,
            iconSize: 24,
            iconColor: iconColor,
            onTap: onTap,
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surface(context).withValues(alpha: 0.92),
              borderRadius: AppRadius.radiusCircular,
            ),
            child: Text(
              l10n.learnPracticeStop,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: done ? level.textColor(context) : AppColors.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Halo doux qui pulse autour de la prochaine leçon pour attirer l'œil.
class _PulseHalo extends StatefulWidget {
  const _PulseHalo({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<_PulseHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        return Transform.scale(
          scale: 0.85 + 0.4 * t,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.28 * (1 - t)),
            ),
          ),
        );
      },
    );
  }
}

/// Décalages horizontaux du squelette de chargement, en écho au Z de la route.
const List<double> _zigzag = [-0.7, 0, 0.7, 0];

/// Rangée du squelette : aligne un placeholder selon [_zigzag].
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

/// Couleurs et icône d'une pastille de leçon selon son état.
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

/// Pastille de leçon sur le parcours : anneau de maîtrise + bouton 3D + titre.
class _LessonNode extends StatelessWidget {
  const _LessonNode({required this.lesson, required this.state, this.progress});

  final LearningLesson lesson;
  final LessonState state;
  final LessonProgress? progress;

  /// Diamètre de la face du bouton.
  static const double _size = 72;
  /// Hauteur du socle (effet 3D).
  static const double _ledge = 8;
  /// Diamètre de l'anneau de maîtrise autour du bouton.
  static const double _ringSize = 104;

  MasteryLevel get _level => masteryLevelOf(progress);

  _NodeStyle _style(BuildContext context) {
    switch (state) {
      case LessonState.completed:
        final level = _level;
        return _NodeStyle(
          fill: level.color,
          ledge: level.ledge,
          iconColor: Colors.white,
          icon: level.icon,
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
        return l10n.learnLessonMastery(
          _level.label(l10n),
          (masteryRatio(progress) * 100).round(),
        );
      case LessonState.current:
        return l10n.learnStateCurrent;
      case LessonState.locked:
        return l10n.learnStateLocked;
      case LessonState.empty:
        return l10n.learnLessonEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = _style(context);
    final isCurrent = state == LessonState.current;
    final isCompleted = state == LessonState.completed;
    final stateLabel = _stateLabel(l10n);
    void onTap() => _openLesson(context, lesson, state, progress);

    final ring = MasteryRing(
      size: _ringSize,
      value: isCompleted ? masteryRatio(progress) : 0,
      color: isCompleted ? _level.color : AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.only(top: _ledge),
        child: _Coin3D(
          size: _size,
          depth: _ledge,
          fill: style.fill,
          ledge: style.ledge,
          border: style.border,
          icon: style.icon,
          iconColor: style.iconColor,
          onTap: onTap,
        ),
      ),
    );

    return Semantics(
      button: true,
      label: '${lesson.title}, $stateLabel, ${l10n.learnLessonSigns(lesson.signCount)}',
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox(
        width: _Stop.wideWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: _ringSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (isCurrent)
                    const _PulseHalo(size: _ringSize, color: AppColors.primary),
                  ring,
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Fond derrière le texte pour rester lisible quand la route passe dessous.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface(context).withValues(alpha: 0.92),
                borderRadius: AppRadius.radiusM,
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  if (isCompleted)
                    Text(
                      stateLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _level.textColor(context),
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

/// Bulle « C'est parti ! » flottant au-dessus de la prochaine leçon.
/// Immobile si l'utilisateur a demandé à réduire les animations.
class _StartBubble extends StatefulWidget {
  const _StartBubble();

  @override
  State<_StartBubble> createState() => _StartBubbleState();
}

class _StartBubbleState extends State<_StartBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bubble = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: AppRadius.radiusM,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Text(
            l10n.learnStartBubble.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        CustomPaint(size: const Size(16, 8), painter: _BubbleTailPainter()),
      ],
    );
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -6 * Curves.easeInOut.transform(_controller.value)),
          child: child,
        ),
        child: bubble,
      ),
    );
  }
}

/// Queue triangulaire sous la bulle « C'est parti ! ».
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) => false;
}

/// Résumé de leçon avec bouton démarrer : bottom sheet sur téléphone,
/// dialogue sur grand écran (où une sheet s'étirerait trop).
void _showLessonSheet(
  BuildContext context,
  LearningLesson lesson,
  LessonState state,
  LessonProgress? progress,
) {
  final content = _LessonSummary(lesson: lesson, state: state, progress: progress);

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

/// Contenu de la fiche leçon (anneau %, métadonnées, bouton démarrer / revoir).
class _LessonSummary extends StatelessWidget {
  const _LessonSummary({required this.lesson, required this.state, this.progress});

  final LearningLesson lesson;
  final LessonState state;
  final LessonProgress? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isReview = state == LessonState.completed;
    final level = masteryLevelOf(progress);
    final percent = (masteryRatio(progress) * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MasteryRing(
              size: 64,
              strokeWidth: 6,
              value: masteryRatio(progress),
              color: level.color,
              child: Text(
                '$percent %',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    level.label(l10n),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isReview ? level.textColor(context) : AppColors.textSecondary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            _MetaChip(icon: AppIcons.practice, label: l10n.learnPracticeIncluded),
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

/// Pastille méta (signes, XP, exercice inclus) dans la fiche leçon.
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

/// Squelette du parcours pendant le chargement (bannière + pastilles en Z).
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

/// Squelette de toute la page d'apprentissage (en-tête + légende + parcours).
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
            const SizedBox(height: AppSpacing.m),
            const Skeleton(child: SkeletonBlock(width: 260, height: 14)),
            const SizedBox(height: AppSpacing.xl),
            const _PathSkeleton(),
          ],
        ),
      ),
    );
  }
}
