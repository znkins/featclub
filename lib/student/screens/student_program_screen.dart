import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/student_session.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_session_providers.dart';
import '../widgets/student_session_tile.dart';
import 'student_session_detail_screen.dart';

/// Onglet « Mon programme » : séances du programme actif, triées pour mettre
/// la prochaine séance en haut, plus compteur des séances de la semaine.
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
                  session: detail.sessions[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentSessionDetailScreen(
                        sessionId: detail.sessions[i].id,
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

/// Compteur des séances assignées sur la semaine calendaire en cours
/// (lundi → dimanche).
class _WeekCounter extends StatelessWidget {
  const _WeekCounter({required this.sessions});

  final List<StudentSession> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Lundi = weekday 1, dimanche = 7. On calcule le lundi de la semaine.
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final count = sessions.where((s) {
      final d = s.assignedDate;
      if (d == null) return false;
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(weekStart) && day.isBefore(weekEnd);
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
