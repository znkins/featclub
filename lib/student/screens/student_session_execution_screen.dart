import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/student_session_exercise.dart';
import '../../core/services/student_program_service.dart';
import '../../core/utils/video_launcher.dart';
import '../../coach/widgets/content_section_header.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/widgets/exercise_note_row.dart';
import '../../shared/widgets/exercise_params_row.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_session_providers.dart';
import '../widgets/complete_session_dialog.dart';

/// Mode d'exécution guidé : l'élève parcourt la séance bloc par bloc, avec
/// chronomètre libre. Quitter ne crée aucune complétion — seul le bouton
/// « Terminer » du dernier bloc le fait (via le sheet de complétion).
class StudentSessionExecutionScreen extends ConsumerWidget {
  const StudentSessionExecutionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentSessionContentProvider(sessionId));
    return async.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: 'Impossible de charger la séance.\n$e',
          onRetry: () =>
              ref.invalidate(studentSessionContentProvider(sessionId)),
        ),
      ),
      data: (content) {
        if (content.blocks.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(content.session.title)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Cette séance ne contient pas de bloc à exécuter.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          );
        }
        return _ExecutionBody(content: content);
      },
    );
  }
}

class _ExecutionBody extends ConsumerStatefulWidget {
  const _ExecutionBody({required this.content});

  final StudentSessionContent content;

  @override
  ConsumerState<_ExecutionBody> createState() => _ExecutionBodyState();
}

class _ExecutionBodyState extends ConsumerState<_ExecutionBody> {
  int _index = 0;
  final _stopwatch = Stopwatch();
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleStopwatch() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _ticker?.cancel();
        _ticker = null;
      } else {
        _stopwatch.start();
        _ticker ??= Timer.periodic(
          const Duration(milliseconds: 100),
          (_) => setState(() {}),
        );
      }
    });
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _ticker?.cancel();
      _ticker = null;
    });
  }

  void _goPrevious() {
    if (_index == 0) return;
    setState(() => _index -= 1);
  }

  void _goNext() {
    if (_index >= widget.content.blocks.length - 1) return;
    setState(() => _index += 1);
  }

  Future<bool> _confirmQuit() async {
    return ConfirmationDialog.show(
      context,
      title: 'Quitter la séance ?',
      message:
          'Ta progression actuelle ne sera pas enregistrée. La séance reste '
          'disponible pour la reprendre plus tard.',
      confirmLabel: 'Quitter',
      cancelLabel: 'Continuer',
      variant: ConfirmationVariant.warning,
    );
  }

  Future<void> _complete() async {
    final completed = await showCompleteSessionDialog(
      context,
      studentSessionId: widget.content.session.id,
      sessionTitle: widget.content.session.title,
    );
    if (completed == true && mounted) {
      afterSessionCompletion(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.content.session;
    final blocks = widget.content.blocks;
    final current = blocks[_index];
    final isFirst = _index == 0;
    final isLast = _index == blocks.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmQuit();
        if (!context.mounted) return;
        if (ok) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(session.title, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            tooltip: 'Quitter',
            icon: const Icon(LucideIcons.x),
            onPressed: () async {
              final ok = await _confirmQuit();
              if (!context.mounted) return;
              if (ok) Navigator.of(context).pop();
            },
          ),
        ),
        body: Column(
          children: [
            _StopwatchBar(
              elapsed: _stopwatch.elapsed,
              isRunning: _stopwatch.isRunning,
              onToggle: _toggleStopwatch,
              onReset: _resetStopwatch,
            ),
            LinearProgressIndicator(
              value: (_index + 1) / blocks.length,
              minHeight: AppSizes.progressBarHeight,
              backgroundColor: theme.colorScheme.outline,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    current.block.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                  if ((current.block.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      current.block.description!.trim(),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                  if (current.exercises.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    ContentSectionHeader(
                      title: 'Exercices',
                      count: current.exercises.length,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < current.exercises.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      _ExecutionExerciseCard(
                        exercise: current.exercises[i],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
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
                    onPressed: isFirst ? null : _goPrevious,
                    icon: const Icon(LucideIcons.chevronLeft),
                    label: const Text('Précédent'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: isLast
                      ? FilledButton.icon(
                          onPressed: _complete,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                          ),
                          icon: const Icon(LucideIcons.checkCircle2),
                          label: const Text('Terminer'),
                        )
                      : FilledButton.icon(
                          onPressed: _goNext,
                          icon: const Icon(LucideIcons.chevronRight),
                          label: const Text('Suivant'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StopwatchBar extends StatelessWidget {
  const _StopwatchBar({
    required this.elapsed,
    required this.isRunning,
    required this.onToggle,
    required this.onReset,
  });

  final Duration elapsed;
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Text(
            _formatDuration(elapsed),
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          IconButton.outlined(
            tooltip: 'Réinitialiser',
            onPressed: elapsed == Duration.zero && !isRunning ? null : onReset,
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
            ),
            icon: const Icon(LucideIcons.rotateCcw),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            tooltip: isRunning ? 'Arrêter' : 'Démarrer',
            onPressed: onToggle,
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            icon: Icon(isRunning ? LucideIcons.pause : LucideIcons.play),
          ),
        ],
      ),
    );
  }
}

class _ExecutionExerciseCard extends StatelessWidget {
  const _ExecutionExerciseCard({required this.exercise});

  final StudentSessionExercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = (exercise.description ?? '').trim();
    final note = (exercise.note ?? '').trim();
    final video = (exercise.videoUrl ?? '').trim();

    final hasParams = ExerciseParamsRow.hasContent(exercise);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.title, style: theme.textTheme.titleMedium),
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
      ),
    );
  }
}

/// Formate une durée en `HH:MM:SS` (ou `MM:SS` si < 1h).
String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:$mm:$ss';
  }
  return '$mm:$ss';
}
