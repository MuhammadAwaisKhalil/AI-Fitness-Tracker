import 'package:flutter/material.dart';
import '../../core/storage/local_database.dart';
import '../../ml/form_rules.dart';
import '../../ml/models/exercise_spec.dart';
import '../workout/screens/workout_screen.dart';

/// Premium home dashboard and workout hub.
/// Allows athletes to review stats, select workout categories, and launch the
/// AI camera tracker only when they are ready to train.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ExerciseCategory? _filterCategory; // null = All
  int _totalReps = 0;
  double _totalCalories = 0.0;
  double _avgForm = 0.0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final reps = await LocalDatabase.instance.getTotalReps();
    final cals = await LocalDatabase.instance.getTotalCaloriesBurned();
    final form = await LocalDatabase.instance.getAverageFormScore();

    if (mounted) {
      setState(() {
        _totalReps = reps;
        _totalCalories = cals;
        _avgForm = form;
        _isLoadingStats = false;
      });
    }
  }

  void _startWorkout({String exerciseKey = '1'}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (ctx) => WorkoutScreen(initialExerciseKey: exerciseKey),
          ),
        )
        .then((_) => _loadStats()); // Refresh stats on return
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _filterCategory == null
        ? exercises.entries.toList()
        : exercises.entries
            .where((e) => e.value.category == _filterCategory)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF090C12),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: const Color(0xFF00E5FF),
          backgroundColor: const Color(0xFF141824),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
            children: [
              // 1. TOP HEADER & ATHLETE PROFILE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00E5FF).withOpacity(0.4),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.bolt,
                                    size: 13, color: Color(0xFF00E5FF)),
                                SizedBox(width: 4),
                                Text(
                                  'AI KINEMATICS ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF00E5FF),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Welcome Back, Athlete',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'Select an exercise to begin your tracked session',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  // Streak Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161C2A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '4 DAYS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'STREAK',
                              style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFFFF9100),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. DAILY PERFORMANCE METRIC CARDS
              Row(
                children: [
                  Expanded(
                    child: _statHeroPill(
                      label: 'CALORIES',
                      value: '${_totalCalories.toInt()} kcal',
                      icon: Icons.local_fire_department,
                      color: const Color(0xFFFF5252),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statHeroPill(
                      label: 'REPS COMPLETED',
                      value: '$_totalReps',
                      icon: Icons.fitness_center,
                      color: const Color(0xFF76FF03),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statHeroPill(
                      label: 'AVG FORM',
                      value: '${_avgForm.toInt()}%',
                      icon: Icons.auto_awesome,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. FEATURED "START AI WORKOUT" HERO BANNER
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D2538),
                      Color(0xFF121E2E),
                      Color(0xFF161C28),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'AI POSE TRACKER',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.camera_alt,
                                size: 14, color: Colors.white60),
                            SizedBox(width: 4),
                            Text(
                              'On-Device Vision',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Full-Body Movement Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Google ML Kit analyses your biomechanical angles, counts valid reps, and diagnoses form in real time.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () => _startWorkout(),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'START AI WORKOUT NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. EXERCISE CATEGORIES FILTER PILLS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exercise Catalog',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_filterCategory != null)
                    GestureDetector(
                      onTap: () => setState(() => _filterCategory = null),
                      child: const Text(
                        'Show All',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "All" filter chip
                    _categoryFilterChip(
                      label: 'All Workouts',
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFF00E5FF),
                      isSelected: _filterCategory == null,
                      onTap: () => setState(() => _filterCategory = null),
                    ),
                    ...ExerciseCategory.values.map((cat) {
                      return _categoryFilterChip(
                        label: cat.label,
                        icon: cat.icon,
                        color: cat.color,
                        isSelected: _filterCategory == cat,
                        onTap: () => setState(() => _filterCategory = cat),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 5. EXERCISE CARDS LIST
              ...filteredExercises.map((entry) {
                final key = entry.key;
                final spec = entry.value;
                return _exerciseCard(key, spec);
              }).toList(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statHeroPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              color: Colors.white38,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.22)
                : const Color(0xFF131824),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.white12,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : Colors.white54),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exerciseCard(String key, ExerciseSpec spec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121622),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _startWorkout(exerciseKey: key),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Category Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: spec.category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: spec.category.color.withOpacity(0.4), width: 1),
                  ),
                  child: Icon(spec.category.icon,
                      color: spec.category.color, size: 22),
                ),
                const SizedBox(width: 14),

                // Name, Target Muscle & Intensity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              spec.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (spec.isHoldBased)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HOLD TIMER',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Color(0xFF00E5FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        spec.targetMuscle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${spec.metValue} MET',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              spec.setupInstruction,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white38,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Start Arrow Button
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: spec.category.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded,
                      color: spec.category.color, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
