import 'package:camera/camera.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';

part 'camera_provider.g.dart';

/// Inference only needs single stills of the signer's hands: medium keeps them
/// sharp enough while costing far less sensor, ISP and battery than 720p.
const _capturePreset = ResolutionPreset.medium;

@riverpod
class CameraState extends _$CameraState {
  CameraController? _active;

  @override
  FutureOr<CameraController?> build() async {
    ref.onDispose(() {
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
    );

    try {
      await controller.initialize();
      _active = controller;
      return controller;
    } catch (e) {
      controller.dispose();
      return null;
    }
  }

  Future<void> switchCamera() async {
    final controller = state.value;
    if (controller == null) return;

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
    );

    await newController.initialize();
    _active = newController;
    state = AsyncData(newController);
  }

  Future<XFile?> takePicture() async {
    final controller = state.value;
    if (controller == null || !controller.value.isInitialized) return null;
    return await controller.takePicture();
  }

  Future<void> startVideoRecording() async {
    final controller = state.value;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isRecordingVideo) return;

    await controller.startVideoRecording();
    state = AsyncData(controller); // Trigger UI update
  }

  Future<XFile?> stopVideoRecording() async {
    final controller = state.value;
    if (controller == null || !controller.value.isInitialized) return null;
    if (!controller.value.isRecordingVideo) return null;

    final file = await controller.stopVideoRecording();
    state = AsyncData(controller); // Trigger UI update
    return file;
  }

  Future<void> setZoomLevel(double zoom) async {
    final controller = state.value;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setZoomLevel(zoom);
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
