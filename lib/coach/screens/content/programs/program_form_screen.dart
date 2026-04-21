import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/program.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/program_providers.dart';

class ProgramFormScreen extends ConsumerStatefulWidget {
  const ProgramFormScreen({super.key, this.existing});

  final Program? existing;

  @override
  ConsumerState<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends ConsumerState<ProgramFormScreen> {
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
      final service = ref.read(programServiceProvider);
      if (_isEdit) {
        await service.update(
          id: widget.existing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
        );
        ref.invalidate(programDetailProvider(widget.existing!.id));
      } else {
        final coachId = ref.read(currentSessionProvider)?.user.id;
        if (coachId == null) {
          throw StateError('Session coach introuvable');
        }
        await service.create(
          coachId: coachId,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
        );
      }
      ref.invalidate(coachProgramsProvider);
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
