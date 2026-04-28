import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../auth/widgets/featclub_wordmark.dart';
import '../../shared/screens/profile_screen.dart';
import '../providers/student_shell_providers.dart';
import 'student_home_screen.dart';
import 'student_program_screen.dart';
import 'student_progress_screen.dart';

/// Coquille de l'espace élève : héberge le `NavigationBar` et les
/// 4 onglets (Accueil, Programme, Progression, Profil).
class StudentShell extends ConsumerWidget {
  const StudentShell({super.key});

  static const _titles = ['Accueil', 'Mon programme', 'Progression', 'Profil'];
  static const _homeTabIndex = 0;
  static const _profileTabIndex = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(studentActiveTabProvider);
    void navigateToTab(int i) =>
        ref.read(studentActiveTabProvider.notifier).state = i;

    final tabs = <Widget>[
      StudentHomeScreen(onNavigate: navigateToTab),
      const StudentProgramScreen(),
      const StudentProgressScreen(),
      const ProfileScreen(),
    ];
    // Profil fournit son propre Scaffold + AppBar (actions qui changent en
    // mode édition) : on masque celle du shell.
    // Accueil affiche le wordmark centré en place du titre.
    final isProfile = index == _profileTabIndex;
    final isHome = index == _homeTabIndex;
    return Scaffold(
      appBar: isProfile
          ? null
          : AppBar(
              centerTitle: isHome,
              title: isHome
                  ? const FeatclubWordmark(
                      titleFontSize: 28,
                      showBaseline: false,
                      logoHeight: 24,
                    )
                  : Text(_titles[index]),
            ),
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: navigateToTab,
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
