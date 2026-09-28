import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/learning/lesson_builder.dart';
import '../../../../domain/learning/practice.dart';
import '../../../../domain/providers/camera_provider.dart';
import '../../../../domain/providers/ml_model_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/camera/camera_view.dart';
import '../../../widgets/sign_media.dart';
import 'learning_widgets.dart';

/// Phases successives de l'exercice pratique (reproduction du signe).
enum _Phase {
  /// Caméra éteinte : explications + bouton pour l'activer.
  idle,

  /// Aperçu caméra prêt, l'apprenant peut lancer l'enregistrement.
  preview,

  /// Compte à rebours 3-2-1 avant l'enregistrement.
  countdown,

  /// Enregistrement vidéo en cours.
  recording,

  /// Envoi de la vidéo au modèle ML et attente du résultat.
  analyzing,

  /// Le signe a été reconnu correctement.
  success,

  /// Le signe n'a pas été reconnu.
  failure,

  /// Pas de caméra / pas de reconnaissance / choix de l'apprenant :
  /// auto-évaluation (« Je l'ai réussi » / « Pas encore »).
  selfCheck,
}

/// Vue « Reproduisez le signe que vous venez d'apprendre ».
///
/// D'un côté le modèle de référence (média du signe), de l'autre la caméra
/// de l'apprenant. Le clip est envoyé au modèle de reconnaissance ; si celui-ci
/// est indisponible, l'apprenant s'auto-évalue pour ne bloquer personne.
///
/// Chaque étape est annoncée par texte, couleur et icône, confirmée par
/// vibrations et lue par les lecteurs d'écran : rien ne repose uniquement
/// sur le son.
class PracticeView extends ConsumerStatefulWidget {
  const PracticeView({
    super.key,
    required this.step,
    required this.onResult,
    required this.onReset,
  });

  /// Étape de pratique (signe + numéro / total).
  final PracticeStep step;

  /// Verdict de la dernière tentative (true = réussi).
  final ValueChanged<bool> onResult;

  /// Nouvelle tentative : l'ancien verdict ne compte plus.
  final VoidCallback onReset;

