import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/providers/data_providers.dart';
import '../../theme/app_spacing.dart';

/// Bottom sheet de complétion de séance : commentaire facultatif puis insert
/// dans `completed_sessions`.
///
/// Renvoie `true` si la complétion a été enregistrée, `false`/`null` si
/// l'utilisateur a annulé. Le titre est snapshot (l'historique reste lisible
/// même si la séance source est supprimée) et la séance n'est pas désactivée
/// (elle reste disponible pour être refaite).
Future<bool?> showCompleteSessionSheet(
  BuildContext context, {
  required String studentSessionId,
  required String sessionTitle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _CompleteSessionSheet(
        studentSessionId: studentSessionId,
        sessionTitle: sessionTitle,
      ),
    ),
  );
}

class _CompleteSessionSheet extends ConsumerStatefulWidget {
  const _CompleteSessionSheet({
    required this.studentSessionId,
    required this.sessionTitle,
  });

  final String studentSessionId;
  final String sessionTitle;

  @override
  ConsumerState<_CompleteSessionSheet> createState() =>
      _CompleteSessionSheetState();
}

class _CompleteSessionSheetState
    extends ConsumerState<_CompleteSessionSheet> {
  final _commentController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) {
      AppSnackbar.showError(context, 'Session expirée, reconnecte-toi.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(completedSessionServiceProvider).create(
            studentId: profile.id,
            studentSessionId: widget.studentSessionId,
            sessionTitle: widget.sessionTitle,
            comment: _commentController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.checkCircle2,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Terminer la séance',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.sessionTitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Un mot pour ton coach ?',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _commentController,
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Facultatif — sensations, difficultés, ressenti...',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
