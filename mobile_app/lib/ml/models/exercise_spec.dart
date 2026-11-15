/// Form check callback signature: takes all detected joints and the active body side,
/// and returns a warning message string or null if the form is correct.
typedef FormCheckFn = String? Function(Map<String, dynamic> joints, String side);

/// Dataclass defining the constraints, angles, and rules for an exercise.
/// Direct translation of Python's ExerciseSpec dataclass in exercises.py.
class ExerciseSpec {
  /// Name of the exercise (e.g. "Bicep Curl", "Squat", "Push-Up")
  final String name;

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

  /// Optional custom form check callback: (joints, side) -> warning string or null
  final FormCheckFn? formCheck;

  const ExerciseSpec({
    required this.name,
    required this.joints,
    required this.extended,
    required this.flexed,
    required this.partial,
    required this.partialMsg,
    this.formCheck,
  });
}

