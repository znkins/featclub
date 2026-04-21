import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/screens/profile_screen.dart';
import '../../shared/widgets/theme_mode_toggle.dart';
import 'coach_content_screen.dart';
import 'coach_featers_screen.dart';
import 'coach_home_screen.dart';

/// Conteneur coach : 4 onglets (Accueil, Featers, Contenu, Profil).
class CoachShell extends StatefulWidget {
  const CoachShell({super.key});

  @override
  State<CoachShell> createState() => _CoachShellState();
}

class _CoachShellState extends State<CoachShell> {
  int _index = 0;

  static const _titles = ['Accueil', 'Featers', 'Contenu', 'Profil'];

  static const _tabs = <Widget>[
    CoachHomeScreen(),
    CoachFeatersScreen(),
    CoachContentScreen(),
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
            icon: Icon(LucideIcons.users),
            label: 'Featers',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.layers),
            label: 'Contenu',
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
