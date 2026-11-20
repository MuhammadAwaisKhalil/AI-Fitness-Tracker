/// Represents a single recorded workout set
class WorkoutSession {
  final String id;
  final String exerciseName;
  final int totalReps;
  final int goodReps;
  final int partialReps;
  final int durationSeconds;
  final double formScore;
  final double caloriesBurned;
  final DateTime timestamp;
  final String summaryFeedback;

  WorkoutSession({
    required this.id,
    required this.exerciseName,
    required this.totalReps,
    required this.goodReps,
    required this.partialReps,
    required this.durationSeconds,
    required this.formScore,
    required this.caloriesBurned,
    required this.timestamp,
    required this.summaryFeedback,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseName': exerciseName,
        'totalReps': totalReps,
        'goodReps': goodReps,
        'partialReps': partialReps,
        'durationSeconds': durationSeconds,
        'formScore': formScore,
        'caloriesBurned': caloriesBurned,
        'timestamp': timestamp.toIso8601String(),
        'summaryFeedback': summaryFeedback,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> map) => WorkoutSession(
        id: map['id'] as String,
        exerciseName: map['exerciseName'] as String,
        totalReps: (map['totalReps'] as num).toInt(),
        goodReps: (map['goodReps'] as num).toInt(),
        partialReps: (map['partialReps'] as num).toInt(),
        durationSeconds: (map['durationSeconds'] as num).toInt(),
        formScore: (map['formScore'] as num).toDouble(),
        caloriesBurned: (map['caloriesBurned'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        summaryFeedback: map['summaryFeedback'] as String,
      );
}

/// Local storage singleton for persisting workout history and telemetry.
/// Uses in-memory storage seeded with initial benchmark sessions for instant analytics.
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  LocalDatabase._init() {
    _seedInitialData();
  }

  final List<WorkoutSession> _sessions = [];

  void _seedInitialData() {
    final now = DateTime.now();
    _sessions.addAll([
      WorkoutSession(
        id: '1',
        exerciseName: 'Squat',
        totalReps: 15,
        goodReps: 14,
        partialReps: 1,
        durationSeconds: 45,
        formScore: 92.0,
        caloriesBurned: 18.5,
        timestamp: now.subtract(const Duration(days: 2, hours: 3)),
        summaryFeedback: 'Excellent squat depth and vertical spine stability.',
      ),
      WorkoutSession(
        id: '2',
        exerciseName: 'Push-Up',
        totalReps: 20,
        goodReps: 18,
        partialReps: 2,
        durationSeconds: 52,
        formScore: 88.0,
        caloriesBurned: 22.0,
        timestamp: now.subtract(const Duration(days: 1, hours: 4)),
        summaryFeedback: 'Solid push-up cadence. Slight hip dip detected near rep 17.',
      ),
      WorkoutSession(
        id: '3',
        exerciseName: 'Bicep Curl',
        totalReps: 12,
        goodReps: 12,
        partialReps: 0,
        durationSeconds: 38,
        formScore: 96.0,
        caloriesBurned: 12.0,
        timestamp: now.subtract(const Duration(hours: 5)),
        summaryFeedback: 'Perfect form! Elbows stayed strictly pinned.',
      ),
    ]);
  }

  Future<void> saveSession(WorkoutSession session) async {
    _sessions.insert(0, session);
  }

  Future<List<WorkoutSession>> getSessions() async {
    return List.unmodifiable(_sessions);
  }

  Future<int> getTotalReps() async {
    int sum = 0;
    for (final s in _sessions) {
      sum += s.totalReps;
    }
    return sum;
  }

  Future<double> getTotalCaloriesBurned() async {
    double sum = 0.0;
    for (final s in _sessions) {
      sum += s.caloriesBurned;
    }
    return sum;
  }

  Future<double> getAverageFormScore() async {
    if (_sessions.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in _sessions) {
      sum += s.formScore;
    }
    return sum / _sessions.length;
  }

  Future<Map<String, int>> getPersonalBests() async {
    final Map<String, int> prs = {};
    for (final s in _sessions) {
      if (!prs.containsKey(s.exerciseName) || s.totalReps > prs[s.exerciseName]!) {
        prs[s.exerciseName] = s.totalReps;
      }
    }
    return prs;
  }
}
