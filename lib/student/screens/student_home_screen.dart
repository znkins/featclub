import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../coach/widgets/duration_pill.dart';
import '../../core/models/profile.dart';
import '../../core/services/student_program_service.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/widgets/section_header.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_session_providers.dart';
import '../widgets/assigned_date_pill.dart';
import 'student_session_detail_screen.dart';

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
            data: (detail) {
              final next =
                  detail.sessions.isEmpty ? null : detail.sessions.first;
              return _NextSessionCard(
                detail: detail,
                onOpenProgram: () => onNavigate(_programTab),
                onStartSession: next == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentSessionDetailScreen(
                              sessionId: next.session.id,
                            ),
                          ),
                        ),
              );
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
    required this.onStartSession,
  });

  final StudentActiveProgramDetail detail;

  /// Tab-switch vers « Mon programme ». Utilisé pour l'état avec programme
  /// mais sans prochaine séance (rien à commencer, on redirige vers la liste).
  final VoidCallback onOpenProgram;

  /// Ouvre l'écran de détail de la prochaine séance. `null` quand il n'y
  /// a pas de séance suivante (pas de programme, ou programme vide).
  final VoidCallback? onStartSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = detail.sessions.isEmpty ? null : detail.sessions.first;
    final hasProgram = detail.program != null;
    final cardTap = onStartSession ?? (hasProgram ? onOpenProgram : null);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: cardTap,
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
                  Expanded(
                    child: Text(
                      'Prochaine séance',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (cardTap != null)
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      // Chevron orange quand la carte est un CTA fort
                      // (commencer la prochaine séance), teal quand c'est
                      // de la simple navigation (vers le tab Programme).
                      color: onStartSession != null
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (next != null)
                _NextSessionContent(view: next)
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
  const _NextSessionContent({required this.view});

  final StudentSessionView view;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = view.session;
    final hasDate = view.nextOccurrence != null;
    final hasDuration = session.durationMinutes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.title,
          style: theme.textTheme.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasDate || hasDuration) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (hasDate) AssignedDatePill(date: view.nextOccurrence!),
              if (hasDuration) DurationPill(minutes: session.durationMinutes!),
            ],
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
              size: 18,
              color: theme.colorScheme.secondary,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Raccourcis'),
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

