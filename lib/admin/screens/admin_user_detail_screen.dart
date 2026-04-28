import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/admin_user_row.dart';
import '../../core/utils/user_role.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/supabase_providers.dart';
import '../../shared/widgets/profile_identity_card.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_pills.dart';

/// Fiche admin d'un utilisateur : édition rôle/statut, suppression
/// (réservée aux comptes élève via la RPC `admin_delete_student`).
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState
    extends ConsumerState<AdminUserDetailScreen> {
  UserRole? _initialRole;
  UserRole? _selectedRole;
  AccessStatus? _initialStatus;
  AccessStatus? _selectedStatus;
  bool _seeded = false;
  bool _saving = false;
  bool _deleting = false;

  void _seed(AdminUserRow row) {
    if (_seeded) return;
    _initialRole = row.role;
    _selectedRole = row.role;
    _initialStatus = row.status;
    _selectedStatus = row.status;
    _seeded = true;
  }

  bool get _isDirty =>
      _selectedRole != _initialRole || _selectedStatus != _initialStatus;

  Future<void> _save() async {
    if (_saving || !_isDirty) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminUserServiceProvider).updateRoleAndStatus(
            id: widget.userId,
            role: _selectedRole!,
            status: _selectedStatus!,
          );
      ref.invalidate(adminUsersProvider);
      if (!mounted) return;
      setState(() {
        _initialRole = _selectedRole;
        _initialStatus = _selectedStatus;
      });
      AppSnackbar.showSuccess(context, 'Modifications enregistrées');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(AdminUserRow row) async {
    if (_deleting) return;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Supprimer le compte',
      message:
          'Toutes les données de ${row.displayName} seront supprimées définitivement. Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      variant: ConfirmationVariant.destructive,
    );
    if (!confirmed || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(adminUserServiceProvider).deleteStudent(row.id);
      ref.invalidate(adminUsersProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Compte supprimé');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, _deleteErrorMessage(e));
      setState(() => _deleting = false);
    }
  }

  /// Message utilisateur pour les erreurs de la RPC `admin_delete_student`.
  /// La RPC refuse la suppression si le compte possède du contenu coach :
  /// on transforme la signature SQL en message clair.
  String _deleteErrorMessage(Object e) {
    final raw = e.toString();
    if (raw.contains('contenu en bibliothèque')) {
      return 'Ce compte possède encore du contenu en bibliothèque '
          '(exercices, blocs, séances, programmes). Supprime-le d\'abord, '
          'puis réessaie.';
    }
    return 'Erreur : $e';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Détail utilisateur')),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger l\'utilisateur.\n$e',
          onRetry: () => ref.invalidate(adminUsersProvider),
        ),
        data: (users) {
          final row = users
              .where((u) => u.id == widget.userId)
              .firstOrNull;
          if (row == null) {
            return ErrorView(
              message: 'Utilisateur introuvable',
              onRetry: () => ref.invalidate(adminUsersProvider),
            );
          }
          _seed(row);
          return _Body(
            row: row,
            selectedRole: _selectedRole!,
            selectedStatus: _selectedStatus!,
            isSelf: row.id == ref.watch(currentSessionProvider)?.user.id,
            isDirty: _isDirty,
            saving: _saving,
            deleting: _deleting,
            onRoleChanged: (r) => setState(() => _selectedRole = r),
            onStatusChanged: (s) => setState(() => _selectedStatus = s),
            onSave: _save,
            onDelete: () => _delete(row),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.row,
    required this.selectedRole,
    required this.selectedStatus,
    required this.isSelf,
    required this.isDirty,
    required this.saving,
    required this.deleting,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onSave,
    required this.onDelete,
  });

  final AdminUserRow row;
  final UserRole selectedRole;
  final AccessStatus selectedStatus;
  final bool isSelf;
  final bool isDirty;
  final bool saving;
  final bool deleting;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<AccessStatus> onStatusChanged;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  bool get _canDelete => row.role == UserRole.eleve;
  bool get _editable => !isSelf && !saving && !deleting;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ProfileIdentityCard(
          avatarUrl: row.avatarUrl,
          initials: row.initials,
          displayName:
              row.fullName.isEmpty ? 'Profil incomplet' : row.fullName,
          subtitle: row.email,
          chip: AdminRolePill(role: row.role),
        ),
        if (isSelf) ...[
          const SizedBox(height: AppSpacing.lg),
          const _SelfNotice(),
        ],
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(text: 'Rôle'),
        const SizedBox(height: AppSpacing.sm),
        _RolePicker(
          selected: selectedRole,
          enabled: _editable,
          onChanged: onRoleChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(text: 'Statut'),
        const SizedBox(height: AppSpacing.sm),
        _StatusToggle(
          status: selectedStatus,
          enabled: _editable,
          onChanged: onStatusChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: (_editable && isDirty) ? onSave : null,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.check, size: 18),
          label: const Text('Enregistrer'),
        ),
        if (_canDelete) ...[
          const SizedBox(height: AppSpacing.xxl),
          _DangerZone(
            deleting: deleting,
            enabled: _editable,
            onDelete: onDelete,
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final UserRole selected;
  final bool enabled;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<UserRole>(
      segments: [
        for (final r in UserRole.values)
          ButtonSegment(
            value: r,
            label: Text(labelForRole(r)),
            icon: Icon(iconForRole(r), size: 16),
          ),
      ],
      selected: {selected},
      onSelectionChanged: enabled
          ? (set) => onChanged(set.first)
          : null,
      showSelectedIcon: false,
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({
    required this.status,
    required this.enabled,
    required this.onChanged,
  });

  final AccessStatus status;
  final bool enabled;
  final ValueChanged<AccessStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = status == AccessStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Compte actif',
                  style: theme.textTheme.bodyLarge,
                ),
                Text(
                  isActive
                      ? 'L\'utilisateur peut se connecter.'
                      : 'L\'utilisateur ne peut plus se connecter.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: enabled
                ? (v) => onChanged(
                      v ? AccessStatus.active : AccessStatus.disabled,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

class _SelfNotice extends StatelessWidget {
  const _SelfNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        color: theme.colorScheme.secondary.withValues(alpha: 0.10),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.info,
            size: 18,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'C\'est ton propre compte, tu ne peux pas le modifier ici.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({
    required this.deleting,
    required this.enabled,
    required this.onDelete,
  });

  final bool deleting;
  final bool enabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Supprimer le compte',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Supprime définitivement le compte élève et toutes ses données (programmes, séances, mesures, complétions).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: enabled ? onDelete : null,
            icon: deleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.trash2, size: 18),
            label: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
