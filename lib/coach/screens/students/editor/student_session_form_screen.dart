import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/student_session.dart';
import '../../../../core/utils/day_of_week.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/student_program_providers.dart';

/// Création ou édition d'une séance élève (métadonnées + jour de semaine).
///
/// Mode création : nécessite `programId`, `existing` est null.
/// Mode édition : nécessite `existing`.
///
/// Le jour de semaine choisi déclenche le calcul automatique de
/// `assigned_date` côté service (prochaine occurrence, aujourd'hui si
/// même jour).
class StudentSessionFormScreen extends ConsumerStatefulWidget {
  const StudentSessionFormScreen({
    super.key,
    this.programId,
    this.existing,
  }) : assert(programId != null || existing != null,
            'programId requis en création');

  final String? programId;
  final StudentSession? existing;

  @override
  ConsumerState<StudentSessionFormScreen> createState() =>
      _StudentSessionFormScreenState();
}

class _StudentSessionFormScreenState
    extends ConsumerState<StudentSessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  DayOfWeek? _dayOfWeek;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    if (s != null) {
      _titleController.text = s.title;
      _descriptionController.text = s.description ?? '';
      _durationController.text = s.durationMinutes?.toString() ?? '';
      _dayOfWeek = DayOfWeek.fromStorage(s.dayOfWeek);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final durationText = _durationController.text.trim();
    int? duration;
    if (durationText.isNotEmpty) {
      duration = int.tryParse(durationText);
      if (duration == null || duration <= 0) {
        AppSnackbar.showError(context, 'Durée invalide');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(studentProgramServiceProvider);
      String programIdToInvalidate;
      if (_isEdit) {
        final updated = await service.updateSessionMetadata(
          id: widget.existing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
          durationMinutes: duration,
          dayOfWeek: _dayOfWeek,
        );
        programIdToInvalidate = updated.studentProgramId;
        ref.invalidate(
          studentSessionEditorDetailProvider(widget.existing!.id),
        );
      } else {
        await service.createEmptySession(
          programId: widget.programId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
          durationMinutes: duration,
          dayOfWeek: _dayOfWeek,
        );
        programIdToInvalidate = widget.programId!;
      }
      ref.invalidate(
        studentProgramEditorDetailProvider(programIdToInvalidate),
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        _isEdit ? 'Séance mise à jour' : 'Séance créée',
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la séance' : 'Nouvelle séance'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Titre *', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Description', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Durée estimée (min)', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '60'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Jour de la semaine', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<DayOfWeek?>(
              initialValue: _dayOfWeek,
              decoration: const InputDecoration(hintText: 'Aucun'),
              items: [
                const DropdownMenuItem<DayOfWeek?>(
                  value: null,
                  child: Text('Aucun'),
                ),
                for (final d in DayOfWeek.values)
                  DropdownMenuItem<DayOfWeek?>(
                    value: d,
                    child: Text(d.frenchLabel),
                  ),
              ],
              onChanged: (v) => setState(() => _dayOfWeek = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEdit ? 'Enregistrer' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
