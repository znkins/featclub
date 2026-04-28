import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'shared/providers/auth_session_reset_provider.dart';
import 'shared/providers/theme_mode_provider.dart';
import 'theme/app_theme.dart';

class FeatclubApp extends ConsumerWidget {
  const FeatclubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde l'écouteur de reset de session actif pour toute la durée de vie
    // de l'app : remet les onglets des shells à 0 dès que l'utilisateur
    // authentifié change.
    ref.watch(authSessionResetProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Featclub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
