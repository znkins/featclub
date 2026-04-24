import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/student_session_block.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/student_program_providers.dart';

/// Création ou édition d'un bloc élève (titre + description).
///
/// Mode création : `sessionId` requis.
/// Mode édition : `existing` requis.
class StudentBlockFormScreen extends ConsumerStatefulWidget {
  const StudentBlockFormScreen({
    super.key,
    this.sessionId,
    this.programId,
    this.existing,
  }) : assert(sessionId != null || existing != null,
            'sessionId requis en création');

  final String? sessionId;

  /// Utilisé en création pour invalider l'éditeur programme dont la
  /// `blockCount` de la séance parente change quand on ajoute un bloc.
  final String? programId;
  final StudentSessionBlock? existing;

  @override
  ConsumerState<StudentBlockFormScreen> createState() =>
      _StudentBlockFormScreenState();
}

class _StudentBlockFormScreenState
    extends ConsumerState<StudentBlockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    if (b != null) {
      _titleController.text = b.title;
      _descriptionController.text = b.description ?? '';
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
      String sessionIdToInvalidate;
      if (_isEdit) {
        final updated = await service.updateBlockMetadata(
          id: widget.existing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
        );
        sessionIdToInvalidate = updated.studentSessionId;
        ref.invalidate(
          studentBlockEditorDetailProvider(widget.existing!.id),
        );
      } else {
        await service.createEmptyBlock(
          sessionId: widget.sessionId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
        );
        sessionIdToInvalidate = widget.sessionId!;
        // Création d'un bloc → la `blockCount` de la séance change, donc
        // l'éditeur programme doit refetch quand on y remonte.
        if (widget.programId != null) {
          ref.invalidate(
            studentProgramEditorDetailProvider(widget.programId!),
          );
        }
      }
      ref.invalidate(
        studentSessionEditorDetailProvider(sessionIdToInvalidate),
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        _isEdit ? 'Bloc mis à jour' : 'Bloc créé',
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
        title: Text(_isEdit ? 'Modifier le bloc' : 'Nouveau bloc'),
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
