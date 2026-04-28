import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_providers.dart';

/// Segment d'un fil d'Ariane.
/// Cible :
/// - `routeName` → le breadcrumb fait `popUntil` sur cette route nommée ;
/// - `onTap` → callback custom (ex. revenir au shell racine).
/// Au moins l'un des deux doit être fourni.
class EditorCrumb {
  const EditorCrumb({
    required this.label,
    this.routeName,
    this.onTap,
  }) : assert(routeName != null || onTap != null,
            'Fournir routeName ou onTap');

  final String label;
  final String? routeName;
  final VoidCallback? onTap;
}

/// Fil d'Ariane des écrans de l'éditeur de programme élève.
/// Segments parents cliquables + segment courant en gras.
class EditorBreadcrumb extends StatelessWidget implements PreferredSizeWidget {
  const EditorBreadcrumb({
    super.key,
    required this.parents,
    required this.current,
  });

  final List<EditorCrumb> parents;
  final String current;

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium;
    final primary = theme.colorScheme.primary;
    return Container(
      height: preferredSize.height,
      color: primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final crumb in parents) ...[
              InkWell(
                onTap: crumb.onTap ??
                    () => Navigator.of(context).popUntil(
                          (r) => r.settings.name == crumb.routeName,
                        ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    crumb.label,
                    style: base?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            Text(
              current,
              style: base?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Noms des routes des écrans de l'éditeur élève (utilisés par le
/// breadcrumb pour remonter via `popUntil`).
class EditorRoutes {
  const EditorRoutes._();
  static const studentDetail = '/coach/student/detail';
  static const program = '/coach/student/editor/program';
  static const session = '/coach/student/editor/session';
  static const block = '/coach/student/editor/block';
  static const exercise = '/coach/student/editor/exercise';
}

/// Noms des routes des écrans de la bibliothèque (pour breadcrumb sur le
/// flow de consultation détail).
class LibraryRoutes {
  const LibraryRoutes._();
  static const program = '/coach/library/program';
  static const session = '/coach/library/session';
  static const block = '/coach/library/block';
  static const exercise = '/coach/library/exercise';
}

/// Récupère le nom d'un élève via le provider partagé (cache Riverpod).
/// Utilisé par les écrans de l'éditeur pour construire le crumb racine
/// sans threader le nom dans tous les constructeurs.
String resolveStudentName(WidgetRef ref, String studentId) {
  final profile = ref.watch(studentByIdProvider(studentId)).valueOrNull;
  final name = profile?.fullName.trim() ?? '';
  return name.isEmpty ? 'Fiche Feater' : name;
}
