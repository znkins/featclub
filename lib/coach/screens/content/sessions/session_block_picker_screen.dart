import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/block_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/block_providers.dart';
import '../../../providers/session_providers.dart';
import '../../../widgets/library_search_field.dart';
import '../../../widgets/library_selectable_tile.dart';
import '../../../widgets/library_type_icon.dart';

/// Sélection multiple de blocs à ajouter à une séance.
///
/// La liste affiche tous les blocs de la bibliothèque : un bloc déjà présent
/// dans la séance peut être ajouté à nouveau (duplicat).
class SessionBlockPickerScreen extends ConsumerStatefulWidget {
  const SessionBlockPickerScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionBlockPickerScreen> createState() =>
      _SessionBlockPickerScreenState();
}

class _SessionBlockPickerScreenState
    extends ConsumerState<SessionBlockPickerScreen> {
  final Set<String> _selected = {};
  String _query = '';
  bool _saving = false;

  List<BlockListItem> _filter(List<BlockListItem> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((it) => it.block.title.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _add() async {
    if (_saving || _selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(sessionServiceProvider);
      for (final id in _selected) {
        await service.addBlock(sessionId: widget.sessionId, blockId: id);
      }
      ref.invalidate(sessionDetailProvider(widget.sessionId));
      ref.invalidate(coachSessionsProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Ajouté à la séance');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachBlocksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des blocs'),
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
                  return const EmptyView(
                    icon: LucideIcons.layers,
                    wrapIcon: true,
                    message:
                        'Aucun bloc disponible.\nCrée d\'abord des blocs dans la bibliothèque.',
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
                    final it = filtered[i];
                    final b = it.block;
                    final checked = _selected.contains(b.id);
                    final count = it.exerciseCount;
                    final theme = Theme.of(context);
                    return LibrarySelectableTile(
                      title: b.title,
                      leading: const LibraryTypeIcon(
                        icon: LucideIcons.layers,
                      ),
                      subtitleWidget: Text(
                        '$count exercice${count > 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      checked: checked,
                      onTap: () => setState(() {
                        if (checked) {
                          _selected.remove(b.id);
                        } else {
                          _selected.add(b.id);
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
