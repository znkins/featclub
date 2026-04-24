import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/completed_session.dart';
import '../../../core/models/profile.dart';
import '../../../core/models/student_program.dart';
import '../../../core/models/weight_measure.dart';
import '../../../core/services/student_program_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../shared/providers/route_observer_provider.dart';
import '../../../shared/widgets/weight_measure_row.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../providers/completed_session_providers.dart';
import '../../providers/student_program_providers.dart';
import '../../providers/student_providers.dart';
import '../../providers/weight_measure_providers.dart';
import '../../widgets/add_choice_sheet.dart';
import '../../widgets/student_program_tile.dart';
import 'editor/student_program_editor_screen.dart';
import 'student_history_list_screen.dart';
import 'student_program_form_screen.dart';
import 'student_program_template_picker_screen.dart';
import 'weight_measure_form_dialog.dart';
import 'weight_measures_sheet.dart';

/// Fiche élève côté coach : identité + programmes + mesures + historique.
class StudentDetailScreen extends ConsumerStatefulWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen>
    with RouteAware {
  RouteObserver<ModalRoute<void>>? _observer;
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = ref.read(appRouteObserverProvider);
    final route = ModalRoute.of(context);
    if (route != null && (observer != _observer || route != _route)) {
      _observer?.unsubscribe(this);
      observer.subscribe(this, route);
      _observer = observer;
      _route = route;
    }
  }

  @override
  void dispose() {
    _observer?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _invalidateAll();
  }

  void _invalidateAll() {
    final id = widget.studentId;
    ref.invalidate(studentByIdProvider(id));
    ref.invalidate(studentProgramsProvider(id));
    ref.invalidate(studentWeightsProvider(id));
    ref.invalidate(studentRecentHistoryProvider(id));
    ref.invalidate(studentCompletedSessionCountProvider(id));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentByIdProvider(widget.studentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Détail Feater')),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger le profil.\n$e',
          onRetry: () =>
              ref.invalidate(studentByIdProvider(widget.studentId)),
        ),
        data: (profile) {
          if (profile == null) {
            return ErrorView(
              message: 'Élève introuvable',
              onRetry: () =>
                  ref.invalidate(studentByIdProvider(widget.studentId)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _invalidateAll(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _StudentHeaderCard(
                  profile: profile,
                  studentId: widget.studentId,
                ),
                const SizedBox(height: AppSpacing.xl),
                _ProgramsSection(studentId: widget.studentId),
                const SizedBox(height: AppSpacing.xl),
                _WeightSection(studentId: widget.studentId),
                const SizedBox(height: AppSpacing.xl),
                _HistorySection(studentId: widget.studentId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentHeaderCard extends ConsumerWidget {
  const _StudentHeaderCard({
    required this.profile,
    required this.studentId,
  });

  final Profile profile;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final displayName =
        profile.fullName.isEmpty ? 'Profil incomplet' : profile.fullName;
    final sessionCountAsync =
        ref.watch(studentCompletedSessionCountProvider(studentId));
    final age = profile.birthDate != null ? _computeAge(profile.birthDate!) : null;

    const bannerHeight = 72.0;
    const avatarSize = 112.0;
    final primary = theme.colorScheme.primary;
    final primaryDark = Color.lerp(primary, Colors.black, 0.18)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: bannerHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primary, primaryDark],
                  ),
                ),
              ),
              const SizedBox(height: avatarSize / 2 + AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        displayName,
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: LucideIcons.cake,
                            value: age != null
                                ? '$age ${age > 1 ? 'ans' : 'an'}'
                                : '—',
                            label: 'Âge',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: LucideIcons.scale,
                            value: profile.currentWeight != null
                                ? formatWeightKg(profile.currentWeight!)
                                : '—',
                            label: 'Poids',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: LucideIcons.activity,
                            value: sessionCountAsync.maybeWhen(
                              data: (c) => '$c',
                              orElse: () => '—',
                            ),
                            label: 'Séances',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _GoalNoteCard(
                      goal: profile.goal,
                      note: profile.bio,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: bannerHeight - avatarSize / 2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface,
                ),
                child: UserAvatar(
                  avatarUrl: profile.avatarUrl,
                  initials: _initials(profile),
                  size: avatarSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(Profile profile) {
    final f = (profile.firstName ?? '').trim();
    final l = (profile.lastName ?? '').trim();
    final i1 = f.isNotEmpty ? f[0] : '';
    final i2 = l.isNotEmpty ? l[0] : '';
    return (i1 + i2).toUpperCase();
  }

  int _computeAge(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GoalNoteCard extends StatelessWidget {
  const _GoalNoteCard({required this.goal, required this.note});

  final String? goal;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        color: theme.colorScheme.secondary.withValues(alpha: 0.15),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoalNoteRow(
            icon: LucideIcons.target,
            label: 'Objectif',
            value: goal,
          ),
          const SizedBox(height: AppSpacing.md),
          _GoalNoteRow(
            icon: LucideIcons.stickyNote,
            label: 'Note',
            value: note,
          ),
        ],
      ),
    );
  }
}

class _GoalNoteRow extends StatelessWidget {
  const _GoalNoteRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.1,
                ),
              ),
              Text(
                hasValue ? value!.trim() : '—',
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.1,
                  fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  color: hasValue
                      ? null
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        ?action,
      ],
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCcw, size: 16),
              label: const Text('Réessayer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdAll,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
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

class _SeeMoreLink extends StatelessWidget {
  const _SeeMoreLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onTap,
        child: const Text('Voir plus'),
      ),
    );
  }
}

