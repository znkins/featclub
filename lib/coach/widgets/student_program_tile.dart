import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/student_program.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'library_type_icon.dart';

/// Tuile d'un programme élève : icône + infos + switch actif + menu actions.
class StudentProgramTile extends StatelessWidget {
  const StudentProgramTile({
    super.key,
    required this.program,
    required this.sessionCount,
    this.onTap,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
    this.busy = false,
  });

  final StudentProgram program;
  final int sessionCount;
  final VoidCallback? onTap;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription =
        program.description != null && program.description!.trim().isNotEmpty;
    final active = program.isActive;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const LibraryTypeIcon(icon: LucideIcons.scrollText),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      program.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasDescription)
                      Text(
                        program.description!,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '$sessionCount séance${sessionCount > 1 ? 's' : ''}',
                      style: muted,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<_TileAction>(
                    tooltip: 'Plus d\'actions',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      LucideIcons.moreVertical,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    onSelected: (a) {
                      switch (a) {
                        case _TileAction.edit:
                          onEdit();
                        case _TileAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _TileAction.edit,
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.pencil,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _TileAction.delete,
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: active,
                      onChanged: busy ? null : onToggleActive,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TileAction { edit, delete }
