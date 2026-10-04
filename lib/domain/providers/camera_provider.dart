import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/camera_frame_convert.dart';
import '../../data/services/spell_frame_prep.dart';

part 'camera_provider.g.dart';

/// Flux live : frames caméra → crop main → JPEG compact pour le ML.
const _capturePreset = ResolutionPreset.medium;

@riverpod
class CameraState extends _$CameraState {
  CameraController? _active;
  bool _streaming = false;
  bool _frameBusy = false;
  bool _releasing = false;
  int _epoch = 0;
  Completer<CameraController?>? _ensureInFlight;
  Completer<void>? _releaseInFlight;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  void Function(Uint8List handJpeg, {required bool handDetected})? _onHandFrame;
  void Function()? _closeKeepAlive;

  /// Intervalle min entre deux envois ML (latence réseau + inférence).
  /// Un peu plus long = frames plus stables pour l'épellation.
  static const frameInterval = Duration(milliseconds: 420);

  /// Lazy: no camera until [ensureCamera] (text→sign must never open it).
  @override
  FutureOr<CameraController?> build() {
    ref.onDispose(() {
      // Same path as [releaseCamera]: await native dispose so Windows LED dies.
      unawaited(_disposeActive(reason: 'provider-dispose'));
    });
    return null;
  }

  void _retain() {
    if (_closeKeepAlive != null) return;
    final link = ref.keepAlive();
    _closeKeepAlive = link.close;
  }

  void _releaseKeepAlive() {
    _closeKeepAlive?.call();
    _closeKeepAlive = null;
  }

  /// Opens the front camera if needed. Safe to call repeatedly (mutex).
  Future<CameraController?> ensureCamera() async {
    // Wait for an in-flight release so we don't orphan a new controller.
    final releasing = _releaseInFlight;
    if (releasing != null) {
      await releasing.future;
    }
    if (_releasing) return null;
    final existing = _active;
    if (existing != null && existing.value.isInitialized) {
      return existing;
    }
    if (_ensureInFlight != null) {
      return _ensureInFlight!.future;
    }

    final epoch = _epoch;
    final gate = Completer<CameraController?>();
    _ensureInFlight = gate;
    state = const AsyncLoading();
    try {
      final cameras = await availableCameras();
      if (_epoch != epoch || _releasing) {
        gate.complete(null);
        return null;
      }
      if (cameras.isEmpty) {
        state = const AsyncData(null);
        gate.complete(null);
        return null;
      }

      final description = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      Future<CameraController> open(CameraController c) async {
        await c.initialize();
        if (_epoch != epoch || _releasing) {
          try {
            await c.dispose();
          } catch (_) {}
          throw StateError('camera open cancelled');
        }
        return c;
      }

      late CameraController controller;
      try {
        controller = await open(
          CameraController(
            description,
            _capturePreset,
            enableAudio: false,
            imageFormatGroup: kIsWeb
                ? ImageFormatGroup.jpeg
                : ImageFormatGroup.yuv420,
          ),
        );
      } catch (e) {
        if (_epoch != epoch || _releasing) {
          gate.complete(null);
          return null;
        }
        // Repli sans format forcé (web / appareils capricieux).
        controller = await open(
          CameraController(
            description,
            _capturePreset,
            enableAudio: false,
          ),
        );
      }

      if (_epoch != epoch || _releasing) {
        try {
          await controller.dispose();
        } catch (_) {}
        gate.complete(null);
        return null;
      }

      _active = controller;
      _retain();
      state = AsyncData(controller);
      gate.complete(controller);
      return controller;
    } catch (e, st) {
      if (_epoch == epoch && !_releasing) {
        state = AsyncError(e, st);
      }
      gate.complete(null);
      return null;
    } finally {
      if (identical(_ensureInFlight, gate)) {
        _ensureInFlight = null;
      }
    }
  }

  Future<void> switchCamera() async {
    final controller = _active ?? state.value;
    if (controller == null) return;
    await stopHandFrameStream();

    final cameras = await availableCameras();
    final currentCamera = controller.description;
    final newCamera = cameras.firstWhere(
      (c) => c.lensDirection != currentCamera.lensDirection,
      orElse: () => currentCamera,
    );

    if (newCamera == currentCamera) return;

    final epoch = ++_epoch;
    _active = null;
    try {
      await controller.dispose();
    } catch (_) {}

    if (_epoch != epoch) return;

    try {
      final newController = CameraController(
        newCamera,
        _capturePreset,
        enableAudio: false,
        imageFormatGroup: kIsWeb ? ImageFormatGroup.jpeg : ImageFormatGroup.yuv420,
      );
      await newController.initialize();
      if (_epoch != epoch) {
        await newController.dispose();
        return;
      }
      _active = newController;
      _retain();
      state = AsyncData(newController);
    } catch (_) {
      final plain = CameraController(newCamera, _capturePreset, enableAudio: false);
      await plain.initialize();
      if (_epoch != epoch) {
        await plain.dispose();
        return;
      }
      _active = plain;
      _retain();
      state = AsyncData(plain);
    }
  }

  Future<XFile?> takePicture() async {
    final controller = _active ?? state.value;
    if (controller == null || !controller.value.isInitialized) return null;
    if (controller.value.isStreamingImages) return null;
    return controller.takePicture();
  }

