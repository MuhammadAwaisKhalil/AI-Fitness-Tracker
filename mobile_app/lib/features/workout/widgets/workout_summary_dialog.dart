import 'package:flutter/material.dart';
import '../../../core/storage/local_database.dart';

/// Modal dialog presented after finishing an exercise set.
/// Displays AI Form Diagnosis, Rep breakdown, and saves to history.
class WorkoutSummaryDialog extends StatelessWidget {
  final String exerciseName;
  final int totalReps;
  final int goodReps;
  final int partialReps;
  final int durationSeconds;
  final double formScore;
  final double caloriesBurned;
  final VoidCallback onSaved;

  const WorkoutSummaryDialog({
    Key? key,
    required this.exerciseName,
    required this.totalReps,
    required this.goodReps,
    required this.partialReps,
    required this.durationSeconds,
    required this.formScore,
    required this.caloriesBurned,
    required this.onSaved,
  }) : super(key: key);

  Color _getScoreColor() {
    if (formScore >= 85) return const Color(0xFF76FF03);
    if (formScore >= 70) return const Color(0xFF00E5FF);
    return const Color(0xFFFFAB00);
  }

  String _getDiagnosisFeedback() {
    if (totalReps == 0 && durationSeconds < 5) {
      return 'Set was too short to generate a full biomechanical evaluation.';
    }
    if (formScore >= 90) {
      return 'Outstanding form! Clean joint angles and consistent tempo across the entire set.';
    } else if (formScore >= 75) {
      return 'Solid execution! Minor deviations detected near the end of the set due to fatigue. Focus on full lockout.';
    } else {
      return 'Noticeable form breakdowns and partial reps. Reduce tempo or take longer rest periods to prevent injury.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final durationStr = '${minutes}m ${seconds}s';

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Workout Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      exerciseName,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form Score Ring / Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withOpacity(0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${formScore.toInt()}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const Text(
                      'Form Score',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stat Grid
              Row(
                children: [
                  Expanded(
                    child: _statCard('Total Reps', '$totalReps', Icons.fitness_center),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard('Clean Reps', '$goodReps', Icons.check_circle,
                        iconColor: const Color(0xFF76FF03)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _statCard('Duration', durationStr, Icons.timer),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      'Calories',
                      '${caloriesBurned.toStringAsFixed(1)} kcal',
                      Icons.local_fire_department,
                      iconColor: const Color(0xFFFF5252),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // AI Biomechanical Diagnosis
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'AI Biomechanical Diagnosis',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getDiagnosisFeedback(),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final session = WorkoutSession(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          exerciseName: exerciseName,
                          totalReps: totalReps,
                          goodReps: goodReps,
                          partialReps: partialReps,
                          durationSeconds: durationSeconds,
                          formScore: formScore,
                          caloriesBurned: caloriesBurned,
                          timestamp: DateTime.now(),
                          summaryFeedback: _getDiagnosisFeedback(),
                        );
                        await LocalDatabase.instance.saveSession(session);
                        onSaved();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Workout saved to History!'),
                              backgroundColor: Color(0xFF1E1E1E),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Save Set',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
