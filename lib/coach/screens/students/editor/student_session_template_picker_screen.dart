import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/session_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/session_providers.dart';
import '../../../providers/student_program_providers.dart';
import '../../../widgets/library_search_field.dart';
import '../../../widgets/library_selectable_tile.dart';
import '../../../widgets/library_type_icon.dart';
import '../../../widgets/session_meta_row.dart';

/// Sélection multiple de séances templates à dupliquer dans un programme élève.
///
/// Chaque séance choisie est copiée en profondeur (séance → blocs →
/// exercices) via la RPC `duplicate_session_template_for_student`.
class StudentSessionTemplatePickerScreen extends ConsumerStatefulWidget {
  const StudentSessionTemplatePickerScreen({
    super.key,
    required this.programId,
  });

  final String programId;

  @override
  ConsumerState<StudentSessionTemplatePickerScreen> createState() =>
      _StudentSessionTemplatePickerScreenState();
}

class _StudentSessionTemplatePickerScreenState
    extends ConsumerState<StudentSessionTemplatePickerScreen> {
  final Set<String> _selected = {};
  String _query = '';
  bool _saving = false;

  List<SessionListItem> _filter(List<SessionListItem> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((it) => it.session.title.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _add() async {
    if (_saving || _selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(studentProgramServiceProvider);
      for (final id in _selected) {
        await service.duplicateSessionFromTemplate(
          studentProgramId: widget.programId,
          sourceSessionId: id,
        );
      }
      ref.invalidate(studentProgramEditorDetailProvider(widget.programId));
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Séances ajoutées');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachSessionsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des séances'),
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
                  return const EmptyView(
                    icon: LucideIcons.calendarClock,
                    wrapIcon: true,
                    message:
                        'Aucune séance template.\nCrée d\'abord une séance dans la bibliothèque.',
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
                    final s = it.session;
                    final checked = _selected.contains(s.id);
                    final hasDescription = s.description != null &&
                        s.description!.isNotEmpty;
                    return LibrarySelectableTile(
                      title: s.title,
                      leading: const LibraryTypeIcon(
                        icon: LucideIcons.calendarClock,
                      ),
                      subtitleWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasDescription)
                            Text(
                              s.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SessionMetaRow(
                            blockCount: it.blockCount,
                            durationMinutes: s.durationMinutes,
                          ),
                        ],
                      ),
                      checked: checked,
                      onTap: () => setState(() {
                        if (checked) {
                          _selected.remove(s.id);
                        } else {
                          _selected.add(s.id);
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
