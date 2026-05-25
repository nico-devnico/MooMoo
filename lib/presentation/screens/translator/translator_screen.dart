import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/camera/camera_view.dart';
import '../../widgets/landmark_viewer/landmark_viewer.dart';
import '../../../domain/providers/sign_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../l10n/app_localizations.dart';

import 'package:moomoo/domain/providers/translator_provider.dart';
import 'package:moomoo/domain/providers/profile_provider.dart';
import 'package:moomoo/domain/providers/three_d_settings_provider.dart';
import 'package:moomoo/domain/providers/sign_view_provider.dart';
import 'package:moomoo/domain/providers/character_provider.dart';
import 'package:moomoo/core/constants/character_constants.dart';
import 'package:moomoo/data/models/character.dart';

import 'package:moomoo/domain/providers/stt_provider.dart';
import 'package:moomoo/domain/providers/tts_provider.dart';

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  bool _isSignToText = true;
  final _textController = TextEditingController();
  String _searchQuery = '';
  XFile? _selectedFile;
  bool _isImage = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String _translationResult = '...';

  @override
  void dispose() {
    _textController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    // Stop translation immediately on dispose
    ref.read(translatorStateProvider.notifier).stop();
    super.dispose();
  }

  void _toggleDirection() {
    setState(() {
      _isSignToText = !_isSignToText;
      ref.read(translatorStateProvider.notifier).stop();
    });
  }

  Future<void> _pickFile(bool isVideo) async {
    final picker = ImagePicker();
    final file = isVideo 
      ? await picker.pickVideo(source: ImageSource.gallery)
      : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      _videoController?.dispose();
      _chewieController?.dispose();
      
      setState(() {
        _selectedFile = file;
        _isImage = !isVideo;
        _videoController = null;
        _chewieController = null;
      });

      if (isVideo) {
        _initVideo(file);
      }
    }
  }

  void _initVideo(XFile file) {
    if (kIsWeb) {
      _videoController = VideoPlayerController.network(file.path);
    } else {
      _videoController = VideoPlayerController.file(File(file.path));
    }

    _videoController!.initialize().then((_) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: true,
          aspectRatio: _videoController!.value.aspectRatio,
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
    final isWide = MediaQuery.of(context).size.width > 900;
    final isTranslating = ref.watch(translatorStateProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: isWide ? null : AppBar(
        title: Text(l10n.translate),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                child: Hero(
                  tag: 'translator_toggle',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light 
                          ? AppColors.neutralLight.withOpacity(0.5)
                          : AppColors.neutralDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ToggleButton(
                            label: l10n.signs,
                            isActive: _isSignToText,
                            onTap: () => setState(() => _isSignToText = true),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                            onPressed: _toggleDirection,
                          ),
                        ),
                        Expanded(
                          child: _ToggleButton(
                            label: l10n.textAudio,
                            isActive: !_isSignToText,
                            onTap: () => setState(() => _isSignToText = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _isSignToText
                      ? _SignToTextTab(
                          key: const ValueKey('sign_to_text'),
                          isTranslating: isTranslating,
                          translationResult: _translationResult,
                          selectedFile: _selectedFile,
                          isImage: _isImage,
                          chewieController: _chewieController,
                          onPickFile: _pickFile,
                          onClearFile: _clearFile,
                          onToggleTranslation: (val) {
                            if (val) {
                              ref.read(translatorStateProvider.notifier).start();
                              setState(() => _translationResult = 'Bonjour');
                            } else {
                              ref.read(translatorStateProvider.notifier).stop();
                              setState(() => _translationResult = '...');
                            }
                          },
                        )
                      : _TextToSignTab(
                          key: const ValueKey('text_to_sign'),
                          controller: _textController,
                          onSearch: (val) => setState(() => _searchQuery = val),
                          searchQuery: _searchQuery,
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

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
              ? (isDark ? AppColors.neutralDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive 
                ? AppColors.primary 
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}

class _SignToTextTab extends ConsumerWidget {
  final bool isTranslating;
  final String translationResult;
  final XFile? selectedFile;
  final bool isImage;
  final ChewieController? chewieController;
  final Function(bool isVideo) onPickFile;
  final VoidCallback onClearFile;
  final Function(bool) onToggleTranslation;

  const _SignToTextTab({
    super.key,
    required this.isTranslating,
    required this.translationResult,
    this.selectedFile,
    this.isImage = false,
    this.chewieController,
    required this.onPickFile,
    required this.onClearFile,
    required this.onToggleTranslation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Media Area (Camera or Selected File)
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.m),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (selectedFile != null)
                  Positioned.fill(
                    child: isImage
                        ? kIsWeb
                            ? Image.network(selectedFile!.path, fit: BoxFit.contain)
                            : Image.file(File(selectedFile!.path), fit: BoxFit.contain)
                        : chewieController != null
                            ? Chewie(controller: chewieController!)
                            : const Center(child: CircularProgressIndicator()),
                  )
                else
                  const CameraView(),
                
                // Clear file button
                if (selectedFile != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: onClearFile,
                      ),
                    ),
                  ),

                // Upload overlays
                if (selectedFile == null)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'upload_video',
                          onPressed: () => onPickFile(true),
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.video_library, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'upload_image',
                          onPressed: () => onPickFile(false),
                          backgroundColor: AppColors.secondary,
                          child: const Icon(Icons.image, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Result Field Below (WhatsApp style) - Takes natural height
        Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutralDark.withOpacity(0.3) : AppColors.neutralLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isTranslating ? 'Traduction en cours...' : 'Prêt à traduire',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            translationResult,
                            style: AppTextStyles.h3,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: AppColors.primary),
                      onPressed: () {
                        if (translationResult != '...') {
                          ref.read(ttsControllerProvider.notifier).speak(translationResult);
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Translation Controls - Only show on Wide screens (Web/Tablet)
              if (isWide) ...[
                const SizedBox(height: AppSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isTranslating) ...[
                      _ControlFab(
                        icon: Icons.stop,
                        color: AppColors.error,
                        label: 'Stopper',
                        onTap: () => onToggleTranslation(false),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      _ControlFab(
                        icon: Icons.refresh,
                        color: AppColors.secondary,
                        label: 'Redémarrer',
                        onTap: () {
                          onToggleTranslation(false);
                          Future.delayed(const Duration(milliseconds: 100), () => onToggleTranslation(true));
                        },
                      ),
                    ] else
                      _ControlFab(
                        icon: Icons.play_arrow,
                        color: AppColors.primary,
                        label: 'Lancer la traduction',
                        onTap: () => onToggleTranslation(true),
                        extended: true,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.s),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlFab extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool extended;

  const _ControlFab({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    if (extended) {
      return FloatingActionButton.extended(
        heroTag: label,
        onPressed: onTap,
        backgroundColor: color,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return FloatingActionButton(
      heroTag: label,
      onPressed: onTap,
      backgroundColor: color,
      mini: true,
      child: Icon(icon),
    );
  }
}

class _TextToSignTab extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final String searchQuery;

  const _TextToSignTab({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.searchQuery,
  });

  @override
  ConsumerState<_TextToSignTab> createState() => _TextToSignTabState();
}

class _TextToSignTabState extends ConsumerState<_TextToSignTab> {
  void _handleSpeech() async {
    final isListening = ref.read(speechControllerProvider);
    final notifier = ref.read(speechControllerProvider.notifier);

    if (isListening) {
      await notifier.stopListening();
    } else {
      await notifier.startListening(
        onResult: (text) {
          widget.controller.text = text;
          widget.onSearch(text);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final threeDSettingsAsync = ref.watch(threeDSettingsProvider);
    final viewModeAsync = ref.watch(signViewModeProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final isListening = ref.watch(speechControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Mode Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: viewModeAsync.when(
            data: (mode) => SegmentedButton<SignViewModeEnum>(
              segments: [
                ButtonSegment(
                  value: SignViewModeEnum.model3d,
                  label: Text(l10n.threeDModel, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.accessibility_new),
                ),
                ButtonSegment(
                  value: SignViewModeEnum.landmarks,
                  label: Text(l10n.landmarks, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.animation),
                ),
                ButtonSegment(
                  value: SignViewModeEnum.video,
                  label: Text(l10n.videoMode, style: const TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.videocam),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (val) {
                ref.read(signViewModeProvider.notifier).setMode(val.first);
              },
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        // Display Area
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.only(
              left: AppSpacing.m,
              right: AppSpacing.m,
              bottom: AppSpacing.m,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                viewModeAsync.when(
                  data: (mode) {
                    switch (mode) {
                      case SignViewModeEnum.model3d:
                        return threeDSettingsAsync.when(
                          data: (settings) {
                            final selectedCharacterId = settings['selectedCharacterId'] ?? CharacterConstants.defaultCharacterId;
                            
                            return ref.watch(characterByIdProvider(selectedCharacterId)).when(
                              data: (character) {
                                if (character == null) return const Center(child: Text('Personnage non trouvé'));
                                
                                return ModelViewer(
                                  key: ValueKey('model_viewer_${settings['autoRotate']}_${settings['zoomEnabled']}_${character.id}'),
                                  src: character.modelPath,
                                  alt: 'Un modèle 3D traducteur de langue des signes',
                                  ar: true,
                                  autoRotate: false, // User requested no auto-rotation
                                  cameraControls: true,
                                  backgroundColor: Colors.transparent,
                                  disableZoom: !(settings['zoomEnabled'] ?? true),
                                  cameraOrbit: '0deg 75deg 2.5m',
                                  cameraTarget: '0m 1.2m 0m',
                                  fieldOfView: '30deg',
                                  minCameraOrbit: 'auto 75deg auto', // Lock vertical axis to 75deg
                                  maxCameraOrbit: 'auto 75deg auto', // Lock vertical axis to 75deg
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, s) => Center(child: Text('Erreur : $e')),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Center(child: Text('Erreur : $e')),
                        );
                      case SignViewModeEnum.landmarks:
                        return const LandmarkViewer(
                          points: [], // Points will be updated by search result
                        );
                      case SignViewModeEnum.video:
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.video_library, size: 64, color: AppColors.primary),
                              const SizedBox(height: 16),
                              Text(l10n.videoWaiting),
                            ],
                          ),
                        );
                    }
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Erreur : $e')),
                ),
                
                // Audio Wave Animation Overlay when listening
                if (isListening)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mic, size: 64, color: Colors.white)
                                .animate(onPlay: (controller) => controller.repeat())
                                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 500.ms, curve: Curves.easeInOut)
                                .then()
                                .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeInOut),
                            const SizedBox(height: 16),
                            const Text(
                              'Écoute en cours...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Input Field Below (WhatsApp style)
        Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black45 : Colors.black12,
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      onChanged: widget.onSearch,
                      decoration: InputDecoration(
                        hintText: l10n.typeWordPhrase,
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : AppColors.neutralLight.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isListening ? Icons.stop : Icons.mic,
                            color: isListening ? AppColors.error : AppColors.primary,
                          ),
                          onPressed: _handleSpeech,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  // Only show send button on Wide screens
                  if (MediaQuery.of(context).size.width > 900)
                    FloatingActionButton.small(
                      onPressed: () => widget.onSearch(widget.controller.text),
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        ),
      ],
    );
  }
}
