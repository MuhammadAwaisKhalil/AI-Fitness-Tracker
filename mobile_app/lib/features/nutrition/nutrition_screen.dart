import 'package:flutter/material.dart';
import '../../core/storage/local_database.dart';

class MealItem {
  final String name;
  final String category;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  MealItem({
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}

/// Dynamic nutrition tracker calculating daily energy balance and macronutrients.
/// Automatically integrates calories burned from the pose detection workout engine.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final int _calorieGoal = 2200;
  final int _proteinGoal = 150;
  final int _carbsGoal = 220;
  final int _fatsGoal = 65;

  double _burnedCalories = 0.0;
  bool _isLoading = true;

  final List<MealItem> _meals = [
    MealItem(
      name: 'Oatmeal with Whey & Berries',
      category: 'Breakfast',
      calories: 420,
      protein: 34,
      carbs: 58,
      fats: 6,
    ),
    MealItem(
      name: 'Grilled Chicken & Quinoa Bowl',
      category: 'Lunch',
      calories: 580,
      protein: 48,
      carbs: 62,
      fats: 12,
    ),
    MealItem(
      name: 'Greek Yogurt & Almonds',
      category: 'Snack',
      calories: 220,
      protein: 20,
      carbs: 12,
      fats: 10,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBurnedCalories();
  }

  Future<void> _loadBurnedCalories() async {
    final burned = await LocalDatabase.instance.getTotalCaloriesBurned();
    if (mounted) {
      setState(() {
        _burnedCalories = burned;
        _isLoading = false;
      });
    }
  }

  int get _totalCaloriesConsumed =>
      _meals.fold(0, (sum, item) => sum + item.calories);
  int get _totalProteinConsumed =>
      _meals.fold(0, (sum, item) => sum + item.protein);
  int get _totalCarbsConsumed =>
      _meals.fold(0, (sum, item) => sum + item.carbs);
  int get _totalFatsConsumed => _meals.fold(0, (sum, item) => sum + item.fats);

  int get _netCaloriesRemaining =>
      (_calorieGoal - _totalCaloriesConsumed + _burnedCalories.toInt());

  void _showAddMealDialog() {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    String selectedCategory = 'Breakfast';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log Nutrition & Meal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Meal Name',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Meal Category',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) =>
                    setSheetState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: calCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Calories',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: proCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Protein (g)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: carbCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Carbs (g)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Fats (g)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final cal = int.tryParse(calCtrl.text) ?? 0;
                    final pro = int.tryParse(proCtrl.text) ?? 0;
                    final carbs = int.tryParse(carbCtrl.text) ?? 0;
                    final fat = int.tryParse(fatCtrl.text) ?? 0;

                    if (name.isNotEmpty && cal > 0) {
                      setState(() {
                        _meals.add(
                          MealItem(
                            name: name,
                            category: selectedCategory,
                            calories: cal,
                            protein: pro,
                            carbs: carbs,
                            fats: fat,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    'Add Meal to Log',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Nutrition & Energy Balance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF00E5FF)),
            onPressed: _showAddMealDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. HERO ENERGY BALANCE CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E1E1E),
                  const Color(0xFF00E5FF).withOpacity(0.08)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calories Remaining',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$_netCaloriesRemaining',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const Text(
                  'kcal to reach target',
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
                const SizedBox(height: 20),
                // Equation row: Goal - Food + Exercise
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _energyEquationItem('Base Goal', '$_calorieGoal', Icons.flag),
                    const Text('-',
                        style: TextStyle(color: Colors.white38, fontSize: 18)),
                    _energyEquationItem(
                        'Food', '$_totalCaloriesConsumed', Icons.restaurant),
                    const Text('+',
                        style: TextStyle(color: Colors.white38, fontSize: 18)),
                    _energyEquationItem(
                      'AI Workout',
                      '${_burnedCalories.toInt()}',
                      Icons.local_fire_department,
                      color: const Color(0xFFFF5252),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. MACRONUTRIENT BARS
          const Text(
            'Macronutrient Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _macroProgress(
                  'Protein',
                  _totalProteinConsumed,
                  _proteinGoal,
                  const Color(0xFF00E5FF),
                ),
                const SizedBox(height: 14),
                _macroProgress(
                  'Carbohydrates',
                  _totalCarbsConsumed,
                  _carbsGoal,
                  const Color(0xFF76FF03),
                ),
                const SizedBox(height: 14),
                _macroProgress(
                  'Dietary Fats',
                  _totalFatsConsumed,
                  _fatsGoal,
                  const Color(0xFFFFAB00),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. MEALS LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meals Logged Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddMealDialog,
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF00E5FF)),
                label: const Text(
                  'Log Meal',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ..._meals.map((meal) => _mealCard(meal)).toList(),
        ],
      ),
    );
  }

  Widget _energyEquationItem(String label, String value, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.white60),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _macroProgress(String name, int current, int target, Color color) {
    final double ratio = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            Text(
              '$current / ${target}g',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _mealCard(MealItem meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lunch_dining,
                color: Color(0xFF00E5FF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${meal.category} • ${meal.protein}g P | ${meal.carbs}g C | ${meal.fats}g F',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
          Text(
            '${meal.calories} kcal',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF76FF03),
            ),
          ),
        ],
      ),
    );
  }
}
