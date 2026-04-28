import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/services/program_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../theme/app_spacing.dart';
import '../../providers/program_providers.dart';
import '../../providers/student_program_providers.dart';
import '../../widgets/library_list_tile.dart';
import '../../widgets/library_search_field.dart';
import '../../widgets/library_type_icon.dart';

/// Choix d'un programme template à dupliquer pour un élève (sélection simple).
///
/// Sur tap d'une tuile : confirmation puis appel de la RPC
/// `duplicate_program_template_for_student`.
class StudentProgramTemplatePickerScreen extends ConsumerStatefulWidget {
  const StudentProgramTemplatePickerScreen({
    super.key,
    required this.studentId,
  });

  final String studentId;

  @override
  ConsumerState<StudentProgramTemplatePickerScreen> createState() =>
      _StudentProgramTemplatePickerScreenState();
}

class _StudentProgramTemplatePickerScreenState
    extends ConsumerState<StudentProgramTemplatePickerScreen> {
  String _query = '';
  bool _busy = false;

  List<ProgramListItem> _filter(List<ProgramListItem> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((it) => it.program.title.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _pick(ProgramListItem item) async {
    if (_busy) return;
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Dupliquer ce programme',
      message:
          'Dupliquer « ${item.program.title} » pour cet élève ? Les séances et blocs seront copiés et modifiables indépendamment du template.',
      confirmLabel: 'Dupliquer',
    );
    if (!confirm) return;
    setState(() => _busy = true);
    try {
      await ref.read(studentProgramServiceProvider).duplicateFromTemplate(
            studentId: widget.studentId,
            sourceProgramId: item.program.id,
          );
      ref.invalidate(studentProgramsProvider(widget.studentId));
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Programme ajouté');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachProgramsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un programme')),
      body: Stack(
        children: [
          Column(
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
                      return const EmptyView(
                        icon: LucideIcons.scrollText,
                        wrapIcon: true,
                        message:
                            'Aucun programme template.\nCrée d\'abord un programme dans la bibliothèque.',
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
                        final p = it.program;
                        final count = it.sessionCount;
                        return LibraryListTile(
                          title: p.title,
                          subtitle:
                              '$count séance${count > 1 ? 's' : ''}',
                          leading: const LibraryTypeIcon(
                            icon: LucideIcons.scrollText,
                          ),
                          onTap: () => _pick(it),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_busy)
            ColoredBox(
              color: Theme.of(context).colorScheme.scrim,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