class _ProgramsSection extends ConsumerStatefulWidget {
  const _ProgramsSection({required this.studentId});

  final String studentId;

  @override
  ConsumerState<_ProgramsSection> createState() => _ProgramsSectionState();
}

class _ProgramsSectionState extends ConsumerState<_ProgramsSection> {
  final Set<String> _togglingIds = {};

  Future<void> _openAddSheet() async {
    final choice = await showAddChoiceSheet(
      context,
      title: 'Ajouter un programme',
      emptyTitle: 'Nouveau programme',
      emptySubtitle: 'Créer un programme vide à construire.',
      templateTitle: 'Copier un template',
      templateSubtitle: 'Copier un programme de la bibliothèque.',
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case AddChoice.empty:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                StudentProgramFormScreen(studentId: widget.studentId),
          ),
        );
      case AddChoice.template:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentProgramTemplatePickerScreen(
              studentId: widget.studentId,
            ),
          ),
        );
    }
  }

  Future<void> _edit(StudentProgram program) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentProgramFormScreen(
          studentId: widget.studentId,
          existing: program,
        ),
      ),
    );
  }

  Future<void> _delete(StudentProgram program) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer le programme',
      message:
          'Supprimer « ${program.title} » ? Les séances et exercices personnalisés seront définitivement perdus.',
      confirmLabel: 'Supprimer',
      variant: ConfirmationVariant.destructive,
    );
    if (!confirm) return;
    try {
      await ref.read(studentProgramServiceProvider).delete(program.id);
      ref.invalidate(studentProgramsProvider(widget.studentId));
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Programme supprimé');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  Future<void> _toggleActive(StudentProgram program, bool active) async {
    if (_togglingIds.contains(program.id)) return;
    setState(() => _togglingIds.add(program.id));
    try {
      await ref.read(studentProgramServiceProvider).setActive(
            studentId: widget.studentId,
            programId: program.id,
            active: active,
          );
      ref.invalidate(studentProgramsProvider(widget.studentId));
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        active ? 'Programme activé' : 'Programme désactivé',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _togglingIds.remove(program.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentProgramsProvider(widget.studentId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Programmes',
          action: TextButton.icon(
            onPressed: _openAddSheet,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Ajouter'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingIndicator(),
          ),
          error: (e, _) => _SectionError(
            message: 'Impossible de charger les programmes.\n$e',
            onRetry: () =>
                ref.invalidate(studentProgramsProvider(widget.studentId)),
          ),
          data: (items) => _buildList(items),
        ),
      ],
    );
  }

  Widget _buildList(List<StudentProgramListItem> items) {
    if (items.isEmpty) {
      return const _EmptySectionCard(
        icon: LucideIcons.dumbbell,
        title: 'Aucun programme',
        subtitle: 'Crée un programme vide ou copie un template pour démarrer.',
      );
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          StudentProgramTile(
            program: items[i].program,
            sessionCount: items[i].sessionCount,
            busy: _togglingIds.contains(items[i].program.id),
            onTap: () => Navigator.of(context).push(
              StudentProgramEditorScreen.route(
                studentId: widget.studentId,
                programId: items[i].program.id,
              ),
            ),
            onToggleActive: (v) => _toggleActive(items[i].program, v),
            onEdit: () => _edit(items[i].program),
            onDelete: () => _delete(items[i].program),
          ),
        ],
      ],
    );
  }
}

