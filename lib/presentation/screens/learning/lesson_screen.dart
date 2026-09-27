import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../data/models/sign.dart';
import '../../../domain/learning/lesson_builder.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/sign_media.dart';
import '../../widgets/skeletons.dart';
import '../../../domain/providers/error_text.dart';

/// Caps the media so the question and the answers stay on screen together.
const double _mediaMaxHeight = 320;

void _leaveLesson(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.goNamed(AppRoutes.learningName);
  }
}

class LessonScreen extends ConsumerWidget {
  final String id;
  const LessonScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(lessonContentProvider(id));

    return Scaffold(
      body: SafeArea(
        child: contentAsync.when(
          data: (content) => _LessonPlayer(key: ValueKey(content.id), content: content),
          loading: () => const _LessonSkeleton(),
          error: (error, _) => AppEmptyState(
            icon: AppIcons.error,
            title: l10n.errorGeneric,
            message: ref.userErrorText(error, l10n),
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(lessonContentProvider(id)),
          ),
        ),
      ),
    );
  }
}

enum _Phase { playing, saving, saveError, done }

class _LessonPlayer extends ConsumerStatefulWidget {
  const _LessonPlayer({super.key, required this.content});

  final LessonContent content;

  @override
  ConsumerState<_LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends ConsumerState<_LessonPlayer> {
  late final List<LessonStep> _steps;
  late final int _questionCount;
  late final int _introCount;

  int _index = 0;
  String? _selectedId;
  bool _checked = false;
  bool _lastCorrect = false;
  int _firstTryCorrect = 0;

  _Phase _phase = _Phase.playing;
  LessonResult? _result;

  final _focusNode = FocusNode(debugLabel: 'lesson');

  @override
  void initState() {
    super.initState();
    _steps = buildLessonSteps(widget.content);
    _questionCount = _steps.where((s) => s.isQuestion).length;
    _introCount = _steps.length - _questionCount;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  LessonStep get _step => _steps[_index];

  bool get _hasStarted => _index > 0 || _checked;

  double get _progress {
    if (_steps.isEmpty) return 0;
    final done = _index + (_checked || _step is IntroStep ? 1 : 0);
    return (done / _steps.length).clamp(0.0, 1.0);
  }

  void _select(String signId) {
    if (_checked || _phase != _Phase.playing) return;
    setState(() => _selectedId = signId);
  }

  void _selectByIndex(int index) {
    final step = _step;
    final options = switch (step) {
      RecognizeStep(:final options) => options,
      FindStep(:final options) => options,
      IntroStep() => const <Sign>[],
    };
    if (index < options.length) _select(options[index].id);
  }

  void _primaryAction() {
    if (_phase != _Phase.playing) return;
    final step = _step;
    if (step is IntroStep || _checked) {
      _next();
    } else if (_selectedId != null) {
      _check();
    }
  }

  void _check() {
    final step = _step;
    final correct = _selectedId == step.sign.id;

    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _checked = true;
      _lastCorrect = correct;
      if (!step.isRetry && correct) _firstTryCorrect++;
      // Comme dans Duolingo, une question ratée revient en fin de leçon.
      if (!correct && !step.isRetry) _steps.add(step.asRetry());
    });
  }

