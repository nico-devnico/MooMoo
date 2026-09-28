import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

/// Number of points MediaPipe gives per body part.
const int kPosePoints = 33;
const int kHandPoints = 21;

/// Last pose index drawn: face, arms and hips.
const int kUpperBodyLast = 24;

/// One instant of a sign: body and hands, in normalised image coordinates
/// (0..1, y pointing down). A missing part is null.
class LandmarkFrame {
  const LandmarkFrame({this.pose, this.leftHand, this.rightHand});

  final List<Offset>? pose;
  final List<Offset>? leftHand;
  final List<Offset>? rightHand;

  bool get isEmpty => pose == null && leftHand == null && rightHand == null;
}

/// Recorded landmarks of a sign: a single pose or a sequence extracted from a
/// video or a GIF.
///
/// [parse] accepts every shape the app has produced so far, so a sign never
/// shows an empty viewer because of how its data was exported:
/// - `{points: [{x, y, z?}, …]}` – one frame (21 = one hand, 42 = two hands,
///   33 = body, 75 = body + both hands);
/// - `{frames: [...], fps?}` where each frame is a flat MediaPipe Holistic
///   vector (pose 33×4, left hand 21×3, right hand 21×3, optional face), a
///   list of points, or a `{pose, left_hand, right_hand}` map;
/// - `{pose, left_hand, right_hand}` at the top level.
/// Coordinates may be ints, `[x, y, z]` lists or pixels (with `width` and
/// `height`).
class SignLandmarks {
  const SignLandmarks({required this.frames, this.fps = 15});

  static const empty = SignLandmarks(frames: []);

  final List<LandmarkFrame> frames;
  final double fps;

  bool get isEmpty => frames.isEmpty;
  bool get isAnimated => frames.length > 1;

  Duration get duration => Duration(
        milliseconds: (frames.length / (fps <= 0 ? 15 : fps) * 1000).round(),
      );

  /// Smallest box holding the hands and upper body over the whole sign, so
  /// the viewer can zoom on the signer instead of drawing a tiny figure in a
  /// corner. Legs are left out: MediaPipe guesses them even off-screen.
  Rect? get bounds {
    double? minX, minY, maxX, maxY;
    for (final frame in frames) {
      final pose = frame.pose;
      final points = [
        if (pose != null)
          for (var i = 0; i < pose.length && i <= kUpperBodyLast; i++)
            if (pose[i] != Offset.zero) pose[i],
        ...?frame.leftHand?.where((p) => p != Offset.zero),
        ...?frame.rightHand?.where((p) => p != Offset.zero),
      ];
      for (final p in points) {
        minX = minX == null ? p.dx : math.min(minX, p.dx);
        minY = minY == null ? p.dy : math.min(minY, p.dy);
        maxX = maxX == null ? p.dx : math.max(maxX, p.dx);
        maxY = maxY == null ? p.dy : math.max(maxY, p.dy);
      }
    }
    if (minX == null) return null;
    return Rect.fromLTRB(minX, minY!, maxX!, maxY!);
  }

  static SignLandmarks parse(Object? data) {
    try {
      return _parse(data);
    } catch (_) {
      return empty;
    }
  }

  static SignLandmarks _parse(Object? data) {
    if (data is! Map) {
      if (data is List) return _fromFrameList(data, const _Scale());
      return empty;
    }
    final scale = _Scale.from(data);
    final fps = _num(data['fps']) ?? _num(data['frame_rate']) ?? 15;

    final rawFrames = data['frames'] ?? data['sequence'];
    if (rawFrames is List) {
      final parsed = _fromFrameList(rawFrames, scale);
      return SignLandmarks(frames: parsed.frames, fps: fps);
    }

    final single = _frame(data['points'] ?? data, scale);
    return single == null || single.isEmpty
        ? empty
        : SignLandmarks(frames: [single], fps: fps);
  }

  static SignLandmarks _fromFrameList(List raw, _Scale scale) {
    final frames = <LandmarkFrame>[];
    for (final item in raw) {
      final frame = _frame(item is Map && item['points'] is List ? item['points'] : item, scale);
      if (frame != null && !frame.isEmpty) frames.add(frame);
    }
    return SignLandmarks(frames: frames);
  }

