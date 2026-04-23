import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/completed_session.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/providers/student_data_providers.dart';
import '../../shared/widgets/weight_measure_row.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../widgets/student_weight_measure_dialog.dart';
import '../widgets/student_weight_measures_sheet.dart';
import '../widgets/weight_evolution_chart.dart';
import 'student_history_screen.dart';

/// Onglet Progression élève : poids actuel, compteur complétions, graphique,
/// 3 dernières mesures (+ voir plus), 3 dernières séances (+ voir plus).
class StudentProgressScreen extends ConsumerWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    return profileAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorView(
        message: 'Impossible de charger ton profil.\n$e',
        onRetry: () => ref.invalidate(currentProfileProvider),
      ),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentProfileProvider);
            ref.invalidate(studentWeightsProvider(profile.id));
            ref.invalidate(studentRecentHistoryProvider(profile.id));
            ref.invalidate(studentCompletedSessionCountProvider(profile.id));
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _StatsRow(
                studentId: profile.id,
                currentWeight: profile.currentWeight,
              ),
              const SizedBox(height: AppSpacing.xl),
              _WeightSection(studentId: profile.id),
              const SizedBox(height: AppSpacing.xl),
              _HistorySection(studentId: profile.id),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.studentId, required this.currentWeight});

  final String studentId;
  final double? currentWeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync =
        ref.watch(studentCompletedSessionCountProvider(studentId));
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: LucideIcons.scale,
            value: currentWeight != null
                ? formatWeightKg(currentWeight!)
                : '—',
            label: 'Poids actuel',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.activity,
            value: countAsync.maybeWhen(
              data: (c) => '$c',
              orElse: () => '—',
            ),
            label: 'Séances terminées',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(title, style: theme.textTheme.headlineSmall),
        ),
        ?action,
      ],
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdAll,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

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

class _SeeMoreLink extends StatelessWidget {
  const _SeeMoreLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(onPressed: onTap, child: const Text('Voir plus')),
    );
  }
}

class _WeightSection extends ConsumerWidget {
  const _WeightSection({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentWeightsProvider(studentId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Mes mesures',
          action: TextButton.icon(
            onPressed: () => showStudentWeightMeasureDialog(context),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Ajouter'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingIndicator(),
          ),
          error: (e, _) => _SectionError(
            message: 'Impossible de charger tes mesures.\n$e',
            onRetry: () => ref.invalidate(studentWeightsProvider(studentId)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const _EmptySectionCard(
                icon: LucideIcons.scale,
                title: 'Aucune mesure',
                subtitle: 'Ajoute ta première pesée pour démarrer le suivi.',
              );
            }
            final recent = items.take(3).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (items.length >= 2) ...[
                  WeightEvolutionChart(measures: items),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  WeightMeasureRow(measure: recent[i]),
                ],
                if (items.length > 3)
                  _SeeMoreLink(
                    onTap: () => showStudentWeightMeasuresSheet(
                      context,
                      studentId: studentId,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HistorySection extends ConsumerWidget {
  const _HistorySection({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentRecentHistoryProvider(studentId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Historique'),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingIndicator(),
          ),
          error: (e, _) => _SectionError(
            message: 'Impossible de charger l\'historique.\n$e',
            onRetry: () =>
                ref.invalidate(studentRecentHistoryProvider(studentId)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const _EmptySectionCard(
                icon: LucideIcons.calendarCheck,
                title: 'Aucune séance terminée',
                subtitle:
                    'Ton historique apparaîtra ici après ta première séance.',
              );
            }
            final recent = items.take(3).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _CompactHistoryRow(item: recent[i]),
                ],
                if (items.length > 3)
                  _SeeMoreLink(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentHistoryScreen(studentId: studentId),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CompactHistoryRow extends StatelessWidget {
  const _CompactHistoryRow({required this.item});

  final CompletedSession item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.sessionTitle,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            formatDate(item.completedAt),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
