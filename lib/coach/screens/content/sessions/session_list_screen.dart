import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/session.dart' as models;
import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/session_providers.dart';
import '../../../widgets/library_list_tile.dart';
import '../../../widgets/library_search_field.dart';
import '../../../widgets/library_type_icon.dart';
import '../../../widgets/session_meta_row.dart';
import 'session_detail_screen.dart';
import 'session_form_screen.dart';

class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen> {
  String _query = '';

  List<SessionListItem> _filter(List<SessionListItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((it) => it.session.title.toLowerCase().contains(q))
        .toList();
  }

  void _openForm({models.Session? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionFormScreen(existing: existing),
      ),
    );
  }

  void _openDetail(models.Session session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(sessionId: session.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachSessionsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Nouvelle séance',
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        children: [
          LibrarySearchField(
            hintText: 'Rechercher une séance',
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: 'Impossible de charger les séances.\n$e',
                onRetry: () => ref.invalidate(coachSessionsProvider),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return EmptyView(
                    icon: LucideIcons.calendarClock,
                    wrapIcon: true,
                    message:
                        'Aucune séance template.\nCrée ta première séance réutilisable.',
                    action: FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Nouvelle séance'),
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
                      ref.invalidate(coachSessionsProvider),
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
                      final it = filtered[i];
                      final s = it.session;
                      final hasDescription =
                          s.description != null && s.description!.isNotEmpty;
                      return LibraryListTile(
                        title: s.title,
                        subtitleWidget: _SessionTileSubtitle(
                          blockCount: it.blockCount,
                          durationMinutes: s.durationMinutes,
                          description: hasDescription ? s.description : null,
                        ),
                        leading: const LibraryTypeIcon(
                          icon: LucideIcons.calendarClock,
                        ),
                        onTap: () => _openDetail(s),
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

class _SessionTileSubtitle extends StatelessWidget {
  const _SessionTileSubtitle({
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
        if (description != null) ...[
          Text(
            description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        SessionMetaRow(
          blockCount: blockCount,
          durationMinutes: durationMinutes,
        ),
      ],
    );
  }
}
