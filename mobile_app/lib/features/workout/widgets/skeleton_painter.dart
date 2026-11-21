import 'package:flutter/material.dart';

/// CustomPainter to render the detected pose skeleton on top of the live camera view.
/// Replicates `draw_landmarks` from MediaPipe / OpenCV in Flutter.
class SkeletonPainter extends CustomPainter {
  /// Joint dictionary formatted as:
  /// `{"left_shoulder": {"x": 100, "y": 200, "visibility": 0.95}, ...}`
  final Map<String, dynamic> joints;

  /// Native resolution of the camera frame processed by ML Kit.
  final Size imageSize;

  /// Whether the view is horizontally mirrored like an actual mirror reflection.
  final bool isMirrored;

  SkeletonPainter({
    required this.joints,
    required this.imageSize,
    this.isMirrored = true,
  });

  /// Pairwise joint connections (bones) to render.
  static const List<List<String>> _connections = [
    // Torso & Chest
    ['left_shoulder', 'right_shoulder'],
    ['left_shoulder', 'left_hip'],
    ['right_shoulder', 'right_hip'],
    ['left_hip', 'right_hip'],
    ['chest', 'left_shoulder'],
    ['chest', 'right_shoulder'],

    // Arms
    ['left_shoulder', 'left_elbow'],
    ['left_elbow', 'left_wrist'],
    ['right_shoulder', 'right_elbow'],
    ['right_elbow', 'right_wrist'],

    // Legs
    ['left_hip', 'left_knee'],
    ['left_knee', 'left_ankle'],
    ['right_hip', 'right_knee'],
    ['right_knee', 'right_ankle'],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (joints.isEmpty || imageSize.width == 0 || imageSize.height == 0) return;

    // Scale factors to map frame coordinates to widget canvas coordinates
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    // Paint for skeletal bones
    final Paint linePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.85)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Paint for joint markers
    final Paint jointPaint = Paint()
      ..color = const Color(0xFF76FF03)
      ..style = PaintingStyle.fill;

    final Paint jointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Offset? getJointOffset(String name) {
      if (!joints.containsKey(name)) return null;
      final joint = joints[name] as Map<String, dynamic>;
      final double vis = (joint['visibility'] as num).toDouble();
      if (vis < 0.5) return null; // Ignore low confidence points

      final double rawX = (joint['x'] as num).toDouble();
      final double rawY = (joint['y'] as num).toDouble();

      final double canvasX =
          isMirrored ? (size.width - (rawX * scaleX)) : (rawX * scaleX);
      final double canvasY = rawY * scaleY;

      return Offset(canvasX, canvasY);
    }

    // 1. Draw bones (connections)
    for (final connection in _connections) {
      final p1 = getJointOffset(connection[0]);
      final p2 = getJointOffset(connection[1]);

      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, linePaint);
      }
    }

    // 2. Draw joint dots
    for (final entry in joints.entries) {
      final offset = getJointOffset(entry.key);
      if (offset != null) {
        canvas.drawCircle(offset, 5.0, jointPaint);
        canvas.drawCircle(offset, 5.0, jointBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.joints != joints ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.isMirrored != isMirrored;
  }
}
