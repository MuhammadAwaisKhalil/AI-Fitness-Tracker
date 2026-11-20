import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/chat/chat_screen.dart';
import 'features/home/home_screen.dart';
import 'features/nutrition/nutrition_screen.dart';
import 'features/workout/screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for optimal computer vision pose tracking
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090C12),
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
        scaffoldBackgroundColor: const Color(0xFF090C12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF76FF03),
          surface: Color(0xFF131824),
          background: Color(0xFF090C12),
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

/// Root application shell providing bottom navigation between
/// Home (Dashboard Hub), Analytics, Nutrition, and AI Coach.
/// Camera is NOT opened by default—it activates only when initiating a workout!
class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    NutritionScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090C12),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E121B),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(0xFF00E5FF),
              unselectedItemColor: Colors.white38,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  activeIcon:
                      Icon(Icons.dashboard_rounded, color: Color(0xFF00E5FF)),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  activeIcon:
                      Icon(Icons.bar_chart_rounded, color: Color(0xFF00E5FF)),
                  label: 'Analytics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu_rounded),
                  activeIcon: Icon(Icons.restaurant_menu_rounded,
                      color: Color(0xFF00E5FF)),
                  label: 'Nutrition',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.psychology_rounded),
                  activeIcon:
                      Icon(Icons.psychology_rounded, color: Color(0xFF00E5FF)),
                  label: 'AI Coach',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
