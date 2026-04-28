import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/student_session.dart';
import '../../../../core/models/student_session_block.dart';
import '../../../../core/services/student_program_service.dart';
import '../../../../core/utils/day_of_week.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/student_program_providers.dart';
import '../../../widgets/add_choice_sheet.dart';
import '../../../widgets/content_section_header.dart';
import '../../../widgets/detail_field.dart';
import '../../../widgets/detail_info_card.dart';
import '../../../widgets/duration_pill.dart';
import '../../../widgets/editor_breadcrumb.dart';
import '../../../widgets/reorderable_library_row.dart';
import 'student_block_editor_screen.dart';
import 'student_block_form_screen.dart';
import 'student_block_template_picker_screen.dart';
import 'student_session_form_screen.dart';

/// Éditeur d'une séance élève : métadonnées + liste des blocs.
class StudentSessionEditorScreen extends ConsumerWidget {
  const StudentSessionEditorScreen({
    super.key,
    required this.studentId,
    required this.programId,
    required this.programTitle,
    required this.sessionId,
  });

  final String studentId;
  final String programId;
  final String programTitle;
  final String sessionId;

  static Route<void> route({
    required String studentId,
    required String programId,
    required String programTitle,
    required String sessionId,
  }) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: EditorRoutes.session),
      builder: (_) => StudentSessionEditorScreen(
        studentId: studentId,
        programId: programId,
        programTitle: programTitle,
        sessionId: sessionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentSessionEditorDetailProvider(sessionId));
    final studentName = resolveStudentName(ref, studentId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.valueOrNull?.session.title ?? 'Séance',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          async.maybeWhen(
            data: (detail) => Row(
              children: [
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(LucideIcons.pencil),
                  onPressed: () => _editSession(context, detail.session),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () =>
                      _deleteSession(context, ref, detail.session),
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
          ],
          current: async.valueOrNull?.session.title ?? 'Séance',
        ),
      ),
      floatingActionButton: async.maybeWhen(
        data: (_) => FloatingActionButton.extended(
          onPressed: () => _openAddSheet(context, ref),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Ajouter'),
        ),
        orElse: () => null,
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger la séance.\n$e',
          onRetry: () =>
              ref.invalidate(studentSessionEditorDetailProvider(sessionId)),
        ),
        data: (detail) => _SessionBody(
          studentId: studentId,
          programId: programId,
          programTitle: programTitle,
          detail: detail,
        ),
      ),
    );
  }

  Future<void> _editSession(
    BuildContext context,
    StudentSession session,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentSessionFormScreen(existing: session),
      ),
    );
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    StudentSession session,
  ) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer la séance',
      message:
          'Supprimer « ${session.title} » ? Les blocs et exercices de cette séance seront définitivement perdus.',
      confirmLabel: 'Supprimer',
      variant: ConfirmationVariant.destructive,
    );
    if (!confirm) return;
    try {
      await ref.read(studentProgramServiceProvider).deleteSession(session.id);
      ref.invalidate(studentProgramEditorDetailProvider(programId));
      if (!context.mounted) return;
      AppSnackbar.showSuccess(context, 'Séance supprimée');
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final choice = await showAddChoiceSheet(
      context,
      title: 'Ajouter un bloc',
      emptyTitle: 'Nouveau bloc',
      emptySubtitle: 'Créer un bloc vide à construire.',
      templateTitle: 'Copier un template',
      templateSubtitle: 'Copier un bloc de la bibliothèque.',
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case AddChoice.empty:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentBlockFormScreen(
              sessionId: sessionId,
              programId: programId,
            ),
          ),
        );
      case AddChoice.template:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentBlockTemplatePickerScreen(
              sessionId: sessionId,
              programId: programId,
            ),
          ),
        );
    }
  }
}

class _SessionBody extends ConsumerStatefulWidget {
  const _SessionBody({
    required this.studentId,
    required this.programId,
    required this.programTitle,
    required this.detail,
  });

  final String studentId;
  final String programId;
  final String programTitle;
  final StudentSessionEditorDetail detail;

