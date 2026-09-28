import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/learning.dart';
import '../../../../domain/learning/mastery.dart';
import '../../../../domain/providers/profile_provider.dart';
import '../../../../domain/providers/tts_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_panel.dart';

/// Style visuel (couleur, socle, icône, libellé) de chaque niveau de maîtrise.
/// La couleur n'est jamais le seul signal : le libellé texte l'accompagne toujours.
extension MasteryLevelStyle on MasteryLevel {
  /// Couleur de remplissage de la pastille / de l'anneau.
  Color get color => switch (this) {
        MasteryLevel.none => AppColors.primary,
        MasteryLevel.fragile => AppColors.error,
        MasteryLevel.learning => AppColors.warning,
        MasteryLevel.acquired => AppColors.success,
        MasteryLevel.mastered => AppColors.gold,
      };

  /// Couleur du socle (effet 3D sous la pastille), plus sombre que [color].
  Color get ledge => switch (this) {
        MasteryLevel.none => AppColors.primaryLedge,
        MasteryLevel.fragile => AppColors.errorLedge,
        MasteryLevel.learning => AppColors.warningLedge,
        MasteryLevel.acquired => AppColors.successLedge,
        MasteryLevel.mastered => AppColors.goldLedge,
      };

  /// Couleur de texte lisible : les teintes des anneaux sont trop claires
  /// pour du petit texte sur fond clair.
  Color textColor(BuildContext context) {
    // En thème sombre, la couleur vive reste lisible.
    if (Theme.of(context).brightness == Brightness.dark) return color;
    // En thème clair : or assombri pour « maîtrisé », sinon le socle.
    return switch (this) {
      MasteryLevel.mastered => const Color(0xFF7A5800),
      _ => ledge,
    };
  }

  /// Icône affichée au centre de la pastille selon le niveau.
  IconData get icon => switch (this) {
        MasteryLevel.none => AppIcons.play,
        MasteryLevel.fragile || MasteryLevel.learning => AppIcons.refresh,
        MasteryLevel.acquired => AppIcons.checkBold,
        MasteryLevel.mastered => AppIcons.crown,
      };

  /// Libellé localisé du niveau (jamais uniquement la couleur).
  String label(AppLocalizations l10n) => switch (this) {
        MasteryLevel.none => l10n.masteryNone,
        MasteryLevel.fragile => l10n.masteryFragile,
        MasteryLevel.learning => l10n.masteryLearning,
        MasteryLevel.acquired => l10n.masteryAcquired,
        MasteryLevel.mastered => l10n.masteryMastered,
      };
}

/// Anneau de progression circulaire autour d'une pastille de leçon.
/// Se remplit selon [value] (0 → 1) avec la couleur de maîtrise.
class MasteryRing extends StatelessWidget {
  const MasteryRing({
    super.key,
    required this.value,
    required this.color,
    required this.size,
    required this.child,
    this.strokeWidth = 8,
  });

  /// Progression entre 0 et 1.
  final double value;

  /// Couleur de l'arc de progression.
  final Color color;

  /// Diamètre total de l'anneau (et de l'espace pour [child]).
  final double size;

  /// Épaisseur du trait de l'anneau.
  final double strokeWidth;

  /// Contenu centré (généralement la pastille 3D).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Couleur de la piste (anneau vide).
    final track = AppColors.border(context);
    // Respecte « réduire les animations » du système.
    final reduced = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        // Sans animation : on affiche directement la valeur finale.
        tween: Tween(begin: reduced ? value : 0, end: value),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(value: v, color: color, track: track, strokeWidth: strokeWidth),
          child: child,
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Peintre qui dessine la piste grise puis l'arc de progression coloré.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Rectangle intérieur pour que le trait ne déborde pas.
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    // Piste complète (cercle gris).
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    // Rien à remplir si la progression est nulle.
    if (value <= 0) return;
    // Arc coloré partant du haut (−π/2) dans le sens horaire.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Petite étiquette colorée (ex. « Nouveau signe », « Exercice 1/3 »).
class LearningTag extends StatelessWidget {
  const LearningTag({super.key, required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        // Fond teinté à partir de la couleur d'accent.
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.radiusCircular,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs + 2),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton qui lit le mot à voix haute (apprenants entendants).
/// Masqué pour les profils sourds : ce serait du bruit inutile à l'écran.
class SpeakWordButton extends ConsumerWidget {
  const SpeakWordButton({super.key, required this.word});

  /// Mot à faire lire par le TTS.
  final String word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lit le flag « sourd » du profil ; false par défaut si profil absent.
    final isDeaf = ref.watch(userProfileProvider.select((p) => p.value?.isDeaf ?? false));
    if (isDeaf) return const SizedBox.shrink();
    return IconButton.filledTonal(
      tooltip: AppLocalizations.of(context)!.lessonSpeakWord,
      onPressed: () => ref.read(ttsControllerProvider.notifier).speak(word),
      icon: const Icon(AppIcons.speaker),
    );
  }
}

/// Pastille compacte (icône + valeur) : série, XP, etc.
class LearningStatPill extends StatelessWidget {
  const LearningStatPill({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color color;
  /// Valeur affichée (souvent un nombre en texte).
  final String value;
  /// Libellé lu par les lecteurs d'écran (remplace le contenu visuel).
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: AppRadius.radiusCircular,
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille de la série de jours consécutifs (streak).
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.summary});