class _WeightSection extends ConsumerWidget {
  const _WeightSection({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentWeightsProvider(studentId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Mesures',
          action: TextButton.icon(
            onPressed: () =>
                showWeightMeasureFormDialog(context, studentId: studentId),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Ajouter'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingIndicator(),
          ),
          error: (e, _) => _SectionError(
            message: 'Impossible de charger les mesures.\n$e',
            onRetry: () => ref.invalidate(studentWeightsProvider(studentId)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const _EmptySectionCard(
                icon: LucideIcons.scale,
                title: 'Aucune mesure',
                subtitle: 'Ajoute la première pesée de ton élève.',
              );
            }
            final recent = items.take(3).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (items.length >= 2) ...[
                  _WeightChart(measures: items),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  WeightMeasureRow(measure: recent[i]),
                ],
                if (items.length > 3)
                  _SeeMoreLink(
                    onTap: () => showWeightMeasuresSheet(
                      context,
                      studentId: studentId,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.measures});

  final List<WeightMeasure> measures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // En ordre chronologique pour le graphique. Tiebreaker sur `createdAt`
    // quand plusieurs mesures partagent la même date : on préserve l'ordre
    // réel de saisie au lieu de garder l'ordre descendant du provider.
    final sorted = [...measures]
      ..sort((a, b) {
        final byDate = a.measuredAt.compareTo(b.measuredAt);
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt);
      });
    final spots = <FlSpot>[
      for (var i = 0; i < sorted.length; i++)
        FlSpot(i.toDouble(), sorted[i].valueKg),
    ];
    final values = sorted.map((m) => m.valueKg).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) < 1 ? 1.0 : (maxY - minY) * 0.2;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            minY: minY - pad,
            maxY: maxY + pad,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touched) => touched.map((t) {
                  final m = sorted[t.spotIndex];
                  return LineTooltipItem(
                    '${formatDateShort(m.measuredAt)}\n${formatWeightKg(m.valueKg)}',
                    theme.textTheme.bodySmall!.copyWith(color: Colors.white),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.2,
                barWidth: 2.5,
                color: theme.colorScheme.primary,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: 4.5,
                    color: theme.colorScheme.secondary,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends ConsumerWidget {
  const _HistorySection({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentRecentHistoryProvider(studentId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Historique'),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingIndicator(),
          ),
          error: (e, _) => _SectionError(
            message: 'Impossible de charger l\'historique.\n$e',
            onRetry: () =>
                ref.invalidate(studentRecentHistoryProvider(studentId)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const _EmptySectionCard(
                icon: LucideIcons.calendarCheck,
                title: 'Aucune séance terminée',
                subtitle:
                    'L\'historique apparaîtra ici après la première séance.',
              );
            }
            final recent = items.take(3).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _CompactHistoryRow(item: recent[i]),
                ],
                if (items.length > 3)
                  _SeeMoreLink(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentHistoryListScreen(studentId: studentId),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CompactHistoryRow extends StatelessWidget {
  const _CompactHistoryRow({required this.item});

  final CompletedSession item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.sessionTitle,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            formatDate(item.completedAt),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
