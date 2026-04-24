import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/screens/profile_screen.dart';
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
  static const _profileTabIndex = 3;

  void _navigateToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      StudentHomeScreen(onNavigate: _navigateToTab),
      const StudentProgramScreen(),
      const StudentProgressScreen(),
      const ProfileScreen(),
    ];
    // L'onglet Profil fournit son propre Scaffold + AppBar (actions qui
    // changent selon le mode lecture/édition), on masque donc celui du shell
    // pour éviter un double AppBar.
    final isProfile = _index == _profileTabIndex;
    return Scaffold(
      appBar: isProfile ? null : AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _navigateToTab,
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
            icon: Icon(LucideIcons.trendingUp),
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
