import 'package:flutter/material.dart';
import '../../../core/storage/local_database.dart';

/// Analytics & History screen showing past sessions, PRs, and biomechanical scores.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<WorkoutSession>> _sessionsFuture;
  late Future<int> _totalRepsFuture;
  late Future<double> _totalCaloriesFuture;
  late Future<double> _avgScoreFuture;
  late Future<Map<String, int>> _prsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _sessionsFuture = LocalDatabase.instance.getSessions();
      _totalRepsFuture = LocalDatabase.instance.getTotalReps();
      _totalCaloriesFuture = LocalDatabase.instance.getTotalCaloriesBurned();
      _avgScoreFuture = LocalDatabase.instance.getAverageFormScore();
      _prsFuture = LocalDatabase.instance.getPersonalBests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Workout Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([
          _sessionsFuture,
          _totalRepsFuture,
          _totalCaloriesFuture,
          _avgScoreFuture,
          _prsFuture,
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
            );
          }

          final sessions = snapshot.data![0] as List<WorkoutSession>;
          final totalReps = snapshot.data![1] as int;
          final totalCalories = snapshot.data![2] as double;
          final avgScore = snapshot.data![3] as double;
          final prs = snapshot.data![4] as Map<String, int>;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Hero Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _statHeroCard(
                      'TOTAL REPS',
                      '$totalReps',
                      Icons.fitness_center,
                      const Color(0xFF76FF03),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statHeroCard(
                      'AVG FORM',
                      '${avgScore.toInt()}%',
                      Icons.auto_awesome,
                      const Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statHeroCard(
                      'CALORIES',
                      '${totalCalories.toInt()}',
                      Icons.local_fire_department,
                      const Color(0xFFFF5252),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Personal Records (PRs)
              const Text(
                'Personal Records (PRs)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: prs.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Color(0xFFFFD600), size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 11, color: Colors.white60),
                              ),
                              Text(
                                '${entry.value} reps',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Recent Sessions List
              const Text(
                'Recent Workout Sessions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              if (sessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Text(
                    'No completed sets yet. Start your first workout!',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              else
                ...sessions.map((s) => _sessionCard(s)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _statHeroCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(WorkoutSession s) {
    final scoreColor = s.formScore >= 85
        ? const Color(0xFF76FF03)
        : (s.formScore >= 70 ? const Color(0xFF00E5FF) : const Color(0xFFFFAB00));

    final dateStr =
        '${s.timestamp.month}/${s.timestamp.day} • ${s.timestamp.hour.toString().padLeft(2, '0')}:${s.timestamp.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Exercise name, timestamp, and score pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.exerciseName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scoreColor, width: 1),
                ),
                child: Text(
                  '${s.formScore.toInt()}% FORM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _metricChip('${s.totalReps} Reps', Icons.repeat),
              _metricChip('${s.durationSeconds}s', Icons.timer),
              _metricChip(
                  '${s.caloriesBurned.toStringAsFixed(1)} kcal',
                  Icons.local_fire_department),
            ],
          ),

          if (s.summaryFeedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              s.summaryFeedback,
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
