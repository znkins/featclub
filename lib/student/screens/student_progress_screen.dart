import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/providers/student_data_providers.dart';
import '../../shared/widgets/compact_history_row.dart';
import '../../shared/widgets/empty_section_card.dart';
import '../../shared/widgets/history_sheet.dart';
import '../../shared/widgets/profile_identity_card.dart';
import '../../shared/widgets/section_error.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/see_more_link.dart';
import '../../shared/widgets/weight_evolution_chart.dart';
import '../../shared/widgets/weight_measure_row.dart';
import '../../shared/widgets/weight_measures_sheet.dart';
import '../../theme/app_spacing.dart';
import '../widgets/student_weight_measure_dialog.dart';

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
    return ProfileStatsGrid(
      tiles: [
        ProfileStatTile(
          icon: LucideIcons.scale,
          value:
              currentWeight != null ? formatWeightKg(currentWeight!) : null,
          label: 'Poids actuel',
        ),
        ProfileStatTile(
          icon: LucideIcons.activity,
          value: countAsync.maybeWhen(
            data: (c) => '$c',
            orElse: () => null,
          ),
          label: 'Séances',
        ),
      ],
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
        SectionHeader(
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
          error: (e, _) => SectionError(
            message: 'Impossible de charger tes mesures.\n$e',
            onRetry: () => ref.invalidate(studentWeightsProvider(studentId)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptySectionCard(
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
                  SeeMoreLink(
                    onTap: () => showWeightMeasuresSheet(
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
        const SectionHeader(title: 'Historique'),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingIndicator(),
          ),
          error: (e, _) => SectionError(
            message: 'Impossible de charger l\'historique.\n$e',
            onRetry: () =>
                ref.invalidate(studentRecentHistoryProvider(studentId)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptySectionCard(
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
                  CompactHistoryRow(item: recent[i]),
                ],
                if (items.length > 3)
                  SeeMoreLink(
                    onTap: () => showHistorySheet(
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
