import 'package:flutter/material.dart';
import '../../../ml/models/exercise_spec.dart';
import '../../../ml/rep_counter.dart';

/// Refined HUD overlay with dual display modes:
/// - Full Expanded Mode: Detailed biomechanical telemetry, form score %, and setup cues.
/// - Minimized Focus Mode: Compact floating glass capsule to give 100% unobstructed camera view.
/// Built with strict overflow protection.
class HudOverlay extends StatelessWidget {
  final RepCounter counter;
  final bool showSwitchPrompt;
  final bool isMinimized;
  final VoidCallback onToggleMinimize;
  final VoidCallback? onDismissSwitchPrompt;

  const HudOverlay({
    Key? key,
    required this.counter,
    this.showSwitchPrompt = false,
    this.isMinimized = false,
    required this.onToggleMinimize,
    this.onDismissSwitchPrompt,
  }) : super(key: key);

  Color _getScoreColor(double score) {
    if (score >= 85) return const Color(0xFF76FF03);
    if (score >= 70) return const Color(0xFF00E5FF);
    return const Color(0xFFFFAB00);
  }

  Color _getFeedbackColor(String feedback) {
    if (feedback.contains('Clean') ||
        feedback.contains('Good') ||
        feedback.contains('Solid')) {
      return const Color(0xFF00E676);
    } else if (feedback.contains('Ready') || feedback.contains('Begin')) {
      return const Color(0xFF00E5FF);
    } else if (feedback.contains('Step back') ||
        feedback.contains('sagging') ||
        feedback.contains('lost')) {
      return const Color(0xFFFF5252);
    } else if (feedback.contains('deeper') ||
        feedback.contains('higher') ||
        feedback.contains('Chest') ||
        feedback.contains('Hips') ||
        feedback.contains('Lockout') ||
        feedback.contains('hands')) {
      return const Color(0xFFFFB300);
    }
    return const Color(0xFF40C4FF);
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'extended':
        return const Color(0xFF00E676);
      case 'holding':
        return const Color(0xFF76FF03);
      case 'moving':
        return const Color(0xFFFFB300);
      case 'break':
        return const Color(0xFFFF5252);
      case 'waiting':
      default:
        return Colors.white54;
    }
  }

  double _calculateRomProgress() {
    if (counter.angle == null) return 0.0;
    final spec = counter.spec;
    final totalRange = (spec.extended - spec.flexed).abs();
    if (totalRange <= 0) return 0.0;
    final currentDelta = (spec.extended - counter.angle!).abs();
    return (currentDelta / totalRange).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final spec = counter.spec;
    final angleTxt =
        counter.angle != null ? '${counter.angle!.toStringAsFixed(0)}°' : '--';
    final scoreColor = _getScoreColor(counter.formScore);

    // ----------------------------------------------------
    // 1. MINIMIZED FOCUS MODE (Overflow-Safe)
    // ----------------------------------------------------
    if (isMinimized) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: onToggleMinimize,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: spec.category.color.withOpacity(0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(spec.category.icon,
                              size: 13, color: spec.category.color),
                          const SizedBox(width: 5),
                          Text(
                            '${counter.reps} ${spec.isHoldBased ? 's' : 'reps'}',
                            style: TextStyle(
                              color: spec.isHoldBased
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0xFF76FF03),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 7),
                            width: 1,
                            height: 12,
                            color: Colors.white24,
                          ),
                          Text(
                            '${counter.formScore.toInt()}%',
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            angleTxt,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Expand Button
              InkWell(
                onTap: onToggleMinimize,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.unfold_more,
                    color: Color(0xFF00E5FF),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------
    // 2. FULL EXPANDED TELEMETRY MODE
    // ----------------------------------------------------
    final romProgress = _calculateRomProgress();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // TOP TELEMETRY CARD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: Colors.white12, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Category Tag, Exercise Name, Target Muscle, Minimize button
                  Row(
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: spec.category.color.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: spec.category.color, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(spec.category.icon,
                                size: 11, color: spec.category.color),
                            const SizedBox(width: 3),
                            Text(
                              spec.category.label.toUpperCase(),
                              style: TextStyle(
                                color: spec.category.color,
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Exercise Name
                      Expanded(
                        child: Text(
                          spec.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),

                      // Target Muscle Pill (Flexible to prevent any right-side overflow)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            spec.targetMuscle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Minimize / Focus View Button
                      InkWell(
                        onTap: onToggleMinimize,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(
                            Icons.visibility,
                            size: 15,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Row 2: Live Numbers, Form Score %, Angle, Stage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reps / Hold Seconds Display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${counter.reps}',
                                style: TextStyle(
                                  color: spec.isHoldBased
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF76FF03),
                                  fontSize: 38.0,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                spec.isHoldBased ? 'SEC' : 'REPS',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department,
                                  size: 12, color: Color(0xFFFF5252)),
                              const SizedBox(width: 2),
                              Text(
                                '${counter.caloriesBurned.toStringAsFixed(1)} kcal',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Form Score Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scoreColor, width: 1.2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${counter.formScore.toInt()}%',
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'FORM SCORE',
                              style: TextStyle(
                                color: scoreColor.withOpacity(0.9),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Angle & Stage Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.straighten,
                                  size: 13, color: Colors.white54),
                              const SizedBox(width: 3),
                              Text(
                                angleTxt,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStageColor(counter.stage)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getStageColor(counter.stage),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              counter.stage.toUpperCase(),
                              style: TextStyle(
                                color: _getStageColor(counter.stage),
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Range of Motion (ROM) dynamic depth bar
                  if (!spec.isHoldBased) ...[
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'DEPTH PROGRESSION',
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white38,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(romProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 9,
                                color: romProgress >= 0.95
                                    ? const Color(0xFF76FF03)
                                    : const Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: romProgress,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              romProgress >= 0.95
                                  ? const Color(0xFF76FF03)
                                  : const Color(0xFF00E5FF),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 6),

            // BIOMECHANICAL REAL-TIME COACHING BANNER
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: _getFeedbackColor(counter.feedback).withOpacity(0.92),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color:
                        _getFeedbackColor(counter.feedback).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports, color: Colors.black, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      counter.feedback,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // VISUAL SWITCHING / SETUP CUE
            if (showSwitchPrompt || counter.stage == 'waiting') ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: spec.category.color.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates,
                        color: spec.category.color, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spec.setupInstruction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            spec.visualCue,
                            style: TextStyle(
                              color: spec.category.color,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