  void _next() {
    if (_index + 1 >= _steps.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _selectedId = null;
      _checked = false;
    });
  }

  Future<void> _finish() async {
    setState(() => _phase = _Phase.saving);

    // Une leçon sans question (signes sans visuel) compte ses présentations :
    // l'apprenant les a vues, il n'y avait rien d'autre à réussir.
    final total = _questionCount == 0 ? _introCount : _questionCount;
    final correct = _questionCount == 0 ? _introCount : _firstTryCorrect;

    try {
      final result = await ref.read(learningRepositoryProvider).completeLesson(
            lessonId: widget.content.id,
            correct: correct,
            total: total,
          );
      ref
        ..invalidate(learningProgressProvider)
        ..invalidate(learnerSummaryProvider);
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.done;
      });
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.saveError);
    }
  }

  Future<void> _confirmQuit() async {
    if (!_hasStarted || _phase == _Phase.done) {
      _leaveLesson(context);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final quit = await showConfirmDialog(
      context,
      title: l10n.lessonQuitConfirmTitle,
      message: l10n.lessonQuitConfirmMessage,
      confirmLabel: l10n.lessonQuitConfirm,
      cancelLabel: l10n.lessonKeepGoing,
      destructive: true,
    );
    if (quit && mounted) _leaveLesson(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_steps.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.signLanguage,
        title: widget.content.title,
        message: l10n.lessonNotEnoughSigns,
        actionLabel: l10n.back,
        onAction: () => _leaveLesson(context),
      );
    }

    if (_phase != _Phase.playing) {
      return _CompletionView(
        phase: _phase,
        result: _result,
        correct: _questionCount == 0 ? _introCount : _firstTryCorrect,
        total: _questionCount == 0 ? _introCount : _questionCount,
        onRetrySave: _finish,
        onFinish: () => _leaveLesson(context),
      );
    }

    return PopScope(
      canPop: !_hasStarted,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _primaryAction,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _primaryAction,
          const SingleActivator(LogicalKeyboardKey.space): _primaryAction,
          const SingleActivator(LogicalKeyboardKey.digit1): () => _selectByIndex(0),
          const SingleActivator(LogicalKeyboardKey.digit2): () => _selectByIndex(1),
          const SingleActivator(LogicalKeyboardKey.digit3): () => _selectByIndex(2),
          const SingleActivator(LogicalKeyboardKey.digit4): () => _selectByIndex(3),
          const SingleActivator(LogicalKeyboardKey.escape): _confirmQuit,
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Column(
            children: [
              _TopBar(
                progress: _progress,
                progressLabel: l10n.lessonProgressLabel(
                  (_index + 1).clamp(1, _steps.length),
                  _steps.length,
                ),
                onClose: _confirmQuit,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                  child: PageContainer.reading(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey('$_index-${_step.sign.id}'),
                        child: _buildStep(context, _step),
                      ),
                    ),
                  ),
                ),
              ),
              _BottomBar(
                step: _step,
                checked: _checked,
                correct: _lastCorrect,
                canCheck: _selectedId != null,
                onPressed: _primaryAction,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, LessonStep step) {
    return switch (step) {
      IntroStep() => _IntroView(sign: step.sign),
      RecognizeStep(:final options) => _RecognizeView(
          sign: step.sign,
          options: options,
          selectedId: _selectedId,
          checked: _checked,
          onSelect: _select,
        ),
      FindStep(:final options) => _FindView(
          sign: step.sign,
          options: options,
          selectedId: _selectedId,
          checked: _checked,
          onSelect: _select,
        ),
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.progress,
    required this.progressLabel,
    required this.onClose,
  });

  final double progress;
  final String progressLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: PageContainer.reading(
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.lessonQuit,
              onPressed: onClose,
              icon: const Icon(AppIcons.close),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Semantics(
                label: progressLabel,
                value: '${(progress * 100).round()} %',
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => ClipRRect(
                    borderRadius: AppRadius.radiusCircular,
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 14,
                      color: AppColors.success,
                      backgroundColor: AppColors.neutral(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
          ],
        ),
      ),
    );
  }
}

class _PromptTitle extends StatelessWidget {
  const _PromptTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: AppTextStyles.h2),
    );
  }
}

class _MediaFrame extends StatelessWidget {
  const _MediaFrame({required this.sign});

  final Sign sign;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _mediaMaxHeight + 56),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: SignMedia(key: ValueKey(sign.id), sign: sign),
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({required this.sign});

  final Sign sign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs + 2),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.radiusCircular,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.achievement, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                l10n.lessonNewSign,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Center(child: _MediaFrame(sign: sign)),
        const SizedBox(height: AppSpacing.l),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(sign.word, style: AppTextStyles.h1),
        ),
        if (sign.description != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            sign.description!,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary(context)),
          ),
        ],
      ],
    );
  }
}

class _RecognizeView extends StatelessWidget {
  const _RecognizeView({
    required this.sign,
    required this.options,
    required this.selectedId,
    required this.checked,
    required this.onSelect,
  });

  final Sign sign;
  final List<Sign> options;
  final String? selectedId;
  final bool checked;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PromptTitle(l10n.lessonWhatSign),
        const SizedBox(height: AppSpacing.l),
        Center(child: _MediaFrame(sign: sign)),
        const SizedBox(height: AppSpacing.l),
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s + 4),
          _TextOption(
            index: i,
            label: options[i].word,
            state: _optionState(options[i].id, sign.id, selectedId, checked),
            onTap: () => onSelect(options[i].id),
          ),
        ],
      ],
    );
  }
}

class _FindView extends StatelessWidget {
  const _FindView({
    required this.sign,
    required this.options,
    required this.selectedId,
    required this.checked,
    required this.onSelect,
  });

