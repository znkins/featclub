import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../auth/widgets/featclub_wordmark.dart';
import '../../shared/screens/profile_screen.dart';
import '../providers/coach_shell_providers.dart';
import 'coach_content_screen.dart';
import 'coach_featers_screen.dart';
import 'coach_home_screen.dart';

/// Conteneur coach : 4 onglets (Accueil, Featers, Contenu, Profil).
class CoachShell extends ConsumerWidget {
  const CoachShell({super.key});

  static const _titles = ['Accueil', 'Featers', 'Contenu', 'Profil'];
  static const _homeTabIndex = 0;
  static const _profileTabIndex = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(coachActiveTabProvider);
    void navigateToTab(int i) =>
        ref.read(coachActiveTabProvider.notifier).state = i;

    final tabs = <Widget>[
      CoachHomeScreen(onNavigate: navigateToTab),
      const CoachFeatersScreen(),
      const CoachContentScreen(),
      const ProfileScreen(),
    ];
    // L'onglet Profil fournit son propre Scaffold + AppBar (actions qui
    // changent selon le mode lecture/édition), on masque donc celui du shell
    // pour éviter un double AppBar. Accueil affiche le logo de marque
    // centré en place du titre (cohérent avec l'élève).
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
            icon: Icon(LucideIcons.users),
            label: 'Featers',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.layoutGrid),
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
