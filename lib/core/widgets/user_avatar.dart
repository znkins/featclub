import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Avatar circulaire : image si `avatarUrl` présent, sinon initiales,
/// sinon icône utilisateur neutre. Taille paramétrable (48 par défaut).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.size = 48,
  });

  final String? avatarUrl;
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        image: hasUrl
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasUrl
          ? null
          : (initials.isNotEmpty
              ? Text(
                  initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.38,
                  ),
                )
              : Icon(
                  LucideIcons.user,
                  size: size * 0.45,
                  color: theme.colorScheme.primary,
                )),
    );
  }
}
