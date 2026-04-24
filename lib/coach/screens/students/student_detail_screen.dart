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
import '../../../shared/providers/route_observer_provider.dart';
import '../../../shared/widgets/compact_history_row.dart';
import '../../../shared/widgets/empty_section_card.dart';
import '../../../shared/widgets/history_sheet.dart';
import '../../../shared/widgets/profile_identity_card.dart';
import '../../../shared/widgets/section_error.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/see_more_link.dart';
import '../../../shared/widgets/weight_evolution_chart.dart';
import '../../../shared/widgets/weight_measure_row.dart';
import '../../../shared/widgets/weight_measures_sheet.dart';
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
    final displayName =
        profile.fullName.isEmpty ? 'Profil incomplet' : profile.fullName;
    final sessionCountAsync =
        ref.watch(studentCompletedSessionCountProvider(studentId));
    final age = profile.age;

    return ProfileIdentityCard(
      avatarUrl: profile.avatarUrl,
      initials: profile.initials,
      displayName: displayName,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileStatsGrid(
            tiles: [
              ProfileStatTile(
                icon: LucideIcons.cake,
                value: age != null ? '$age ${age > 1 ? 'ans' : 'an'}' : null,
                label: 'Âge',
              ),
              ProfileStatTile(
                icon: LucideIcons.moveVertical,
                value:
                    profile.heightCm != null ? '${profile.heightCm} cm' : null,
                label: 'Taille',
              ),
              ProfileStatTile(
                icon: LucideIcons.scale,
                value: profile.currentWeight != null
                    ? formatWeightKg(profile.currentWeight!)
                    : null,
                label: 'Poids',
              ),
              ProfileStatTile(
                icon: LucideIcons.activity,
                value: sessionCountAsync.maybeWhen(
                  data: (c) => '$c',
                  orElse: () => null,
                ),
                label: 'Séances',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileInfoCard(
            rows: [
              ProfileInfoRow(
                icon: LucideIcons.target,
                label: 'Objectif',
                value: profile.goal,
              ),
              ProfileInfoRow(
                icon: LucideIcons.stickyNote,
                label: 'Note',
                value: profile.bio,
              ),
            ],
          ),
        ],
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

