/// Represents a single body landmark joint with 2D pixel coordinates
/// and a visibility/confidence score.
///
/// Direct translation of the Python joint dictionary structure:
/// `{"x": int, "y": int, "visibility": float}`
class JointPoint {
  final int x;
  final int y;
  final double visibility;

  const JointPoint({
    required this.x,
    required this.y,
    required this.visibility,
  });

  /// Factory constructor to deserialize from a map.
  factory JointPoint.fromMap(Map<String, dynamic> map) {
    return JointPoint(
      x: (map['x'] as num).toInt(),
      y: (map['y'] as num).toInt(),
      visibility: (map['visibility'] as num).toDouble(),
    );
  }

  /// Serializes the joint point back to the dictionary structure.
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'visibility': visibility,
    };
  }

  @override
  String toString() => 'JointPoint(x: $x, y: $y, visibility: $visibility)';
}

