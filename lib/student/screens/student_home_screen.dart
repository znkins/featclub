import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/profile.dart';
import '../../core/models/student_session.dart';
import '../../core/services/student_program_service.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_session_providers.dart';
import '../widgets/student_session_tile.dart';

/// Accueil élève : bienvenue, prochaine séance, raccourcis, CTA profil.
///
/// `onNavigate(int)` permet aux raccourcis et au CTA de basculer sur un autre
/// onglet du shell sans passer par le routeur global.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  static const _programTab = 1;
  static const _progressTab = 2;
  static const _profileTab = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final activeAsync = ref.watch(studentActiveProgramProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentProfileProvider);
        ref.invalidate(studentActiveProgramProvider);
      },
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
          activeAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: LoadingIndicator(),
            ),
            error: (e, _) => _NextSessionError(
              message: 'Impossible de charger ta prochaine séance.',
              onRetry: () => ref.invalidate(studentActiveProgramProvider),
            ),
            data: (detail) => _NextSessionCard(
              detail: detail,
              onOpenProgram: () => onNavigate(_programTab),
            ),
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
          _ShortcutsGrid(
            onProgram: () => onNavigate(_programTab),
            onProgress: () => onNavigate(_progressTab),
            onProfile: () => onNavigate(_profileTab),
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
    final title = firstName.isEmpty
        ? 'Bienvenue Feater !'
        : 'Bonjour $firstName !';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Prêt(e) pour ta prochaine séance ?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.detail,
    required this.onOpenProgram,
  });

  final StudentActiveProgramDetail detail;
  final VoidCallback onOpenProgram;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = detail.sessions.isEmpty ? null : detail.sessions.first;
    final hasProgram = detail.program != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasProgram ? onOpenProgram : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.calendarClock,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Prochaine séance',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (next != null)
                _NextSessionContent(session: next)
              else
                _NextSessionEmpty(hasProgram: hasProgram),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextSessionContent extends StatelessWidget {
  const _NextSessionContent({required this.session});

  final StudentSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaParts = <String>[
      ?formatAssignedDateLabel(session.assignedDate),
      if (session.durationMinutes != null) '${session.durationMinutes} min',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.title,
          style: theme.textTheme.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (metaParts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            metaParts.join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if ((session.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            session.description!.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _NextSessionEmpty extends StatelessWidget {
  const _NextSessionEmpty({required this.hasProgram});

  final bool hasProgram;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = hasProgram
        ? 'Ton programme ne contient pas encore de séance.'
        : 'Ton coach ne t\'a pas encore assigné de programme.';
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _NextSessionError extends StatelessWidget {
  const _NextSessionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCcw, size: 16),
              label: const Text('Réessayer'),
            ),
          ),
        ],
      ),
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
                    'Renseigne ton profil pour commencer ton suivi.',
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
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutsGrid extends StatelessWidget {
  const _ShortcutsGrid({
    required this.onProgram,
    required this.onProgress,
    required this.onProfile,
  });

  final VoidCallback onProgram;
  final VoidCallback onProgress;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Raccourcis', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        _ShortcutTile(
          icon: LucideIcons.dumbbell,
          title: 'Mon programme',
          subtitle: 'Consulter mes séances',
          onTap: onProgram,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ShortcutTile(
          icon: LucideIcons.trendingUp,
          title: 'Progression',
          subtitle: 'Suivre mes mesures et mon historique',
          onTap: onProgress,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ShortcutTile(
          icon: LucideIcons.user,
          title: 'Profil',
          subtitle: 'Gérer mes informations',
          onTap: onProfile,
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

