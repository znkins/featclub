import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../theme/app_spacing.dart';
import '../providers/coach_activity_providers.dart';
import '../widgets/activity_list_tile.dart';

/// Page Activité coach : feed des dernières séances complétées par tous les
/// élèves. Ouverte depuis l'accueil coach (Navigator.push).
class CoachActivityScreen extends ConsumerWidget {
  const CoachActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coachActivityFeedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Activité')),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger l\'activité.\n$e',
          onRetry: () => ref.invalidate(coachActivityFeedProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(coachActivityFeedProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: AppSpacing.xxl * 2),
                  EmptyView(
                    icon: LucideIcons.calendarCheck,
                    wrapIcon: true,
                    message:
                        'Aucune séance terminée pour le moment.\nLe feed se remplira au fil des complétions.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(coachActivityFeedProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => ActivityListTile(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}
