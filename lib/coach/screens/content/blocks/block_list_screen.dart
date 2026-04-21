import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/block.dart';
import '../../../../core/services/block_service.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/block_providers.dart';
import '../../../widgets/library_list_tile.dart';
import '../../../widgets/library_search_field.dart';
import '../../../widgets/library_type_icon.dart';
import 'block_detail_screen.dart';
import 'block_form_screen.dart';

class BlockListScreen extends ConsumerStatefulWidget {
  const BlockListScreen({super.key});

  @override
  ConsumerState<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends ConsumerState<BlockListScreen> {
  String _query = '';

  List<BlockListItem> _filter(List<BlockListItem> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((it) => it.block.title.toLowerCase().contains(q))
        .toList();
  }

  void _openForm({Block? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlockFormScreen(existing: existing),
      ),
    );
  }

  void _openDetail(Block block) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlockDetailScreen(blockId: block.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachBlocksProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Nouveau bloc',
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        children: [
          LibrarySearchField(
            hintText: 'Rechercher un bloc',
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: 'Impossible de charger les blocs.\n$e',
                onRetry: () => ref.invalidate(coachBlocksProvider),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return EmptyView(
                    icon: LucideIcons.layers,
                    wrapIcon: true,
                    message:
                        'Aucun bloc.\nCrée ton premier bloc réutilisable.',
                    action: FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Nouveau bloc'),
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
                      ref.invalidate(coachBlocksProvider),
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
                      final count = it.exerciseCount;
                      final subtitle =
                          '$count exercice${count > 1 ? 's' : ''}';
                      return LibraryListTile(
                        title: it.block.title,
                        subtitle: subtitle,
                        leading: const LibraryTypeIcon(
                          icon: LucideIcons.layers,
                        ),
                        onTap: () => _openDetail(it.block),
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
