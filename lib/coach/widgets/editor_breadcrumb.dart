import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_spacing.dart';
import '../providers/student_providers.dart';

/// Segment d'un fil d'Ariane : libellé à afficher + nom de route à remonter.
///
/// `routeName` doit correspondre au `RouteSettings.name` de la route cible ;
/// le breadcrumb utilise `Navigator.popUntil` pour y remonter.
class EditorCrumb {
  const EditorCrumb({required this.label, required this.routeName});

  final String label;
  final String routeName;
}

/// Fil d'Ariane pour les écrans de l'éditeur de programme élève.
///
/// Affiche les segments parents cliquables + le segment courant en gras.
/// Un tap sur un segment remonte via `popUntil` jusqu'à la route nommée.
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
                onTap: () => Navigator.of(context).popUntil(
                  (r) => r.settings.name == crumb.routeName,
                ),
                borderRadius: BorderRadius.circular(6),
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

/// Noms de routes des écrans de l'éditeur (utilisés par le breadcrumb pour
/// remonter via `popUntil`).
class EditorRoutes {
  const EditorRoutes._();
  static const studentDetail = '/coach/student/detail';
  static const program = '/coach/student/editor/program';
  static const session = '/coach/student/editor/session';
  static const block = '/coach/student/editor/block';
  static const exercise = '/coach/student/editor/exercise';
}

/// Résout le nom de l'élève via le provider partagé (cache Riverpod → lookup
/// gratuit si la fiche élève a déjà été visitée, ce qui est le cas standard
/// d'entrée dans l'éditeur).
///
/// Utilisé par chaque écran de l'éditeur pour construire le crumb racine
/// sans avoir à threader le nom dans tous les constructeurs.
String resolveStudentName(WidgetRef ref, String studentId) {
  final profile = ref.watch(studentByIdProvider(studentId)).valueOrNull;
  final name = profile?.fullName.trim() ?? '';
  return name.isEmpty ? 'Fiche Feater' : name;
}
