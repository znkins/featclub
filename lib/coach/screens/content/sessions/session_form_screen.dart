import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/session.dart' as models;
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/session_providers.dart';

/// Formulaire de création / édition d'une séance template
/// (titre, description, durée estimée). Les blocs sont ajoutés ensuite
/// via le détail (picker).
class SessionFormScreen extends ConsumerStatefulWidget {
  const SessionFormScreen({super.key, this.existing});

  final models.Session? existing;

  @override
  ConsumerState<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends ConsumerState<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
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
      final service = ref.read(sessionServiceProvider);
      if (_isEdit) {
        await service.update(
          id: widget.existing!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
          durationMinutes: duration,
        );
        ref.invalidate(sessionDetailProvider(widget.existing!.id));
      } else {
        final coachId = ref.read(currentSessionProvider)?.user.id;
        if (coachId == null) {
          throw StateError('Session coach introuvable');
        }
        await service.create(
          coachId: coachId,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
          durationMinutes: duration,
        );
      }
      ref.invalidate(coachSessionsProvider);
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
