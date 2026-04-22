import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/student_program.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../theme/app_spacing.dart';
import '../../providers/student_program_providers.dart';

/// Création vide ou édition des métadonnées (titre + description) d'un
/// programme élève. L'édition profonde (séances/blocs) sera ajoutée en 3.c.
class StudentProgramFormScreen extends ConsumerStatefulWidget {
  const StudentProgramFormScreen({
    super.key,
    required this.studentId,
    this.existing,
  });

  final String studentId;
  final StudentProgram? existing;

  @override
  ConsumerState<StudentProgramFormScreen> createState() =>
      _StudentProgramFormScreenState();
}

class _StudentProgramFormScreenState
    extends ConsumerState<StudentProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _titleController.text = p.title;
      _descriptionController.text = p.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final service = ref.read(studentProgramServiceProvider);
      if (_isEdit) {
        await service.updateMetadata(
          id: widget.existing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
        );
      } else {
        await service.createEmpty(
          studentId: widget.studentId,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
        );
      }
      ref.invalidate(studentProgramsProvider(widget.studentId));
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        _isEdit ? 'Programme mis à jour' : 'Programme créé',
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
        title: Text(_isEdit ? 'Modifier le programme' : 'Nouveau programme'),
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
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
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
