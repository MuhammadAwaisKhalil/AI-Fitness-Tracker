import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/workout/screens/workout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation and dark system UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AiFitnessTrackerApp());
}

class AiFitnessTrackerApp extends StatelessWidget {
  const AiFitnessTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF76FF03),
          surface: Color(0xFF1E1E1E),
          background: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const WorkoutScreen(),
    );
  }
}

