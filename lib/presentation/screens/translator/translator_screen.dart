import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/camera/camera_view.dart';
import '../../widgets/landmark_viewer/landmark_viewer.dart';
import '../../widgets/sign_media.dart';
import '../../widgets/skeletons.dart';

/// Au-delà de cette largeur, média et résultat s'affichent côte à côte.
const double _splitBreakpoint = 900;
const double _sidePanelWidth = 400;
const double _controlHeight = 56;

enum _SignStatus { idle, translating, done, unavailable }

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
  String? _activeModelLabel;
  String? _errorMessage;

  /// Incrémenté à chaque lancement ou arrêt : une réponse arrivée après coup
  /// ne doit pas écraser l'état courant.
  int _inferenceRun = 0;

  /// One history session per direction for the time the screen is open.
  final Map<String, String> _sessions = {};

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    ref.read(translatorStateProvider.notifier).stop();
    final repo = ref.read(sessionRepositoryProvider);
    for (final id in _sessions.values) {
      repo.closeSession(id).catchError((_) {});
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

  Future<XFile?> _captureFrame() async {
    // Sur le web, la caméra ne s'initialise qu'une fois la traduction lancée :
    // on laisse CameraView s'abonner au provider avant de le lire.
    await WidgetsBinding.instance.endOfFrame;
    final controller = await ref.read(cameraStateProvider.future);
    if (controller == null || !controller.value.isInitialized) return null;
    return ref.read(cameraStateProvider.notifier).takePicture();
  }

  Future<void> _runInference() async {
    final l10n = AppLocalizations.of(context)!;
    final run = ++_inferenceRun;
    setState(() {
      _signStatus = _SignStatus.translating;
      _errorMessage = null;
    });

    List<int>? bytes;
    String? filename;
    try {
      final file = _selectedFile ?? await _captureFrame();
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
        _activeModelLabel = null;
        _errorMessage = l10n.translCameraUnavailable;
      });
      return;
    }

    final result = await ref
        .read(mlModelRepositoryProvider)
        .infer(fileBytes: bytes, filename: filename);
    if (!mounted || run != _inferenceRun) return;

    final label = result.label?.trim();
    setState(() {
      if (result.ok && label != null && label.isNotEmpty) {
        _signStatus = _SignStatus.done;
        _translationResult = label;
        _confidence = result.confidence;
        _activeModelLabel = result.model?.displayLabel;
      } else {
        _signStatus = _SignStatus.unavailable;
        _translationResult = null;
        _confidence = null;
        _activeModelLabel = null;
        _errorMessage = l10n.inferenceUnavailableMessage;
      }
    });
    if (result.ok && label != null && label.isNotEmpty) {
      _record(
        direction: 'sign_to_text',
        translatedText: label,
        confidence: result.confidence,
        inferenceTimeMs: result.latencyMs?.round(),
        modelVersion: result.model?.version,
      );
    }
  }

  void _start() => ref.read(translatorStateProvider.notifier).start();

  void _stop() => ref.read(translatorStateProvider.notifier).stop();

  void _setMode(TranslationMode mode) {
    if (ref.read(translationModeStateProvider) == mode) return;
    ref.read(translationModeStateProvider.notifier).setMode(mode);
    _stop();
    ref.read(speechControllerProvider.notifier).stopListening();
  }

  void _toggleDirection() {
    final current = ref.read(translationModeStateProvider);
    _setMode(
      current == TranslationMode.signToText
          ? TranslationMode.textToSign
          : TranslationMode.signToText,
    );
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

    // Couvre aussi le bouton flottant du shell mobile, qui ne fait que
    // basculer l'état : l'inférence part d'ici dans tous les cas.
    ref.listen<bool>(translatorStateProvider, (previous, next) {
      if (next && previous != true) {
        if (ref.read(translationModeStateProvider) ==
            TranslationMode.signToText) {
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
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.l,
                AppSpacing.m,
              ),
              child: _DirectionBar(
                mode: mode,
                onModeChanged: _setMode,
                onSwap: _toggleDirection,
              ),
            ),
            Expanded(
              child: mode == TranslationMode.signToText
                  ? _SignToTextView(
                      key: const ValueKey('sign_to_text'),
                      isTranslating: isTranslating,
                      status: _signStatus,
                      result: _translationResult,
                      confidence: _confidence,
                      modelLabel: _activeModelLabel,
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
                      onQueryChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onTranslated: (text, signIds) => _record(
                        direction: 'text_to_sign',
                        sourceText: text,
                        signIds: signIds,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionBar extends StatelessWidget {
  const _DirectionBar({
    required this.mode,
    required this.onModeChanged,
    required this.onSwap,
  });

  final TranslationMode mode;
  final ValueChanged<TranslationMode> onModeChanged;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Row(
          children: [
            Expanded(
              child: SegmentedButton<TranslationMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, kMinTouchTarget),
                ),
                segments: [
                  ButtonSegment(
                    value: TranslationMode.signToText,
                    icon: const Icon(AppIcons.signLanguage),
                    label: Text(l10n.translDirectionSignToText),
                  ),
                  ButtonSegment(
                    value: TranslationMode.textToSign,
                    icon: const Icon(AppIcons.keyboard),
                    label: Text(l10n.translDirectionTextToSign),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (value) => onModeChanged(value.first),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            IconButton.outlined(
              tooltip: l10n.translSwapDirection,
              constraints: const BoxConstraints(
                minWidth: kMinTouchTarget,
                minHeight: kMinTouchTarget,
              ),
              onPressed: onSwap,
              icon: const Icon(PhosphorIconsRegular.arrowsLeftRight),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne d'état annoncée aux lecteurs d'écran à chaque changement.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.text,
    required this.icon,
    required this.color,
    this.busy = false,
  });

  final String text;
  final IconData icon;
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
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s + 4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.radiusM,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: busy
                  ? CircularProgressIndicator(strokeWidth: 2, color: color)
                  : Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: AppSpacing.s + 4),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignToTextView extends ConsumerWidget {
  const _SignToTextView({
    super.key,
    required this.isTranslating,
    required this.status,
    required this.result,
    required this.confidence,
    required this.modelLabel,
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
  final String? modelLabel;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final statusLine = switch (status) {
      _SignStatus.translating => _StatusLine(
        text: l10n.translatingInProgress,
        icon: AppIcons.info,
        color: AppColors.primary,
        busy: true,
      ),
      _SignStatus.done => _StatusLine(
        text: l10n.translDone,
        icon: AppIcons.success,
        color: AppColors.success,
      ),
      _SignStatus.unavailable => _StatusLine(
        text: l10n.inferenceUnavailable,
        icon: AppIcons.warning,
        color: AppColors.warning,
      ),
      _SignStatus.idle => _StatusLine(
        text: l10n.readyToTranslate,
        icon: AppIcons.info,
        color: AppColors.textSecondary(context),
      ),
    };

    final media = _MediaStage(
      selectedFile: selectedFile,
      isImage: isImage,
      chewieController: chewieController,
    );
    final sourceBar = _SourceBar(
      selectedFile: selectedFile,
      onPickFile: onPickFile,
      onClearFile: onClearFile,
    );
    final resultPanel = _ResultPanel(
      result: result,
      confidence: confidence,
      modelLabel: modelLabel,
      unavailable: status == _SignStatus.unavailable,
      errorMessage: errorMessage,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _splitBreakpoint;
        final controls = _TranslateControls(
          isTranslating: isTranslating,
          busy: status == _SignStatus.translating,
          stretch: !wide,
          onStart: onStart,
          onStop: onStop,
          onRestart: onRestart,
        );

        if (wide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: media),
                      const SizedBox(height: AppSpacing.m),
                      sourceBar,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.l),
                SizedBox(
                  width: _sidePanelWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        statusLine,
                        const SizedBox(height: AppSpacing.m),
                        resultPanel,
                        const SizedBox(height: AppSpacing.l),
                        controls,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final mediaHeight = (constraints.maxWidth * 0.9).clamp(240.0, 420.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.xxl,
          ),
          children: [
            statusLine,
            const SizedBox(height: AppSpacing.m),
            SizedBox(height: mediaHeight, child: media),
            const SizedBox(height: AppSpacing.m),
            sourceBar,
            const SizedBox(height: AppSpacing.l),
            controls,
            const SizedBox(height: AppSpacing.l),
            resultPanel,
          ],
        );
      },
    );
  }
}

class _MediaStage extends StatelessWidget {
  const _MediaStage({
    required this.selectedFile,
    required this.isImage,
    required this.chewieController,
  });

  final XFile? selectedFile;
  final bool isImage;
  final ChewieController? chewieController;

  @override
  Widget build(BuildContext context) {
    final file = selectedFile;
    Widget content;
    if (file == null) {
      content = const CameraView();
    } else if (isImage) {
      content = kIsWeb
          ? Image.network(file.path, fit: BoxFit.contain, cacheWidth: 1280)
          : Image.file(File(file.path), fit: BoxFit.contain, cacheWidth: 1280);
    } else if (chewieController != null) {
      content = Chewie(controller: chewieController!);
    } else {
      content = const Skeleton(child: SkeletonBlock(height: double.infinity));
    }

    return ClipRRect(
      borderRadius: AppRadius.radiusL,
      child: ColoredBox(color: Colors.black, child: content),
    );
  }
}

class _SourceBar extends StatelessWidget {
  const _SourceBar({
    required this.selectedFile,
    required this.onPickFile,
    required this.onClearFile,
  });

  final XFile? selectedFile;
  final ValueChanged<bool> onPickFile;
  final VoidCallback onClearFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, kMinTouchTarget),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            OutlinedButton.icon(
              style: buttonStyle,
              onPressed: () => onPickFile(true),
              icon: const Icon(AppIcons.video, size: 20),
              label: Text(l10n.translImportVideo),
            ),
            OutlinedButton.icon(
              style: buttonStyle,
              onPressed: () => onPickFile(false),
              icon: const Icon(AppIcons.image, size: 20),
              label: Text(l10n.translImportImage),
            ),
            if (selectedFile != null)
              OutlinedButton.icon(
                style: buttonStyle.copyWith(
                  foregroundColor: const WidgetStatePropertyAll(
                    AppColors.error,
                  ),
                ),
                onPressed: onClearFile,
                icon: const Icon(AppIcons.camera, size: 20),
                label: Text(l10n.translRemoveFile),
              ),
          ],
        ),
        if (selectedFile != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            l10n.translFileSelected(selectedFile!.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _TranslateControls extends StatelessWidget {
  const _TranslateControls({
    required this.isTranslating,
    required this.busy,
    required this.stretch,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  });

  final bool isTranslating;
  final bool busy;
  final bool stretch;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const size = Size(0, _controlHeight);

    if (!isTranslating) {
      final start = FilledButton.icon(
        autofocus: context.isDesktop,
        style: FilledButton.styleFrom(minimumSize: size),
        onPressed: onStart,
        icon: const Icon(AppIcons.play),
        label: Text(l10n.translStart),
      );
      return stretch
          ? SizedBox(width: double.infinity, child: start)
          : Align(alignment: Alignment.centerLeft, child: start);
    }

    final stop = FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: size,
        backgroundColor: AppColors.error,
      ),
      onPressed: onStop,
      icon: const Icon(AppIcons.stop),
      label: Text(l10n.stopTranslation),
    );
    final restart = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: size),
      onPressed: busy ? null : onRestart,
      icon: const Icon(AppIcons.refresh),
      label: Text(l10n.translRestart),
    );

    if (stretch) {
      return Row(
        children: [
          Expanded(child: stop),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: restart),
        ],
      );
    }
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [stop, restart],
    );
  }
}

