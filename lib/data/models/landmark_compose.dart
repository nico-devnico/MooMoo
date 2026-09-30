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
  });

  final bool ok;
  final SignLandmarks landmarks;
  final List<LandmarkSegment> segments;
  final List<LandmarkMissing> missing;
  final String? errorCode;
  final String? errorMessage;

  factory LandmarkComposeResult.fromJson(Map<String, dynamic> json) {
    final frames = json['frames'];
    final fps = (json['fps'] as num?)?.toDouble() ?? 15;
    final landmarks = SignLandmarks.parse({
      'frames': frames,
      'fps': fps,
    });
    return LandmarkComposeResult(
      ok: json['ok'] == true && landmarks.frames.isNotEmpty,
      landmarks: landmarks,
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
