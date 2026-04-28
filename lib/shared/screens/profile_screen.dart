import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/profile.dart';
import '../../core/utils/avatar_picker.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/user_role.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../providers/auth_provider.dart';
import '../providers/current_profile_provider.dart';
import '../providers/student_data_providers.dart';
import '../providers/supabase_providers.dart';
import '../widgets/profile_identity_card.dart';
import '../widgets/theme_mode_toggle.dart';

/// Écran de profil partagé (élève + coach).
///
/// Mode lecture par défaut + bascule en édition. Champs adaptés au rôle :
/// élève (prénom, nom, bio, naissance, taille, objectif), coach (prénom,
/// nom, bio).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _heightController = TextEditingController();
  final _goalController = TextEditingController();
  DateTime? _birthDate;

  bool _isEditing = false;
  bool _saving = false;
  bool _uploadingAvatar = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _startEditing(Profile profile) {
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _bioController.text = profile.bio ?? '';
    _heightController.text = profile.heightCm?.toString() ?? '';
    _goalController.text = profile.goal ?? '';
    _birthDate = profile.birthDate;
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _save(Profile profile) async {
    if (_saving) return;
    setState(() => _saving = true);

    final heightText = _heightController.text.trim();
    int? heightCm;
    if (heightText.isNotEmpty) {
      heightCm = int.tryParse(heightText);
      if (heightCm == null || heightCm <= 0) {
        AppSnackbar.showError(context, 'Taille invalide');
        setState(() => _saving = false);
        return;
      }
    }

    try {
      await ref.read(profileServiceProvider).updateOwnProfile(
            id: profile.id,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            bio: _bioController.text.trim(),
            birthDate: _birthDate,
            heightCm: heightCm,
            goal: _goalController.text.trim(),
          );
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _isEditing = false;
      });
      AppSnackbar.showSuccess(context, 'Profil mis à jour');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.showError(context, 'Échec de la mise à jour : $e');
    }
  }

  Future<void> _pickAvatar(Profile profile) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final picked = await AvatarPicker.pick(source: source);
      if (picked == null) {
        if (mounted) setState(() => _uploadingAvatar = false);
        return;
      }
      final url = await ref.read(storageServiceProvider).uploadAvatar(
            userId: profile.id,
            bytes: picked.bytes,
            contentType: picked.contentType,
          );
      await ref.read(profileServiceProvider).updateOwnProfile(
            id: profile.id,
            firstName: profile.firstName ?? '',
            lastName: profile.lastName ?? '',
            bio: profile.bio ?? '',
            birthDate: profile.birthDate,
            heightCm: profile.heightCm,
            goal: profile.goal ?? '',
            avatarUrl: url,
          );
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Avatar mis à jour');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, "Échec de l'upload : $e");
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date de naissance',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _logout() async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Se déconnecter',
      message: 'Veux-tu vraiment te déconnecter ?',
      confirmLabel: 'Déconnexion',
    );
    if (!confirm) return;
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final session = ref.watch(currentSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: _buildAppBarActions(profileAsync.valueOrNull),
      ),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger le profil.\n$e',
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return ErrorView(
              message: 'Profil introuvable',
              onRetry: () => ref.invalidate(currentProfileProvider),
            );
          }
          return _buildProfile(context, profile, session?.user.email);
        },
      ),
    );
  }

  // En édition, on n'expose que Annuler/Enregistrer pour éviter toute action
  // destructive (déconnexion, switch thème) pendant qu'une saisie est ouverte.
  List<Widget> _buildAppBarActions(Profile? profile) {
    if (profile == null) return const [ThemeModeToggle()];
    if (_isEditing) {
      return [
        IconButton(
          tooltip: 'Annuler',
          icon: const Icon(LucideIcons.x),
          onPressed: _saving ? null : _cancelEditing,
        ),
        IconButton(
          tooltip: 'Enregistrer',
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(LucideIcons.check),
          onPressed: _saving ? null : () => _save(profile),
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Modifier',
        icon: const Icon(LucideIcons.pencil),
        onPressed: () => _startEditing(profile),
      ),
      const ThemeModeToggle(),
      IconButton(
        tooltip: 'Se déconnecter',
        icon: const Icon(LucideIcons.logOut),
        onPressed: _logout,
      ),
    ];
  }

  Widget _buildProfile(BuildContext context, Profile profile, String? email) {
    final isStudent = profile.role == UserRole.eleve;
    final displayName =
        profile.fullName.isEmpty ? 'Feater' : profile.fullName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileIdentityCard(
            avatarUrl: profile.avatarUrl,
            initials: profile.initials,
            displayName: displayName,
            subtitle: email,
            // Pas de chip rôle pour un élève consultant son propre profil
            // (info redondante).
            chip: !isStudent ? _RoleChip(role: profile.role) : null,
            chipAsideAvatar: true,
            avatarOverlay: _isEditing
                ? _AvatarEditButton(
                    uploading: _uploadingAvatar,
                    onTap: () => _pickAvatar(profile),
                  )
                : null,
            // En mode édition, la carte reste minimale (identité seule) :
            // les champs modifiables sont dans le formulaire en dessous.
            body: _isEditing
                ? null
                : (isStudent
                    ? _StudentProfileBody(profile: profile)
                    : _CoachProfileBody(profile: profile)),
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildEditForm(context, profile),
          ],
        ],
      ),
    );
  }

  Widget _buildEditForm(BuildContext context, Profile profile) {
    final isStudent = profile.role == UserRole.eleve;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EditField(label: 'Prénom', controller: _firstNameController),
        const SizedBox(height: AppSpacing.lg),
        _EditField(label: 'Nom', controller: _lastNameController),
        const SizedBox(height: AppSpacing.lg),
        _EditField(
          label: 'Bio',
          controller: _bioController,
          keyboardType: TextInputType.multiline,
          minLines: 3,
          maxLines: null,
        ),
        if (isStudent) ...[
          const SizedBox(height: AppSpacing.lg),
          _BirthDatePickerField(
            value: _birthDate,
            onPick: _pickBirthDate,
          ),
          const SizedBox(height: AppSpacing.lg),
          _EditField(
            label: 'Taille (cm)',
            controller: _heightController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          _EditField(
            label: 'Objectif',
            controller: _goalController,
            maxLines: 2,
          ),
        ],
      ],
    );
  }

}

