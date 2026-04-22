import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/profile.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../theme/app_spacing.dart';
import '../providers/student_providers.dart';
import '../widgets/library_search_field.dart';
import '../widgets/student_list_tile.dart';
import 'students/student_detail_screen.dart';

/// Onglet Featers : liste des élèves actifs + recherche.
class CoachFeatersScreen extends ConsumerStatefulWidget {
  const CoachFeatersScreen({super.key});

  @override
  ConsumerState<CoachFeatersScreen> createState() => _CoachFeatersScreenState();
}

class _CoachFeatersScreenState extends ConsumerState<CoachFeatersScreen> {
  String _query = '';

  List<Profile> _filter(List<Profile> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((p) {
      final first = (p.firstName ?? '').toLowerCase();
      final last = (p.lastName ?? '').toLowerCase();
      final full = p.fullName.toLowerCase();
      return first.contains(q) || last.contains(q) || full.contains(q);
    }).toList();
  }

  void _openDetail(Profile student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(studentId: student.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachStudentsProvider);
    return Column(
      children: [
        LibrarySearchField(
          hintText: 'Rechercher un élève',
          onChanged: (v) => setState(() => _query = v),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => ErrorView(
              message: 'Impossible de charger les élèves.\n$e',
              onRetry: () => ref.invalidate(coachStudentsProvider),
            ),
            data: (all) {
              if (all.isEmpty) {
                return const EmptyView(
                  icon: LucideIcons.users,
                  wrapIcon: true,
                  message: 'Aucun élève actif pour le moment.',
                );
              }
              final filtered = _filter(all);
              if (filtered.isEmpty) {
                return const EmptyView(
                  icon: LucideIcons.search,
                  message: 'Aucun résultat',
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(coachStudentsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl * 2,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) => StudentListTile(
                    profile: filtered[i],
                    onTap: () => _openDetail(filtered[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