  @override
  ConsumerState<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends ConsumerState<PracticeView> {
  /// Phase courante de l'exercice.
  _Phase _phase = _Phase.idle;

  /// Valeur affichée pendant le compte à rebours.
  int _count = practiceCountdown;

  /// True si la caméra / le ML étaient indisponibles (on reste en self-check au retry).
  bool _unavailable = false;

  /// True si le dernier verdict vient de l'auto-évaluation.
  bool _selfRated = false;

  /// Compteur d'essai : une étape tardive d'un ancien essai ne doit rien faire.
  int _run = 0;

  /// Notifier caméra capturé pour pouvoir arrêter l'enregistrement au dispose.
  CameraState? _camera;

  /// Indique si la caméra doit être affichée dans le panneau « Vous ».
  bool get _cameraOn => switch (_phase) {
        _Phase.preview ||
        _Phase.countdown ||
        _Phase.recording ||
        _Phase.analyzing ||
        _Phase.success ||
        _Phase.failure =>
          !_selfRated,
        _ => false,
      };

  @override
  void dispose() {
    // Invalide toute opération asynchrone encore en cours.
    _run++;
    // Si on enregistre encore, on tente d'arrêter proprement.
    if (_phase == _Phase.recording) {
      _camera?.stopVideoRecording().catchError((_) => null);
    }
    super.dispose();
  }

  /// Change la phase si le widget est toujours monté.
  void _set(_Phase phase) {
    if (mounted) setState(() => _phase = phase);
  }

  /// Active la caméra et passe en aperçu.
  void _enableCamera() => _set(_Phase.preview);

  /// Ouvre le mode auto-évaluation (optionnellement après échec technique).
  void _openSelfCheck({bool unavailable = false}) {
    _run++;
    setState(() {
      _unavailable = unavailable;
      _phase = _Phase.selfCheck;
    });
  }

  /// Lance le compte à rebours puis l'enregistrement.
  Future<void> _start() async {
    final run = ++_run;
    // Annule le verdict précédent auprès du parent.
    widget.onReset();
    // Compte à rebours 3 → 1 avec vibration légère à chaque seconde.
    for (var i = practiceCountdown; i > 0; i--) {
      if (!mounted || run != _run) return;
      setState(() {
        _phase = _Phase.countdown;
        _count = i;
      });
      HapticFeedback.selectionClick();
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted || run != _run) return;
    await _record(run);
  }

  /// Enregistre la vidéo, l'envoie au ML et rend le verdict.
  Future<void> _record(int run) async {
    try {
      // Attend que la caméra soit prête.
      final controller = await ref.read(cameraStateProvider.future);
      if (!mounted || run != _run) return;
      if (controller == null || !controller.value.isInitialized) {
        _openSelfCheck(unavailable: true);
        return;
      }
      final camera = ref.read(cameraStateProvider.notifier);
      _camera = camera;
      // Démarre l'enregistrement.
      await camera.startVideoRecording();
      if (!mounted || run != _run) return;
      _set(_Phase.recording);
      HapticFeedback.mediumImpact();

      // Laisse signer pendant la durée dédiée.
      await Future<void>.delayed(practiceRecordingDuration);
      if (!mounted || run != _run) return;
      final file = await camera.stopVideoRecording();
      HapticFeedback.mediumImpact();
      if (!mounted || run != _run) return;
      if (file == null) {
        _openSelfCheck(unavailable: true);
        return;
      }
      _set(_Phase.analyzing);

      // Envoie les octets au modèle ; sur le web le nom de fichier est .webm.
      final bytes = await file.readAsBytes();
      final result = await ref.read(mlModelRepositoryProvider).infer(
            fileBytes: bytes,
            filename: kIsWeb ? 'practice.webm' : file.name,
          );
      if (!mounted || run != _run) return;
      if (!result.ok) {
        _openSelfCheck(unavailable: true);
        return;
      }
      // Compare le label attendu aux meilleures prédictions.
      _verdict(practiceMatches(widget.step.sign.word, result));
    } catch (_) {
      // Toute erreur technique → auto-évaluation plutôt qu'un blocage.
      if (mounted && run == _run) _openSelfCheck(unavailable: true);
    }
  }

  /// Applique le verdict (vibrations + phase + callback parent).
  void _verdict(bool ok) {
    if (ok) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    _set(ok ? _Phase.success : _Phase.failure);
    widget.onResult(ok);
  }

  /// Auto-évaluation manuelle de l'apprenant.
  void _rateSelf(bool ok) {
    setState(() => _selfRated = true);
    _verdict(ok);
  }

  /// Relance une tentative (self-check si caméra/ML absents, sinon aperçu).
  void _retry() {
    _run++;
    widget.onReset();
    setState(() {
      _phase = _unavailable || _selfRated ? _Phase.selfCheck : _Phase.preview;
      _selfRated = false;
    });
  }

  /// Texte d'état affiché sous les panneaux (région live pour l'accessibilité).
  String _status(AppLocalizations l10n) => switch (_phase) {
        _Phase.idle => l10n.practiceCameraHint,
        _Phase.preview => l10n.practiceCameraHint,
        _Phase.countdown => l10n.practiceCountdown(_count),
        _Phase.recording => l10n.practiceRecording,
        _Phase.analyzing => l10n.practiceAnalyzing,
        _Phase.success => l10n.practiceSuccess,
        _Phase.failure => l10n.practiceFailure,
        _Phase.selfCheck =>
          _unavailable ? l10n.practiceUnavailable : l10n.practiceSelfCheckMessage,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = widget.step;

    // Panneau de gauche / haut : signe de référence.
    final reference = _Panel(
      label: l10n.practiceReference,
      child: SignMedia(key: ValueKey(step.sign.id), sign: step.sign),
    );
    // Panneau de droite / bas : caméra ou message (sombre pour le flux vidéo).
    final learner = _Panel(
      label: l10n.practiceYou,
      dark: true,
      child: _stage(l10n),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Badge « Exercice pratique · n/total ».
        Align(
          alignment: Alignment.centerLeft,
          child: LearningTag(
            icon: AppIcons.practice,
            label: l10n.practiceSession(step.number, step.total),
            color: AppColors.warningLedge,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Semantics(
          header: true,
          child: Text(l10n.practiceTitle, style: AppTextStyles.h2),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Mot à reproduire + éventuel bouton TTS.
        Row(
          children: [
            Flexible(
              child: Text(
                step.sign.word,
                style: AppTextStyles.h1.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            SpeakWordButton(word: step.sign.word),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        // ≥ 600 px : côte à côte ; sinon empilé (référence puis caméra plus haute).
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 600) {
              return SizedBox(
                height: 340,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: reference),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(child: learner),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 220, child: reference),
                const SizedBox(height: AppSpacing.m),
                SizedBox(height: 360, child: learner),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.m),
        // Statut annoncé aux lecteurs d'écran (live region).
        Semantics(
          liveRegion: true,
          child: Text(
            _status(l10n),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: switch (_phase) {
                _Phase.success => AppColors.success,
                _Phase.failure => AppColors.error,
                _Phase.recording => AppColors.error,
                _ => AppColors.textSecondary(context),
              },
            ),
          ),
        ),
        // Conseil après un échec de reconnaissance.
        if (_phase == _Phase.failure) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.practiceFailureHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        // Boutons d'action selon la phase.
        ..._actions(l10n),
      ],
    );
  }

  /// Construit la liste des boutons selon la phase courante.
  List<Widget> _actions(AppLocalizations l10n) {
    Widget big(Widget button) => SizedBox(height: 56, child: button);
    final shape = RoundedRectangleBorder(borderRadius: AppRadius.radiusL);

    switch (_phase) {
      case _Phase.idle:
        // Activer la caméra, ou passer directement en auto-évaluation.
        return [
          big(FilledButton.icon(
            style: FilledButton.styleFrom(shape: shape, textStyle: AppTextStyles.button),
            onPressed: _enableCamera,
            icon: const Icon(AppIcons.camera),
            label: Text(l10n.practiceEnableCamera),
          )),
          const SizedBox(height: AppSpacing.s),
          TextButton(onPressed: _openSelfCheck, child: Text(l10n.practiceNoCamera)),
        ];
      case _Phase.preview:
        // Bouton rouge « Je signe ! » + option sans caméra.
        return [
          big(FilledButton.icon(
            autofocus: true,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: shape,
              textStyle: AppTextStyles.button,
            ),
            onPressed: _start,
            icon: const Icon(AppIcons.record),
            label: Text(l10n.practiceStart),
          )),
          const SizedBox(height: AppSpacing.s),
          TextButton(onPressed: _openSelfCheck, child: Text(l10n.practiceNoCamera)),
        ];
      // Pendant le compte à rebours / l'enregistrement / l'analyse : pas d'action.
      case _Phase.countdown:
      case _Phase.recording:
      case _Phase.analyzing:
        return const [];
      case _Phase.success:
        // Mention optionnelle si c'était une auto-évaluation.
        return [
          if (_selfRated)
            Text(
              l10n.practiceSelfRated,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
            ),
        ];
      case _Phase.failure:
        // Réessayer après un échec ML.
        return [
          big(OutlinedButton.icon(
            style: OutlinedButton.styleFrom(shape: shape, textStyle: AppTextStyles.button),
            onPressed: _retry,
            icon: const Icon(AppIcons.refresh),
            label: Text(l10n.practiceRetry),
          )),
        ];
      case _Phase.selfCheck:
        // « Pas encore » / « Je l'ai réussi ».
        return [
          Row(
            children: [
              Expanded(
                child: big(OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(shape: shape, textStyle: AppTextStyles.button),
                  onPressed: () => _rateSelf(false),
                  icon: const Icon(AppIcons.refresh),
                  label: Text(l10n.practiceSelfNo),
                )),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: big(FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: shape,
                    textStyle: AppTextStyles.button,
                  ),
                  onPressed: () => _rateSelf(true),
                  icon: const Icon(AppIcons.checkBold),
                  label: Text(l10n.practiceSelfYes),
                )),
              ),
            ],
          ),
        ];
    }
  }

