import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../shared/providers/current_profile_provider.dart';
import '../../shared/providers/data_providers.dart';
import '../../shared/providers/student_data_providers.dart';
import '../../theme/app_spacing.dart';

/// Affiche une modale pour que l'élève ajoute sa propre mesure de poids.
///
/// L'insertion déclenche le trigger DB `update_current_weight` qui met à jour
/// `profiles.current_weight` — on invalide donc aussi `currentProfileProvider`.
Future<void> showStudentWeightMeasureDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _StudentWeightMeasureDialog(),
  );
}

class _StudentWeightMeasureDialog extends ConsumerStatefulWidget {
  const _StudentWeightMeasureDialog();

  @override
  ConsumerState<_StudentWeightMeasureDialog> createState() =>
      _StudentWeightMeasureDialogState();
}

class _StudentWeightMeasureDialogState
    extends ConsumerState<_StudentWeightMeasureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) {
      AppSnackbar.showError(context, 'Session expirée, reconnecte-toi.');
      return;
    }
    final value = double.parse(_weightController.text.replaceAll(',', '.'));
    setState(() => _saving = true);
    try {
      await ref.read(weightMeasureServiceProvider).create(
            studentId: profile.id,
            valueKg: value,
            measuredAt: _date,
          );
      ref.invalidate(studentWeightsProvider(profile.id));
      // `current_weight` est mis à jour par trigger DB : recharger le profil.
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Mesure ajoutée');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Nouvelle mesure'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Date', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Text(
                  formatDate(_date),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Poids (kg)', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _weightController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Poids requis';
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed == null) return 'Valeur invalide';
                if (parsed <= 0 || parsed > 500) return 'Valeur hors bornes';
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
