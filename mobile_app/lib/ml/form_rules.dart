import 'angle_utils.dart';
import 'models/exercise_spec.dart';

/// Minimum visibility threshold: ignore joints MediaPipe is not confident about.
const double minVisibility = 0.5;

/// Shoulder-hip-ankle should be roughly a straight line (side-on camera).
/// Port of `_pushup_form(joints, side)` from `exercises.py`.
String? pushupFormCheck(Map<String, dynamic> joints, String side) {
  final names = [
    '${side}_shoulder',
    '${side}_hip',
    '${side}_ankle',
  ];

  for (final name in names) {
    if (!joints.containsKey(name)) return null;
    final joint = joints[name] as Map<String, dynamic>;
    final vis = (joint['visibility'] as num).toDouble();
    if (vis < minVisibility) return null;
  }

  final shoulder = joints['${side}_shoulder'] as Map<String, dynamic>;
  final hip = joints['${side}_hip'] as Map<String, dynamic>;
  final ankle = joints['${side}_ankle'] as Map<String, dynamic>;

  if (calculateAngle(shoulder, hip, ankle) < 155.0) {
    return 'Keep your hips in line with your shoulders';
  }
  return null;
}

final ExerciseSpec bicepCurl = ExerciseSpec(
  name: 'Bicep Curl',
  joints: const ['shoulder', 'elbow', 'wrist'],
  extended: 150.0,
  flexed: 50.0,
  partial: 100.0,
  partialMsg: 'Curl all the way up',
);

final ExerciseSpec squat = ExerciseSpec(
  name: 'Squat',
  joints: const ['hip', 'knee', 'ankle'],
  extended: 160.0,
  flexed: 100.0,
  partial: 130.0,
  partialMsg: 'Go deeper - hips down',
);

final ExerciseSpec pushUp = ExerciseSpec(
  name: 'Push-Up',
  joints: const ['shoulder', 'elbow', 'wrist'],
  extended: 155.0,
  flexed: 90.0,
  partial: 120.0,
  partialMsg: 'Lower your chest further',
  formCheck: pushupFormCheck,
);

/// Map matching the Python `EXERCISES` dictionary {"1": BICEP_CURL, "2": SQUAT, "3": PUSH_UP}
final Map<String, ExerciseSpec> exercises = {
  '1': bicepCurl,
  '2': squat,
  '3': pushUp,
};

