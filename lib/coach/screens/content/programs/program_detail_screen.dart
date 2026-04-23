import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/program.dart';
import '../../../../core/services/program_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../shared/providers/route_observer_provider.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/program_providers.dart';
import '../../../widgets/detail_field.dart';
import '../../../widgets/reorderable_library_row.dart';
import '../../../widgets/session_meta_row.dart';
import '../sessions/session_detail_screen.dart';
import 'program_form_screen.dart';
import 'program_session_picker_screen.dart';

class ProgramDetailScreen extends ConsumerStatefulWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final String programId;

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen>
    with RouteAware {
  RouteObserver<ModalRoute<void>>? _observer;
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = ref.read(appRouteObserverProvider);
    final route = ModalRoute.of(context);
    if (route != null && (observer != _observer || route != _route)) {
      _observer?.unsubscribe(this);
      observer.subscribe(this, route);
      _observer = observer;
      _route = route;
    }
  }

  @override
  void dispose() {
    _observer?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    ref.invalidate(programDetailProvider(widget.programId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(programDetailProvider(widget.programId));
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
                  onPressed: () => _edit(detail.program),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () => _delete(detail.program),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: async.maybeWhen(
        data: (_) => FloatingActionButton.extended(
          onPressed: _openPicker,
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
              ref.invalidate(programDetailProvider(widget.programId)),
        ),
        data: (detail) => _ProgramBody(detail: detail),
      ),
    );
  }

  Future<void> _edit(Program program) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramFormScreen(existing: program),
      ),
    );
  }

  Future<void> _delete(Program program) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer le programme',
      message:
          'Supprimer « ${program.title} » ? Les séances restent dans ta bibliothèque.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!confirm) return;
    try {
      await ref.read(programServiceProvider).delete(program.id);
      ref.invalidate(coachProgramsProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Programme supprimé');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _openPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProgramSessionPickerScreen(programId: widget.programId),
      ),
    );
  }
}

class _ProgramBody extends ConsumerStatefulWidget {
  const _ProgramBody({required this.detail});

  final ProgramDetail detail;

  @override
  ConsumerState<_ProgramBody> createState() => _ProgramBodyState();
}

class _ProgramBodyState extends ConsumerState<_ProgramBody> {
  late List<ProgramSessionLink> _links;

  @override
  void initState() {
    super.initState();
    _links = List.of(widget.detail.links);
  }

  @override
  void didUpdateWidget(covariant _ProgramBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.links != widget.detail.links) {
      _links = List.of(widget.detail.links);
    }
  }

  Future<void> _remove(ProgramSessionLink link) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Retirer la séance',
      message:
          'Retirer « ${link.session.title} » du programme ? Elle reste dans ta bibliothèque.',
      confirmLabel: 'Retirer',
    );
    if (!confirm) return;
    try {
      await ref.read(programServiceProvider).removeLink(link.linkId);
      ref.invalidate(programDetailProvider(widget.detail.program.id));
      ref.invalidate(coachProgramsProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Séance retirée');
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
      await ref.read(programServiceProvider).reorderLinks(
            programId: widget.detail.program.id,
            linkIdsInOrder: _links.map((l) => l.linkId).toList(),
          );
      ref.invalidate(programDetailProvider(widget.detail.program.id));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur lors du réordonnancement : $e');
      ref.invalidate(programDetailProvider(widget.detail.program.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final program = widget.detail.program;

    if (_links.isEmpty) {
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
            Text(
              '${_links.length} séance${_links.length > 1 ? 's' : ''}',
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
        final session = link.session;
        final hasDescription =
            session.description != null && session.description!.isNotEmpty;
        return Padding(
          key: ValueKey(link.linkId),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ReorderableLibraryRow(
            index: i,
            title: session.title,
            subtitleWidget: _ProgramSessionSubtitle(
              blockCount: link.blockCount,
              durationMinutes: session.durationMinutes,
              description: hasDescription ? session.description : null,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SessionDetailScreen(sessionId: session.id),
              ),
            ),
            onRemove: () => _remove(link),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.program});
  final Program program;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription =
        program.description != null && program.description!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailField(
          label: 'Titre',
          child: Text(program.title, style: theme.textTheme.bodyLarge),
        ),
        const SizedBox(height: AppSpacing.xl),
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

class _ProgramSessionSubtitle extends StatelessWidget {
  const _ProgramSessionSubtitle({
    required this.blockCount,
    required this.durationMinutes,
    required this.description,
  });

  final int blockCount;
  final int? durationMinutes;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (description != null)
          Text(
            description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        SessionMetaRow(
          blockCount: blockCount,
          durationMinutes: durationMinutes,
        ),
      ],
    );
  }
}
