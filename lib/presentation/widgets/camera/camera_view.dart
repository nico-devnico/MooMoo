import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/camera_provider.dart';
import '../../../domain/providers/translator_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'camera_overlay.dart';
import 'camera_controls_bar.dart';

class CameraView extends ConsumerStatefulWidget {
  const CameraView({super.key});

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _baseScale = 1.0;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null) {
      final file = result.files.single;
      final fileName = file.name;
      
      // On Web, bytes are available. On Mobile/Desktop, path is available.
      if (kIsWeb ? file.bytes != null : file.path != null) {
        // Logic to handle the picked file (e.g., upload to Supabase or process locally)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vidéo importée : $fileName')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTranslating = ref.watch(translatorStateProvider);
    final settings = ref.watch(cameraSettingsProvider);
    final isRecording = settings['isRecording'] ?? false;

    // On Web, only initialize camera if translating is active
    if (kIsWeb && !isTranslating) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Caméra en attente',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cliquez sur le bouton de traduction pour activer la caméra',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Ou importer une vidéo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cameraState = ref.watch(cameraStateProvider);

    return cameraState.when(
      data: (controller) {
        if (controller == null || !controller.value.isInitialized) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview with Zoom
              GestureDetector(
                onScaleStart: (details) {
                  _baseScale = _currentScale;
                },
                onScaleUpdate: (details) {
                  _currentScale = (_baseScale * details.scale).clamp(1.0, 5.0);
                  ref.read(cameraStateProvider.notifier).setZoomLevel(_currentScale);
                },
                child: Center(
                  child: CameraPreview(controller),
                ),
              ),
              
              // Overlay
              CustomPaint(
                painter: CameraOverlayPainter(
                  isRecording: isRecording,
                  animation: _animationController,
                ),
              ),

              // Grid (optional)
              if (settings['showGrid'] ?? false) const _CameraGrid(),

              // Controls Bar
              const Positioned(
                bottom: 20,
                left: AppSpacing.l,
                right: AppSpacing.l,
                child: CameraControlsBar(),
              ),

              // Recording Timer
              if (isRecording)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _RecordingTimer(duration: settings['recordingDuration'] ?? 0),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        if (kIsWeb) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off_outlined, color: Colors.white, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Accès caméra impossible sur ce navigateur',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importer une vidéo'),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: Center(child: Text('Erreur caméra: $error')),
        );
      },
    );
  }
}

class _CameraGrid extends StatelessWidget {
  const _CameraGrid();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Row(
            children: [
              const Spacer(),
              Container(width: 1, color: Colors.white24),
              const Spacer(),
              Container(width: 1, color: Colors.white24),
              const Spacer(),
            ],
          ),
          Column(
            children: [
              const Spacer(),
              Container(height: 1, color: Colors.white24),
              const Spacer(),
              Container(height: 1, color: Colors.white24),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordingTimer extends StatelessWidget {
  final int duration;
  const _RecordingTimer({required this.duration});

  @override
  Widget build(BuildContext context) {
    final minutes = (duration / 60).floor().toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
          const SizedBox(width: 8),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
