import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/program.dart';
import '../../../../core/services/program_service.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/program_providers.dart';
import '../../../widgets/library_list_tile.dart';
import '../../../widgets/library_search_field.dart';
import '../../../widgets/library_type_icon.dart';
import 'program_detail_screen.dart';
import 'program_form_screen.dart';

class ProgramListScreen extends ConsumerStatefulWidget {
  const ProgramListScreen({super.key});

  @override
  ConsumerState<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends ConsumerState<ProgramListScreen> {
  String _query = '';

  List<ProgramListItem> _filter(List<ProgramListItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((it) => it.program.title.toLowerCase().contains(q))
        .toList();
  }

  void _openForm({Program? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramFormScreen(existing: existing),
      ),
    );
  }

  void _openDetail(Program program) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(programId: program.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachProgramsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Nouveau programme',
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        children: [
          LibrarySearchField(
            hintText: 'Rechercher un programme',
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: 'Impossible de charger les programmes.\n$e',
                onRetry: () => ref.invalidate(coachProgramsProvider),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return EmptyView(
                    icon: LucideIcons.scrollText,
                    wrapIcon: true,
                    message:
                        'Aucun programme template.\nConstruis ton premier programme.',
                    action: FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Nouveau programme'),
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
                      ref.invalidate(coachProgramsProvider),
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
                      final p = it.program;
                      final count = it.sessionCount;
                      final hasDescription =
                          p.description != null && p.description!.isNotEmpty;
                      return LibraryListTile(
                        title: p.title,
                        subtitleWidget: _ProgramTileSubtitle(
                          sessionCount: count,
                          description: hasDescription ? p.description : null,
                        ),
                        leading: const LibraryTypeIcon(
                          icon: LucideIcons.scrollText,
                        ),
                        onTap: () => _openDetail(p),
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

class _ProgramTileSubtitle extends StatelessWidget {
  const _ProgramTileSubtitle({
    required this.sessionCount,
    required this.description,
  });

  final int sessionCount;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (description != null)
          Text(
            description!,
            style: muted,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        Text(
          '$sessionCount séance${sessionCount > 1 ? 's' : ''}',
          style: muted,
        ),
      ],
    );
  }
}
