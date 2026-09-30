import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
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
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  void Function(Uint8List handJpeg, {required bool handDetected})? _onHandFrame;

  /// Intervalle min entre deux envois ML (latence réseau + inférence).
  static const frameInterval = Duration(milliseconds: 280);

  @override
  FutureOr<CameraController?> build() async {
    ref.onDispose(() {
      unawaited(stopHandFrameStream());
      _active?.dispose();
      _active = null;
    });

    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;

    final controller = CameraController(
      cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      ),
      _capturePreset,
      enableAudio: false,
      imageFormatGroup: kIsWeb
          ? ImageFormatGroup.jpeg
          : ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      _active = controller;
      return controller;
    } catch (e) {
      // Repli sans format forcé (web / appareils capricieux).
      try {
        final fallback = CameraController(
          cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          ),
          _capturePreset,
          enableAudio: false,
        );
        await fallback.initialize();
        _active = fallback;
        return fallback;
      } catch (_) {
        controller.dispose();
        return null;
      }
    }
  }

  Future<void> switchCamera() async {
    final controller = state.value;
    if (controller == null) return;
    await stopHandFrameStream();

    final cameras = await availableCameras();
    final currentCamera = controller.description;
    final newCamera = cameras.firstWhere(
      (c) => c.lensDirection != currentCamera.lensDirection,
      orElse: () => currentCamera,
    );

    if (newCamera == currentCamera) return;

    _active = null;
    await controller.dispose();

    final newController = CameraController(
      newCamera,
      _capturePreset,
      enableAudio: false,
      imageFormatGroup: kIsWeb ? ImageFormatGroup.jpeg : ImageFormatGroup.yuv420,
    );

    try {
      await newController.initialize();
      _active = newController;
      state = AsyncData(newController);
    } catch (_) {
      await newController.dispose();
      final plain = CameraController(newCamera, _capturePreset, enableAudio: false);
      await plain.initialize();
      _active = plain;
      state = AsyncData(plain);
    }
  }

  Future<XFile?> takePicture() async {
    final controller = state.value;
    if (controller == null || !controller.value.isInitialized) return null;
    if (controller.value.isStreamingImages) return null;
    return controller.takePicture();
  }

  Future<void> startVideoRecording() async {
    final controller = state.value;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isRecordingVideo) return;
    await controller.startVideoRecording();
    state = AsyncData(controller);
  }

  Future<XFile?> stopVideoRecording() async {
    final controller = state.value;
    if (controller == null || !controller.value.isInitialized) return null;
    if (!controller.value.isRecordingVideo) return null;
    final file = await controller.stopVideoRecording();
    state = AsyncData(controller);
    return file;
  }

  Future<void> setZoomLevel(double zoom) async {
    final controller = state.value;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setZoomLevel(zoom);
  }

  /// Démarre le flux : chaque frame → détection main → JPEG crop → callback.
  Future<bool> startHandFrameStream(
    void Function(Uint8List handJpeg, {required bool handDetected}) onFrame,
  ) async {
    final controller = state.value;
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
    if (state.hasValue) state = AsyncData(controller);
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_frameBusy || _onHandFrame == null) return;
    final now = DateTime.now();
    if (now.difference(_lastFrameAt) < frameInterval) return;
    _frameBusy = true;
    _lastFrameAt = now;
    try {
      final jpeg = await cameraImageToJpeg(image, quality: 90);
      if (jpeg == null || _onHandFrame == null) return;
      final mirror = state.value?.description.lensDirection == CameraLensDirection.front;
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
    final controller = state.value;
    final file = await takePicture();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final mirror =
        controller?.description.lensDirection == CameraLensDirection.front;
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
