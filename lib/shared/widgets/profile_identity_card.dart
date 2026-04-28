import 'package:flutter/material.dart';

import '../../core/widgets/user_avatar.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Carte d'identité partagée : bandeau primaire + avatar centré flottant +
/// nom + sous-titre optionnel + chip optionnel + body libre.
/// Utilisée par la fiche élève (côté coach) et les écrans Profil.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.avatarUrl,
    required this.initials,
    required this.displayName,
    this.subtitle,
    this.chip,
    this.chipAsideAvatar = false,
    this.avatarOverlay,
    this.body,
  });

  final String? avatarUrl;
  final String initials;
  final String displayName;
  final String? subtitle;
  final Widget? chip;

  /// Si `true`, le chip flotte en haut-droite plutôt que centré sous le nom.
  final bool chipAsideAvatar;

  /// Widget posé en bas-droite de l'avatar (bouton d'édition, etc.).
  final Widget? avatarOverlay;

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const bannerHeight = 72.0;
    const avatarSize = 112.0;
    final showChipInline = chip != null && !chipAsideAvatar;
    final showChipAside = chip != null && chipAsideAvatar;

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
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    if (showChipInline) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Center(child: chip!),
                    ],
                    if (body != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      body!,
                    ],
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
              child: SizedBox(
                width: avatarSize + 6,
                height: avatarSize + 6,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surface,
                      ),
                      child: UserAvatar(
                        avatarUrl: avatarUrl,
                        initials: initials,
                        size: avatarSize,
                      ),
                    ),
                    if (avatarOverlay != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: avatarOverlay!,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (showChipAside)
            Positioned(
              top: bannerHeight + AppSpacing.md,
              right: AppSpacing.lg,
              child: chip!,
            ),
        ],
      ),
    );
  }
}

/// Tuile statistique compacte : icône + valeur + label.
/// `value == null` rend un `—` italique (donnée non renseignée).
class ProfileStatTile extends StatelessWidget {
  const ProfileStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdAll,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasValue ? value! : '—',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color:
                        hasValue ? null : theme.colorScheme.onSurfaceVariant,
                    fontStyle: hasValue ? null : FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
          ),
        ],
      ),
    );
  }
}

/// Grille de tuiles statistiques (4 tuiles → 2x2, sinon une seule ligne).
class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({super.key, required this.tiles});

  final List<ProfileStatTile> tiles;

  @override
  Widget build(BuildContext context) {
    if (tiles.length == 4) {
      return Column(
        children: [
          _row([tiles[0], tiles[1]]),
          const SizedBox(height: AppSpacing.md),
          _row([tiles[2], tiles[3]]),
        ],
      );
    }
    return _row(tiles);
  }

  Widget _row(List<ProfileStatTile> items) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

/// Carte d'informations sur fond orange léger (Objectif, Note, Bio, etc.).
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.rows});

  final List<ProfileInfoRow> rows;

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
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Ligne d'info : icône orange + label muet + valeur indentée sous le label.
/// `value` nul/vide rend un `—` italique.
class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  // Largeur icône + gap pour aligner la valeur sous le label
  // (doit matcher l'icône 20 + SizedBox md).
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
              color: hasValue ? null : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
