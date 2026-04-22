import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/profile.dart';
import '../../core/widgets/user_avatar.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Tuile de liste dédiée à un profil élève (Featers).
///
/// Spécifique au module élèves : avatar photo en leading avec un gap `lg`
/// (plus aéré que la tuile `LibraryListTile` conçue pour les icônes de la
/// bibliothèque de contenu).
class StudentListTile extends StatelessWidget {
  const StudentListTile({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final Profile profile;
  final VoidCallback onTap;

  String get _initials {
    final f = (profile.firstName ?? '').trim();
    final l = (profile.lastName ?? '').trim();
    final i1 = f.isNotEmpty ? f[0] : '';
    final i2 = l.isNotEmpty ? l[0] : '';
    return (i1 + i2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName =
        profile.fullName.isEmpty ? 'Profil incomplet' : profile.fullName;
    final note = (profile.bio ?? '').trim();

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: profile.avatarUrl,
                initials: _initials,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (note.isNotEmpty)
                      Text(
                        note,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
