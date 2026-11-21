import 'package:flutter/material.dart';

/// Form check callback signature: takes all detected joints and the active body side,
/// and returns a warning message string or null if the form is correct.
typedef FormCheckFn = String? Function(Map<String, dynamic> joints, String side);

/// Categories for exercises to group them cleanly in the UI
enum ExerciseCategory {
  strength,
  legs,
  cardio,
  core,
}

extension ExerciseCategoryExtension on ExerciseCategory {
  String get label {
    switch (this) {
      case ExerciseCategory.strength:
        return 'Strength';
      case ExerciseCategory.legs:
        return 'Legs';
      case ExerciseCategory.cardio:
        return 'Cardio';
      case ExerciseCategory.core:
        return 'Core';
    }
  }

  IconData get icon {
    switch (this) {
      case ExerciseCategory.strength:
        return Icons.fitness_center;
      case ExerciseCategory.legs:
        return Icons.directions_walk;
      case ExerciseCategory.cardio:
        return Icons.bolt;
      case ExerciseCategory.core:
        return Icons.shield;
    }
  }

  Color get color {
    switch (this) {
      case ExerciseCategory.strength:
        return const Color(0xFF00E5FF); // Neon Cyan
      case ExerciseCategory.legs:
        return const Color(0xFF76FF03); // Neon Green
      case ExerciseCategory.cardio:
        return const Color(0xFFFF5252); // Neon Red/Orange
      case ExerciseCategory.core:
        return const Color(0xFFFFD600); // Neon Amber
    }
  }
}

/// Dataclass defining the constraints, angles, rules, and UI metadata for an exercise.
class ExerciseSpec {
  /// Name of the exercise (e.g. "Bicep Curl", "Squat", "Jumping Jacks")
  final String name;

  /// Category: strength, legs, cardio, core
  final ExerciseCategory category;

  /// Target muscle group for badges and summary (e.g. "Biceps", "Quads & Glutes")
  final String targetMuscle;

  /// (first, middle, last) joint suffixes; the middle one is the angle vertex.
  /// For instance: ["shoulder", "elbow", "wrist"] for curls.
  final List<String> joints;

  /// Angle at/above this = start position (arm straight, standing, plank)
  final double extended;

  /// Angle at/below this = full-depth rep
  final double flexed;

  /// Dipping below this but not reaching `flexed` = partial rep
  final double partial;

  /// Feedback string for a partial rep
  final String partialMsg;

  /// Whether this is a static hold exercise (like Plank) measured in seconds rather than reps
  final bool isHoldBased;

  /// MET (Metabolic Equivalent of Task) value for estimating calories burned
  final double metValue;

  /// Visual instruction shown to the user when switching to this exercise
  final String setupInstruction;

  /// Visual cue for optimal biomechanical alignment
  final String visualCue;

  /// Optional custom form check callback: (joints, side) -> warning string or null
  final FormCheckFn? formCheck;

  const ExerciseSpec({
    required this.name,
    this.category = ExerciseCategory.strength,
    this.targetMuscle = 'Full Body',
    required this.joints,
    required this.extended,
    required this.flexed,
    required this.partial,
    required this.partialMsg,
    this.isHoldBased = false,
    this.metValue = 5.0,
    this.setupInstruction = 'Get into starting position facing the camera',
    this.visualCue = 'Maintain controlled tempo and full range of motion',
    this.formCheck,
  });
}
