import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/student_session.dart';
import '../../core/models/student_session_exercise.dart';
import '../../core/services/student_program_service.dart';
import '../../core/utils/video_launcher.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/providers/student_data_providers.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_session_providers.dart';
import '../widgets/complete_session_sheet.dart';
import '../widgets/student_session_tile.dart';
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
        _SessionHeader(session: content.session, blockCount: content.blocks.length),
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
  const _SessionHeader({required this.session, required this.blockCount});

  final StudentSession session;
  final int blockCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = formatAssignedDateLabel(session.assignedDate);
    final description = (session.description ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(session.title, style: theme.textTheme.headlineSmall),
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            if (dateLabel != null)
              _MetaPill(icon: LucideIcons.calendar, label: dateLabel),
            if (session.durationMinutes != null)
              _MetaPill(
                icon: LucideIcons.clock,
                label: '${session.durationMinutes} min',
              ),
            _MetaPill(
              icon: LucideIcons.layers,
              label: '$blockCount bloc${blockCount > 1 ? 's' : ''}',
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.fullAll,
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
            'Cette séance ne contient pas encore de bloc.',
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
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (blockContent.exercises.isEmpty)
            Text(
              'Aucun exercice dans ce bloc.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (var i = 0; i < blockContent.exercises.length; i++) ...[
              if (i > 0)
                Divider(
                  height: AppSpacing.xl,
                  color: theme.colorScheme.outline,
                ),
              _ExerciseRow(exercise: blockContent.exercises[i]),
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

    final params = <(IconData, String, String)>[
      if ((exercise.reps ?? '').trim().isNotEmpty)
        (LucideIcons.repeat, 'Reps', exercise.reps!.trim()),
      if ((exercise.load ?? '').trim().isNotEmpty)
        (LucideIcons.dumbbell, 'Charge', exercise.load!.trim()),
      if ((exercise.intensity ?? '').trim().isNotEmpty)
        (LucideIcons.flame, 'Intensité', exercise.intensity!.trim()),
      if ((exercise.rest ?? '').trim().isNotEmpty)
        (LucideIcons.timer, 'Repos', exercise.rest!.trim()),
    ];

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
        if (params.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final p in params)
                _ParamChip(icon: p.$1, label: p.$2, value: p.$3),
            ],
          ),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.stickyNote,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    note,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _ParamChip extends StatelessWidget {
  const _ParamChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label : ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
    final completed = await showCompleteSessionSheet(
      context,
      studentSessionId: content.session.id,
      sessionTitle: content.session.title,
    );
    if (completed == true && context.mounted) {
      final profile = ref.read(currentProfileProvider).valueOrNull;
      if (profile != null) {
        ref.invalidate(studentRecentHistoryProvider(profile.id));
        ref.invalidate(studentHistoryProvider(profile.id));
        ref.invalidate(studentCompletedSessionCountProvider(profile.id));
      }
      AppSnackbar.showSuccess(context, 'Séance enregistrée');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBlocks = content.blocks.isNotEmpty;
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
                icon: const Icon(LucideIcons.checkCircle2),
                label: const Text('Terminer'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: hasBlocks ? () => _start(context) : null,
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
