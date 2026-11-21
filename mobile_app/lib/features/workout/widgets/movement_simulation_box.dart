import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../ml/models/exercise_spec.dart';
import '../../../ml/rep_counter.dart';

/// High-tech Motion Capture (MoCap) simulation box.
///
/// Features:
/// 1. Full-Body Guarantee: ALWAYS renders the complete human body from head to feet
///    at all times, regardless of camera framing or occluded limbs.
/// 2. Maximizable View: Toggle between corner PiP card and an enlarged, full-stage MoCap view.
/// 3. Biomechanical Joint Tracking: Highlights active exercise joints with dynamic degree telemetry.
class MovementSimulationBox extends StatefulWidget {
  final Map<String, dynamic> joints;
  final Size imageSize;
  final bool isMirrored;
  final RepCounter counter;
  final VoidCallback? onToggleFullScreenSkeleton;
  final bool isFullScreenSkeleton;
  final bool isMaximized;
  final VoidCallback onToggleMaximize;

  const MovementSimulationBox({
    Key? key,
    required this.joints,
    required this.imageSize,
    required this.counter,
    this.isMirrored = true,
    this.onToggleFullScreenSkeleton,
    this.isFullScreenSkeleton = false,
    this.isMaximized = false,
    required this.onToggleMaximize,
  }) : super(key: key);

  @override
  State<MovementSimulationBox> createState() => _MovementSimulationBoxState();
}

