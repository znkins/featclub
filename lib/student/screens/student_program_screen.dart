import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/services/student_program_service.dart';
import '../../core/utils/day_of_week.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_session_providers.dart';
import '../widgets/student_session_tile.dart';
import 'student_session_detail_screen.dart';

/// Onglet « Mon programme » de l'élève : compteur de séances de la
/// semaine + liste des séances triées (prochaine en premier).
class StudentProgramScreen extends ConsumerWidget {
  const StudentProgramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentActiveProgramProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentActiveProgramProvider),
      child: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger ton programme.\n$e',
          onRetry: () => ref.invalidate(studentActiveProgramProvider),
        ),
        data: (detail) {
          if (detail.program == null) {
            return CustomScrollView(
              slivers: const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(
                    icon: LucideIcons.dumbbell,
                    wrapIcon: true,
                    message:
                        'Ton coach ne t\'a pas encore assigné de programme.\nReviens bientôt !',
                  ),
                ),
              ],
            );
          }
          if (detail.sessions.isEmpty) {
            return CustomScrollView(
              slivers: const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyView(
                    icon: LucideIcons.calendarX,
                    wrapIcon: true,
                    message:
                        'Ton programme ne contient pas encore de séance.\nReviens bientôt !',
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              _WeekCounter(sessions: detail.sessions),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < detail.sessions.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                StudentSessionTile(
                  view: detail.sessions[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentSessionDetailScreen(
                        sessionId: detail.sessions[i].session.id,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Compteur des séances restantes sur la semaine en cours. Une séance
/// complétée cette semaine voit sa `nextOccurrence` rouler à la semaine
/// suivante, donc elle sort du décompte.
class _WeekCounter extends StatelessWidget {
  const _WeekCounter({required this.sessions});

  final List<StudentSessionView> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekEnd = currentWeekEnd();
    final count = sessions.where((v) {
      final d = v.nextOccurrence;
      if (d == null) return false;
      return d.isBefore(weekEnd);
    }).length;

    final label = count == 0
        ? 'Aucune séance prévue cette semaine'
        : '$count séance${count > 1 ? 's' : ''} prévue${count > 1 ? 's' : ''} cette semaine';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.calendarDays,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
