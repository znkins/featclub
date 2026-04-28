import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_data_providers.dart';
import 'compact_history_row.dart';

/// Bottom sheet listant l'historique complet des séances terminées d'un
/// élève. Utilisé par la fiche coach et l'onglet progression élève
/// (le `studentId` change selon l'appelant).
Future<void> showHistorySheet(
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
      builder: (_, controller) => _HistorySheet(
        studentId: studentId,
        scrollController: controller,
      ),
    ),
  );
}

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet({
    required this.studentId,
    required this.scrollController,
  });

  final String studentId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(studentHistoryProvider(studentId));
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
                  'Historique des séances',
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
              message: 'Impossible de charger l\'historique.\n$e',
              onRetry: () =>
                  ref.invalidate(studentHistoryProvider(studentId)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Aucune séance terminée pour l\'instant.',
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
                itemBuilder: (_, i) => CompactHistoryRow(
                  item: items[i],
                  showComment: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