  final LearnerSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Série active si au moins un jour d'affilée.
    final active = summary.currentStreak > 0;
    return LearningStatPill(
      icon: active ? AppIcons.streakActive : AppIcons.streak,
      color: active ? AppColors.warning : AppColors.textSecondary(context),
      value: '${summary.currentStreak}',
      semanticLabel: l10n.learnStreakDays(summary.currentStreak),
    );
  }
}

/// Pastille du total d'XP de l'apprenant.
class XpPill extends StatelessWidget {
  const XpPill({super.key, required this.summary});

  final LearnerSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LearningStatPill(
      icon: AppIcons.pointsActive,
      color: AppColors.primary,
      value: '${summary.totalXp}',
      semanticLabel: l10n.learnXpAmount(summary.totalXp),
    );
  }
}

/// Pastille compacte « objectif du jour » pour l'en-tête fixe sur téléphone.
/// Affiche un mini-anneau + le texte XP du jour / objectif.
class DailyGoalPill extends StatelessWidget {
  const DailyGoalPill({super.key, required this.summary, this.onTap});

  final LearnerSummary summary;
  /// Ouverture de la page de progression (optionnel).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reached = summary.dailyGoalReached;
    // Vert si l'objectif est atteint, sinon couleur primaire.
    final accent = reached ? AppColors.success : AppColors.primary;
    final progressText = l10n.learnDailyGoalProgress(summary.todayXp, summary.dailyGoalXp);

    return Semantics(
      button: onTap != null,
      label: '${l10n.learnDailyGoal}, $progressText'
          '${reached ? ', ${l10n.learnDailyGoalReached}' : ''}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface(context),
        shape: StadiumBorder(side: BorderSide(color: AppColors.border(context))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs + 2,
              AppSpacing.xs + 2,
              AppSpacing.m,
              AppSpacing.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini anneau de progression de l'objectif journalier.
                MasteryRing(
                  value: summary.dailyGoalProgress,
                  color: accent,
                  size: 30,
                  strokeWidth: 4,
                  child: Icon(
                    reached ? AppIcons.success : AppIcons.goal,
                    size: 15,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  progressText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte complète « objectif du jour » (barre de progression + message).
/// Utilisée dans la barre latérale desktop.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key, required this.summary, this.onTap});

  final LearnerSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reached = summary.dailyGoalReached;
    final accent = reached ? AppColors.success : AppColors.primary;
    final progressText = l10n.learnDailyGoalProgress(summary.todayXp, summary.dailyGoalXp);

    return AppPanel(
      onTap: onTap,
      // Libellé sémantique unique : titre + progression + éventuellement « atteint ».
      semanticLabel: '${l10n.learnDailyGoal}, $progressText'
          '${reached ? ', ${l10n.learnDailyGoalReached}' : ''}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icône dans un cercle soft (vert si atteint).
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: reached ? AppColors.successSoft : AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reached ? AppIcons.success : AppIcons.goal,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    l10n.learnDailyGoal,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  progressText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            // Barre linéaire de progression vers l'objectif XP du jour.
            ClipRRect(
              borderRadius: AppRadius.radiusCircular,
              child: LinearProgressIndicator(
                value: summary.dailyGoalProgress,
                minHeight: 10,
                color: accent,
                backgroundColor: AppColors.neutral(context),
              ),
            ),
            // Message de félicitations si l'objectif est atteint.
            if (reached) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.learnDailyGoalReached,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
