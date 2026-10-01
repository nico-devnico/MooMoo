import 'dart:ui' show Offset;

import '../models/sign_landmarks.dart';

/// One resolved dictionary clip before landmark extraction.
class TextToSignClip {
  const TextToSignClip({
    required this.word,
    required this.url,
    this.signId,
    this.matchedWord,
  });

  final String word;
  final String url;
  final String? signId;
  final String? matchedWord;

  Map<String, dynamic> toJson() => {
        'word': matchedWord ?? word,
        'url': url,
        if (signId != null) 'sign_id': signId,
      };
}

/// Result of composing several dictionary medias into one landmark sequence.
class LandmarkComposeResult {
  const LandmarkComposeResult({
    required this.ok,
    required this.landmarks,
    this.segments = const [],
    this.missing = const [],
    this.errorCode,
    this.errorMessage,
    this.rawFrames,
    this.fps = 15,
  });

  final bool ok;
  final SignLandmarks landmarks;
  final List<LandmarkSegment> segments;
  final List<LandmarkMissing> missing;
  final String? errorCode;
  final String? errorMessage;

  /// Flat Holistic vectors `[pose33×4 | left21×3 | right21×3 | face?]`, kept for
  /// 3D retargeting (XYZ). Null when only 2D landmark JSON was available.
  final List<List<double>>? rawFrames;
  final double fps;

  /// Payload consumed by the Mixamo rig script inside ModelViewer.
  Map<String, dynamic>? toRigPayload() {
    final raw = rawFrames;
    if (raw == null || raw.isEmpty) {
      return _rigPayloadFromLandmarks();
    }
    return {
      'fps': fps,
      'frames': [
        for (final v in raw) _holisticToRigFrame(v),
      ],
    };
  }

  Map<String, dynamic>? _rigPayloadFromLandmarks() {
    if (landmarks.isEmpty) return null;
    return {
      'fps': landmarks.fps,
      'frames': [
        for (final f in landmarks.frames)
          {
            'pose': [
              for (final p in f.pose ?? const <Offset>[])
                [p.dx, p.dy, 0.0],
            ],
            'leftHand': [
              for (final p in f.leftHand ?? const <Offset>[])
                [p.dx, p.dy, 0.0],
            ],
            'rightHand': [
              for (final p in f.rightHand ?? const <Offset>[])
                [p.dx, p.dy, 0.0],
            ],
          },
      ],
    };
  }

  static Map<String, dynamic> _holisticToRigFrame(List<double> v) {
    const poseSize = 33 * 4;
    const handSize = 21 * 3;
    List<List<double>> chunk(int start, int count, int dims) => [
          for (var i = 0; i < count; i++)
            if (start + i * dims + 1 < v.length)
              [
                v[start + i * dims],
                v[start + i * dims + 1],
                dims >= 3 && start + i * dims + 2 < v.length
                    ? v[start + i * dims + 2]
                    : 0.0,
              ]
            else
              [0.0, 0.0, 0.0],
        ];
    return {
      'pose': chunk(0, 33, 4),
      'leftHand':
          v.length >= poseSize + handSize ? chunk(poseSize, 21, 3) : <List<double>>[],
      'rightHand': v.length >= poseSize + 2 * handSize
          ? chunk(poseSize + handSize, 21, 3)
          : <List<double>>[],
    };
  }

  factory LandmarkComposeResult.fromJson(Map<String, dynamic> json) {
    final frames = json['frames'];
    final fps = (json['fps'] as num?)?.toDouble() ?? 15;
    final landmarks = SignLandmarks.parse({
      'frames': frames,
      'fps': fps,
    });
    List<List<double>>? raw;
    if (frames is List && frames.isNotEmpty && frames.first is List) {
      raw = [
        for (final f in frames)
          if (f is List && f.isNotEmpty && f.first is num)
            [for (final n in f) (n as num).toDouble()],
      ];
      if (raw.isEmpty) raw = null;
    }
    return LandmarkComposeResult(
      ok: json['ok'] == true && landmarks.frames.isNotEmpty,
      landmarks: landmarks,
      rawFrames: raw,
      fps: fps,
      segments: [
        for (final item in (json['segments'] as List? ?? const []))
          if (item is Map)
            LandmarkSegment.fromJson(Map<String, dynamic>.from(item)),
      ],
      missing: [
        for (final item in (json['missing'] as List? ?? const []))
          if (item is Map)
            LandmarkMissing.fromJson(Map<String, dynamic>.from(item)),
      ],
      errorCode: json['error'] as String?,
      errorMessage: json['message'] as String? ?? json['detail'] as String?,
    );
  }

  factory LandmarkComposeResult.unavailable(String message) {
    return LandmarkComposeResult(
      ok: false,
      landmarks: SignLandmarks.empty,
      errorCode: 'backend_unavailable',
      errorMessage: message,
    );
  }
}

class LandmarkSegment {
  const LandmarkSegment({
    required this.word,
    required this.startFrame,
    required this.frames,
    this.signId,
  });

  final String word;
  final int startFrame;
  final int frames;
  final String? signId;

  factory LandmarkSegment.fromJson(Map<String, dynamic> json) {
    return LandmarkSegment(
      word: json['word'] as String? ?? '',
      startFrame: (json['start_frame'] as num?)?.toInt() ?? 0,
      frames: (json['frames'] as num?)?.toInt() ?? 0,
      signId: json['sign_id'] as String?,
    );
  }
}

class LandmarkMissing {
  const LandmarkMissing({
    required this.word,
    this.reason,
    this.signId,
  });

  final String word;
  final String? reason;
  final String? signId;

  factory LandmarkMissing.fromJson(Map<String, dynamic> json) {
    return LandmarkMissing(
      word: json['word'] as String? ?? '',
      reason: json['reason'] as String?,
      signId: json['sign_id'] as String?,
    );
  }
}