  /// Contenu du panneau « Vous » : message, caméra, ou overlays selon la phase.
  Widget _stage(AppLocalizations l10n) {
    if (!_cameraOn) {
      final selfCheck = _phase == _Phase.selfCheck || _selfRated;
      return _StageMessage(
        icon: selfCheck ? AppIcons.practice : AppIcons.camera,
        title: selfCheck ? l10n.practiceSelfCheckTitle : null,
        message: selfCheck ? l10n.practiceSelfCheckMessage : l10n.practiceCameraHint,
      );
    }

    // Overlay au-dessus de la caméra selon la phase.
    final overlay = switch (_phase) {
      _Phase.countdown => _CountdownBadge(count: _count),
      _Phase.recording => const _RecordingOverlay(),
      _Phase.analyzing => const ColoredBox(
          color: Colors.black45,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      _Phase.success => const _VerdictBadge(ok: true),
      _Phase.failure => const _VerdictBadge(ok: false),
      _ => null,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        const CameraView(active: true),
        ?overlay,
      ],
    );
  }
}

/// Panneau arrondi avec un libellé en badge (référence ou caméra).
class _Panel extends StatelessWidget {
  const _Panel({required this.label, required this.child, this.dark = false});

  final String label;
  final Widget child;
  /// Fond noir (flux caméra) vs fond neutre (média du signe).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: ClipRRect(
        borderRadius: AppRadius.radiusL,
        child: ColoredBox(
          color: dark ? Colors.black : AppColors.neutral(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.all(dark ? 0 : AppSpacing.s),
                child: child,
              ),
              // Badge de libellé en haut à gauche.
              Positioned(
                top: AppSpacing.s,
                left: AppSpacing.s,
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s + 2, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: AppRadius.radiusCircular,
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

/// Message centré dans le panneau caméra (avant activation ou en self-check).
class _StageMessage extends StatelessWidget {
  const _StageMessage({required this.icon, required this.message, this.title});

  final IconData icon;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 48),
            const SizedBox(height: AppSpacing.m),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grand chiffre du compte à rebours (avec scale-in si animations autorisées).
class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final badge = Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 64, height: 1),
      ),
    );
    return Center(
      child: ExcludeSemantics(
        child: reduced
            ? badge
            : TweenAnimationBuilder<double>(
                // Relance l'animation à chaque nouvelle valeur.
                key: ValueKey(count),
                tween: Tween(begin: 1.4, end: 1),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: badge,
              ),
      ),
    );
  }
}

/// Overlay pendant l'enregistrement : pastille REC + barre de progression.
class _RecordingOverlay extends StatelessWidget {
  const _RecordingOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        // Pastille « Enregistrement » en haut à droite.
        Positioned(
          top: AppSpacing.s,
          right: AppSpacing.s,
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s + 2, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: AppRadius.radiusCircular,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.record, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    l10n.practiceRecording,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Barre qui se remplit sur toute la durée d'enregistrement.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: practiceRecordingDuration,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: AppColors.error,
              backgroundColor: Colors.white24,
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge de verdict (succès ou échec) superposé à la caméra.
class _VerdictBadge extends StatelessWidget {
  const _VerdictBadge({required this.ok});

  /// true = succès (vert), false = échec (rouge).
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.error;
    return ColoredBox(
      color: color.withValues(alpha: 0.25),
      child: Center(
        child: ExcludeSemantics(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(ok ? AppIcons.checkBold : AppIcons.xBold, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}
