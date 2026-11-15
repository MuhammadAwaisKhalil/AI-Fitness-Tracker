import 'package:flutter/material.dart';

/// Placeholder UI for Nutrition Feature
/// Future: Displays calorie and macro targets calculated and fetched from the FastAPI backend.
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Nutrition Module Placeholder (Calculated by FastAPI)'),
      ),
    );
  }
}