  Future<void> startVideoRecording() async {
    final controller = _active ?? state.value;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isRecordingVideo) return;
    await controller.startVideoRecording();
    state = AsyncData(controller);
  }

  Future<XFile?> stopVideoRecording() async {
    final controller = _active ?? state.value;
    if (controller == null || !controller.value.isInitialized) return null;
    if (!controller.value.isRecordingVideo) return null;
    final file = await controller.stopVideoRecording();
    state = AsyncData(controller);
    return file;
  }

  Future<void> setZoomLevel(double zoom) async {
    final controller = _active ?? state.value;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setZoomLevel(zoom);
  }

  /// Démarre le flux : chaque frame → détection main → JPEG crop → callback.
  Future<bool> startHandFrameStream(
    void Function(Uint8List handJpeg, {required bool handDetected}) onFrame,
  ) async {
    final controller = await ensureCamera();
    if (controller == null || !controller.value.isInitialized) return false;
    if (_streaming) {
      _onHandFrame = onFrame;
      return true;
    }
    // Image stream souvent indisponible sur le web.
    if (kIsWeb) return false;

    _onHandFrame = onFrame;
    try {
      await controller.startImageStream(_onCameraImage);
      _streaming = true;
      state = AsyncData(controller);
      return true;
    } catch (e) {
      debugPrint('[camera] startImageStream failed: $e');
      _streaming = false;
      _onHandFrame = null;
      return false;
    }
  }

  Future<void> stopHandFrameStream() async {
    _onHandFrame = null;
    final controller = _active ?? state.value;
    if (controller == null) {
      _streaming = false;
      return;
    }
    if (_streaming || controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }
    _streaming = false;
    _frameBusy = false;
    if (state.hasValue && _active != null) state = AsyncData(controller);
  }

  /// Arrête le flux et dispose le [CameraController] (LED Windows / indicateur OS).
  Future<void> releaseCamera() async {
    await _disposeActive(reason: 'release');
  }

  Future<void> _disposeActive({required String reason}) async {
    if (_releaseInFlight != null) {
      await _releaseInFlight!.future;
      return;
    }
    if (_active == null && !_streaming) {
      _releasing = false;
      _releaseKeepAlive();
      return;
    }
    final gate = Completer<void>();
    _releaseInFlight = gate;
    _releasing = true;
    _epoch++;
    final epoch = _epoch;
    try {
      await stopHandFrameStream();
      final controller = _active;
      _active = null;
      if (state.hasValue || state.isLoading) {
        state = const AsyncData(null);
      }
      // Let Flutter unmount CameraPreview before native dispose (Windows LED).
      try {
        await SchedulerBinding.instance.endOfFrame;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (controller != null) {
        try {
          await controller.dispose();
          debugPrint('[camera] disposed ($reason)');
        } catch (e) {
          debugPrint('[camera] dispose failed ($reason): $e');
        }
      }
    } finally {
      if (_epoch == epoch) {
        _releaseKeepAlive();
        _releasing = false;
      }
      if (identical(_releaseInFlight, gate)) {
        _releaseInFlight = null;
      }
      if (!gate.isCompleted) gate.complete();
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_frameBusy || _onHandFrame == null || _releasing) return;
    final now = DateTime.now();
    if (now.difference(_lastFrameAt) < frameInterval) return;
    _frameBusy = true;
    _lastFrameAt = now;
    try {
      final jpeg = await cameraImageToJpeg(image, quality: 90);
      if (jpeg == null || _onHandFrame == null) return;
      final mirror = (_active ?? state.value)?.description.lensDirection ==
          CameraLensDirection.front;
      final hand = prepareHandSpellFrame(
        jpeg,
        outSize: 256,
        jpegQuality: 90,
        mirrorHorizontal: mirror,
      );
      _onHandFrame!(hand.jpeg, handDetected: hand.detected);
    } finally {
      _frameBusy = false;
    }
  }

  /// Capture one-shot JPEG (même qualité qu'un import) → crop main.
  Future<({Uint8List jpeg, bool handDetected})?> captureHandStill() async {
    final controller = await ensureCamera();
    if (controller == null) return null;
    final file = await takePicture();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final mirror =
        controller.description.lensDirection == CameraLensDirection.front;
    final hand = prepareHandSpellFrame(
      bytes,
      outSize: 256,
      jpegQuality: 90,
      mirrorHorizontal: mirror,
    );
    return (jpeg: hand.jpeg, handDetected: hand.detected);
  }
}

@riverpod
class CameraSettings extends _$CameraSettings {
  @override
  Map<String, dynamic> build() {
    return {
      'showGrid': false,
      'resolution': _capturePreset,
      'flashMode': FlashMode.off,
      'isRecording': false,
      'recordingDuration': 0,
    };
  }

  void toggleGrid() {
    state = {...state, 'showGrid': !state['showGrid']};
  }

  void setResolution(ResolutionPreset resolution) {
    state = {...state, 'resolution': resolution};
  }

  void setRecording(bool isRecording) {
    state = {...state, 'isRecording': isRecording};
  }

  void updateRecordingDuration(int seconds) {
    state = {...state, 'recordingDuration': seconds};
  }
}