class _StudentProfileBody extends ConsumerWidget {
  const _StudentProfileBody({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionCountAsync =
        ref.watch(studentCompletedSessionCountProvider(profile.id));
    final age = profile.age;

    return Column(
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
              value: profile.heightCm != null ? '${profile.heightCm} cm' : null,
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
              label: 'Bio',
              value: profile.bio,
            ),
          ],
        ),
      ],
    );
  }

}

class _CoachProfileBody extends StatelessWidget {
  const _CoachProfileBody({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return ProfileInfoCard(
      rows: [
        ProfileInfoRow(
          icon: LucideIcons.stickyNote,
          label: 'Bio',
          value: profile.bio,
        ),
      ],
    );
  }
}

class _AvatarEditButton extends StatelessWidget {
  const _AvatarEditButton({required this.uploading, required this.onTap});

  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    return Material(
      color: theme.colorScheme.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: uploading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: uploading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: onPrimary,
                  ),
                )
              : Icon(
                  LucideIcons.pencil,
                  color: onPrimary,
                  size: 18,
                ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (role) {
      UserRole.eleve => 'Élève',
      UserRole.coach => 'Coach',
      UserRole.admin => 'Admin',
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

class _BirthDatePickerField extends StatelessWidget {
  const _BirthDatePickerField({required this.value, required this.onPick});

  final DateTime? value;
  final VoidCallback onPick;

  String _format(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date de naissance', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onPick,
          borderRadius: AppRadius.smAll,
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: SizedBox(
              height: AppSizes.tapTargetMin - 16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value != null ? _format(value!) : 'Choisir une date',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: value != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
