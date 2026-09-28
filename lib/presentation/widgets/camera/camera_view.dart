import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/camera_provider.dart';
import '../../../domain/providers/translator_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Live camera for sign recognition: a clean full-bleed preview with a single
/// "switch camera" control. Importing files is handled by the translator
/// screen.
class CameraView extends ConsumerStatefulWidget {
  const CameraView({super.key, this.active});

  /// Whether the camera is in use. Defaults to the translator's state; the
  /// lesson practice passes its own.
  final bool? active;

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView> {
  late final AppLifecycleListener _lifecycle;
  bool _appVisible = true;
  double _baseScale = 1.0;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
  }

  void _onLifecycle(AppLifecycleState state) {
    final visible =
        state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
    if (visible != _appVisible && mounted) setState(() => _appVisible = visible);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = widget.active ?? ref.watch(translatorStateProvider) == true;

    // Not watching the auto-dispose provider releases the camera: nothing to
    // film while the tab is hidden (the shell keeps it mounted) or the app is
    // in the background.
    if (!_appVisible || !TickerMode.valuesOf(context).enabled) {
      return const ColoredBox(color: Colors.black);
    }

    // The browser asks for camera permission: only when the user starts.
    if (kIsWeb && !isActive) {
      return _CameraMessage(
        icon: PhosphorIconsRegular.videoCameraSlash,
        title: l10n.translCameraIdleTitle,
        message: l10n.translCameraIdleMessage,
      );
    }

    const loading = ColoredBox(
      color: Colors.black,
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    return ref.watch(cameraStateProvider).when(
          loading: () => loading,
          error: (_, _) => _CameraMessage(
            icon: PhosphorIconsRegular.videoCameraSlash,
            message: l10n.errCamera,
          ),
          data: (controller) {
            if (controller == null || !controller.value.isInitialized) {
              return loading;
            }
            return ColoredBox(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onScaleStart: (_) => _baseScale = _currentScale,
                    onScaleUpdate: (details) {
                      _currentScale = (_baseScale * details.scale).clamp(1.0, 5.0);
                      ref.read(cameraStateProvider.notifier).setZoomLevel(_currentScale);
                    },
                    child: _CoverPreview(controller: controller),
                  ),
                  if (!kIsWeb)
                    Positioned(
                      right: AppSpacing.m,
                      bottom: AppSpacing.m,
                      child: IconButton.filled(
                        tooltip: l10n.translSwitchCamera,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.square(48),
                        ),
                        onPressed: () =>
                            ref.read(cameraStateProvider.notifier).switchCamera(),
                        icon: const Icon(PhosphorIconsRegular.cameraRotate),
                      ),
                    ),
                ],
              ),
            );
          },
        );
  }
}

/// Fills the whole frame like a native camera app instead of letterboxing.
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The plugin reports the sensor's landscape ratio.
        var ratio = controller.value.aspectRatio;
        if (MediaQuery.orientationOf(context) == Orientation.portrait && !kIsWeb) {
          ratio = 1 / ratio;
        }
        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth / ratio,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.icon, this.title, required this.message});

  final IconData icon;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
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
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
