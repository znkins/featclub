import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/profile.dart';
import '../../../core/models/student_program.dart';
import '../../../core/services/student_program_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../shared/providers/route_observer_provider.dart';
import '../../../shared/widgets/compact_history_row.dart';
import '../../../shared/widgets/empty_section_card.dart';
import '../../../shared/widgets/history_sheet.dart';
import '../../../shared/widgets/section_error.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/see_more_link.dart';
import '../../../shared/widgets/weight_evolution_chart.dart';
import '../../../shared/widgets/weight_measure_row.dart';
import '../../../shared/widgets/weight_measures_sheet.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../providers/completed_session_providers.dart';
import '../../providers/student_program_providers.dart';
import '../../providers/student_providers.dart';
import '../../providers/weight_measure_providers.dart';
import '../../widgets/add_choice_sheet.dart';
import '../../widgets/student_program_tile.dart';
import 'editor/student_program_editor_screen.dart';
import 'student_program_form_screen.dart';
import 'student_program_template_picker_screen.dart';
import 'weight_measure_form_dialog.dart';

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
                color: theme.colorScheme.primary,
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
        color: theme.colorScheme.secondary.withValues(alpha: 0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoalNoteRow(
            icon: LucideIcons.target,
            label: 'Objectif',
            value: goal,
          ),
          const SizedBox(height: AppSpacing.lg),
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

  // Largeur totale icône + gap utilisée pour indenter la valeur sous le
  // label (doit matcher `Icon.size` + `SizedBox(width)` ci-dessous).
  static const double _labelIndent = 20 + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.secondary),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: _labelIndent),
          child: Text(
            hasValue ? value!.trim() : '—',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
              color:
                  hasValue ? null : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
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
        SectionHeader(
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
          error: (e, _) => SectionError(
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
      return const EmptySectionCard(
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
        SectionHeader(
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
          error: (e, _) => SectionError(
            message: 'Impossible de charger les mesures.\n$e',
            onRetry: () => ref.invalidate(studentWeightsProvider(studentId)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptySectionCard(
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
                  WeightEvolutionChart(measures: items),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  WeightMeasureRow(measure: recent[i]),
                ],
                if (items.length > 3)
                  SeeMoreLink(
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


class _HistorySection extends ConsumerWidget {
  const _HistorySection({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentRecentHistoryProvider(studentId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Historique'),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: LoadingIndicator(),
          ),
          error: (e, _) => SectionError(
            message: 'Impossible de charger l\'historique.\n$e',
            onRetry: () =>
                ref.invalidate(studentRecentHistoryProvider(studentId)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptySectionCard(
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
                  CompactHistoryRow(item: recent[i]),
                ],
                if (items.length > 3)
                  SeeMoreLink(
                    onTap: () => showHistorySheet(
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

