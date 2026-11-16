import 'angle_utils.dart';
import 'form_rules.dart';
import 'models/exercise_spec.dart';

/// Counts reps for one [ExerciseSpec] using a state machine:
///
/// - waiting  -> waiting for the user to reach the start position
/// - extended -> in the start position
/// - moving   -> left the start position; tracking the deepest angle reached
///
/// A rep is counted when the user returns to `extended` after having reached `flexed`.
/// Direct port of `RepCounter` in `exercises.py`.
class RepCounter {
  ExerciseSpec spec;

  /// Smoothing alpha: 1.0 = no smoothing, lower = smoother but laggier.
  /// Preserves the smoothing alpha logic from Python (default 0.35).
  final double alpha;

  int reps = 0;
  String stage = 'waiting';
  double? angle;
  String feedback = 'Get into the start position';
  double _minAngle = 180.0;

  RepCounter(this.spec, {double smoothing = 0.35}) : alpha = smoothing {
    reset();
  }

  /// Resets rep count, stage, angle, and feedback to initial values.
  void reset() {
    reps = 0;
    stage = 'waiting';
    angle = null;
    feedback = 'Get into the start position';
    _minAngle = 180.0;
  }

  /// Switches to a new exercise and resets state.
  void switchExercise(ExerciseSpec newSpec) {
    spec = newSpec;
    reset();
  }

  /// Use whichever side of the body the camera sees best.
  /// Replicates `_pick_side` from `exercises.py`.
  String? pickSide(Map<String, dynamic> joints) {
    String? bestSide;
    double bestScore = 0.0;

    for (final side in ['left', 'right']) {
      final names = spec.joints.map((j) => '${side}_$j').toList();
      final allPresent = names.every((n) => joints.containsKey(n));
      if (!allPresent) continue;

      final double score = names
          .map((n) => (joints[n]['visibility'] as num).toDouble())
          .reduce((a, b) => a < b ? a : b);

      if (score > bestScore) {
        bestSide = side;
        bestScore = score;
      }
    }

    return (bestScore >= minVisibility) ? bestSide : null;
  }

  /// Updates state with a new joint dictionary.
  /// Replicates `update` from `exercises.py`.
  RepCounter update(Map<String, dynamic> joints) {
    final side = pickSide(joints);
    if (side == null) {
      feedback = 'Step back so your body is fully in view';
      return this;
    }

    final a = joints['${side}_${spec.joints[0]}'] as Map<String, dynamic>;
    final b = joints['${side}_${spec.joints[1]}'] as Map<String, dynamic>;
    final c = joints['${side}_${spec.joints[2]}'] as Map<String, dynamic>;

    final double raw = calculateAngle(a, b, c);

    // Exponential moving average smoothing preserved from Python
    angle = (angle == null) ? raw : (alpha * raw + (1.0 - alpha) * angle!);
    final double curAngle = angle!;

    if (stage == 'waiting') {
      if (curAngle >= spec.extended) {
        stage = 'extended';
        feedback = 'Ready - start your reps';
      }
    } else if (stage == 'extended') {
      if (curAngle < spec.extended) {
        stage = 'moving';
        _minAngle = curAngle;
      }
    } else if (stage == 'moving') {
      if (curAngle < _minAngle) {
        _minAngle = curAngle;
      }
      if (curAngle >= spec.extended) {
        // Back at the start: judge the rep
        if (_minAngle <= spec.flexed) {
          reps += 1;
          feedback = 'Good rep!';
        } else if (_minAngle <= spec.partial) {
          feedback = spec.partialMsg;
        }
        stage = 'extended';
      } else if (_minAngle <= spec.flexed) {
        feedback = 'Depth reached - now return';
      }
    }

    if (spec.formCheck != null) {
      final warning = spec.formCheck!(joints, side);
      if (warning != null) {
        feedback = warning;
      }
    }

    return this;
  }
}

