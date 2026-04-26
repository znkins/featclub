import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/providers/student_data_providers.dart';
import '../providers/student_session_providers.dart';
import '../providers/student_shell_providers.dart';

/// Modale de complétion de séance : commentaire facultatif puis insert dans
/// `completed_sessions`.
///
/// Renvoie `true` si la complétion a été enregistrée, `false`/`null` si
/// l'utilisateur a annulé. Le titre est snapshot (l'historique reste lisible
/// même si la séance source est supprimée) et la séance n'est pas désactivée
/// (elle reste disponible pour être refaite).
Future<bool?> showCompleteSessionDialog(
  BuildContext context, {
  required String studentSessionId,
  required String sessionTitle,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _CompleteSessionDialog(
      studentSessionId: studentSessionId,
      sessionTitle: sessionTitle,
    ),
  );
}

/// À appeler dans la branche succès qui suit [showCompleteSessionDialog].
///
/// Centralise la logique post-complétion identique aux deux points
/// d'entrée (écran détail + écran exécution) : invalide les providers
/// d'historique/compteur/programme actif, bascule sur l'onglet « Mon
/// programme », affiche le snackbar de succès et pop tous les écrans
/// empilés au-dessus du shell.
void afterSessionCompletion(BuildContext context, WidgetRef ref) {
  final profile = ref.read(currentProfileProvider).valueOrNull;
  if (profile != null) {
    ref.invalidate(studentRecentHistoryProvider(profile.id));
    ref.invalidate(studentHistoryProvider(profile.id));
    ref.invalidate(studentCompletedSessionCountProvider(profile.id));
  }
  // La séance fraîchement complétée doit être recalculée par le provider
  // d'« active program » (pour que la prochaine séance soit à jour sur
  // l'accueil et la liste programme).
  ref.invalidate(studentActiveProgramProvider);
  ref.read(studentActiveTabProvider.notifier).state = 1;
  AppSnackbar.showSuccess(context, 'Séance enregistrée');
  Navigator.of(context).popUntil((route) => route.isFirst);
}

class _CompleteSessionDialog extends ConsumerStatefulWidget {
  const _CompleteSessionDialog({
    required this.studentSessionId,
    required this.sessionTitle,
  });

  final String studentSessionId;
  final String sessionTitle;

  @override
  ConsumerState<_CompleteSessionDialog> createState() =>
      _CompleteSessionDialogState();
}

class _CompleteSessionDialogState
    extends ConsumerState<_CompleteSessionDialog> {
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
    return AlertDialog(
      title: const Text('Un mot pour ton coach ?'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      content: TextField(
        controller: _commentController,
        minLines: 3,
        maxLines: 4,
        textInputAction: TextInputAction.newline,
        decoration: const InputDecoration(
          hintText: 'Remarques, difficultés, ressenti...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
          ),
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
              : const Text('Terminer'),
        ),
      ],
    );
  }
}
