import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../coach/widgets/duration_pill.dart';
import '../../core/models/student_session_exercise.dart';
import '../../core/services/student_program_service.dart';
import '../../core/utils/video_launcher.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/widgets/exercise_note_row.dart';
import '../../shared/widgets/exercise_params_row.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_session_providers.dart';
import '../widgets/assigned_date_pill.dart';
import '../widgets/block_count_pill.dart';
import '../widgets/complete_session_dialog.dart';
import 'student_session_execution_screen.dart';

/// Détail d'une séance élève : méta + blocs + exercices, avec boutons
/// Démarrer (mode d'exécution) et Terminer (complétion directe).
class StudentSessionDetailScreen extends ConsumerWidget {
  const StudentSessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentSessionContentProvider(sessionId));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.valueOrNull?.session.title ?? 'Séance',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger la séance.\n$e',
          onRetry: () =>
              ref.invalidate(studentSessionContentProvider(sessionId)),
        ),
        data: (content) => _Body(content: content),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (content) => _SessionActionsBar(content: content),
        orElse: () => null,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.content});

  final StudentSessionContent content;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        _SessionHeader(content: content),
        const SizedBox(height: AppSpacing.xl),
        if (content.blocks.isEmpty)
          _EmptyBlocks()
        else
          for (var i = 0; i < content.blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            _BlockCard(
              index: i,
              total: content.blocks.length,
              blockContent: content.blocks[i],
            ),
          ],
      ],
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.content});

  final StudentSessionContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = content.session;
    final description = (session.description ?? '').trim();
    final hasDate = content.nextOccurrence != null;
    final hasDuration = session.durationMinutes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty) ...[
          Text(description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            if (hasDate) AssignedDatePill(date: content.nextOccurrence!),
            if (hasDuration) DurationPill(minutes: session.durationMinutes!),
            BlockCountPill(count: content.blocks.length),
          ],
        ),
      ],
    );
  }
}

class _EmptyBlocks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.layers,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Aucun contenu pour cette séance.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.index,
    required this.total,
    required this.blockContent,
  });

  final int index;
  final int total;
  final StudentSessionBlockContent blockContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = blockContent.block;
    final description = (block.description ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.fullAll,
                ),
                child: Text(
                  'Bloc ${index + 1}/$total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  block.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(description, style: theme.textTheme.bodyMedium),
          ],
          // Si le bloc est vide, on n'affiche aucun message : c'est une
          // anomalie côté coach que l'élève ne peut pas résoudre.
          if (blockContent.exercises.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < blockContent.exercises.length; i++) ...[
              if (i > 0)
                Divider(
                  height: AppSpacing.xl,
                  color: theme.colorScheme.outline,
                ),
              _ExerciseRow(exercise: blockContent.exercises[i]),
            ],
          ],
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final StudentSessionExercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = (exercise.description ?? '').trim();
    final note = (exercise.note ?? '').trim();
    final video = (exercise.videoUrl ?? '').trim();

    final hasParams = ExerciseParamsRow.hasContent(exercise);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(exercise.title, style: theme.textTheme.titleSmall),
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (hasParams) ...[
          const SizedBox(height: AppSpacing.sm),
          ExerciseParamsRow(exercise: exercise),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ExerciseNoteRow(note: note),
        ],
        if (video.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => openVideoUrl(context, video),
              icon: const Icon(LucideIcons.playCircle, size: 18),
              label: const Text('Lire la vidéo'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Barre d'actions en bas : « Terminer » (secondaire) + « Démarrer » (CTA).
class _SessionActionsBar extends ConsumerWidget {
  const _SessionActionsBar({required this.content});

  final StudentSessionContent content;

  Future<void> _start(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentSessionExecutionScreen(
          sessionId: content.session.id,
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    final completed = await showCompleteSessionDialog(
      context,
      studentSessionId: content.session.id,
      sessionTitle: content.session.title,
    );
    if (completed == true && context.mounted) {
      afterSessionCompletion(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Démarrer n'a de sens que si la séance contient au moins un exercice.
    // Une séance avec des blocs tous vides est une anomalie côté coach.
    final hasExercises = content.blocks.any((b) => b.exercises.isNotEmpty);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _complete(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                  side: BorderSide(color: theme.colorScheme.secondary),
                ),
                icon: const Icon(LucideIcons.checkCircle2),
                label: const Text('Terminer'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: hasExercises ? () => _start(context) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                icon: const Icon(LucideIcons.play),
                label: const Text('Démarrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