  final Sign sign;
  final List<Sign> options;
  final String? selectedId;
  final bool checked;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PromptTitle(l10n.lessonFindSign(sign.word)),
        const SizedBox(height: AppSpacing.l),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.m,
            mainAxisSpacing: AppSpacing.m,
            childAspectRatio: 0.82,
          ),
          itemCount: options.length,
          itemBuilder: (context, i) => _MediaOption(
            index: i,
            sign: options[i],
            state: _optionState(options[i].id, sign.id, selectedId, checked),
            onTap: () => onSelect(options[i].id),
          ),
        ),
      ],
    );
  }
}

enum _OptionState { idle, selected, correct, wrong, dimmed }

_OptionState _optionState(String optionId, String answerId, String? selectedId, bool checked) {
  if (!checked) {
    return optionId == selectedId ? _OptionState.selected : _OptionState.idle;
  }
  if (optionId == answerId) return _OptionState.correct;
  if (optionId == selectedId) return _OptionState.wrong;
  return _OptionState.dimmed;
}

class _OptionColors {
  const _OptionColors(this.border, this.fill, this.foreground);

  final Color border;
  final Color fill;
  final Color? foreground;

  static _OptionColors of(BuildContext context, _OptionState state) {
    switch (state) {
      case _OptionState.idle:
      case _OptionState.dimmed:
        return _OptionColors(AppColors.border(context), AppColors.surface(context), null);
      case _OptionState.selected:
        return const _OptionColors(AppColors.primary, AppColors.primarySoft, AppColors.primary);
      case _OptionState.correct:
        return const _OptionColors(AppColors.success, AppColors.successSoft, AppColors.success);
      case _OptionState.wrong:
        return const _OptionColors(AppColors.error, AppColors.errorSoft, AppColors.error);
    }
  }
}

/// The number shown next to an answer doubles as its keyboard shortcut.
class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.index, required this.state});

  final int index;
  final _OptionState state;

  @override
  Widget build(BuildContext context) {
    final colors = _OptionColors.of(context, state);
    final icon = switch (state) {
      _OptionState.correct => AppIcons.checkBold,
      _OptionState.wrong => AppIcons.xBold,
      _ => null,
    };
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.radiusS,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: icon != null
          ? Icon(icon, size: 16, color: colors.foreground)
          : Text(
              '${index + 1}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.foreground ?? AppColors.textSecondary(context),
              ),
            ),
    );
  }
}

String _optionSemantics(AppLocalizations l10n, int index, String label, _OptionState state) {
  final base = '${l10n.lessonOptionLabel(index + 1)}: $label';
  return switch (state) {
    _OptionState.correct => '$base, ${l10n.lessonCorrect}',
    _OptionState.wrong => '$base, ${l10n.lessonIncorrect}',
    _ => base,
  };
}

