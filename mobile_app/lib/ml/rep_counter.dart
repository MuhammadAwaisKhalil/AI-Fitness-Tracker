import 'angle_utils.dart';
import 'form_rules.dart';
import 'models/exercise_spec.dart';
import '../core/utils/voice_coach.dart';

/// Counts reps or hold duration for one [ExerciseSpec] using a state machine:
///
/// For Dynamic Reps (Curls, Squats, Push-Ups, Jacks, etc.):
/// - waiting  -> waiting for user to reach start position
/// - extended -> in the start position
/// - moving   -> actively performing concentric/eccentric movement
///
/// For Static Holds (Plank):
/// - waiting  -> waiting for user to assume plank posture
/// - holding  -> correct form held; timer runs
/// - break    -> posture collapsed or hips out of range
class RepCounter {
  ExerciseSpec spec;
  final double alpha;

  int reps = 0;
  int goodReps = 0;
  int partialReps = 0;
  int formWarningsCount = 0;

  String stage = 'waiting';
  double? angle;
  String feedback = 'Get into starting position';
  double _minAngle = 180.0;
  double _maxAngle = 0.0;

  // Real-time Form Scoring (0 - 100%)
  double formScore = 100.0;

  // Hold-based tracking (Plank)
  DateTime? _lastHoldTick;
  int holdSeconds = 0;

  // Set timing & Calorie tracking
  DateTime? setStartTime;

  RepCounter(this.spec, {double smoothing = 0.35}) : alpha = smoothing {
    reset();
  }

  void reset() {
    reps = 0;
    goodReps = 0;
    partialReps = 0;
    formWarningsCount = 0;
    formScore = 100.0;
    stage = 'waiting';
    angle = null;
    feedback = 'Get into starting position';
    _minAngle = 180.0;
    _maxAngle = 0.0;
    _lastHoldTick = null;
    holdSeconds = 0;
    setStartTime = DateTime.now();
  }

  void switchExercise(ExerciseSpec newSpec) {
    spec = newSpec;
    reset();
  }

  int get durationSeconds {
    if (setStartTime == null) return 0;
    return DateTime.now().difference(setStartTime!).inSeconds;
  }

  /// Calories burned estimation using ACSM MET formula:
  /// Calories = (MET * 3.5 * weightKg / 200) * (minutes)
  /// Using standard reference weight 70 kg
  double get caloriesBurned {
    final double minutes = durationSeconds / 60.0;
    if (minutes <= 0) return 0.0;
    return (spec.metValue * 3.5 * 70.0 / 200.0) * minutes;
  }

  void _recalculateFormScore() {
    if (spec.isHoldBased) {
      if (holdSeconds <= 0) {
        formScore = 100.0;
        return;
      }
      final penalty = (formWarningsCount * 2.5);
      formScore = (100.0 - penalty).clamp(50.0, 100.0);
    } else {
      final totalAttempts = goodReps + partialReps;
      if (totalAttempts == 0) {
        formScore = 100.0;
        return;
      }
      final double cleanRatio = goodReps / totalAttempts;
      final double formDeduction = (formWarningsCount * 1.5).clamp(0.0, 25.0);
      formScore = ((cleanRatio * 100.0) - formDeduction).clamp(40.0, 100.0);
    }
  }

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
    angle = (angle == null) ? raw : (alpha * raw + (1.0 - alpha) * angle!);
    final double curAngle = angle!;

    // 1. Check Biomechanical Form
    String? warning;
    if (spec.formCheck != null) {
      warning = spec.formCheck!(joints, side);
      if (warning != null) {
        formWarningsCount++;
        feedback = warning;
        VoiceCoach.instance.onFormWarning(warning);
        _recalculateFormScore();
      }
    }

    // 2. State Machine: Hold-Based (e.g. Plank) vs Dynamic Reps
    if (spec.isHoldBased) {
      _updateHoldExercise(curAngle, warning != null);
    } else {
      _updateRepExercise(curAngle, warning != null);
    }

    return this;
  }

  void _updateHoldExercise(double curAngle, bool hasWarning) {
    final bool inHoldRange = curAngle >= spec.extended - 15.0;

    if (!inHoldRange || hasWarning) {
      stage = 'break';
      if (!hasWarning) {
        feedback = 'Form lost! Re-align to resume timer';
      }
      _lastHoldTick = null;
    } else {
      stage = 'holding';
      final now = DateTime.now();
      if (_lastHoldTick == null) {
        _lastHoldTick = now;
      } else {
        final elapsedMs = now.difference(_lastHoldTick!).inMilliseconds;
        if (elapsedMs >= 1000) {
          final addedSec = elapsedMs ~/ 1000;
          holdSeconds += addedSec;
          reps = holdSeconds;
          _lastHoldTick = now;
          VoiceCoach.instance.onHoldMilestone(holdSeconds);
        }
      }
      feedback = 'Solid hold! Keep core engaged (${holdSeconds}s)';
    }
    _recalculateFormScore();
  }

  void _updateRepExercise(double curAngle, bool hasWarning) {
    if (stage == 'waiting') {
      if (curAngle >= spec.extended - 10.0) {
        stage = 'extended';
        feedback = 'Ready! Begin your set';
      }
    } else if (stage == 'extended') {
      if (curAngle < spec.extended - 10.0) {
        stage = 'moving';
        _minAngle = curAngle;
        _maxAngle = curAngle;
      }
    } else if (stage == 'moving') {
      if (curAngle < _minAngle) _minAngle = curAngle;
      if (curAngle > _maxAngle) _maxAngle = curAngle;

      if (curAngle >= spec.extended - 10.0) {
        // Returned to starting position: evaluate rep quality
        if (_minAngle <= spec.flexed) {
          reps += 1;
          goodReps += 1;
          feedback = 'Clean Rep! Keep going';
          VoiceCoach.instance.onGoodRep(reps);
        } else if (_minAngle <= spec.partial) {
          reps += 1;
          partialReps += 1;
          feedback = spec.partialMsg;
          VoiceCoach.instance.onPartialRep();
        }
        _recalculateFormScore();
        stage = 'extended';
      } else if (_minAngle <= spec.flexed && !hasWarning) {
        feedback = 'Full depth! Now push back up';
      }
    }
  }
}
