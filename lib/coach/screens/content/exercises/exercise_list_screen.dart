import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/exercise.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/exercise_providers.dart';
import '../../../widgets/editor_breadcrumb.dart';
import '../../../widgets/exercise_tile_subtitle.dart';
import '../../../widgets/library_list_tile.dart';
import '../../../widgets/library_search_field.dart';
import '../../../widgets/library_type_icon.dart';
import 'exercise_detail_screen.dart';
import 'exercise_form_screen.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  String _query = '';

  List<Exercise> _filter(List<Exercise> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            (e.category?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  void _openForm({Exercise? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseFormScreen(existing: existing),
      ),
    );
  }

  void _openDetail(Exercise exercise) {
    Navigator.of(context).push(
      ExerciseDetailScreen.route(
        exerciseId: exercise.id,
        parents: [
          EditorCrumb(
            label: 'Exercices',
            onTap: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachExercisesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Nouvel exercice',
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        children: [
          LibrarySearchField(
            hintText: 'Rechercher un exercice',
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: 'Impossible de charger les exercices.\n$e',
                onRetry: () => ref.invalidate(coachExercisesProvider),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return EmptyView(
                    icon: LucideIcons.dumbbell,
                    wrapIcon: true,
                    message:
                        'Aucun exercice.\nAjoute ton premier exercice pour commencer.',
                    action: FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Nouvel exercice'),
                    ),
                  );
                }
                final filtered = _filter(all);
                if (filtered.isEmpty) {
                  return const EmptyView(
                    icon: LucideIcons.search,
                    message: 'Aucun résultat',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(coachExercisesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxl * 2,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) {
                      final e = filtered[i];
                      return LibraryListTile(
                        title: e.title,
                        subtitleWidget: ExerciseTileSubtitle.hasContent(
                          description: e.description,
                          category: e.category,
                        )
                            ? ExerciseTileSubtitle(
                                description: e.description,
                                category: e.category,
                              )
                            : null,
                        leading: const LibraryTypeIcon(
                          icon: LucideIcons.dumbbell,
                        ),
                        onTap: () => _openDetail(e),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

