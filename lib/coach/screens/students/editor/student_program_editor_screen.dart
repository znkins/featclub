import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/student_program.dart';
import '../../../../core/models/student_session.dart';
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
import '../../../widgets/editor_breadcrumb.dart';
import '../../../widgets/reorderable_library_row.dart';
import '../../../widgets/session_meta_row.dart';
import '../student_program_form_screen.dart';
import 'student_session_editor_screen.dart';
import 'student_session_form_screen.dart';
import 'student_session_template_picker_screen.dart';

/// Éditeur racine d'un programme élève : métadonnées + liste des séances.
///
/// Le coach peut y ajouter des séances (vides ou depuis template), les
/// réordonner, les supprimer, et ouvrir chaque séance pour éditer ses blocs.
class StudentProgramEditorScreen extends ConsumerWidget {
  const StudentProgramEditorScreen({
    super.key,
    required this.studentId,
    required this.programId,
  });

  final String studentId;
  final String programId;

  static Route<void> route({
    required String studentId,
    required String programId,
  }) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: EditorRoutes.program),
      builder: (_) => StudentProgramEditorScreen(
        studentId: studentId,
        programId: programId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentProgramEditorDetailProvider(programId));
    final studentName = resolveStudentName(ref, studentId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.valueOrNull?.program.title ?? 'Programme',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          async.maybeWhen(
            data: (detail) => Row(
              children: [
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(LucideIcons.pencil),
                  onPressed: () => _editProgram(context, detail.program),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () =>
                      _deleteProgram(context, ref, detail.program),
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
          ],
          current: async.valueOrNull?.program.title ?? 'Programme',
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
          message: 'Impossible de charger le programme.\n$e',
          onRetry: () =>
              ref.invalidate(studentProgramEditorDetailProvider(programId)),
        ),
        data: (detail) => _ProgramBody(
          studentId: studentId,
          detail: detail,
        ),
      ),
    );
  }

  Future<void> _editProgram(
    BuildContext context,
    StudentProgram program,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentProgramFormScreen(
          studentId: studentId,
          existing: program,
        ),
      ),
    );
  }

  Future<void> _deleteProgram(
    BuildContext context,
    WidgetRef ref,
    StudentProgram program,
  ) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer le programme',
      message:
          'Supprimer « ${program.title} » ? Les séances et exercices personnalisés seront définitivement perdus.',
      confirmLabel: 'Supprimer',
      variant: ConfirmationVariant.destructive,
    );
    if (!confirm) return;
    try {
      await ref.read(studentProgramServiceProvider).delete(program.id);
      ref.invalidate(studentProgramsProvider(studentId));
      if (!context.mounted) return;
      AppSnackbar.showSuccess(context, 'Programme supprimé');
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final choice = await showAddChoiceSheet(
      context,
      title: 'Ajouter une séance',
      emptyTitle: 'Nouvelle séance',
      emptySubtitle: 'Créer une séance vide à construire.',
      templateTitle: 'Copier un template',
      templateSubtitle: 'Copier une séance de la bibliothèque.',
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case AddChoice.empty:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                StudentSessionFormScreen(programId: programId),
          ),
        );
      case AddChoice.template:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                StudentSessionTemplatePickerScreen(programId: programId),
          ),
        );
    }
  }
}

class _ProgramBody extends ConsumerStatefulWidget {
  const _ProgramBody({
    required this.studentId,
    required this.detail,
  });

  final String studentId;
  final StudentProgramEditorDetail detail;

  @override
  ConsumerState<_ProgramBody> createState() => _ProgramBodyState();
}

class _ProgramBodyState extends ConsumerState<_ProgramBody> {
  late List<StudentSessionListItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.detail.sessions);
  }

  @override
  void didUpdateWidget(covariant _ProgramBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.sessions != widget.detail.sessions) {
      _items = List.of(widget.detail.sessions);
    }
  }

  Future<void> _deleteSession(StudentSession session) async {
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
      ref.invalidate(
        studentProgramEditorDetailProvider(widget.detail.program.id),
      );
      ref.invalidate(studentProgramsProvider(widget.studentId));
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Séance supprimée');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _duplicateSession(StudentSession session) async {
    try {
      await ref
          .read(studentProgramServiceProvider)
          .duplicateStudentSession(session.id);
      ref.invalidate(
        studentProgramEditorDetailProvider(widget.detail.program.id),
      );
      ref.invalidate(studentProgramsProvider(widget.studentId));
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Séance dupliquée');
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
      await ref.read(studentProgramServiceProvider).reorderSessions(
            programId: widget.detail.program.id,
            sessionIdsInOrder: _items.map((i) => i.session.id).toList(),
          );
      ref.invalidate(
        studentProgramEditorDetailProvider(widget.detail.program.id),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur lors du réordonnancement : $e');
      ref.invalidate(
        studentProgramEditorDetailProvider(widget.detail.program.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.detail.program;

    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Header(program: program),
          const SizedBox(height: AppSpacing.xl),
          const EmptyView(
            icon: LucideIcons.calendarClock,
            wrapIcon: true,
            message:
                'Aucune séance dans ce programme.\nAppuie sur « Ajouter » pour commencer.',
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
            _Header(program: program),
            const SizedBox(height: AppSpacing.xl),
            ContentSectionHeader(title: 'Séances', count: _items.length),
          ],
        ),
      ),
      itemCount: _items.length,
      onReorder: _onReorder,
      itemBuilder: (_, i) {
        final item = _items[i];
        final session = item.session;
        final hasDescription =
            session.description != null && session.description!.isNotEmpty;
        return Padding(
          key: ValueKey(session.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ReorderableLibraryRow(
            index: i,
            title: session.title,
            removeLabel: 'Supprimer',
            subtitleWidget: _SessionSubtitle(
              blockCount: item.blockCount,
              durationMinutes: session.durationMinutes,
              dayOfWeek: DayOfWeek.fromStorage(session.dayOfWeek),
              description: hasDescription ? session.description : null,
            ),
            onTap: () => Navigator.of(context).push(
              StudentSessionEditorScreen.route(
                studentId: widget.studentId,
                programId: widget.detail.program.id,
                programTitle: program.title,
                sessionId: session.id,
              ),
            ),
            onDuplicate: () => _duplicateSession(session),
            onRemove: () => _deleteSession(session),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.program});
  final StudentProgram program;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription =
        program.description != null && program.description!.isNotEmpty;
    return DetailInfoCard(
      children: [
        DetailField(
          label: 'Titre',
          child: Text(program.title, style: theme.textTheme.bodyLarge),
        ),
        DetailField(
          label: 'Description',
          child: hasDescription
              ? Text(
                  program.description!,
                  style: theme.textTheme.bodyLarge,
                )
              : null,
        ),
      ],
    );
  }
}

class _SessionSubtitle extends StatelessWidget {
  const _SessionSubtitle({
    required this.blockCount,
    required this.durationMinutes,
    required this.dayOfWeek,
    required this.description,
  });

  final int blockCount;
  final int? durationMinutes;
  final DayOfWeek? dayOfWeek;
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
        SessionMetaRow(
          dayOfWeek: dayOfWeek,
          blockCount: blockCount,
          durationMinutes: durationMinutes,
        ),
      ],
    );
  }
}
