import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/student_session_block.dart';
import '../../../../core/models/student_session_exercise.dart';
import '../../../../core/services/student_program_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../shared/widgets/exercise_note_row.dart';
import '../../../../shared/widgets/exercise_params_row.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/student_program_providers.dart';
import '../../../widgets/add_choice_sheet.dart';
import '../../../widgets/content_section_header.dart';
import '../../../widgets/detail_field.dart';
import '../../../widgets/detail_info_card.dart';
import '../../../widgets/editor_breadcrumb.dart';
import '../../../widgets/reorderable_library_row.dart';
import 'student_block_form_screen.dart';
import 'student_exercise_editor_screen.dart';
import 'student_exercise_library_picker_screen.dart';

/// Éditeur d'un bloc d'un élève : titre + liste des exercices.
/// Ajout d'exercice : depuis la bibliothèque coach (snapshot titre/vidéo)
/// ou en saisie libre (paramètres custom).
class StudentBlockEditorScreen extends ConsumerWidget {
  const StudentBlockEditorScreen({
    super.key,
    required this.studentId,
    required this.programId,
    required this.programTitle,
    required this.sessionId,
    required this.sessionTitle,
    required this.blockId,
  });

  final String studentId;
  final String programId;
  final String programTitle;
  final String sessionId;
  final String sessionTitle;
  final String blockId;

  static Route<void> route({
    required String studentId,
    required String programId,
    required String programTitle,
    required String sessionId,
    required String sessionTitle,
    required String blockId,
  }) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: EditorRoutes.block),
      builder: (_) => StudentBlockEditorScreen(
        studentId: studentId,
        programId: programId,
        programTitle: programTitle,
        sessionId: sessionId,
        sessionTitle: sessionTitle,
        blockId: blockId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentBlockEditorDetailProvider(blockId));
    final studentName = resolveStudentName(ref, studentId);
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
        bottom: EditorBreadcrumb(
          parents: [
            EditorCrumb(
              label: studentName,
              routeName: EditorRoutes.studentDetail,
            ),
            EditorCrumb(
              label: programTitle,
              routeName: EditorRoutes.program,
            ),
            EditorCrumb(
              label: sessionTitle,
              routeName: EditorRoutes.session,
            ),
          ],
          current: async.valueOrNull?.block.title ?? 'Bloc',
        ),
      ),
      floatingActionButton: async.maybeWhen(
        data: (detail) => FloatingActionButton.extended(
          onPressed: () => _openAddSheet(context, ref, detail.block.title),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Ajouter'),
        ),
        orElse: () => null,
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger le bloc.\n$e',
          onRetry: () =>
              ref.invalidate(studentBlockEditorDetailProvider(blockId)),
        ),
        data: (detail) => _BlockBody(
          studentId: studentId,
          programId: programId,
          programTitle: programTitle,
          sessionId: sessionId,
          sessionTitle: sessionTitle,
          detail: detail,
        ),
      ),
    );
  }

  Future<void> _editBlock(
    BuildContext context,
    StudentSessionBlock block,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentBlockFormScreen(existing: block),
      ),
    );
  }

  Future<void> _deleteBlock(
    BuildContext context,
    WidgetRef ref,
    StudentSessionBlock block,
  ) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer le bloc',
      message:
          'Supprimer « ${block.title} » ? Les exercices de ce bloc seront définitivement perdus.',
      confirmLabel: 'Supprimer',
      variant: ConfirmationVariant.destructive,
    );
    if (!confirm) return;
    try {
      await ref.read(studentProgramServiceProvider).deleteBlock(block.id);
      ref.invalidate(studentSessionEditorDetailProvider(sessionId));
      // Le `blockCount` de la séance affichée dans l'éditeur programme
      // change : invalider aussi ce niveau.
      ref.invalidate(studentProgramEditorDetailProvider(programId));
      if (!context.mounted) return;
      AppSnackbar.showSuccess(context, 'Bloc supprimé');
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _openAddSheet(
    BuildContext context,
    WidgetRef ref,
    String blockTitle,
  ) async {
    final choice = await showAddChoiceSheet(
      context,
      title: 'Ajouter un exercice',
      emptyTitle: 'Exercice ad hoc',
      emptySubtitle: 'Créer un exercice libre avec des paramètres custom.',
      templateTitle: 'Depuis la bibliothèque',
      templateSubtitle: 'Copier un exercice de ta bibliothèque.',
      emptyIcon: LucideIcons.filePlus,
      templateIcon: LucideIcons.library,
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case AddChoice.empty:
        await Navigator.of(context).push(
          StudentExerciseEditorScreen.createRoute(
            studentId: studentId,
            programId: programId,
            programTitle: programTitle,
            sessionId: sessionId,
            sessionTitle: sessionTitle,
            blockId: blockId,
            blockTitle: blockTitle,
          ),
        );
      case AddChoice.template:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentExerciseLibraryPickerScreen(
              blockId: blockId,
              sessionId: sessionId,
            ),
          ),
        );
    }
  }
}

