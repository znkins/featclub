import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/block.dart';
import '../../../../core/models/exercise.dart';
import '../../../../core/services/block_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/block_providers.dart';
import '../../../widgets/category_chip.dart';
import '../../../widgets/detail_field.dart';
import '../../../widgets/reorderable_library_row.dart';
import '../exercises/exercise_detail_screen.dart';
import 'block_exercise_picker_screen.dart';
import 'block_form_screen.dart';

class BlockDetailScreen extends ConsumerWidget {
  const BlockDetailScreen({super.key, required this.blockId});

  final String blockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blockDetailProvider(blockId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.valueOrNull?.block.title ?? 'Bloc',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          async.maybeWhen(
            data: (detail) => Row(
              children: [
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(LucideIcons.pencil),
                  onPressed: () => _editBlock(context, detail.block),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () => _deleteBlock(context, ref, detail.block),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: async.maybeWhen(
        data: (_) => FloatingActionButton.extended(
          onPressed: () => _openPicker(context),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Ajouter'),
        ),
        orElse: () => null,
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger le bloc.\n$e',
          onRetry: () => ref.invalidate(blockDetailProvider(blockId)),
        ),
        data: (detail) => _BlockBody(detail: detail),
      ),
    );
  }

  Future<void> _editBlock(BuildContext context, Block block) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlockFormScreen(existing: block),
      ),
    );
  }

  Future<void> _deleteBlock(
    BuildContext context,
    WidgetRef ref,
    Block block,
  ) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer le bloc',
      message:
          'Supprimer « ${block.title} » ? Les exercices restent dans ta bibliothèque.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!confirm) return;
    try {
      await ref.read(blockServiceProvider).delete(block.id);
      ref.invalidate(coachBlocksProvider);
      if (!context.mounted) return;
      AppSnackbar.showSuccess(context, 'Bloc supprimé');
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _openPicker(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlockExercisePickerScreen(blockId: blockId),
      ),
    );
  }
}

class _BlockBody extends ConsumerStatefulWidget {
  const _BlockBody({required this.detail});

  final BlockDetail detail;

  @override
  ConsumerState<_BlockBody> createState() => _BlockBodyState();
}

class _BlockBodyState extends ConsumerState<_BlockBody> {
  late List<BlockExerciseLink> _links;

  @override
  void initState() {
    super.initState();
    _links = List.of(widget.detail.links);
  }

  @override
  void didUpdateWidget(covariant _BlockBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.links != widget.detail.links) {
      _links = List.of(widget.detail.links);
    }
  }

  Future<void> _remove(BlockExerciseLink link) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Retirer l\'exercice',
      message:
          'Retirer « ${link.exercise.title} » du bloc ? Il reste dans ta bibliothèque.',
      confirmLabel: 'Retirer',
    );
    if (!confirm) return;
    try {
      await ref.read(blockServiceProvider).removeLink(link.linkId);
      ref.invalidate(blockDetailProvider(widget.detail.block.id));
      ref.invalidate(coachBlocksProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Exercice retiré');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _duplicate(Exercise exercise) async {
    try {
      await ref.read(blockServiceProvider).addExercise(
            blockId: widget.detail.block.id,
            exerciseId: exercise.id,
          );
      ref.invalidate(blockDetailProvider(widget.detail.block.id));
      ref.invalidate(coachBlocksProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Exercice dupliqué');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _links.removeAt(oldIndex);
      _links.insert(newIndex, item);
    });
    try {
      await ref.read(blockServiceProvider).reorderLinks(
            blockId: widget.detail.block.id,
            linkIdsInOrder: _links.map((l) => l.linkId).toList(),
          );
      ref.invalidate(blockDetailProvider(widget.detail.block.id));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur lors du réordonnancement : $e');
      ref.invalidate(blockDetailProvider(widget.detail.block.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.detail.block;

    if (_links.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Header(block: block),
          const SizedBox(height: AppSpacing.xl),
          const EmptyView(
            icon: LucideIcons.dumbbell,
            wrapIcon: true,
            message:
                'Aucun exercice dans ce bloc.\nAppuie sur « Ajouter » pour commencer.',
          ),
        ],
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl * 2,
      ),
      proxyDecorator: flatProxyDecorator,
      header: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(block: block),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '${_links.length} exercice${_links.length > 1 ? 's' : ''}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      itemCount: _links.length,
      onReorder: _onReorder,
      itemBuilder: (_, i) {
        final link = _links[i];
        final exercise = link.exercise;
        return Padding(
          key: ValueKey(link.linkId),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ReorderableLibraryRow(
            index: i,
            title: exercise.title,
            subtitleWidget:
                exercise.category != null && exercise.category!.isNotEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: CategoryChip(label: exercise.category!),
                      )
                    : null,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ExerciseDetailScreen(exerciseId: exercise.id),
              ),
            ),
            onDuplicate: () => _duplicate(exercise),
            onRemove: () => _remove(link),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.block});
  final Block block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription =
        block.description != null && block.description!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailField(
          label: 'Titre',
          child: Text(block.title, style: theme.textTheme.bodyLarge),
        ),
        const SizedBox(height: AppSpacing.xl),
        DetailField(
          label: 'Description',
          child: hasDescription
              ? Text(
                  block.description!,
                  style: theme.textTheme.bodyLarge,
                )
              : null,
        ),
      ],
    );
  }
}
