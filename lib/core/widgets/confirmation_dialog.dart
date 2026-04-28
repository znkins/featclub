import 'package:flutter/material.dart';

/// Variante visuelle du bouton de confirmation.
/// - [standard]    : action neutre (déconnexion, duplication) → primaire teal.
/// - [warning]     : retrait réversible (cohérent avec l'icône orange) → orange.
/// - [destructive] : suppression définitive avec cascade → rouge erreur.
enum ConfirmationVariant { standard, warning, destructive }

/// Dialogue de confirmation standard.
/// `show` renvoie `true` si l'utilisateur confirme, `false` sinon.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmer',
    this.cancelLabel = 'Annuler',
    this.variant = ConfirmationVariant.standard,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final ConfirmationVariant variant;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    ConfirmationVariant variant = ConfirmationVariant.standard,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        variant: variant,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = switch (variant) {
      ConfirmationVariant.standard => null,
      ConfirmationVariant.warning => theme.colorScheme.secondary,
      ConfirmationVariant.destructive => theme.colorScheme.error,
    };
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: background != null
              ? FilledButton.styleFrom(backgroundColor: background)
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