class _BlockBody extends ConsumerStatefulWidget {
  const _BlockBody({
    required this.studentId,
    required this.programId,
    required this.programTitle,
    required this.sessionId,
    required this.sessionTitle,
    required this.detail,
  });

  final String studentId;
  final String programId;
  final String programTitle;
  final String sessionId;
  final String sessionTitle;
  final StudentBlockEditorDetail detail;

  @override
  ConsumerState<_BlockBody> createState() => _BlockBodyState();
}

class _BlockBodyState extends ConsumerState<_BlockBody> {
  late List<StudentSessionExercise> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.detail.exercises);
  }

  @override
  void didUpdateWidget(covariant _BlockBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.exercises != widget.detail.exercises) {
      _items = List.of(widget.detail.exercises);
    }
  }

  Future<void> _deleteExercise(StudentSessionExercise exercise) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer l\'exercice',
      message:
          'Supprimer « ${exercise.title} » ? Les paramètres personnalisés seront définitivement perdus.',
      confirmLabel: 'Supprimer',
      variant: ConfirmationVariant.destructive,
    );
    if (!confirm) return;
    try {
      await ref
          .read(studentProgramServiceProvider)
          .deleteExercise(exercise.id);
      ref.invalidate(
        studentBlockEditorDetailProvider(widget.detail.block.id),
      );
      ref.invalidate(studentSessionEditorDetailProvider(widget.sessionId));
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Exercice supprimé');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    try {
      await ref.read(studentProgramServiceProvider).reorderExercises(
            blockId: widget.detail.block.id,
            exerciseIdsInOrder: _items.map((e) => e.id).toList(),
          );
      ref.invalidate(
        studentBlockEditorDetailProvider(widget.detail.block.id),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur lors du réordonnancement : $e');
      ref.invalidate(
        studentBlockEditorDetailProvider(widget.detail.block.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.detail.block;

    if (_items.isEmpty) {
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
            ContentSectionHeader(title: 'Exercices', count: _items.length),
          ],
        ),
      ),
      itemCount: _items.length,
      onReorder: _onReorder,
      itemBuilder: (_, i) {
        final exercise = _items[i];
        return Padding(
          key: ValueKey(exercise.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ReorderableLibraryRow(
            index: i,
            title: exercise.title,
            removeLabel: 'Supprimer',
            subtitleWidget: _ExerciseSubtitle(exercise: exercise),
            onTap: () => Navigator.of(context).push(
              StudentExerciseEditorScreen.editRoute(
                studentId: widget.studentId,
                programId: widget.programId,
                programTitle: widget.programTitle,
                sessionId: widget.sessionId,
                sessionTitle: widget.sessionTitle,
                blockId: widget.detail.block.id,
                blockTitle: block.title,
                exerciseId: exercise.id,
              ),
            ),
            onRemove: () => _deleteExercise(exercise),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.block});
  final StudentSessionBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription =
        block.description != null && block.description!.isNotEmpty;
    return DetailInfoCard(
      children: [
        DetailField(
          label: 'Titre',
          child: Text(block.title, style: theme.textTheme.bodyLarge),
        ),
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

class _ExerciseSubtitle extends StatelessWidget {
  const _ExerciseSubtitle({required this.exercise});

  final StudentSessionExercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = (exercise.description ?? '').trim();
    final note = (exercise.note ?? '').trim();
    final hasParams = ExerciseParamsRow.hasContent(exercise);
    if (description.isEmpty && !hasParams && note.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (description.isNotEmpty) ...[
          Text(
            description,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasParams || note.isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
        ],
        if (hasParams) ExerciseParamsRow(exercise: exercise),
        if (note.isNotEmpty) ...[
          if (hasParams) const SizedBox(height: AppSpacing.sm),
          // Borne le texte pour que les tuiles gardent une hauteur
          // raisonnable même avec une note longue.
          ExerciseNoteRow(note: note, maxLines: 3),
        ],
      ],
    );
  }
}