class _TextOption extends StatelessWidget {
  const _TextOption({
    required this.index,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final int index;
  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _OptionColors.of(context, state);

    return Semantics(
      button: true,
      selected: state == _OptionState.selected,
      label: _optionSemantics(l10n, index, label, state),
      excludeSemantics: true,
      child: Opacity(
        opacity: state == _OptionState.dimmed ? 0.5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: colors.fill,
            borderRadius: AppRadius.radiusM,
            border: Border.all(color: colors.border, width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.radiusM,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                  child: Row(
                    children: [
                      _KeyBadge(index: index, state: state),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Text(
                          label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  const _MediaOption({
    required this.index,
    required this.sign,
    required this.state,
    required this.onTap,
  });

  final int index;
  final Sign sign;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _OptionColors.of(context, state);
    final revealed = state == _OptionState.correct || state == _OptionState.wrong;

    return Semantics(
      button: true,
      selected: state == _OptionState.selected,
      label: _optionSemantics(
        l10n,
        index,
        revealed ? sign.word : l10n.lessonOptionLabel(index + 1),
        state,
      ),
      excludeSemantics: true,
      child: Opacity(
        opacity: state == _OptionState.dimmed ? 0.5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: colors.fill,
            borderRadius: AppRadius.radiusL,
            border: Border.all(color: colors.border, width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.radiusL,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SignMedia(
                        sign: sign,
                        preferStill: true,
                        showReplay: false,
                        borderRadius: AppRadius.radiusM,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      children: [
                        _KeyBadge(index: index, state: state),
                        if (revealed) ...[
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              sign.word,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.checked,
    required this.correct,
    required this.canCheck,
    required this.onPressed,
  });

  final LessonStep step;
  final bool checked;
  final bool correct;
  final bool canCheck;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIntro = step is IntroStep;

    final Color background;
    final Color accent;
    if (!checked) {
      background = AppColors.surface(context);
      accent = AppColors.primary;
    } else if (correct) {
      background = AppColors.successSoft;
      accent = AppColors.success;
    } else {
      background = AppColors.errorSoft;
      accent = AppColors.error;
    }

    final label = isIntro || checked ? l10n.lessonContinue : l10n.lessonCheck;
    final enabled = isIntro || checked || canCheck;

    final button = SizedBox(
      height: 56,
      width: context.isMobile ? double.infinity : 240,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
          textStyle: AppTextStyles.button,
        ),
        child: Text(label),
      ),
    );

    final feedback = !checked
        ? null
        : Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Icon(
                    correct ? AppIcons.checkBold : AppIcons.xBold,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        correct ? l10n.lessonCorrect : l10n.lessonIncorrect,
                        style: AppTextStyles.h3.copyWith(color: accent),
                      ),
                      if (!correct) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.lessonCorrectAnswer(step.sign.word),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: background,
        border: Border(top: BorderSide(color: checked ? background : AppColors.border(context))),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
      child: PageContainer.reading(
        child: context.isMobile
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (feedback != null) ...[feedback, const SizedBox(height: AppSpacing.m)],
                  button,
                ],
              )
            : Row(
                children: [
                  Expanded(child: feedback ?? const SizedBox.shrink()),
                  const SizedBox(width: AppSpacing.l),
                  button,
                ],
              ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.phase,
    required this.result,
    required this.correct,
    required this.total,
    required this.onRetrySave,
    required this.onFinish,
  });

  final _Phase phase;
  final LessonResult? result;
  final int correct;
  final int total;
  final VoidCallback onRetrySave;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final perfect = correct == total;
    final accuracy = total == 0 ? 100 : (correct * 100 / total).round();

    final Widget details;
    switch (phase) {
      case _Phase.saving:
        details = const Padding(
          padding: EdgeInsets.all(AppSpacing.l),
          child: CircularProgressIndicator(),
        );
      case _Phase.saveError:
        details = Column(
          children: [
            Text(
              l10n.lessonSaveError,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.m),
            OutlinedButton.icon(
              onPressed: onRetrySave,
              icon: const Icon(AppIcons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        );
      case _Phase.done:
      case _Phase.playing:
        final r = result;
        details = Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.m,
          children: [
            _ResultStat(
              icon: AppIcons.pointsActive,
              color: AppColors.primary,
              label: l10n.lessonXp,
              value: l10n.lessonXpEarned(r?.xpEarned ?? 0),
            ),
            _ResultStat(
              icon: AppIcons.goal,
              color: AppColors.success,
              label: l10n.lessonAccuracy,
              value: '$accuracy %',
            ),
            _ResultStat(
              icon: AppIcons.streakActive,
              color: AppColors.warning,
              label: l10n.lessonStreak,
              value: l10n.lessonDays(r?.summary.currentStreak ?? 0),
            ),
          ],
        );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: PageContainer.reading(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: AppColors.warningSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.trophy, size: 56, color: AppColors.warning),
              ),
              const SizedBox(height: AppSpacing.l),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  l10n.lessonCompleteTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1,
                ),
              ),
              if (perfect) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.lessonCompletePerfect,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary(context)),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              details,
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 56,
                width: context.isMobile ? double.infinity : 280,
                child: FilledButton(
                  autofocus: true,
                  onPressed: phase == _Phase.saving ? null : onFinish,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
                    textStyle: AppTextStyles.button,
                  ),
                  child: Text(l10n.lessonFinish),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: AppPanel(
        semanticLabel: '$label: $value',
        padding: const EdgeInsets.all(AppSpacing.m),
        child: ExcludeSemantics(
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: AppSpacing.s),
              Text(value, style: AppTextStyles.h3.copyWith(color: color)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonSkeleton extends StatelessWidget {
  const _LessonSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: AppLocalizations.of(context)!.loading,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.m),
        child: PageContainer.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  SkeletonBlock.circle(size: 40),
                  SizedBox(width: AppSpacing.m),
                  Expanded(child: SkeletonBlock(height: 14, radius: AppRadius.circular)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SkeletonBlock(width: 260, height: 26),
              const SizedBox(height: AppSpacing.l),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _mediaMaxHeight),
                child: const AspectRatio(
                  aspectRatio: 4 / 3,
                  child: SkeletonBlock(height: double.infinity, radius: AppRadius.l),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s + 4),
                const SkeletonBlock(height: 60, radius: AppRadius.m),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