  static LandmarkFrame? _frame(Object? raw, _Scale scale) {
    if (raw is Map) {
      final pose = _points(raw['pose'] ?? raw['pose_landmarks'] ?? raw['body'], scale, 4);
      final left = _points(
        raw['left_hand'] ?? raw['leftHand'] ?? raw['left_hand_landmarks'] ?? raw['left'],
        scale,
        3,
      );
      final right = _points(
        raw['right_hand'] ?? raw['rightHand'] ?? raw['right_hand_landmarks'] ?? raw['right'],
        scale,
        3,
      );
      if (pose == null && left == null && right == null) {
        final hand = _points(raw['hand'] ?? raw['hands'], scale, 3);
        return hand == null ? null : _split(hand);
      }
      return LandmarkFrame(
        pose: _visible(pose, kPosePoints),
        leftHand: _visible(left, kHandPoints),
        rightHand: _visible(right, kHandPoints),
      );
    }
    if (raw is! List || raw.isEmpty) return null;

    // Flat Holistic vector, as written by the ML extraction.
    if (raw.first is num) {
      final values = [for (final v in raw) (v as num).toDouble()];
      const poseSize = kPosePoints * 4;
      const handSize = kHandPoints * 3;
      if (values.length >= poseSize + 2 * handSize) {
        return LandmarkFrame(
          pose: _visible(_chunk(values, 0, kPosePoints, 4, scale), kPosePoints),
          leftHand: _visible(_chunk(values, poseSize, kHandPoints, 3, scale), kHandPoints),
          rightHand: _visible(
            _chunk(values, poseSize + handSize, kHandPoints, 3, scale),
            kHandPoints,
          ),
        );
      }
      if (values.length >= 2 * handSize) {
        return LandmarkFrame(
          leftHand: _visible(_chunk(values, 0, kHandPoints, 3, scale), kHandPoints),
          rightHand: _visible(_chunk(values, handSize, kHandPoints, 3, scale), kHandPoints),
        );
      }
      if (values.length >= handSize) {
        return LandmarkFrame(
          rightHand: _visible(_chunk(values, 0, kHandPoints, 3, scale), kHandPoints),
        );
      }
      return null;
    }

    final points = _points(raw, scale, 3);
    return points == null ? null : _split(points);
  }

  /// Splits a plain list of points by its size.
  static LandmarkFrame _split(List<Offset?> points) {
    List<Offset?> part(int start, int count) => points.sublist(start, start + count);
    switch (points.length) {
      case >= kPosePoints + 2 * kHandPoints:
        return LandmarkFrame(
          pose: _visible(part(0, kPosePoints), kPosePoints),
          leftHand: _visible(part(kPosePoints, kHandPoints), kHandPoints),
          rightHand: _visible(part(kPosePoints + kHandPoints, kHandPoints), kHandPoints),
        );
      case >= 2 * kHandPoints:
        return LandmarkFrame(
          leftHand: _visible(part(0, kHandPoints), kHandPoints),
          rightHand: _visible(part(kHandPoints, kHandPoints), kHandPoints),
        );
      case >= kPosePoints:
        return LandmarkFrame(pose: _visible(part(0, kPosePoints), kPosePoints));
      default:
        // A single hand, possibly partial: keep what there is.
        return LandmarkFrame(rightHand: _visible(points, points.length));
    }
  }

  static List<Offset?>? _points(Object? raw, _Scale scale, int dims) {
    if (raw is! List || raw.isEmpty) return null;
    if (raw.first is num) {
      final values = [for (final v in raw) (v as num).toDouble()];
      final perPoint = values.length % 4 == 0 && values.length ~/ 4 == kPosePoints ? 4 : dims;
      return _chunk(values, 0, values.length ~/ perPoint, perPoint, scale);
    }
    return [for (final p in raw) _point(p, scale)];
  }

  static Offset? _point(Object? p, _Scale scale) {
    double? x, y;
    if (p is Map) {
      x = _num(p['x']);
      y = _num(p['y']);
    } else if (p is List && p.length >= 2) {
      x = _num(p[0]);
      y = _num(p[1]);
    }
    if (x == null || y == null) return null;
    return scale.apply(x, y);
  }

  static List<Offset?> _chunk(List<double> v, int start, int count, int dims, _Scale scale) {
    return [
      for (var i = 0; i < count; i++)
        if (start + i * dims + 1 < v.length)
          scale.apply(v[start + i * dims], v[start + i * dims + 1])
        else
          null,
    ];
  }

  /// MediaPipe writes zeros for an undetected part: treat it as missing.
  static List<Offset>? _visible(List<Offset?>? points, int expected) {
    if (points == null) return null;
    final kept = <Offset>[];
    var detected = 0;
    for (final p in points) {
      final valid = p != null && (p.dx != 0 || p.dy != 0);
      if (valid) detected++;
      kept.add(p ?? Offset.zero);
    }
    if (detected == 0) return null;
    return kept.length >= expected ? kept.sublist(0, expected) : kept;
  }

  static double? _num(Object? v) => v is num ? v.toDouble() : null;
}

class _Scale {
  const _Scale({this.width, this.height});

  factory _Scale.from(Map data) {
    final w = data['width'] ?? data['image_width'];
    final h = data['height'] ?? data['image_height'];
    return _Scale(
      width: w is num && w > 0 ? w.toDouble() : null,
      height: h is num && h > 0 ? h.toDouble() : null,
    );
  }

  final double? width;
  final double? height;

  Offset apply(double x, double y) {
    final w = width;
    final h = height;
    if (w != null && h != null && (x > 1.5 || y > 1.5)) {
      return Offset(x / w, y / h);
    }
    return Offset(x, y);
  }
}
