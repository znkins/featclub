import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/exercise.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/exercise_providers.dart';

/// Création / édition d'un exercice.
class ExerciseFormScreen extends ConsumerStatefulWidget {
  const ExerciseFormScreen({super.key, this.existing});

  final Exercise? existing;

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _videoUrlController = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _descriptionController.text = e.description ?? '';
      _categoryController.text = e.category ?? '';
      _videoUrlController.text = e.videoUrl ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  /// URL facultative : si renseignée, doit être un http(s) parsable.
  String? _validateOptionalUrl(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    final uri = Uri.tryParse(s);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'URL invalide (https://… attendu)';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    try {
      final service = ref.read(exerciseServiceProvider);
      if (_isEdit) {
        await service.update(
          id: widget.existing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
          category: _categoryController.text,
          videoUrl: _videoUrlController.text,
        );
      } else {
        final coachId = ref.read(currentSessionProvider)?.user.id;
        if (coachId == null) {
          throw StateError('Session coach introuvable');
        }
        await service.create(
          coachId: coachId,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
          category: _categoryController.text,
          videoUrl: _videoUrlController.text,
        );
      }
      ref.invalidate(coachExercisesProvider);
      if (_isEdit) {
        ref.invalidate(exerciseByIdProvider(widget.existing!.id));
      }
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        _isEdit ? 'Exercice mis à jour' : 'Exercice créé',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier l\'exercice' : 'Nouvel exercice'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _LabelledField(
              label: 'Titre *',
              child: TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
              ),
            ),
            _LabelledField(
              label: 'Description',
              child: TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
            _LabelledField(
              label: 'Catégorie',
              child: TextFormField(
                controller: _categoryController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Jambes, Dos, Cardio, ...',
                ),
              ),
            ),
            _LabelledField(
              label: 'URL vidéo',
              child: TextFormField(
                controller: _videoUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'https://...',
                ),
                validator: _validateOptionalUrl,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
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

class _LabelledField extends StatelessWidget {
  const _LabelledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
