import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'courses_screen.dart';
import 'stats_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(int index) => setState(() => _currentIndex = index);

  Widget get _currentScreen {
    switch (_currentIndex) {
      case 0:  return HomeScreen(onNavTap: _onNavTap);
      case 1:  return CalendarScreen(onNavTap: _onNavTap);
      case 2:  return CoursesScreen(onNavTap: _onNavTap);
      case 3:  return StatsScreen(onNavTap: _onNavTap);
      default: return HomeScreen(onNavTap: _onNavTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentScreen,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
