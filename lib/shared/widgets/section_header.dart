import 'package:flutter/material.dart';

/// Entête de section : titre H1 + action optionnelle à droite
/// (typiquement un `TextButton.icon` « + Ajouter »).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(title, style: theme.textTheme.headlineSmall),
        ),
        ?action,
      ],
    );
  }
}
