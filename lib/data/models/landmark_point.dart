class LandmarkPoint {
  final double x;
  final double y;
  final double? z;
  final String? label;

  const LandmarkPoint({
    required this.x,
    required this.y,
    this.z,
    this.label,
  });

  factory LandmarkPoint.fromJson(Map<String, dynamic> json) {
    return LandmarkPoint(
      x: json['x'] as double,
      y: json['y'] as double,
      z: json['z'] as double?,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'label': label,
    };
  }
}
