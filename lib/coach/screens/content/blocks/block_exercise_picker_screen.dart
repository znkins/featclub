import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/exercise.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/block_providers.dart';
import '../../../providers/exercise_providers.dart';
import '../../../widgets/category_chip.dart';
import '../../../widgets/library_search_field.dart';
import '../../../widgets/library_selectable_tile.dart';
import '../../../widgets/library_type_icon.dart';

/// Picker multi-sélection d'exercices à ajouter dans un bloc template.
/// Les duplicats sont autorisés : on n'exclut pas les exercices déjà présents.
class BlockExercisePickerScreen extends ConsumerStatefulWidget {
  const BlockExercisePickerScreen({super.key, required this.blockId});

  final String blockId;

  @override
  ConsumerState<BlockExercisePickerScreen> createState() =>
      _BlockExercisePickerScreenState();
}

class _BlockExercisePickerScreenState
    extends ConsumerState<BlockExercisePickerScreen> {
  final Set<String> _selected = {};
  String _query = '';
  bool _saving = false;

  List<Exercise> _filter(List<Exercise> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            (e.category?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<void> _add() async {
    if (_saving || _selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(blockServiceProvider);
      for (final id in _selected) {
        await service.addExercise(blockId: widget.blockId, exerciseId: id);
      }
      ref.invalidate(blockDetailProvider(widget.blockId));
      ref.invalidate(coachBlocksProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Ajouté au bloc');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachExercisesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des exercices'),
        actions: [
          TextButton(
            onPressed: (_selected.isEmpty || _saving) ? null : _add,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Ajouter (${_selected.length})'),
          ),
        ],
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
                  return const EmptyView(
                    icon: LucideIcons.dumbbell,
                    wrapIcon: true,
                    message:
                        'Aucun exercice disponible.\nCrée d\'abord des exercices dans la bibliothèque.',
                  );
                }
                final filtered = _filter(all);
                if (filtered.isEmpty) {
                  return const EmptyView.noResults();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) {
                    final e = filtered[i];
                    final checked = _selected.contains(e.id);
                    final hasCategory =
                        e.category != null && e.category!.isNotEmpty;
                    return LibrarySelectableTile(
                      title: e.title,
                      leading: const LibraryTypeIcon(
                        icon: LucideIcons.dumbbell,
                      ),
                      subtitleWidget: hasCategory
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: CategoryChip(label: e.category!),
                            )
                          : null,
                      checked: checked,
                      onTap: () => setState(() {
                        if (checked) {
                          _selected.remove(e.id);
                        } else {
                          _selected.add(e.id);
                        }
                      }),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
