import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../theme/app_spacing.dart';
import '../../providers/student_providers.dart';
import '../../providers/weight_measure_providers.dart';

/// Affiche une modale pour ajouter une mesure de poids.
Future<void> showWeightMeasureFormDialog(
  BuildContext context, {
  required String studentId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _WeightMeasureFormDialog(studentId: studentId),
  );
}

/// Formulaire d'ajout d'une mesure : date + valeur en kg.
///
/// L'insertion déclenche le trigger DB qui met à jour `profiles.current_weight`.
class _WeightMeasureFormDialog extends ConsumerStatefulWidget {
  const _WeightMeasureFormDialog({required this.studentId});

  final String studentId;

  @override
  ConsumerState<_WeightMeasureFormDialog> createState() =>
      _WeightMeasureFormDialogState();
}

class _WeightMeasureFormDialogState
    extends ConsumerState<_WeightMeasureFormDialog> {
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
    final value = double.parse(_weightController.text.replaceAll(',', '.'));
    setState(() => _saving = true);
    try {
      await ref.read(weightMeasureServiceProvider).create(
            studentId: widget.studentId,
            valueKg: value,
            measuredAt: _date,
          );
      ref.invalidate(studentWeightsProvider(widget.studentId));
      // `current_weight` est mis à jour par trigger DB.
      ref.invalidate(studentByIdProvider(widget.studentId));
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
