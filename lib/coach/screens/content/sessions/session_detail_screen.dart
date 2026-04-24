import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/session.dart' as models;
import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../shared/providers/route_observer_provider.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/session_providers.dart';
import '../../../widgets/content_section_header.dart';
import '../../../widgets/detail_field.dart';
import '../../../widgets/detail_info_card.dart';
import '../../../widgets/duration_pill.dart';
import '../../../widgets/reorderable_library_row.dart';
import '../blocks/block_detail_screen.dart';
import 'session_block_picker_screen.dart';
import 'session_form_screen.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen>
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
    ref.invalidate(sessionDetailProvider(widget.sessionId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sessionDetailProvider(widget.sessionId));
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
                  onPressed: () => _edit(detail.session),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () => _delete(detail.session),
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
          message: 'Impossible de charger la séance.\n$e',
          onRetry: () =>
              ref.invalidate(sessionDetailProvider(widget.sessionId)),
        ),
        data: (detail) => _SessionBody(detail: detail),
      ),
    );
  }

  Future<void> _edit(models.Session session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionFormScreen(existing: session),
      ),
    );
  }

  Future<void> _delete(models.Session session) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer la séance',
      message:
          'Supprimer « ${session.title} » ? Les blocs restent dans ta bibliothèque.',
      confirmLabel: 'Supprimer',
      variant: ConfirmationVariant.destructive,
    );
    if (!confirm) return;
    try {
      await ref.read(sessionServiceProvider).delete(session.id);
      ref.invalidate(coachSessionsProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Séance supprimée');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _openPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionBlockPickerScreen(sessionId: widget.sessionId),
      ),
    );
  }
}

class _SessionBody extends ConsumerStatefulWidget {
  const _SessionBody({required this.detail});

  final SessionDetail detail;

  @override
  ConsumerState<_SessionBody> createState() => _SessionBodyState();
}

class _SessionBodyState extends ConsumerState<_SessionBody> {
  late List<SessionBlockLink> _links;

  @override
  void initState() {
    super.initState();
    _links = List.of(widget.detail.links);
  }

  @override
  void didUpdateWidget(covariant _SessionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.links != widget.detail.links) {
      _links = List.of(widget.detail.links);
    }
  }

  Future<void> _remove(SessionBlockLink link) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Retirer le bloc',
      message:
          'Retirer « ${link.block.title} » de la séance ? Il reste dans ta bibliothèque.',
      confirmLabel: 'Retirer',
      variant: ConfirmationVariant.warning,
    );
    if (!confirm) return;
    try {
      await ref.read(sessionServiceProvider).removeLink(link.linkId);
      ref.invalidate(sessionDetailProvider(widget.detail.session.id));
      ref.invalidate(coachSessionsProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Bloc retiré');
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
      await ref.read(sessionServiceProvider).reorderLinks(
            sessionId: widget.detail.session.id,
            linkIdsInOrder: _links.map((l) => l.linkId).toList(),
          );
      ref.invalidate(sessionDetailProvider(widget.detail.session.id));
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur lors du réordonnancement : $e');
      ref.invalidate(sessionDetailProvider(widget.detail.session.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.detail.session;

    if (_links.isEmpty) {
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
            ContentSectionHeader(title: 'Blocs', count: _links.length),
          ],
        ),
      ),
      itemCount: _links.length,
      onReorder: _onReorder,
      itemBuilder: (_, i) {
        final link = _links[i];
        final block = link.block;
        final hasDescription =
            block.description != null && block.description!.isNotEmpty;
        return Padding(
          key: ValueKey(link.linkId),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ReorderableLibraryRow(
            index: i,
            title: block.title,
            subtitleWidget: _SessionBlockSubtitle(
              exerciseCount: link.exerciseCount,
              description: hasDescription ? block.description : null,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlockDetailScreen(blockId: block.id),
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
  const _Header({required this.session});
  final models.Session session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription =
        session.description != null && session.description!.isNotEmpty;
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

class _SessionBlockSubtitle extends StatelessWidget {
  const _SessionBlockSubtitle({
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

