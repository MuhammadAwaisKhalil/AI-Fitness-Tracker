import 'dart:math' as math;

/// Angle in degrees at joint b, formed by the segments b->a and b->c.
///
/// a, b, c are joint dictionaries from joint mapping containing 'x' and 'y'.
/// Returns a value between 0 and 180.
///
/// Pure Dart translation of `calculate_angle` from `exercises.py`.
double calculateAngle(
  Map<String, dynamic> a,
  Map<String, dynamic> b,
  Map<String, dynamic> c,
) {
  final double ax = (a['x'] as num).toDouble();
  final double ay = (a['y'] as num).toDouble();
  final double bx = (b['x'] as num).toDouble();
  final double by = (b['y'] as num).toDouble();
  final double cx = (c['x'] as num).toDouble();
  final double cy = (c['y'] as num).toDouble();

  // atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x)
  final double radC = math.atan2(cy - by, cx - bx);
  final double radA = math.atan2(ay - by, ax - bx);

  // Convert radians difference to degrees: rad * (180 / pi)
  final double diffDegrees = (radC - radA) * (180.0 / math.pi);
  double angle = diffDegrees.abs();

  return angle > 180.0 ? (360.0 - angle) : angle;
}

