import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/screens/profile_screen.dart';
import '../../shared/widgets/theme_mode_toggle.dart';
import 'student_home_screen.dart';
import 'student_program_screen.dart';
import 'student_progress_screen.dart';

/// Conteneur élève : 4 onglets (Accueil, Programme, Progression, Profil).
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  static const _titles = ['Accueil', 'Mon programme', 'Progression', 'Profil'];

  static const _tabs = <Widget>[
    StudentHomeScreen(),
    StudentProgramScreen(),
    StudentProgressScreen(),
    ProfileScreen(),
  ];

  static const _profileTabIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          if (_index == _profileTabIndex) const ThemeModeToggle(),
        ],
      ),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.dumbbell),
            label: 'Programme',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.lineChart),
            label: 'Progression',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
