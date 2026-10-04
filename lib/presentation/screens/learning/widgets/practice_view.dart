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
class PracticeView extends ConsumerStatefulWidget {
  const PracticeView({
    super.key,
    required this.step,
    required this.onResult,
    required this.onReset,
    this.embedded = false,
  });

  /// Étape de pratique (signe + numéro / total).
  final PracticeStep step;

  /// Verdict de la dernière tentative (true = réussi).
  final ValueChanged<bool> onResult;

  /// Nouvelle tentative : l'ancien verdict ne compte plus.
  final VoidCallback onReset;

  /// Mode dictionnaire : en-tête compact, layout flex (pas d'overflow).
  final bool embedded;

  @override
  ConsumerState<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends ConsumerState<PracticeView> {
  _Phase _phase = _Phase.idle;
  int _count = practiceCountdown;
  bool _unavailable = false;
  bool _selfRated = false;
  int _run = 0;
  CameraState? _camera;
  ProviderContainer? _container;

  bool get _cameraOn => switch (_phase) {
        _Phase.preview ||
        _Phase.countdown ||
        _Phase.recording ||
        _Phase.analyzing =>
          true,
        _Phase.success || _Phase.failure => !_selfRated,
        _ => false,
      };

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    _run++;
    if (_phase == _Phase.recording) {
      _camera?.stopVideoRecording().catchError((_) => null);
    }
    final cam = _camera;
    final container = _container;
    if (cam != null) {
      unawaited(cam.releaseCamera());
    } else if (container != null) {
      unawaited(container.read(cameraStateProvider.notifier).releaseCamera());
    }
    super.dispose();
  }

  void _set(_Phase phase) {
    if (!mounted) return;
    final wasOn = _cameraOn;
    setState(() => _phase = phase);
    final nowOn = switch (phase) {
      _Phase.preview ||
      _Phase.countdown ||
      _Phase.recording ||
      _Phase.analyzing =>
        true,
      _Phase.success || _Phase.failure => !_selfRated,
      _ => false,
    };
    if (wasOn && !nowOn) {
      unawaited(ref.read(cameraStateProvider.notifier).releaseCamera());
    }
  }

  void _enableCamera() => _set(_Phase.preview);

  void _openSelfCheck({bool unavailable = false}) {
    _run++;
    setState(() {
      _unavailable = unavailable;
      _phase = _Phase.selfCheck;
    });
    unawaited(ref.read(cameraStateProvider.notifier).releaseCamera());
  }