  @override
  ConsumerState<_SessionBody> createState() => _SessionBodyState();
}

class _SessionBodyState extends ConsumerState<_SessionBody> {
  late List<StudentBlockListItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.detail.blocks);
  }

  @override
  void didUpdateWidget(covariant _SessionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.blocks != widget.detail.blocks) {
      _items = List.of(widget.detail.blocks);
    }
  }

  Future<void> _deleteBlock(StudentSessionBlock block) async {
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
      ref.invalidate(
        studentSessionEditorDetailProvider(widget.detail.session.id),
      );
      ref.invalidate(studentProgramEditorDetailProvider(widget.programId));
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Bloc supprimé');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _duplicateBlock(StudentSessionBlock block) async {
    try {
      await ref
          .read(studentProgramServiceProvider)
          .duplicateStudentBlock(block.id);
      ref.invalidate(
        studentSessionEditorDetailProvider(widget.detail.session.id),
      );
      ref.invalidate(studentProgramEditorDetailProvider(widget.programId));
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Bloc dupliqué');
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
      await ref.read(studentProgramServiceProvider).reorderBlocks(
            sessionId: widget.detail.session.id,
            blockIdsInOrder: _items.map((i) => i.block.id).toList(),
          );
      ref.invalidate(
        studentSessionEditorDetailProvider(widget.detail.session.id),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur lors du réordonnancement : $e');
      ref.invalidate(
        studentSessionEditorDetailProvider(widget.detail.session.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.detail.session;

    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Header(session: session),
          const SizedBox(height: AppSpacing.xl),
          const EmptyView(
            icon: LucideIcons.layers,
            wrapIcon: true,
            message:
                'Aucun bloc dans cette séance.\nAppuie sur « Ajouter » pour commencer.',
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
            _Header(session: session),
            const SizedBox(height: AppSpacing.xl),
            ContentSectionHeader(title: 'Blocs', count: _items.length),
          ],
        ),
      ),
      itemCount: _items.length,
      onReorder: _onReorder,
      itemBuilder: (_, i) {
        final item = _items[i];
        final block = item.block;
        final hasDescription =
            block.description != null && block.description!.isNotEmpty;
        return Padding(
          key: ValueKey(block.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ReorderableLibraryRow(
            index: i,
            title: block.title,
            removeLabel: 'Supprimer',
            subtitleWidget: _BlockSubtitle(
              exerciseCount: item.exerciseCount,
              description: hasDescription ? block.description : null,
            ),
            onTap: () => Navigator.of(context).push(
              StudentBlockEditorScreen.route(
                studentId: widget.studentId,
                programId: widget.programId,
                programTitle: widget.programTitle,
                sessionId: widget.detail.session.id,
                sessionTitle: session.title,
                blockId: block.id,
              ),
            ),
            onDuplicate: () => _duplicateBlock(block),
            onRemove: () => _deleteBlock(block),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session});
  final StudentSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription =
        session.description != null && session.description!.isNotEmpty;
    final day = DayOfWeek.fromStorage(session.dayOfWeek);
    return DetailInfoCard(
      children: [
        DetailField(
          label: 'Titre',
          child: Text(session.title, style: theme.textTheme.bodyLarge),
        ),
        DetailField(
          label: 'Durée',
          child: session.durationMinutes != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: DurationPill(minutes: session.durationMinutes!),
                )
              : null,
        ),
        DetailField(
          label: 'Jour',
          child: day != null
              ? Text(day.frenchLabel, style: theme.textTheme.bodyLarge)
              : null,
        ),
        DetailField(
          label: 'Description',
          child: hasDescription
              ? Text(
                  session.description!,
                  style: theme.textTheme.bodyLarge,
                )
              : null,
        ),
      ],
    );
  }
}

class _BlockSubtitle extends StatelessWidget {
  const _BlockSubtitle({
    required this.exerciseCount,
    required this.description,
  });

  final int exerciseCount;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (description != null) ...[
          Text(
            description!,
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          '$exerciseCount exercice${exerciseCount > 1 ? 's' : ''}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
