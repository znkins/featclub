import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../shared/providers/supabase_providers.dart';
import '../../shared/widgets/theme_mode_toggle.dart';
import '../../theme/app_spacing.dart';

/// Espace admin (placeholder Phase 1, implémenté en Phase 5).
///
/// Single page : pas de bottom nav par design.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        actions: [
          const ThemeModeToggle(),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
              } catch (e) {
                if (!context.mounted) return;
                AppSnackbar.showError(context, 'Erreur : $e');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Administration des comptes — Phase 5',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
