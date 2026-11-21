import 'angle_utils.dart';
import 'models/exercise_spec.dart';

/// Minimum visibility threshold: ignore joints ML Kit is not confident about.
const double minVisibility = 0.5;

/// Push-up form check: Shoulder-hip-ankle should be roughly a straight line.
String? pushupFormCheck(Map<String, dynamic> joints, String side) {
  final names = ['${side}_shoulder', '${side}_hip', '${side}_ankle'];

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

/// Squat form check: Chest shouldn't collapse forward too far.
String? squatFormCheck(Map<String, dynamic> joints, String side) {
  final names = ['${side}_shoulder', '${side}_hip', '${side}_knee'];

  for (final name in names) {
    if (!joints.containsKey(name)) return null;
    final joint = joints[name] as Map<String, dynamic>;
    if ((joint['visibility'] as num).toDouble() < minVisibility) return null;
  }

  final shoulder = joints['${side}_shoulder'] as Map<String, dynamic>;
  final hip = joints['${side}_hip'] as Map<String, dynamic>;
  final knee = joints['${side}_knee'] as Map<String, dynamic>;

  // Severe forward torso tilt
  if (calculateAngle(shoulder, hip, knee) < 60.0) {
    return 'Chest up! Keep your back neutral';
  }
  return null;
}

/// Plank form check: Spine straight, hips neither sagging nor piked.
String? plankFormCheck(Map<String, dynamic> joints, String side) {
  final names = ['${side}_shoulder', '${side}_hip', '${side}_ankle'];

  for (final name in names) {
    if (!joints.containsKey(name)) return null;
    final joint = joints[name] as Map<String, dynamic>;
    if ((joint['visibility'] as num).toDouble() < minVisibility) return null;
  }

  final shoulder = joints['${side}_shoulder'] as Map<String, dynamic>;
  final hip = joints['${side}_hip'] as Map<String, dynamic>;
  final ankle = joints['${side}_ankle'] as Map<String, dynamic>;

  final bodyAngle = calculateAngle(shoulder, hip, ankle);
  if (bodyAngle < 150.0) {
    return 'Hips too high! Lower hips level with spine';
  } else if (bodyAngle > 195.0) {
    return 'Hips sagging! Squeeze core and glutes';
  }
  return null;
}

/// Shoulder press form check: ensure full lockout without extreme hyper-extension.
String? shoulderPressFormCheck(Map<String, dynamic> joints, String side) {
  final names = ['${side}_shoulder', '${side}_elbow', '${side}_wrist'];

  for (final name in names) {
    if (!joints.containsKey(name)) return null;
    final joint = joints[name] as Map<String, dynamic>;
    if ((joint['visibility'] as num).toDouble() < minVisibility) return null;
  }
  return null;
}

// ---------------- EXERCISE DEFINITIONS BY CATEGORY ----------------

// --- STRENGTH ---
final ExerciseSpec bicepCurl = ExerciseSpec(
  name: 'Bicep Curl',
  category: ExerciseCategory.strength,
  targetMuscle: 'Biceps & Forearms',
  joints: const ['shoulder', 'elbow', 'wrist'],
  extended: 150.0,
  flexed: 50.0,
  partial: 100.0,
  partialMsg: 'Curl all the way up',
  metValue: 4.0,
  setupInstruction: 'Stand facing camera, arms by your sides with weights',
  visualCue: 'Keep elbows locked against your ribs throughout the curl',
);

final ExerciseSpec pushUp = ExerciseSpec(
  name: 'Push-Up',
  category: ExerciseCategory.strength,
  targetMuscle: 'Chest, Shoulders & Triceps',
  joints: const ['shoulder', 'elbow', 'wrist'],
  extended: 155.0,
  flexed: 90.0,
  partial: 120.0,
  partialMsg: 'Lower your chest further to 90°',
  metValue: 7.0,
  setupInstruction: 'Position phone on the floor, side view in high plank',
  visualCue: 'Form a straight line from crown of head to heels',
  formCheck: pushupFormCheck,
);

final ExerciseSpec shoulderPress = ExerciseSpec(
  name: 'Shoulder Press',
  category: ExerciseCategory.strength,
  targetMuscle: 'Deltoids & Triceps',
  joints: const ['shoulder', 'elbow', 'wrist'],
  extended: 160.0, // arms fully locked overhead
  flexed: 85.0,   // weights down at shoulder/ear height
  partial: 115.0,
  partialMsg: 'Press all the way overhead',
  metValue: 5.0,
  setupInstruction: 'Stand or sit facing camera, weights at shoulder height',
  visualCue: 'Press weights directly overhead without arching lower back',
  formCheck: shoulderPressFormCheck,
);

// --- LEGS ---
final ExerciseSpec squat = ExerciseSpec(
  name: 'Squat',
  category: ExerciseCategory.legs,
  targetMuscle: 'Quads, Glutes & Hamstrings',
  joints: const ['hip', 'knee', 'ankle'],
  extended: 160.0,
  flexed: 100.0,
  partial: 130.0,
  partialMsg: 'Go deeper - hips parallel to knees',
  metValue: 6.0,
  setupInstruction: 'Step 6-8 feet back, angled profile so hips and knees are visible',
  visualCue: 'Push knees outward and send hips back like sitting into a chair',
  formCheck: squatFormCheck,
);

final ExerciseSpec lunge = ExerciseSpec(
  name: 'Lunge',
  category: ExerciseCategory.legs,
  targetMuscle: 'Quads, Glutes & Calves',
  joints: const ['hip', 'knee', 'ankle'],
  extended: 155.0,
  flexed: 95.0,
  partial: 125.0,
  partialMsg: 'Drop rear knee closer to the floor',
  metValue: 5.5,
  setupInstruction: 'Stand in side profile, step forward into a split stance',
  visualCue: 'Both front and back knees should form 90° angles at depth',
);

// --- CORE ---
final ExerciseSpec plank = ExerciseSpec(
  name: 'Plank',
  category: ExerciseCategory.core,
  targetMuscle: 'Transverse Abdominis & Lower Back',
  joints: const ['shoulder', 'hip', 'ankle'],
  extended: 155.0,
  flexed: 155.0,
  partial: 140.0,
  partialMsg: 'Engage core - do not sag',
  isHoldBased: true,
  metValue: 4.0,
  setupInstruction: 'Place phone on floor, hold a solid forearm or push-up plank',
  visualCue: 'Tuck pelvis, brace abdomen tightly as if taking a punch',
  formCheck: plankFormCheck,
);

// --- CARDIO ---
final ExerciseSpec jumpingJacks = ExerciseSpec(
  name: 'Jumping Jacks',
  category: ExerciseCategory.cardio,
  targetMuscle: 'Full Body Cardiovascular',
  joints: const ['hip', 'shoulder', 'wrist'],
  extended: 40.0,   // arms down by sides
  flexed: 140.0,   // arms clapped overhead
  partial: 90.0,
  partialMsg: 'Bring hands all the way overhead',
  metValue: 8.5,
  setupInstruction: 'Step 8-10 feet back so your full body from head to feet is in view',
  visualCue: 'Synchronize arm overhead clapping with wide foot jumps',
);

final ExerciseSpec highKnees = ExerciseSpec(
  name: 'High Knees',
  category: ExerciseCategory.cardio,
  targetMuscle: 'Hip Flexors & Core Cardio',
  joints: const ['shoulder', 'hip', 'knee'],
  extended: 160.0, // standing upright
  flexed: 85.0,   // knee driven up high past waist
  partial: 120.0,
  partialMsg: 'Drive knee higher up to hip level!',
  metValue: 9.0,
  setupInstruction: 'Stand tall facing camera, pump your arms with high knee drives',
  visualCue: 'Explosive drive off balls of feet, drive knees up to hip height',
);

/// Master exercise dictionary mapped by ID
final Map<String, ExerciseSpec> exercises = {
  '1': bicepCurl,
  '2': pushUp,
  '3': shoulderPress,
  '4': squat,
  '5': lunge,
  '6': plank,
  '7': jumpingJacks,
  '8': highKnees,
};

/// Get all exercises belonging to a specific category
List<MapEntry<String, ExerciseSpec>> getExercisesByCategory(ExerciseCategory category) {
  return exercises.entries.where((entry) => entry.value.category == category).toList();
}
