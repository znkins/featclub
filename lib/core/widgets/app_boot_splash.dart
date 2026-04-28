import 'dart:async';

import 'package:flutter/material.dart';

import '../../auth/widgets/featclub_wordmark.dart';
import '../../theme/app_spacing.dart';

/// Splash de boot affiché à un utilisateur déjà connecté, le temps que
/// `currentProfileProvider` réponde avant la redirection vers son espace.
/// Reprend le wordmark animé du login pour la continuité visuelle.
class AppBootSplash extends StatefulWidget {
  const AppBootSplash({super.key});

  @override
  State<AppBootSplash> createState() => _AppBootSplashState();
}

class _AppBootSplashState extends State<AppBootSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinnerFade;
  Timer? _spinnerTimer;

  @override
  void initState() {
    super.initState();
    _spinnerFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // Spinner différé : n'apparaît que si le chargement dépasse l'animation
    // d'entrée du wordmark, pour signaler que l'app n'est pas figée.
    _spinnerTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _spinnerFade.forward();
    });
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    _spinnerFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FeatclubWordmark(animate: true),
              const SizedBox(height: AppSpacing.xxl),
              FadeTransition(
                opacity: _spinnerFade,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
