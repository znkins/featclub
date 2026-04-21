import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Onglet Accueil élève (placeholder Phase 1).
///
/// L'implémentation réelle (message de bienvenue + prochaine séance + raccourcis)
/// arrive en Phase 4.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          'Accueil élève — Phase 4',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
