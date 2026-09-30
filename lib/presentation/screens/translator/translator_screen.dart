import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/character_constants.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/sign.dart';
import '../../../data/models/sign_landmarks.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/spell_frame_prep.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/camera_provider.dart';
import '../../../domain/providers/character_provider.dart';
import '../../../domain/providers/error_text.dart';
import '../../../domain/providers/ml_model_provider.dart';
import '../../../domain/providers/session_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../domain/providers/sign_view_provider.dart';
import '../../../domain/providers/stt_provider.dart';
import '../../../domain/providers/three_d_settings_provider.dart';
import '../../../domain/providers/translator_provider.dart';
import '../../../domain/providers/tts_provider.dart';
import '../../../domain/translator/spelling_buffer.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/camera/camera_view.dart';
import '../../widgets/landmark_viewer/landmark_viewer.dart';
import '../../widgets/sign_media.dart';
import '../../widgets/skeletons.dart';

/// From this width the stage and the side column sit next to each other.
const double _splitBreakpoint = 900;
const double _sideColumnWidth = 380;
const double _actionHeight = 56;

enum _SignStatus { idle, translating, done, unavailable }

Duration _motion(BuildContext context) => MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 220);

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final _textController = TextEditingController();
  final _textFocus = FocusNode();
  String _searchQuery = '';

  XFile? _selectedFile;
  bool _isImage = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  _SignStatus _signStatus = _SignStatus.idle;
  String? _translationResult;
  double? _confidence;
  String? _errorMessage;

  /// Bumped on every start or stop: a late answer must not overwrite the
  /// current state.
  int _inferenceRun = 0;

  /// Session d'épellation côté ML (conserve la phrase entre les frames).
  String? _spellSessionId;

  /// Tampon local de secours si le serveur ne renvoie pas encore de texte.
  final SpellingBuffer _spellBuffer = SpellingBuffer();

  /// Dernière lettre détectée (affichage live).
  String? _lastLetter;

  /// One history session per direction for the time the screen is open.
  final Map<String, String> _sessions = {};

  // `ref` is unusable in dispose(): keep what it needs.
  late final ProviderContainer _container;
  late final SessionRepository _sessionRepository;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    _sessionRepository = ref.read(sessionRepositoryProvider);
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    final container = _container;
    // Providers must not change while the tree is being torn down.
    Future.microtask(() => container.read(translatorStateProvider.notifier).stop());
    for (final id in _sessions.values) {
      _sessionRepository.closeSession(id).catchError((_) {});
    }
    super.dispose();
  }

  /// Saves a translation to the user's history; failures never block the UI.
  Future<void> _record({
    required String direction,
    String? sourceText,
    String? translatedText,
    List<String>? signIds,
    double? confidence,
    int? inferenceTimeMs,
    String? modelVersion,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      _sessions[direction] = await ref.read(sessionRepositoryProvider).recordTranslation(
            userId: user.id,
            sessionId: _sessions[direction],
            direction: direction,
            sourceText: sourceText,
            translatedText: translatedText,
            signIds: signIds,
            confidence: confidence,
            inferenceTimeMs: inferenceTimeMs,
            modelVersion: modelVersion,
          );
      ref.invalidate(userHistoryProvider);
    } catch (e) {
      debugPrint('[history] translation not saved: $e');
    }
  }

  Future<void> _runInference() async {
    // Fichier importé (image/vidéo) : une seule passe.
    if (_selectedFile != null) {
      await _runOnceFromFile();
      return;
    }
    // Caméra : clips vidéo courts en continu → traduction temps réel.
    await _runSpellLoop();
  }

  Future<void> _runOnceFromFile() async {
    final l10n = AppLocalizations.of(context)!;
    final run = ++_inferenceRun;
    setState(() {
      _signStatus = _SignStatus.translating;
      _errorMessage = null;
    });

    List<int>? bytes;
    String? filename;
    try {
      final file = _selectedFile;
      if (file != null) {
        bytes = await file.readAsBytes();
        filename = file.name;
      }
    } catch (_) {
      bytes = null;
    }
    if (!mounted || run != _inferenceRun) return;

    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _signStatus = _SignStatus.unavailable;
        _translationResult = null;
        _confidence = null;
        _errorMessage = l10n.translCameraUnavailable;
      });
      return;
    }

    final isImage = _isImage ||
        (filename != null &&
            RegExp(r'\.(jpe?g|png|webp|bmp)$', caseSensitive: false).hasMatch(filename));
    // Même pipeline que le live : crop main + handDetected (pas de main → space).
    final hand = isImage ? prepareHandSpellFrame(bytes) : null;
    final result = isImage
        ? await ref.read(mlModelRepositoryProvider).inferSpell(
              fileBytes: hand!.jpeg,
              filename: 'hand.jpg',
              reset: true,
              threshold: 0.35,
              singleShot: true,
              handDetected: hand.detected,
            )
        : await ref.read(mlModelRepositoryProvider).infer(
              fileBytes: bytes,
              filename: filename,
            );
    if (!mounted || run != _inferenceRun) return;

    // text peut être "" (buffer vide) alors que label est correct — ne pas
    // traiter "" comme absence de résultat (?? ne bascule pas sur label).
    final text = result.text?.trim();
    final label = result.label?.trim();
    final phrase = (text != null && text.isNotEmpty)
        ? text
        : (label != null &&
                label.isNotEmpty &&
                label.toLowerCase() != 'nothing')
            ? label
            : null;
    final ok = result.ok && phrase != null && phrase.isNotEmpty;
    setState(() {
      if (ok) {
        _signStatus = _SignStatus.done;
        _translationResult = phrase;
        _confidence = result.confidence;
        _lastLetter = result.committed ?? result.label;
        _spellSessionId = result.sessionId;
      } else {
        _signStatus = _SignStatus.unavailable;
        _translationResult = null;
        _confidence = null;
        _errorMessage =
            result.errorMessage ?? l10n.inferenceUnavailableMessage;
      }
    });
    if (ok) {
      _record(
        direction: 'sign_to_text',
        translatedText: phrase,
        confidence: result.confidence,
        inferenceTimeMs: result.latencyMs?.round(),
        modelVersion: result.model?.version,
      );
    }
  }

  /// Flux caméra live : détecte la main, envoie uniquement le crop au ML.
  Future<void> _runSpellLoop() async {
    final l10n = AppLocalizations.of(context)!;
    final run = ++_inferenceRun;
    _spellBuffer.reset();
    _spellSessionId = null;
    ApiClient.resetAvailability();

    setState(() {
      _signStatus = _SignStatus.translating;
      _errorMessage = null;
      _translationResult = '';
      _confidence = null;
      _lastLetter = null;
    });

    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (mounted && DateTime.now().isBefore(deadline)) {
      try {
        final c = await ref.read(cameraStateProvider.future);
        if (c != null && c.value.isInitialized) break;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted || run != _inferenceRun) return;

    var resetSession = true;
    var consecutiveFailures = 0;
    var inferBusy = false;
    final cam = ref.read(cameraStateProvider.notifier);

    Future<void> handleHandJpeg(Uint8List jpeg, {required bool handDetected}) async {
      if (!mounted || run != _inferenceRun || inferBusy) return;
      if (!ref.read(translatorStateProvider)) return;
      inferBusy = true;
      try {
        // Même seuil / pipeline que l'import image ; live=true pour hold=1.
        final result = await ref.read(mlModelRepositoryProvider).inferSpell(
              fileBytes: jpeg,
              filename: 'hand.jpg',
              sessionId: _spellSessionId,
              reset: resetSession,
              threshold: 0.35,
              handDetected: handDetected,
              live: true,
            );
        resetSession = false;
        if (!mounted || run != _inferenceRun) return;
        if (!result.ok) {
          consecutiveFailures++;
          final hardFail = result.errorCode == 'backend_unavailable' ||
              result.errorCode == 'ml_unavailable' ||
              consecutiveFailures >= 8;
          setState(() {
            _errorMessage =
                result.errorMessage ?? l10n.inferenceUnavailableMessage;
            if (hardFail) _signStatus = _SignStatus.unavailable;
          });
          if (hardFail) {
            ref.read(translatorStateProvider.notifier).stop();
          }
          return;
        }
        consecutiveFailures = 0;
        _spellSessionId = result.sessionId ?? _spellSessionId;
        String phrase = result.text?.trim() ?? '';
        if (phrase.isEmpty &&
            result.label != null &&
            result.confidence != null &&
            result.label!.toLowerCase() != 'nothing' &&
            result.label!.toLowerCase() != 'space') {
          _spellBuffer.update(result.label, result.confidence!);
          phrase = _spellBuffer.text;
        }
        setState(() {
          _signStatus = _SignStatus.translating;
          _translationResult = phrase;
          _confidence = result.confidence;
          _lastLetter = result.committed ?? result.label;
          _errorMessage = null;
        });
      } finally {
        inferBusy = false;
      }
    }

    // Stream d'abord (même preprocess 256 + miroir que l'import) ; stills en secours.
    final streamed = await cam.startHandFrameStream(
      (jpeg, {required handDetected}) {
        unawaited(handleHandJpeg(jpeg, handDetected: handDetected));
      },
    );

    if (streamed) {
      while (mounted && run == _inferenceRun && ref.read(translatorStateProvider)) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      await cam.stopHandFrameStream();
    } else {
      while (mounted && run == _inferenceRun && ref.read(translatorStateProvider)) {
        final still = await cam.captureHandStill();
        if (!mounted || run != _inferenceRun) break;
        if (still == null) {
          consecutiveFailures++;
          if (consecutiveFailures >= 3) {
            setState(() {
              _signStatus = _SignStatus.unavailable;
              _errorMessage = l10n.translCameraUnavailable;
            });
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 220));
          continue;
        }
        consecutiveFailures = 0;
        await handleHandJpeg(still.jpeg, handDetected: still.handDetected);
        await Future<void>.delayed(CameraState.frameInterval);
      }
    }

    if (!mounted || run != _inferenceRun) return;
    final finalText = (_translationResult ?? '').trim();
    setState(() {
      _signStatus = finalText.isEmpty ? _SignStatus.idle : _SignStatus.done;
      _translationResult = finalText.isEmpty ? null : finalText;
    });
    if (finalText.isNotEmpty) {
      _record(
        direction: 'sign_to_text',
        translatedText: finalText,
        confidence: _confidence,
        modelVersion: 'fingerspell-1.0.0',
      );
    }
  }

  void _start() => ref.read(translatorStateProvider.notifier).start();

  void _stop() {
    unawaited(ref.read(cameraStateProvider.notifier).stopHandFrameStream());
    ref.read(translatorStateProvider.notifier).stop();
  }

  void _setMode(TranslationMode mode) {
    if (ref.read(translationModeStateProvider) == mode) return;
    ref.read(translationModeStateProvider.notifier).setMode(mode);
    _stop();
    ref.read(speechControllerProvider.notifier).stopListening();
  }

  Future<void> _pickFile(bool isVideo) async {
    final picker = ImagePicker();
    final file = isVideo
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;

    _videoController?.dispose();
    _chewieController?.dispose();
    setState(() {
      _selectedFile = file;
      _isImage = !isVideo;
      _videoController = null;
      _chewieController = null;
    });
    if (isVideo) _initVideo(file);
  }

  void _initVideo(XFile file) {
    final controller = kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(file.path))
        : VideoPlayerController.file(File(file.path));
    _videoController = controller;
    controller.initialize().then((_) {
      if (!mounted || _videoController != controller) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: true,
          aspectRatio: controller.value.aspectRatio,
        );
      });
    });
  }

  void _clearFile() {
    _videoController?.dispose();
    _chewieController?.dispose();
    setState(() {
      _selectedFile = null;
      _videoController = null;
      _chewieController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.hasSideNavigation;
    final isTranslating = ref.watch(translatorStateProvider);
    final mode = ref.watch(translationModeStateProvider);
    final l10n = AppLocalizations.of(context)!;

    // Also covers the mobile shell's central button, which only toggles the
    // state: inference always starts from here.
    ref.listen<bool>(translatorStateProvider, (previous, next) {
      if (next && previous != true) {
        if (ref.read(translationModeStateProvider) == TranslationMode.signToText) {
          _runInference();
        }
      } else if (!next) {
        _inferenceRun++;
        if (_signStatus == _SignStatus.translating) {
          setState(() => _signStatus = _SignStatus.idle);
        }
      }
    });

    return Scaffold(
      appBar: isWide ? null : AppBar(title: Text(l10n.translate)),
      body: PageContainer(
        width: ContentWidth.dashboard,
        padding: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.s,
                AppSpacing.m,
                AppSpacing.m,
              ),
              child: _ModeSwitch(mode: mode, onChanged: _setMode),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: _motion(context),
                child: mode == TranslationMode.signToText
                    ? _SignToTextView(
                        key: const ValueKey('sign_to_text'),
                        isTranslating: isTranslating,
                        status: _signStatus,
                        result: _translationResult,
                        confidence: _confidence,
                        lastLetter: _lastLetter,
                        errorMessage: _errorMessage,
                        selectedFile: _selectedFile,
                        isImage: _isImage,
                        chewieController: _chewieController,
                        onPickFile: _pickFile,
                        onClearFile: _clearFile,
                        onStart: _start,
                        onStop: _stop,
                        onRestart: _runInference,
                      )
                    : _TextToSignView(
                        key: const ValueKey('text_to_sign'),
                        controller: _textController,
                        focusNode: _textFocus,
                        query: _searchQuery,
                        onQueryChanged: (value) => setState(() => _searchQuery = value),
                        onTranslated: (text, signIds) => _record(
                          direction: 'text_to_sign',
                          sourceText: text,
                          signIds: signIds,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Direction switch
// ---------------------------------------------------------------------------

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final TranslationMode mode;
  final ValueChanged<TranslationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.circular),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModeTab(
                  icon: AppIcons.signLanguage,
                  label: l10n.translDirectionSignToText,
                  selected: mode == TranslationMode.signToText,
                  onTap: () => onChanged(TranslationMode.signToText),
                ),
              ),
              Expanded(
                child: _ModeTab(
                  icon: AppIcons.keyboard,
                  label: l10n.translDirectionTextToSign,
                  selected: mode == TranslationMode.textToSign,
                  onTap: () => onChanged(TranslationMode.textToSign),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      label: label,
      child: AnimatedContainer(
        duration: _motion(context),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinTouchTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s + 4,
                  vertical: AppSpacing.s,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: foreground),
                    const SizedBox(width: AppSpacing.s),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Sign -> text
// ---------------------------------------------------------------------------

class _SignToTextView extends StatelessWidget {
  const _SignToTextView({
    super.key,
    required this.isTranslating,
    required this.status,
    required this.result,
    required this.confidence,
    required this.lastLetter,
    required this.errorMessage,
    required this.selectedFile,
    required this.isImage,
    required this.chewieController,
    required this.onPickFile,
    required this.onClearFile,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  });

  final bool isTranslating;
  final _SignStatus status;
  final String? result;
  final double? confidence;
  final String? lastLetter;
  final String? errorMessage;
  final XFile? selectedFile;
  final bool isImage;
  final ChewieController? chewieController;
  final ValueChanged<bool> onPickFile;
  final VoidCallback onClearFile;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final stage = _CaptureStage(
      status: status,
      selectedFile: selectedFile,
      isImage: isImage,
      chewieController: chewieController,
      onPickFile: onPickFile,
      onClearFile: onClearFile,
    );
    final resultCard = _ResultCard(
      result: result,
      confidence: confidence,
      lastLetter: lastLetter,
      spelling: status == _SignStatus.translating && selectedFile == null,
      unavailable: status == _SignStatus.unavailable,
      errorMessage: errorMessage,
    );
    final action = _TranslateAction(
      isTranslating: isTranslating,
      busy: status == _SignStatus.translating,
      onStart: onStart,
      onStop: onStop,
      onRestart: onRestart,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _splitBreakpoint) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: stage),
                const SizedBox(width: AppSpacing.l),
                SizedBox(
                  width: _sideColumnWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: SingleChildScrollView(child: resultCard)),
                      const SizedBox(height: AppSpacing.m),
                      action,
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // On phones the bottom bar's central button starts and stops the
        // translation: the camera takes the room of the in-page button.
        final phone = !context.hasTopNavigation;
        final stageHeight = phone
            ? (constraints.maxHeight * 0.78).clamp(320.0, 720.0)
            : (constraints.maxWidth * 0.95).clamp(260.0, 460.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.xxl,
          ),
          children: [
            SizedBox(height: stageHeight, child: stage),
            if (!phone) ...[
              const SizedBox(height: AppSpacing.m),
              action,
            ],
            SizedBox(height: phone ? AppSpacing.l : AppSpacing.m),
            resultCard,
          ],
        );
      },
    );
  }
}

/// Camera (or imported file) with the state and the source control laid over
/// it, so the whole capture reads as one block.
class _CaptureStage extends StatelessWidget {
  const _CaptureStage({
    required this.status,
    required this.selectedFile,
    required this.isImage,
    required this.chewieController,
    required this.onPickFile,
    required this.onClearFile,
  });

  final _SignStatus status;
  final XFile? selectedFile;
  final bool isImage;
  final ChewieController? chewieController;
  final ValueChanged<bool> onPickFile;
  final VoidCallback onClearFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final file = selectedFile;

    final Widget content;
    if (file == null) {
      content = const CameraView();
    } else if (isImage) {
      content = kIsWeb
          ? Image.network(file.path, fit: BoxFit.contain, cacheWidth: 1280)
          : Image.file(File(file.path), fit: BoxFit.contain, cacheWidth: 1280);
    } else if (chewieController != null) {
      content = Chewie(controller: chewieController!);
    } else {
      content = const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final (statusText, statusColor) = switch (status) {
      _SignStatus.idle => (l10n.translStatusReady, Colors.white70),
      _SignStatus.translating => (l10n.translatingInProgress, AppColors.primary),
      _SignStatus.done => (l10n.translDone, AppColors.success),
      _SignStatus.unavailable => (l10n.inferenceUnavailable, AppColors.warning),
    };

    return ClipRRect(
      borderRadius: AppRadius.radiusL,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            Positioned(
              top: AppSpacing.m,
              left: AppSpacing.m,
              right: AppSpacing.m,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: _StatusPill(
                      text: statusText,
                      color: statusColor,
                      busy: status == _SignStatus.translating,
                    ),
                  ),
                  const Spacer(),
                  if (file == null)
                    _ImportButton(onPickFile: onPickFile)
                  else
                    _OverlayChip(
                      icon: AppIcons.camera,
                      label: l10n.translBackToCamera,
                      tooltip: l10n.translFileSelected(file.name),
                      onPressed: onClearFile,
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

/// State of the recognition, announced to screen readers when it changes.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color, this.busy = false});

  final String text;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s + 4,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 12,
              child: busy
                  ? CircularProgressIndicator(strokeWidth: 2, color: color)
                  : DecoratedBox(
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
            ),
            const SizedBox(width: AppSpacing.s),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  const _ImportButton({required this.onPickFile});

  final ValueChanged<bool> onPickFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MenuAnchor(
      alignmentOffset: const Offset(0, AppSpacing.xs),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.video),
          onPressed: () => onPickFile(true),
          child: Text(l10n.translImportVideo),
        ),
        MenuItemButton(
          leadingIcon: const Icon(AppIcons.image),
          onPressed: () => onPickFile(false),
          child: Text(l10n.translImportImage),
        ),
      ],
      builder: (context, menu, _) => _OverlayChip(
        icon: AppIcons.upload,
        label: l10n.translImportTooltip,
        compact: true,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }
}

/// Translucent control laid over the camera image.
class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback onPressed;

  /// Icon only; [label] is then the tooltip and the accessible name.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      foregroundColor: Colors.white,
      minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : AppSpacing.m),
      shape: const StadiumBorder(),
    );
    final button = compact
        ? IconButton(
            tooltip: label,
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 22),
          )
        : TextButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _TranslateAction extends StatelessWidget {
  const _TranslateAction({
    required this.isTranslating,
    required this.busy,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  });

  final bool isTranslating;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const shape = StadiumBorder();

    if (!isTranslating) {
      return SizedBox(
        height: _actionHeight,
        child: FilledButton.icon(
          autofocus: context.isDesktop,
          style: FilledButton.styleFrom(shape: shape),
          onPressed: onStart,
          icon: const Icon(AppIcons.play),
          label: Text(l10n.translate, style: AppTextStyles.button),
        ),
      );
    }

    return SizedBox(
      height: _actionHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: shape,
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: onStop,
              icon: const Icon(AppIcons.stop),
              label: Text(l10n.stopTranslation, style: AppTextStyles.button),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          IconButton.outlined(
            tooltip: l10n.translRestart,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(_actionHeight),
            ),
            onPressed: busy ? null : onRestart,
            icon: const Icon(AppIcons.refresh),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({
    required this.result,
    required this.confidence,
    required this.lastLetter,
    required this.spelling,
    required this.unavailable,
    required this.errorMessage,
  });

  final String? result;
  final double? confidence;
  final String? lastLetter;
  final bool spelling;
  final bool unavailable;
  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final text = (result == null || result!.isEmpty) ? null : result;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.translResultLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Sound only complements the text, which stays the reference.
              IconButton(
                tooltip: l10n.translSpeak,
                onPressed: text == null
                    ? null
                    : () => ref.read(ttsControllerProvider.notifier).speak(text),
                icon: const Icon(AppIcons.speaker),
              ),
              IconButton(
                tooltip: l10n.translCopy,
                onPressed: text == null
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: text));
                        AppSnackbar.show(
                          context,
                          message: l10n.translCopied,
                          type: AppSnackbarType.success,
                        );
                      },
                icon: const Icon(PhosphorIconsRegular.copy),
              ),
            ],
          ),
          if (spelling) ...[
            Text(
              l10n.translSpellingHint,
              style: AppTextStyles.bodySmall.copyWith(color: secondary),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          AnimatedSwitcher(
            duration: _motion(context),
            child: Semantics(
              key: ValueKey('${text}_$lastLetter'),
              liveRegion: true,
              child: SizedBox(
                width: double.infinity,
                child: text == null
                    ? Text(
                        spelling ? l10n.translatingInProgress : l10n.translResultPlaceholder,
                        style: AppTextStyles.bodyLarge.copyWith(color: secondary),
                      )
                    : SelectableText(text, style: AppTextStyles.h1),
              ),
            ),
          ),
          if (lastLetter != null &&
              lastLetter!.isNotEmpty &&
              lastLetter!.toLowerCase() != 'nothing') ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              l10n.translLastLetter(lastLetter!),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (text != null && confidence != null) ...[
            const SizedBox(height: AppSpacing.m),
            _ConfidenceBar(value: confidence!),
          ],
          if (unavailable) ...[
            const SizedBox(height: AppSpacing.m),
            _Notice(
              title: l10n.inferenceUnavailable,
              message: errorMessage ?? l10n.inferenceUnavailableMessage,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final percent = (value * 100).round().clamp(0, 100);
    final color = value >= 0.7
        ? AppColors.success
        : value >= 0.4
            ? AppColors.warning
            : AppColors.error;

    return Semantics(
      label: l10n.translConfidence(percent),
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.circular),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s + 4),
          Text(
            l10n.translConfidence(percent),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusM,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.warning, color: AppColors.warning),
          const SizedBox(width: AppSpacing.s + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text -> sign
// ---------------------------------------------------------------------------

class _TextToSignView extends ConsumerStatefulWidget {
  const _TextToSignView({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onQueryChanged,
    required this.onTranslated,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final void Function(String text, List<String> signIds) onTranslated;

  @override
  ConsumerState<_TextToSignView> createState() => _TextToSignViewState();
}

class _TextToSignViewState extends ConsumerState<_TextToSignView> {
  String? _activeWord;
  String? _selectedSignId;

  /// Set on an explicit request (submit or dictation), not on every keystroke,
  /// so the history only keeps finished phrases.
  bool _recordPending = false;

  void _setQuery(String value) {
    setState(() {
      _activeWord = null;
      _selectedSignId = null;
    });
    widget.onQueryChanged(value);
  }

  void _submit() {
    _recordPending = widget.controller.text.trim().isNotEmpty;
    _setQuery(widget.controller.text);
    widget.focusNode.requestFocus();
  }

  void _clear() {
    widget.controller.clear();
    _setQuery('');
    widget.focusNode.requestFocus();
  }

  Future<void> _toggleSpeech() async {
    final isListening = ref.read(speechControllerProvider);
    final notifier = ref.read(speechControllerProvider.notifier);
    if (isListening) {
      await notifier.stopListening();
      return;
    }
    await notifier.startListening(
      onResult: (text) {
        if (!mounted) return;
        widget.controller.text = text;
        _recordPending = text.trim().isNotEmpty;
        _setQuery(text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Dictation started from the mobile shell's central button.
    ref.listen<String>(sttResultProvider, (previous, next) {
      if (next.isNotEmpty && mounted) {
        widget.controller.text = next;
        _recordPending = true;
        _setQuery(next);
      }
    });

    final isListening = ref.watch(speechControllerProvider);
    final viewMode = ref.watch(signViewModeProvider).value ?? SignViewModeEnum.video;

    final trimmed = widget.query.trim();
    final words = trimmed.isEmpty
        ? const <String>[]
        : trimmed.split(RegExp(r'\s+')).toSet().toList(growable: false);
    // A phrase is translated word by word: one word is looked up at a time.
    final lookup = words.length > 1
        ? (words.contains(_activeWord) ? _activeWord! : words.first)
        : trimmed;

    final resultsAsync =
        lookup.isEmpty ? null : ref.watch(signSearchProvider(query: lookup));
    final signs = resultsAsync?.value ?? const <Sign>[];
    final selected = _pickSign(signs, lookup);
    final detailAsync =
        selected == null ? null : ref.watch(signDetailProvider(selected.id));
    final displaySign = detailAsync?.value ?? selected;
    final searching = resultsAsync != null && resultsAsync.isLoading && signs.isEmpty;
    final failed = resultsAsync != null && resultsAsync.hasError && signs.isEmpty;

    if (_recordPending &&
        trimmed.isNotEmpty &&
        resultsAsync != null &&
        !resultsAsync.isLoading) {
      _recordPending = false;
      final ids = selected == null ? const <String>[] : [selected.id];
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onTranslated(trimmed, ids));
    }

    final composer = _Composer(
      controller: widget.controller,
      focusNode: widget.focusNode,
      isListening: isListening,
      onChanged: _setQuery,
      onSubmit: _submit,
      onClear: _clear,
      onToggleSpeech: _toggleSpeech,
    );

    final wordPicker = words.length > 1
        ? _ChipGroup(
            label: l10n.translPickWord,
            options: [for (final w in words) (w, w)],
            selected: lookup,
            onSelected: (word) => setState(() {
              _activeWord = word;
              _selectedSignId = null;
            }),
          )
        : null;

    final alternatives = signs.length > 1
        ? _ChipGroup(
            label: l10n.translMatches,
            options: [for (final s in signs.take(12)) (s.id, s.word)],
            selected: selected?.id,
            onSelected: (id) => setState(() => _selectedSignId = id),
          )
        : null;

    final header = Row(
      children: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              displaySign?.word ?? l10n.translViewModeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: displaySign == null
                  ? AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    )
                  : AppTextStyles.h3,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        _ViewToggle(mode: viewMode),
      ],
    );

    final stage = _SignStage(
      viewMode: viewMode,
      lookup: lookup,
      searching: searching,
      failed: failed,
      sign: displaySign,
      detailLoading: detailAsync?.isLoading ?? false,
    );

    final description = displaySign?.description?.trim() ?? '';
    final details = [
      if (description.isNotEmpty)
        Text(description, style: AppTextStyles.bodyLarge),
      ?alternatives,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _splitBreakpoint) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _sideColumnWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        composer,
                        if (wordPicker != null) ...[
                          const SizedBox(height: AppSpacing.l),
                          wordPicker,
                        ],
                        for (final detail in details) ...[
                          const SizedBox(height: AppSpacing.l),
                          detail,
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const SizedBox(height: AppSpacing.s),
                      Expanded(child: stage),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // On phones the signs fill what the composer and title leave of the
        // screen.
        final stageHeight = !context.hasTopNavigation
            ? (constraints.maxHeight - 136).clamp(380.0, 900.0)
            : (constraints.maxWidth * 0.9).clamp(240.0, 420.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.xxl,
          ),
          children: [
            composer,
            if (wordPicker != null) ...[
              const SizedBox(height: AppSpacing.m),
              wordPicker,
            ],
            const SizedBox(height: AppSpacing.l),
            header,
            const SizedBox(height: AppSpacing.s),
            SizedBox(height: stageHeight, child: stage),
            for (final detail in details) ...[
              const SizedBox(height: AppSpacing.m),
              detail,
            ],
          ],
        );
      },
    );
  }

  Sign? _pickSign(List<Sign> signs, String lookup) {
    if (signs.isEmpty) return null;
    for (final sign in signs) {
      if (sign.id == _selectedSignId) return sign;
    }
    final target = lookup.toLowerCase();
    for (final sign in signs) {
      if (sign.word.toLowerCase() == target) return sign;
    }
    return signs.first;
  }
}

/// Single-line composer: text, clear, dictation and translate in one bar.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onToggleSpeech,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onToggleSpeech;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    const noBorder = InputBorder.none;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([focusNode, controller]),
          builder: (context, _) {
            final focused = focusNode.hasFocus;
            return AnimatedContainer(
              duration: _motion(context),
              padding: const EdgeInsets.fromLTRB(AppSpacing.m, 4, 6, 4),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: focused ? scheme.primary : scheme.outlineVariant,
                  width: focused ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: l10n.translInputLabel,
                      child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      style: AppTextStyles.bodyLarge,
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmit(),
                      decoration: InputDecoration(
                        hintText: l10n.typeWordPhrase,
                        filled: false,
                        isDense: true,
                        border: noBorder,
                        enabledBorder: noBorder,
                        focusedBorder: noBorder,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    IconButton(
                      tooltip: l10n.translClear,
                      onPressed: onClear,
                      icon: const Icon(AppIcons.close, size: 20),
                    ),
                  IconButton(
                    tooltip: isListening
                        ? l10n.translStopDictation
                        : l10n.translStartDictation,
                    isSelected: isListening,
                    style: isListening
                        ? IconButton.styleFrom(
                            backgroundColor: AppColors.error.withValues(alpha: 0.12),
                          )
                        : null,
                    onPressed: onToggleSpeech,
                    icon: Icon(
                      isListening ? AppIcons.stop : AppIcons.microphone,
                      color: isListening ? AppColors.error : scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton.filled(
                    tooltip: l10n.translate,
                    onPressed: onSubmit,
                    icon: const Icon(PhosphorIconsRegular.arrowRight),
                  ),
                ],
              ),
            );
          },
        ),
        if (isListening)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s, left: AppSpacing.m),
            child: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  const Icon(AppIcons.microphone, size: 16, color: AppColors.error),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.translListening,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Labelled row of choice chips (words of a phrase, alternative signs).
class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;

  /// `(value, text)` pairs.
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final (value, text) in options)
              ChoiceChip(
                label: Text(text),
                selected: value == selected,
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _ViewToggle extends ConsumerWidget {
  const _ViewToggle({required this.mode});

  final SignViewModeEnum mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final options = [
      (SignViewModeEnum.video, AppIcons.video, l10n.videoMode),
      (SignViewModeEnum.landmarks, AppIcons.signLanguage, l10n.landmarks),
      (SignViewModeEnum.model3d, PhosphorIconsRegular.cube, l10n.threeDModel),
    ];

    return Semantics(
      container: true,
      label: l10n.translViewModeLabel,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, icon, label) in options)
              Semantics(
                selected: value == mode,
                inMutuallyExclusiveGroup: true,
                child: IconButton(
                  tooltip: label,
                  isSelected: value == mode,
                  style: IconButton.styleFrom(
                    backgroundColor: value == mode ? scheme.primary : null,
                    foregroundColor:
                        value == mode ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      ref.read(signViewModeProvider.notifier).setMode(value),
                  icon: Icon(icon, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SignStage extends StatelessWidget {
  const _SignStage({
    required this.viewMode,
    required this.lookup,
    required this.searching,
    required this.failed,
    required this.sign,
    required this.detailLoading,
  });

  final SignViewModeEnum viewMode;
  final String lookup;
  final bool searching;
  final bool failed;
  final Sign? sign;
  final bool detailLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = sign;
    const loading = Skeleton(
      child: SkeletonBlock(height: double.infinity, radius: AppRadius.l),
    );

    final Widget content;
    if (viewMode == SignViewModeEnum.model3d) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(child: _AvatarView()),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Text(
              l10n.translAvatarNote,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ],
      );
    } else if (searching) {
      content = Skeleton(
        label: l10n.translSearching,
        child: const SkeletonBlock(height: double.infinity, radius: AppRadius.l),
      );
    } else if (failed) {
      content = _StagePlaceholder(icon: AppIcons.error, title: l10n.errorGeneric);
    } else if (current == null) {
      content = _StagePlaceholder(
        icon: lookup.isEmpty ? AppIcons.signLanguage : AppIcons.search,
        title: lookup.isEmpty ? l10n.translEmptyPrompt : l10n.translNoMatch(lookup),
        message: lookup.isEmpty ? null : l10n.translNoMatchHint,
      );
    } else if (viewMode == SignViewModeEnum.landmarks) {
      content = detailLoading && current.landmarkData == null
          ? loading
          : LandmarkViewer(landmarks: SignLandmarks.parse(current.landmarkData));
    } else {
      content = Padding(
        padding: const EdgeInsets.all(AppSpacing.s),
        child: SignMedia(sign: current),
      );
    }

    return Semantics(
      container: true,
      label: current == null ? null : l10n.translShownSign(current.word),
      child: AppPanel(
        padding: EdgeInsets.zero,
        child: AnimatedSwitcher(
          duration: _motion(context),
          // The 3D avatar ignores the text: keep it mounted while typing.
          child: KeyedSubtree(
            key: ValueKey(
              viewMode == SignViewModeEnum.model3d
                  ? viewMode
                  : '$viewMode-${current?.id ?? lookup}-$searching-$failed',
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _StagePlaceholder extends StatelessWidget {
  const _StagePlaceholder({required this.icon, required this.title, this.message});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(icon, size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.m),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary(context),
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

class _AvatarView extends ConsumerWidget {
  const _AvatarView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    const loading = Skeleton(
      child: SkeletonBlock(height: double.infinity, radius: AppRadius.l),
    );
    Widget failure(Object e) => _StagePlaceholder(
          icon: AppIcons.error,
          title: l10n.translLoadError,
          message: ref.userErrorText(e, l10n),
        );

    return ref.watch(threeDSettingsProvider).when(
          loading: () => loading,
          error: (e, _) => failure(e),
          data: (settings) {
            final characterId = settings['selectedCharacterId'] as String? ??
                CharacterConstants.defaultCharacterId;
            return ref.watch(characterByIdProvider(characterId)).when(
                  loading: () => loading,
                  error: (e, _) => failure(e),
                  data: (character) {
                    if (character == null) {
                      return _StagePlaceholder(
                        icon: AppIcons.warning,
                        title: l10n.translCharacterNotFound,
                      );
                    }
                    return ModelViewer(
                      key: ValueKey(
                        'model_viewer_${settings['cameraControlsEnabled']}_${settings['zoomEnabled']}_${character.id}',
                      ),
                      src: character.modelPath,
                      alt: l10n.translModelAlt,
                      ar: true,
                      autoRotate: false,
                      cameraControls: settings['cameraControlsEnabled'] ?? true,
                      interactionPrompt: InteractionPrompt.none,
                      backgroundColor: Colors.transparent,
                      disableZoom: !(settings['zoomEnabled'] ?? true),
                      cameraOrbit: '0deg 75deg 2.5m',
                      cameraTarget: '0m 1.2m 0m',
                      fieldOfView: '30deg',
                      // Vertical axis locked at 75°: the avatar stays facing.
                      minCameraOrbit: 'auto 75deg auto',
                      maxCameraOrbit: 'auto 75deg auto',
                    );
                  },
                );
          },
        );
  }
}
