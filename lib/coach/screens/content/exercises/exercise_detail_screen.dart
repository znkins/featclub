import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/exercise.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/exercise_providers.dart';
import '../../../widgets/category_chip.dart';
import '../../../widgets/detail_field.dart';
import 'exercise_form_screen.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  Future<void> _openVideo(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppSnackbar.showError(context, 'URL invalide');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnackbar.showError(context, 'Impossible d\'ouvrir la vidéo');
    }
  }

  Future<void> _edit(BuildContext context, Exercise exercise) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseFormScreen(existing: exercise),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer l\'exercice',
      message:
          'Supprimer « ${exercise.title} » ? Il sera retiré de ta bibliothèque.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!confirm) return;
    try {
      await ref.read(exerciseServiceProvider).delete(exercise.id);
      ref.invalidate(coachExercisesProvider);
      if (!context.mounted) return;
      AppSnackbar.showSuccess(context, 'Exercice supprimé');
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(exerciseByIdProvider(exerciseId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.valueOrNull?.title ?? 'Exercice',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          async.maybeWhen(
            data: (exercise) => Row(
              children: [
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(LucideIcons.pencil),
                  onPressed: () => _edit(context, exercise),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(LucideIcons.trash2),
                  onPressed: () => _delete(context, ref, exercise),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger l\'exercice.\n$e',
          onRetry: () => ref.invalidate(exerciseByIdProvider(exerciseId)),
        ),
        data: (exercise) => _buildContent(context, exercise),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Exercise exercise) {
    final theme = Theme.of(context);
    final hasCategory =
        exercise.category != null && exercise.category!.isNotEmpty;
    final hasDescription =
        exercise.description != null && exercise.description!.isNotEmpty;
    final hasVideo =
        exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        DetailField(
          label: 'Titre',
          child: Text(exercise.title, style: theme.textTheme.bodyLarge),
        ),
        const SizedBox(height: AppSpacing.xl),
        DetailField(
          label: 'Catégorie',
          child: hasCategory
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: CategoryChip(label: exercise.category!),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        DetailField(
          label: 'Description',
          child: hasDescription
              ? Text(
                  exercise.description!,
                  style: theme.textTheme.bodyLarge,
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        DetailField(
          label: 'Vidéo',
          child: hasVideo
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _openVideo(context, exercise.videoUrl!),
                    icon: const Icon(LucideIcons.playCircle,
                        color: Colors.white),
                    label: const Text('Lire la vidéo'),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
