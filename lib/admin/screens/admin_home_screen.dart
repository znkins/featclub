import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/admin_user_row.dart';
import '../../core/utils/user_role.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/supabase_providers.dart';
import '../../shared/widgets/theme_mode_toggle.dart';
import '../../theme/app_spacing.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_pills.dart';
import '../widgets/admin_user_tile.dart';
import 'admin_user_detail_screen.dart';

/// Espace admin (page unique) : liste des comptes + recherche.
///
/// Ouvre une fiche utilisateur en push pour modifier rôle / statut ou
/// supprimer un élève. Pas de bottom nav par design (cf. parcours doc 7.1).
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  String _query = '';

  /// Filtre client-side : matche prénom, nom, nom complet, email,
  /// libellé du rôle (« coach », « élève », « admin », ou les valeurs
  /// brutes), et libellé du statut (« désactivé » ou « disabled »).
  List<AdminUserRow> _filter(List<AdminUserRow> users) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      final tokens = <String>[
        (u.firstName ?? '').toLowerCase(),
        (u.lastName ?? '').toLowerCase(),
        u.fullName.toLowerCase(),
        u.email.toLowerCase(),
        u.role.name.toLowerCase(),
        labelForRole(u.role).toLowerCase(),
        u.status.name.toLowerCase(),
        if (u.status == AccessStatus.disabled) 'désactivé',
        if (u.status == AccessStatus.active) 'actif',
      ];
      return tokens.any((t) => t.contains(q));
    }).toList();
  }

  Future<void> _openDetail(AdminUserRow user) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminUserDetailScreen(userId: user.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        actions: [
          const ThemeModeToggle(),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
              } catch (e) {
                if (!context.mounted) return;
                AppSnackbar.showError(context, 'Erreur : $e');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Rechercher (nom, email, rôle, statut)',
                prefixIcon: Icon(LucideIcons.search, size: 18),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: 'Impossible de charger les utilisateurs.\n$e',
                onRetry: () => ref.invalidate(adminUsersProvider),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return const EmptyView(
                    icon: LucideIcons.users,
                    wrapIcon: true,
                    message: 'Aucun utilisateur.',
                  );
                }
                final filtered = _filter(all);
                if (filtered.isEmpty) {
                  return const EmptyView.noResults();
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminUsersProvider),
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
                    itemBuilder: (_, i) => AdminUserTile(
                      user: filtered[i],
                      onTap: () => _openDetail(filtered[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

