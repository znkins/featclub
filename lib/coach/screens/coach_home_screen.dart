import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/profile.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/widgets/section_header.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import 'coach_activity_screen.dart';

/// Accueil coach : bienvenue, raccourcis (Featers, Activité) et CTA de
/// complétion de profil si nécessaire.
///
/// `onNavigate(int)` permet au raccourci Featers de basculer sur l'onglet
/// du shell (cf. [CoachShell]). L'Activité, elle, est un écran poussé
/// (Navigator.push) puisqu'elle n'a pas d'onglet dédié.
class CoachHomeScreen extends ConsumerWidget {
  const CoachHomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  static const _featersTab = 1;
  static const _profileTab = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(currentProfileProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          profileAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: LoadingIndicator(),
            ),
            error: (e, _) => ErrorView(
              message: 'Impossible de charger ton profil.\n$e',
              onRetry: () => ref.invalidate(currentProfileProvider),
            ),
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return _Greeting(profile: profile);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          profileAsync.maybeWhen(
            data: (profile) {
              if (profile == null || profile.isComplete) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: _ProfileCompletionBanner(
                  onTap: () => onNavigate(_profileTab),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          _ShortcutsSection(
            onFeaters: () => onNavigate(_featersTab),
            onActivity: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CoachActivityScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = (profile.firstName ?? '').trim();
    final title = firstName.isEmpty ? 'Bienvenue Coach !' : 'Bonjour $firstName !';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Gère le contenu sportif et garde un œil sur l\'activité des Featers !',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProfileCompletionBanner extends StatelessWidget {
  const _ProfileCompletionBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          color: theme.colorScheme.secondary.withValues(alpha: 0.12),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.userCircle2,
              color: theme.colorScheme.secondary,
              size: AppSizes.iconDefault,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Complète ton profil',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Complète ton profil pour commencer à utiliser l\'application.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutsSection extends StatelessWidget {
  const _ShortcutsSection({
    required this.onFeaters,
    required this.onActivity,
  });

  final VoidCallback onFeaters;
  final VoidCallback onActivity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Raccourcis'),
        const SizedBox(height: AppSpacing.md),
        _ShortcutTile(
          icon: LucideIcons.users,
          title: 'Featers',
          subtitle: 'Consulter et gérer les élèves',
          onTap: onFeaters,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ShortcutTile(
          icon: LucideIcons.calendarCheck,
          title: 'Activité',
          subtitle: 'Voir les dernières séances complétées',
          onTap: onActivity,
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outline),
        borderRadius: AppRadius.lgAll,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdAll,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
