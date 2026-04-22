import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/widgets/weight_measure_row.dart';
import '../../../theme/app_spacing.dart';
import '../../providers/weight_measure_providers.dart';

/// Affiche un bottom sheet modal avec l'historique complet des mesures.
Future<void> showWeightMeasuresSheet(
  BuildContext context, {
  required String studentId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => _WeightMeasuresSheet(
        studentId: studentId,
        scrollController: controller,
      ),
    ),
  );
}

/// Liste en lecture seule de toutes les mesures d'un élève.
class _WeightMeasuresSheet extends ConsumerWidget {
  const _WeightMeasuresSheet({
    required this.studentId,
    required this.scrollController,
  });

  final String studentId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(studentWeightsProvider(studentId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Toutes les mesures',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(
              message: 'Impossible de charger les mesures.\n$e',
              onRetry: () =>
                  ref.invalidate(studentWeightsProvider(studentId)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Aucune mesure enregistrée.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => WeightMeasureRow(measure: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}