class _ResultPanel extends ConsumerWidget {
  const _ResultPanel({
    required this.result,
    required this.confidence,
    required this.modelLabel,
    required this.unavailable,
    required this.errorMessage,
  });

  final String? result;
  final double? confidence;
  final String? modelLabel;
  final bool unavailable;
  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final text = result;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.translResultLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Semantics(
            liveRegion: true,
            child: SelectableText(
              text ?? l10n.translResultPlaceholder,
              style: text == null
                  ? AppTextStyles.bodyLarge.copyWith(color: secondary)
                  : AppTextStyles.h1,
            ),
          ),
          if (text != null && (confidence != null || modelLabel != null)) ...[
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.m,
              runSpacing: AppSpacing.xs,
              children: [
                if (confidence != null)
                  Text(
                    l10n.translConfidence((confidence! * 100).round()),
                    style: AppTextStyles.bodySmall.copyWith(color: secondary),
                  ),
                if (modelLabel != null)
                  Text(
                    l10n.translModelUsed(modelLabel!),
                    style: AppTextStyles.bodySmall.copyWith(color: secondary),
                  ),
              ],
            ),
          ],
          if (unavailable) ...[
            const SizedBox(height: AppSpacing.m),
            Container(
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
                          l10n.inferenceUnavailable,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          errorMessage ?? l10n.inferenceUnavailableMessage,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          // Le son n'est qu'un complément : le texte ci-dessus reste la source.
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, kMinTouchTarget),
            ),
            onPressed: text == null
                ? null
                : () => ref.read(ttsControllerProvider.notifier).speak(text),
            icon: const Icon(AppIcons.speaker, size: 20),
            label: Text(l10n.translSpeak),
          ),
        ],
      ),
    );
  }
}

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

    // Résultats de la dictée lancée depuis le bouton flottant du shell.
    ref.listen<String>(sttResultProvider, (previous, next) {
      if (next.isNotEmpty && mounted) {
        widget.controller.text = next;
        _recordPending = true;
        _setQuery(next);
      }
    });

    final isListening = ref.watch(speechControllerProvider);
    final viewMode =
        ref.watch(signViewModeProvider).value ?? SignViewModeEnum.video;

    final trimmed = widget.query.trim();
    final words = trimmed.isEmpty
        ? const <String>[]
        : trimmed.split(RegExp(r'\s+')).toList(growable: false);
    // Une phrase se traduit mot à mot : on cherche un mot à la fois.
    final lookup = words.length > 1
        ? (words.contains(_activeWord) ? _activeWord! : words.first)
        : trimmed;

    final resultsAsync = lookup.isEmpty
        ? null
        : ref.watch(signSearchProvider(query: lookup));
    final signs = resultsAsync?.value ?? const <Sign>[];
    final selected = _pickSign(signs, lookup);
    final detailAsync = selected == null
        ? null
        : ref.watch(signDetailProvider(selected.id));
    final displaySign = detailAsync?.value ?? selected;
    final searching =
        resultsAsync != null && resultsAsync.isLoading && signs.isEmpty;

    if (_recordPending && trimmed.isNotEmpty && resultsAsync != null && !resultsAsync.isLoading) {
      _recordPending = false;
      final ids = selected == null ? const <String>[] : [selected.id];
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onTranslated(trimmed, ids));
    }

    final statusLine = isListening
        ? _StatusLine(
            text: l10n.translListening,
            icon: AppIcons.microphone,
            color: AppColors.primary,
          )
        : lookup.isEmpty
        ? _StatusLine(
            text: l10n.translEmptyPrompt,
            icon: AppIcons.info,
            color: AppColors.textSecondary(context),
          )
        : searching
        ? _StatusLine(
            text: l10n.translSearching,
            icon: AppIcons.search,
            color: AppColors.primary,
            busy: true,
          )
        : resultsAsync!.hasError && signs.isEmpty
        ? _StatusLine(
            text: l10n.errorGeneric,
            icon: AppIcons.error,
            color: AppColors.error,
          )
        : displaySign == null
        ? _StatusLine(
            text: l10n.translNoMatch(lookup),
            icon: AppIcons.warning,
            color: AppColors.warning,
          )
        : _StatusLine(
            text: l10n.translShownSign(displaySign.word),
            icon: AppIcons.success,
            color: AppColors.success,
          );

    final input = _InputPanel(
      controller: widget.controller,
      focusNode: widget.focusNode,
      isListening: isListening,
      words: words,
      activeWord: lookup,
      signs: signs,
      selectedSignId: selected?.id,
      onChanged: _setQuery,
      onSubmit: _submit,
      onToggleSpeech: _toggleSpeech,
      onWordSelected: (word) => setState(() {
        _activeWord = word;
        _selectedSignId = null;
      }),
      onSignSelected: (id) => setState(() => _selectedSignId = id),
    );

    final stage = _SignStage(
      viewMode: viewMode,
      lookup: lookup,
      searching: searching,
      sign: displaySign,
      detailLoading: detailAsync?.isLoading ?? false,
    );

    final caption = displaySign == null
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(displaySign.word, style: AppTextStyles.h1),
              if (displaySign.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(displaySign.description!, style: AppTextStyles.bodyLarge),
              ],
            ],
          );

    final viewSelector = _ViewModeSelector(mode: viewMode);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _sidePanelWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        statusLine,
                        const SizedBox(height: AppSpacing.m),
                        input,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      viewSelector,
                      const SizedBox(height: AppSpacing.m),
                      Expanded(child: stage),
                      const SizedBox(height: AppSpacing.m),
                      caption,
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final stageHeight = (constraints.maxWidth * 0.9).clamp(240.0, 400.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.xxl,
          ),
          children: [
            statusLine,
            const SizedBox(height: AppSpacing.m),
            input,
            const SizedBox(height: AppSpacing.l),
            viewSelector,
            const SizedBox(height: AppSpacing.m),
            SizedBox(height: stageHeight, child: stage),
            const SizedBox(height: AppSpacing.m),
            caption,
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

class _InputPanel extends StatelessWidget {
  const _InputPanel({
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.words,
    required this.activeWord,
    required this.signs,
    required this.selectedSignId,
    required this.onChanged,
    required this.onSubmit,
    required this.onToggleSpeech,
    required this.onWordSelected,
    required this.onSignSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final List<String> words;
  final String activeWord;
  final List<Sign> signs;
  final String? selectedSignId;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onToggleSpeech;
  final ValueChanged<String> onWordSelected;
  final ValueChanged<String> onSignSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            style: AppTextStyles.bodyLarge,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: l10n.translInputLabel,
              hintText: l10n.typeWordPhrase,
              helperText: context.isAtLeastTablet ? l10n.translInputHint : null,
              prefixIcon: const Icon(AppIcons.keyboard),
              suffixIcon: IconButton(
                tooltip: isListening
                    ? l10n.translStopDictation
                    : l10n.translStartDictation,
                constraints: const BoxConstraints(
                  minWidth: kMinTouchTarget,
                  minHeight: kMinTouchTarget,
                ),
                onPressed: onToggleSpeech,
                icon: Icon(
                  isListening ? AppIcons.stop : AppIcons.microphone,
                  color: isListening ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, _controlHeight),
              ),
              onPressed: onSubmit,
              icon: const Icon(AppIcons.translate),
              label: Text(l10n.translate),
            ),
          ),
          if (words.length > 1) ...[
            const SizedBox(height: AppSpacing.l),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final word in words.toSet())
                  ChoiceChip(
                    label: Text(word),
                    selected: word == activeWord,
                    onSelected: (_) => onWordSelected(word),
                  ),
              ],
            ),
          ],
          if (signs.length > 1) ...[
            const SizedBox(height: AppSpacing.l),
            Semantics(
              header: true,
              child: Text(
                l10n.translMatches,
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
                for (final sign in signs.take(12))
                  ChoiceChip(
                    label: Text(sign.word),
                    selected: sign.id == selectedSignId,
                    onSelected: (_) => onSignSelected(sign.id),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ViewModeSelector extends ConsumerWidget {
  const _ViewModeSelector({required this.mode});

  final SignViewModeEnum mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<SignViewModeEnum>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, kMinTouchTarget),
        ),
        segments: [
          ButtonSegment(
            value: SignViewModeEnum.video,
            icon: const Icon(AppIcons.video),
            label: Text(l10n.videoMode),
          ),
          ButtonSegment(
            value: SignViewModeEnum.landmarks,
            icon: const Icon(AppIcons.signLanguage),
            label: Text(l10n.landmarks),
          ),
          ButtonSegment(
            value: SignViewModeEnum.model3d,
            icon: const Icon(PhosphorIconsRegular.cube),
            label: Text(l10n.threeDModel),
          ),
        ],
        selected: {mode},
        onSelectionChanged: (value) =>
            ref.read(signViewModeProvider.notifier).setMode(value.first),
      ),
    );
  }
}

