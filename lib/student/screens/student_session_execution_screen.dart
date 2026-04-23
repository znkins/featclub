import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/student_session_exercise.dart';
import '../../core/services/student_program_service.dart';
import '../../core/utils/video_launcher.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/providers/student_data_providers.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_session_providers.dart';
import '../widgets/complete_session_sheet.dart';

/// Mode d'exécution guidé : l'élève parcourt la séance bloc par bloc, avec un
/// chronomètre libre et la possibilité de terminer la séance depuis le dernier
/// bloc. Quitter ne crée aucune complétion — seule l'action « Terminer » le
/// fait (via le sheet de complétion).
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
      destructive: true,
    );
  }

  Future<void> _complete() async {
    final completed = await showCompleteSessionSheet(
      context,
      studentSessionId: widget.content.session.id,
      sessionTitle: widget.content.session.title,
    );
    if (completed == true && mounted) {
      final profile = ref.read(currentProfileProvider).valueOrNull;
      if (profile != null) {
        ref.invalidate(studentRecentHistoryProvider(profile.id));
        ref.invalidate(studentHistoryProvider(profile.id));
        ref.invalidate(studentCompletedSessionCountProvider(profile.id));
      }
      AppSnackbar.showSuccess(context, 'Séance enregistrée');
      if (mounted) Navigator.of(context).pop();
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: Text(
                      'Bloc ${_index + 1} / ${blocks.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    current.block.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                  if ((current.block.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      current.block.description!.trim(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${current.exercises.length} exercice${current.exercises.length > 1 ? 's' : ''}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (current.exercises.isEmpty)
                    Text(
                      'Aucun exercice dans ce bloc.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    for (var i = 0; i < current.exercises.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      _ExecutionExerciseCard(
                        exercise: current.exercises[i],
                      ),
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
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline),
        ),
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
          IconButton.filledTonal(
            tooltip: isRunning ? 'Arrêter' : 'Démarrer',
            onPressed: onToggle,
            icon: Icon(isRunning ? LucideIcons.pause : LucideIcons.play),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Réinitialiser',
            onPressed: elapsed == Duration.zero && !isRunning ? null : onReset,
            icon: const Icon(LucideIcons.rotateCcw),
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
          if (params.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final p in params)
                  _ExecParamChip(icon: p.$1, label: p.$2, value: p.$3),
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
                    child: Text(note, style: theme.textTheme.bodyMedium),
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
      ),
    );
  }
}

class _ExecParamChip extends StatelessWidget {
  const _ExecParamChip({
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
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
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