class _MovementSimulationBoxState extends State<MovementSimulationBox>
    with SingleTickerProviderStateMixin {
  bool _isMinimized = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.counter.spec;
    final hasJoints = widget.joints.isNotEmpty;

    if (_isMinimized && !widget.isMaximized) {
      return GestureDetector(
        onTap: () => setState(() => _isMinimized = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.accessibility_new, color: Color(0xFF00E5FF), size: 16),
              SizedBox(width: 6),
              Text(
                'MOCAP AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17).withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: spec.category.color.withOpacity(widget.isMaximized ? 0.9 : 0.6),
          width: widget.isMaximized ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.85),
            blurRadius: widget.isMaximized ? 24 : 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: spec.category.color.withOpacity(widget.isMaximized ? 0.35 : 0.2),
            blurRadius: widget.isMaximized ? 18 : 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            // 1. Perspective MoCap Grid Background
            Positioned.fill(
              child: CustomPaint(
                painter: _MocapGridPainter(isMaximized: widget.isMaximized),
              ),
            ),

            // 2. Full-Body Guaranteed Avatar Movement Simulation
            Positioned.fill(
              child: CustomPaint(
                painter: _FullBodyAvatarPainter(
                  joints: widget.joints,
                  isMirrored: widget.isMirrored,
                  spec: spec,
                  currentAngle: widget.counter.angle,
                  pulseValue: _pulseController.value,
                  isMaximized: widget.isMaximized,
                ),
              ),
            ),

            // 3. Top Header Bar (Status & Actions)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.70),
                  border: const Border(
                    bottom: BorderSide(color: Colors.white10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasJoints
                                ? const Color(0xFF76FF03)
                                : const Color(0xFFFF5252),
                            boxShadow: [
                              BoxShadow(
                                color: (hasJoints
                                        ? const Color(0xFF76FF03)
                                        : const Color(0xFFFF5252))
                                    .withOpacity(0.8),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isMaximized ? 'MOCAP AI STAGE • FULL BODY' : 'MOCAP AI',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // MAXIMIZE / RESTORE BUTTON
                        InkWell(
                          onTap: widget.onToggleMaximize,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                            child: Icon(
                              widget.isMaximized
                                  ? Icons.close_fullscreen
                                  : Icons.open_in_full,
                              size: 15,
                              color: const Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Toggle Full-screen camera skeleton overlay
                        if (widget.onToggleFullScreenSkeleton != null)
                          InkWell(
                            onTap: widget.onToggleFullScreenSkeleton,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: Icon(
                                widget.isFullScreenSkeleton
                                    ? Icons.layers
                                    : Icons.layers_outlined,
                                size: 14,
                                color: widget.isFullScreenSkeleton
                                    ? const Color(0xFF00E5FF)
                                    : Colors.white54,
                              ),
                            ),
                          ),
                        if (!widget.isMaximized) ...[
                          const SizedBox(width: 4),
                          // Minimize button
                          InkWell(
                            onTap: () => setState(() => _isMinimized = true),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3.0),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Active Joint Telemetry Pill
            Positioned(
              bottom: 6,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.80),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      spec.joints.isNotEmpty
                          ? 'TRACKING: ${spec.joints[1].toUpperCase()}'
                          : 'FULL BODY TRACKING',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.counter.angle != null
                          ? '${widget.counter.angle!.toInt()}°'
                          : '--',
                      style: TextStyle(
                        color: spec.category.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Detection Status Indicator
            if (!hasJoints)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Text(
                      'STEP IN VIEW\nINITIALIZING KINEMATICS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paints high-tech perspective floor grid lines
class _MocapGridPainter extends CustomPainter {
  final bool isMaximized;
  _MocapGridPainter({this.isMaximized = false});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.06)
      ..strokeWidth = 1.0;

    final step = isMaximized ? 28.0 : 18.0;

    // Horizontal lines
    for (double y = 20; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Vertical lines
    for (double x = 12; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MocapGridPainter oldDelegate) =>
      oldDelegate.isMaximized != isMaximized;
}

/// CustomPainter that GUARANTEES the entire human body (head, torso, arms,
/// hips, legs, feet) is ALWAYS completely visible inside the MoCap viewport,
/// even when the camera only captures upper body or parts of the user.
class _FullBodyAvatarPainter extends CustomPainter {
  final Map<String, dynamic> joints;
  final bool isMirrored;
  final ExerciseSpec spec;
  final double? currentAngle;
  final double pulseValue;
  final bool isMaximized;

  _FullBodyAvatarPainter({
    required this.joints,
    required this.isMirrored,
    required this.spec,
    required this.currentAngle,
    required this.pulseValue,
    required this.isMaximized,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // -------------------------------------------------------------------
    // 1. CANONICAL FULL-BODY ANCHOR REFERENCE (Head to Toe)
    // -------------------------------------------------------------------
    // We map the virtual human body into a guaranteed bounding box inside the canvas:
    final double topMargin = isMaximized ? 36.0 : 26.0;
    final double bottomMargin = isMaximized ? 32.0 : 24.0;
    final double avatarHeight = size.height - topMargin - bottomMargin;
    final double centerX = size.width / 2.0;

    // Default neutral human anatomy proportions (relative to avatarHeight):
    // Head: 0.08, Shoulders: 0.20, Elbows: 0.35, Wrists: 0.50
    // Mid-Hip: 0.50, Knees: 0.72, Ankles: 0.94
    final double shoulderSpan = avatarHeight * 0.28;
    final double hipSpan = avatarHeight * 0.18;

    // Baseline neutral offsets for all joints:
    final Map<String, Offset> modelPoints = {
      'head': Offset(centerX, topMargin + (avatarHeight * 0.08)),
      'nose': Offset(centerX, topMargin + (avatarHeight * 0.08)),
      'chest': Offset(centerX, topMargin + (avatarHeight * 0.22)),
      'left_shoulder': Offset(centerX - (shoulderSpan / 2), topMargin + (avatarHeight * 0.20)),
      'right_shoulder': Offset(centerX + (shoulderSpan / 2), topMargin + (avatarHeight * 0.20)),
      'left_elbow': Offset(centerX - (shoulderSpan * 0.65), topMargin + (avatarHeight * 0.36)),
      'right_elbow': Offset(centerX + (shoulderSpan * 0.65), topMargin + (avatarHeight * 0.36)),
      'left_wrist': Offset(centerX - (shoulderSpan * 0.70), topMargin + (avatarHeight * 0.50)),
      'right_wrist': Offset(centerX + (shoulderSpan * 0.70), topMargin + (avatarHeight * 0.50)),
      'left_hip': Offset(centerX - (hipSpan / 2), topMargin + (avatarHeight * 0.50)),
      'right_hip': Offset(centerX + (hipSpan / 2), topMargin + (avatarHeight * 0.50)),
      'left_knee': Offset(centerX - (hipSpan * 0.60), topMargin + (avatarHeight * 0.72)),
      'right_knee': Offset(centerX + (hipSpan * 0.60), topMargin + (avatarHeight * 0.72)),
      'left_ankle': Offset(centerX - (hipSpan * 0.65), topMargin + (avatarHeight * 0.94)),
      'right_ankle': Offset(centerX + (hipSpan * 0.65), topMargin + (avatarHeight * 0.94)),
    };

    final Map<String, bool> isJointDetected = {};

    // -------------------------------------------------------------------
    // 2. KINEMATIC INTEGRATION WITH LIVE DETECTED ML JOINTS
    // -------------------------------------------------------------------
    if (joints.isNotEmpty) {
      // Find bounding coordinates of detected joints
      double rawMinX = double.infinity, rawMaxX = -double.infinity;
      double rawMinY = double.infinity, rawMaxY = -double.infinity;
      int visibleCount = 0;

      joints.forEach((name, data) {
        final double vis = (data['visibility'] as num).toDouble();
        if (vis >= 0.4) {
          final double x = (data['x'] as num).toDouble();
          final double y = (data['y'] as num).toDouble();
          if (x < rawMinX) rawMinX = x;
          if (x > rawMaxX) rawMaxX = x;
          if (y < rawMinY) rawMinY = y;
          if (y > rawMaxY) rawMaxY = y;
          visibleCount++;
        }
      });

      if (visibleCount >= 3 && rawMaxX > rawMinX && rawMaxY > rawMinY) {
        // Detect whether full body or upper body is visible
        final bool hasAnkles = (joints.containsKey('left_ankle') &&
                (joints['left_ankle']['visibility'] as num) >= 0.4) ||
            (joints.containsKey('right_ankle') &&
                (joints['right_ankle']['visibility'] as num) >= 0.4);

        final bool hasShoulders = (joints.containsKey('left_shoulder') &&
                (joints['left_shoulder']['visibility'] as num) >= 0.4) &&
            (joints.containsKey('right_shoulder') &&
                (joints['right_shoulder']['visibility'] as num) >= 0.4);

        // Estimate full human standing scale even if only waist-up is in view
        double estimatedFullHeight = rawMaxY - rawMinY;
        double estimatedTopHead = rawMinY;

        if (hasShoulders && !hasAnkles) {
          // Torso is only ~35% of total height; scale up to full body so legs stay anchored!
          estimatedFullHeight = (rawMaxY - rawMinY) / 0.45;
        }

        final double rawBodyWidth = (rawMaxX - rawMinX).clamp(estimatedFullHeight * 0.25, estimatedFullHeight * 0.6);
        final double scaleY = avatarHeight / estimatedFullHeight;
        final double scaleX = (avatarHeight * 0.4) / rawBodyWidth;
        final double scale = math.min(scaleX, scaleY);

        final double midRawX = (rawMinX + rawMaxX) / 2.0;

        joints.forEach((name, data) {
          final double vis = (data['visibility'] as num).toDouble();
          if (vis >= 0.4) {
            final double rx = (data['x'] as num).toDouble();
            final double ry = (data['y'] as num).toDouble();

            double relX = (rx - midRawX) * scale;
            if (isMirrored) {
              relX = -relX;
            }

            final double relY = topMargin + ((ry - estimatedTopHead) * scale).clamp(0.0, avatarHeight);
            final double finalX = (centerX + relX).clamp(12.0, size.width - 12.0);

            modelPoints[name] = Offset(finalX, relY);
            isJointDetected[name] = true;
          }
        });
      }
    }

    // -------------------------------------------------------------------
    // 3. RENDER FULL ANATOMICAL SKELETON
    // -------------------------------------------------------------------
    final Paint normalBonePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.7)
      ..strokeWidth = isMaximized ? 3.5 : 2.5
      ..strokeCap = StrokeCap.round;

    final Paint activeBonePaint = Paint()
      ..color = spec.category.color.withOpacity(0.95)
      ..strokeWidth = isMaximized ? 4.5 : 3.5
      ..strokeCap = StrokeCap.round;

    final Paint unobservedBonePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const List<List<String>> connections = [
      // Torso
      ['left_shoulder', 'right_shoulder'],
      ['left_shoulder', 'left_hip'],
      ['right_shoulder', 'right_hip'],
      ['left_hip', 'right_hip'],
      // Left Arm
      ['left_shoulder', 'left_elbow'],
      ['left_elbow', 'left_wrist'],
      // Right Arm
      ['right_shoulder', 'right_elbow'],
      ['right_elbow', 'right_wrist'],
      // Left Leg
      ['left_hip', 'left_knee'],
      ['left_knee', 'left_ankle'],
      // Right Leg
      ['right_hip', 'right_knee'],
      ['right_knee', 'right_ankle'],
    ];

    final activeJointNames = spec.joints;
    bool isConnectionActive(String a, String b) {
      final aActive = activeJointNames.any((name) => a.contains(name));
      final bActive = activeJointNames.any((name) => b.contains(name));
      return aActive && bActive;
    }

    // Draw Bones
    for (final conn in connections) {
      final p1 = modelPoints[conn[0]];
      final p2 = modelPoints[conn[1]];
      if (p1 != null && p2 != null) {
        final p1Detected = isJointDetected[conn[0]] ?? false;
        final p2Detected = isJointDetected[conn[1]] ?? false;

        Paint paintToUse;
        if (!p1Detected && !p2Detected) {
          paintToUse = unobservedBonePaint;
        } else if (isConnectionActive(conn[0], conn[1])) {
          paintToUse = activeBonePaint;
        } else {
          paintToUse = normalBonePaint;
        }

        canvas.drawLine(p1, p2, paintToUse);
      }
    }

    // Draw Head
    final leftSh = modelPoints['left_shoulder'];
    final rightSh = modelPoints['right_shoulder'];
    final headPt = modelPoints['nose'] ?? modelPoints['head'];

    Offset finalHeadPt = headPt ?? Offset(centerX, topMargin + 14);
    if (leftSh != null && rightSh != null) {
      final midSh = (leftSh + rightSh) / 2;
      finalHeadPt = Offset(midSh.dx, math.min(midSh.dy - (isMaximized ? 18 : 12), finalHeadPt.dy));
    }

    final double headRadius = isMaximized ? 10.0 : 6.5;
    final headPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    final headBorder = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(finalHeadPt, headRadius, headPaint);
    canvas.drawCircle(finalHeadPt, headRadius, headBorder);

    // -------------------------------------------------------------------
    // 4. DRAW ALL JOINTS WITH ACTIVE HIGHLIGHTS & DEGREE READOUTS
    // -------------------------------------------------------------------
    modelPoints.forEach((name, pt) {
      if (name == 'head' || name == 'chest') return;

      final isDetected = isJointDetected[name] ?? false;
      final isTargetVertex = activeJointNames.length > 1 && name.contains(activeJointNames[1]);
      final isTargetLimb = activeJointNames.any((j) => name.contains(j));

      if (isTargetVertex && isDetected) {
        // Glowing vertex pulse
        final double glowRadius = (isMaximized ? 8.0 : 5.0) + (pulseValue * 4.0);
        final Paint glowPaint = Paint()
          ..color = spec.category.color.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, glowRadius, glowPaint);

        // Core vertex circle
        final Paint vertexPaint = Paint()
          ..color = spec.category.color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, isMaximized ? 6.0 : 4.5, vertexPaint);

        final Paint borderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(pt, isMaximized ? 6.0 : 4.5, borderPaint);

        // If maximized, render joint degree text right beside vertex!
        if (isMaximized && currentAngle != null) {
          final textSpan = TextSpan(
            text: '${currentAngle!.toInt()}°',
            style: TextStyle(
              color: spec.category.color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(canvas, Offset(pt.dx + 8, pt.dy - 6));
        }
      } else if (isTargetLimb && isDetected) {
        final Paint limbPaint = Paint()
          ..color = const Color(0xFF76FF03)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, isMaximized ? 4.5 : 3.5, limbPaint);
      } else if (isDetected) {
        final Paint standardPaint = Paint()
          ..color = const Color(0xFF00E5FF)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, isMaximized ? 3.5 : 2.5, standardPaint);
      } else {
        // Unobserved joint in full-body anchor
        final Paint phantomPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 2.0, phantomPaint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant _FullBodyAvatarPainter oldDelegate) {
    return oldDelegate.joints != joints ||
        oldDelegate.isMirrored != isMirrored ||
        oldDelegate.currentAngle != currentAngle ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isMaximized != isMaximized;
  }
}
