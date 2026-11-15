import 'package:flutter/material.dart';
import '../../../ml/rep_counter.dart';

/// Overlay widget displaying real-time exercise telemetry, rep counts, joint angles,
/// state machine stage, and live form feedback.
/// Replaces `draw_hud` from `webCam.py` with modern Flutter UI.
class HudOverlay extends StatelessWidget {
  final RepCounter counter;

  const HudOverlay({
    Key? key,
    required this.counter,
  }) : super(key: key);

  Color _getFeedbackColor(String feedback) {
    if (feedback.contains('Good rep!')) {
      return const Color(0xFF00E676); // Vibrant Green
    } else if (feedback.contains('Ready')) {
      return const Color(0xFF00E5FF); // Cyan
    } else if (feedback.contains('Step back')) {
      return const Color(0xFFFF5252); // Red
    } else if (feedback.contains('deeper') ||
        feedback.contains('further') ||
        feedback.contains('Keep your hips') ||
        feedback.contains('Curl all')) {
      return const Color(0xFFFFB300); // Amber Warning
    }
    return const Color(0xFF64B5F6); // Soft Blue default
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'extended':
        return const Color(0xFF00E676);
      case 'moving':
        return const Color(0xFFFFB300);
      case 'waiting':
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final angleTxt = counter.angle != null
        ? '${counter.angle!.toStringAsFixed(0)}°'
        : '--';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top telemetry card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: Colors.white12, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Rep count display
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          counter.spec.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${counter.reps}',
                              style: const TextStyle(
                                color: Color(0xFF76FF03),
                                fontSize: 48.0,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'REPS',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    height: 50,
                    width: 1,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),

                  // Angle & Stage indicators
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Angle readout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.straighten,
                              size: 16,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              angleTxt,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Stage chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getStageColor(counter.stage).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStageColor(counter.stage),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            counter.stage.toUpperCase(),
                            style: TextStyle(
                              color: _getStageColor(counter.stage),
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Feedback banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: _getFeedbackColor(counter.feedback).withOpacity(0.9),
                borderRadius: BorderRadius.circular(14.0),
                boxShadow: [
                  BoxShadow(
                    color: _getFeedbackColor(counter.feedback).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.black87,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      counter.feedback,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