  Future<void> _start() async {
    final run = ++_run;
    widget.onReset();
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

  Future<void> _record(int run) async {
    try {
      final controller = await ref.read(cameraStateProvider.notifier).ensureCamera();
      if (!mounted || run != _run) return;
      if (controller == null || !controller.value.isInitialized) {
        _openSelfCheck(unavailable: true);
        return;
      }
      final camera = ref.read(cameraStateProvider.notifier);
      _camera = camera;
      await camera.startVideoRecording();
      if (!mounted || run != _run) return;
      _set(_Phase.recording);
      HapticFeedback.mediumImpact();

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
      _verdict(practiceMatches(widget.step.sign.word, result));
    } catch (_) {
      if (mounted && run == _run) _openSelfCheck(unavailable: true);
    }
  }

  void _verdict(bool ok) {
    if (ok) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    _set(ok ? _Phase.success : _Phase.failure);
    widget.onResult(ok);
  }

  void _rateSelf(bool ok) {
    setState(() => _selfRated = true);
    _verdict(ok);
  }

  void _retry() {
    _run++;
    widget.onReset();
    setState(() {
      _phase = _unavailable || _selfRated ? _Phase.selfCheck : _Phase.preview;
      _selfRated = false;
    });
  }

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
    final embedded = widget.embedded;

    final header = _PracticeHeader(
      embedded: embedded,
      step: step,
      l10n: l10n,
    );

    final statusBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
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
        if (_phase == _Phase.failure) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.practiceFailureHint,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        ..._actions(l10n),
      ],
    );

    if (embedded) {
      // Dictionnaire : tout tient dans l'Expanded parent, sans overflow.
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: AppSpacing.m),
            Expanded(child: _panels(l10n)),
            const SizedBox(height: AppSpacing.m),
            statusBlock,
          ],
        ),
      );
    }

    // Leçon : souvent dans un ScrollView — hauteurs plafonnées, pas de flex.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.l),
        _panels(l10n, maxPanelHeight: 280),
        const SizedBox(height: AppSpacing.m),
        statusBlock,
      ],
    );
  }

  Widget _panels(AppLocalizations l10n, {double? maxPanelHeight}) {
    final step = widget.step;
    final reference = _Panel(
      label: l10n.practiceReference,
      child: SignMedia(key: ValueKey(step.sign.id), sign: step.sign),
    );
    final learner = _Panel(
      label: l10n.practiceYou,
      dark: true,
      child: _stage(l10n),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        if (wide) {
          final h = maxPanelHeight ??
              (constraints.maxHeight.isFinite
                  ? constraints.maxHeight.clamp(180.0, 360.0)
                  : 280.0);
          return SizedBox(
            height: h,
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

        // Empilé : partage l'espace dispo (embedded) ou hauteurs fixes plafonnées.
        if (maxPanelHeight == null && constraints.maxHeight.isFinite) {
          final gap = AppSpacing.m;
          final each = ((constraints.maxHeight - gap) / 2).clamp(140.0, 280.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: each, child: reference),
              SizedBox(height: gap),
              Expanded(child: learner),
            ],
          );
        }

        final refH = (maxPanelHeight ?? 200).clamp(140.0, 220.0);
        final youH = (maxPanelHeight ?? 240).clamp(160.0, 280.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: refH, child: reference),
            const SizedBox(height: AppSpacing.m),
            SizedBox(height: youH, child: learner),
          ],
        );
      },
    );
  }

  List<Widget> _actions(AppLocalizations l10n) {
    Widget big(Widget button) => SizedBox(height: 52, child: button);
    final shape = RoundedRectangleBorder(borderRadius: AppRadius.radiusL);

    switch (_phase) {
      case _Phase.idle:
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
      case _Phase.countdown:
      case _Phase.recording:
      case _Phase.analyzing:
        return const [];
      case _Phase.success:
        return [
          if (_selfRated)
            Text(
              l10n.practiceSelfRated,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
        ];
      case _Phase.failure:
        return [
          big(OutlinedButton.icon(
            style: OutlinedButton.styleFrom(shape: shape, textStyle: AppTextStyles.button),
            onPressed: _retry,
            icon: const Icon(AppIcons.refresh),
            label: Text(l10n.practiceRetry),
          )),
        ];
      case _Phase.selfCheck:
        return [
          Row(
            children: [
              Expanded(
                child: big(OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: shape,
                    textStyle: AppTextStyles.button,
                  ),
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

  Widget _stage(AppLocalizations l10n) {
    if (!_cameraOn) {
      final selfCheck = _phase == _Phase.selfCheck || _selfRated;
      return _StageMessage(
        icon: selfCheck ? AppIcons.practice : AppIcons.camera,
        title: selfCheck ? l10n.practiceSelfCheckTitle : null,
        message: selfCheck ? l10n.practiceSelfCheckMessage : l10n.practiceCameraHint,
      );
    }

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

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({
    required this.embedded,
    required this.step,
    required this.l10n,
  });

  final bool embedded;
  final PracticeStep step;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  step.sign.word,
                  style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              SpeakWordButton(word: step.sign.word),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.practiceSignHint(step.sign.word),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.label, required this.child, this.dark = false});

  final String label;
  final Widget child;
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
              Positioned(
                top: AppSpacing.s,
                left: AppSpacing.s,
                child: ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s + 2,
                      vertical: 4,
                    ),
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
            Icon(icon, color: Colors.white70, size: 40),
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

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final badge = Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 56, height: 1),
      ),
    );
    return Center(
      child: ExcludeSemantics(
        child: reduced
            ? badge
            : TweenAnimationBuilder<double>(
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

class _RecordingOverlay extends StatelessWidget {
  const _RecordingOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned(
          top: AppSpacing.s,
          right: AppSpacing.s,
          child: ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s + 2,
                vertical: 4,
              ),
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

class _VerdictBadge extends StatelessWidget {
  const _VerdictBadge({required this.ok});

  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.error;
    return ColoredBox(
      color: color.withValues(alpha: 0.25),
      child: Center(
        child: ExcludeSemantics(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              ok ? AppIcons.checkBold : AppIcons.xBold,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
