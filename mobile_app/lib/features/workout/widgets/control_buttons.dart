import 'package:flutter/material.dart';
import '../../../ml/models/exercise_spec.dart';

/// Control buttons bar to switch exercises, reset counts, and manage workout sessions.
/// Replaces the OpenCV keyboard controls ('1', '2', '3', 'r', 'q') with responsive touch controls.
class ControlButtons extends StatelessWidget {
  /// Available exercises to choose from (e.g. {'1': bicepCurl, '2': squat, '3': pushUp})
  final Map<String, ExerciseSpec> exercises;

  /// Currently selected exercise key
  final String selectedKey;

  /// Callback when user selects a different exercise
  final ValueChanged<String> onExerciseChanged;

  /// Callback when user presses the reset button
  final VoidCallback onReset;

  /// Optional callback to flip/switch camera or toggle pause
  final VoidCallback? onSwitchCamera;

  const ControlButtons({
    Key? key,
    required this.exercises,
    required this.selectedKey,
    required this.onExerciseChanged,
    required this.onReset,
    this.onSwitchCamera,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exercise selector row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: exercises.entries.map((entry) {
                    final isSelected = entry.key == selectedKey;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(entry.value.name),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00E5FF),
                        backgroundColor: Colors.white10,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            onExerciseChanged(entry.key);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // Action buttons row (Reset & Camera)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset Button ('r')
                  ElevatedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('RESET'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Camera switch button (if provided)
                  if (onSwitchCamera != null)
                    IconButton(
                      onPressed: onSwitchCamera,
                      icon: const Icon(Icons.cameraswitch, color: Colors.white70),
                      tooltip: 'Switch Camera',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