class _SignStage extends StatelessWidget {
  const _SignStage({
    required this.viewMode,
    required this.lookup,
    required this.searching,
    required this.sign,
    required this.detailLoading,
  });

  final SignViewModeEnum viewMode;
  final String lookup;
  final bool searching;
  final Sign? sign;
  final bool detailLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = sign;

    Widget content;
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
        child: const SkeletonBlock(
          height: double.infinity,
          radius: AppRadius.l,
        ),
      );
    } else if (current == null) {
      content = _StagePlaceholder(
        icon: lookup.isEmpty ? AppIcons.signLanguage : AppIcons.search,
        title: lookup.isEmpty
            ? l10n.translEmptyPrompt
            : l10n.translNoMatch(lookup),
        message: lookup.isEmpty ? null : l10n.translNoMatchHint,
      );
    } else if (viewMode == SignViewModeEnum.landmarks) {
      content = detailLoading && current.landmarkData == null
          ? const Skeleton(
              child: SkeletonBlock(
                height: double.infinity,
                radius: AppRadius.l,
              ),
            )
          : LandmarkViewer(
              points: SignMedia.parseLandmarks(current.landmarkData),
            );
    } else {
      content = Padding(
        padding: const EdgeInsets.all(AppSpacing.s),
        child: SignMedia(sign: current),
      );
    }

    return Semantics(
      container: true,
      label: current == null ? null : l10n.translShownSign(current.word),
      child: AppPanel(padding: EdgeInsets.zero, child: content),
    );
  }
}

class _StagePlaceholder extends StatelessWidget {
  const _StagePlaceholder({
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textSecondary(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: AppSpacing.m),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: secondary),
              ),
            ],
          ],
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

    return ref
        .watch(threeDSettingsProvider)
        .when(
          loading: () => loading,
          error: (e, _) => failure(e),
          data: (settings) {
            final characterId =
                settings['selectedCharacterId'] as String? ??
                CharacterConstants.defaultCharacterId;
            return ref
                .watch(characterByIdProvider(characterId))
                .when(
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
                      // Axe vertical verrouillé à 75° : l'avatar reste de face.
                      minCameraOrbit: 'auto 75deg auto',
                      maxCameraOrbit: 'auto 75deg auto',
                    );
                  },
                );
          },
        );
  }
}
