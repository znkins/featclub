import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/student_session_exercise.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../theme/app_spacing.dart';
import '../../../providers/student_program_providers.dart';
import '../../../widgets/editor_breadcrumb.dart';

/// Éditeur d'un exercice élève (titre + vidéo + paramètres prescriptifs).
///
/// Deux modes :
/// - création ad hoc (`exerciseId == null`) : tous les champs vides, on
///   enregistre avec `createEmptyExercise`.
/// - édition (`exerciseId != null`) : charge l'exercice, permet de modifier
///   tous les champs puis enregistrer, avec action supprimer dans l'AppBar.
///
/// Pas de liste d'enfants ici donc pas de détail en lecture seule : on ouvre
/// directement le formulaire (simple et cohérent).
class StudentExerciseEditorScreen extends ConsumerStatefulWidget {
  const StudentExerciseEditorScreen._({
    required this.studentId,
    required this.programId,
    required this.programTitle,
    required this.sessionId,
    required this.sessionTitle,
    required this.blockId,
    required this.blockTitle,
    this.exerciseId,
  });

  final String studentId;
  final String programId;
  final String programTitle;
  final String sessionId;
  final String sessionTitle;
  final String blockId;
  final String blockTitle;
  final String? exerciseId;

  /// Route de création ad hoc (exercice vide à construire).
  static Route<void> createRoute({
    required String studentId,
    required String programId,
    required String programTitle,
    required String sessionId,
    required String sessionTitle,
    required String blockId,
    required String blockTitle,
  }) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: EditorRoutes.exercise),
      builder: (_) => StudentExerciseEditorScreen._(
        studentId: studentId,
        programId: programId,
        programTitle: programTitle,
        sessionId: sessionId,
        sessionTitle: sessionTitle,
        blockId: blockId,
        blockTitle: blockTitle,
      ),
    );
  }

  /// Route d'édition d'un exercice existant.
  static Route<void> editRoute({
    required String studentId,
    required String programId,
    required String programTitle,
    required String sessionId,
    required String sessionTitle,
    required String blockId,
    required String blockTitle,
    required String exerciseId,
  }) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: EditorRoutes.exercise),
      builder: (_) => StudentExerciseEditorScreen._(
        studentId: studentId,
        programId: programId,
        programTitle: programTitle,
        sessionId: sessionId,
        sessionTitle: sessionTitle,
        blockId: blockId,
        blockTitle: blockTitle,
        exerciseId: exerciseId,
      ),
    );
  }

  @override
  ConsumerState<StudentExerciseEditorScreen> createState() =>
      _StudentExerciseEditorScreenState();
}

class _StudentExerciseEditorScreenState
    extends ConsumerState<StudentExerciseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _repsController = TextEditingController();
  final _loadController = TextEditingController();
  final _intensityController = TextEditingController();
  final _restController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.exerciseId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _repsController.dispose();
    _loadController.dispose();
    _intensityController.dispose();
    _restController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _fillFrom(StudentSessionExercise e) {
    if (_loaded) return;
    _loaded = true;
    _titleController.text = e.title;
    _descriptionController.text = e.description ?? '';
    _videoUrlController.text = e.videoUrl ?? '';
    _repsController.text = e.reps ?? '';
    _loadController.text = e.load ?? '';
    _intensityController.text = e.intensity ?? '';
    _restController.text = e.rest ?? '';
    _noteController.text = e.note ?? '';
  }

  Future<void> _openVideo() async {
    final url = _videoUrlController.text.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppSnackbar.showError(context, 'URL invalide');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppSnackbar.showError(context, 'Impossible d\'ouvrir la vidéo');
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(studentProgramServiceProvider);
      if (_isEdit) {
        await service.updateExercise(
          id: widget.exerciseId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
          videoUrl: _videoUrlController.text,
          reps: _repsController.text,
          load: _loadController.text,
          intensity: _intensityController.text,
          rest: _restController.text,
          note: _noteController.text,
        );
        ref.invalidate(studentExerciseProvider(widget.exerciseId!));
      } else {
        await service.createEmptyExercise(
          blockId: widget.blockId,
          title: _titleController.text.trim(),
          description: _descriptionController.text,
          videoUrl: _videoUrlController.text,
          reps: _repsController.text,
          load: _loadController.text,
          intensity: _intensityController.text,
          rest: _restController.text,
          note: _noteController.text,
        );
      }
      ref.invalidate(studentBlockEditorDetailProvider(widget.blockId));
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

  Future<void> _delete() async {
    if (!_isEdit) return;
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Supprimer l\'exercice',
      message:
          'Supprimer « ${_titleController.text.trim()} » ? Les paramètres personnalisés seront définitivement perdus.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!confirm) return;
    try {
      await ref
          .read(studentProgramServiceProvider)
          .deleteExercise(widget.exerciseId!);
      ref.invalidate(studentBlockEditorDetailProvider(widget.blockId));
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Exercice supprimé');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Source de vérité pour le libellé AppBar + breadcrumb : on dérive du
    // provider Riverpod (les données fraîches du serveur), pas du controller
    // local — celui-ci reflète les saisies en cours et ne notifie pas
    // l'AppBar des changements.
    final async = _isEdit
        ? ref.watch(studentExerciseProvider(widget.exerciseId!))
        : null;
    final titleLabel = _isEdit
        ? (async?.valueOrNull?.title.trim().isNotEmpty == true
            ? async!.value!.title.trim()
            : 'Exercice')
        : 'Nouvel exercice';
    final studentName = resolveStudentName(ref, widget.studentId);

    final breadcrumb = EditorBreadcrumb(
      parents: [
        EditorCrumb(
          label: studentName,
          routeName: EditorRoutes.studentDetail,
        ),
        EditorCrumb(
          label: widget.programTitle,
          routeName: EditorRoutes.program,
        ),
        EditorCrumb(
          label: widget.sessionTitle,
          routeName: EditorRoutes.session,
        ),
        if (widget.blockTitle.isNotEmpty)
          EditorCrumb(
            label: widget.blockTitle,
            routeName: EditorRoutes.block,
          ),
      ],
      current: titleLabel,
    );

    if (!_isEdit) {
      return Scaffold(
        appBar: AppBar(
          title: Text(titleLabel),
          bottom: breadcrumb,
        ),
        body: _buildForm(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titleLabel,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          async!.maybeWhen(
            data: (_) => IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(LucideIcons.trash2),
              onPressed: _delete,
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
        bottom: breadcrumb,
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: 'Impossible de charger l\'exercice.\n$e',
          onRetry: () =>
              ref.invalidate(studentExerciseProvider(widget.exerciseId!)),
        ),
        data: (exercise) {
          _fillFrom(exercise);
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
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
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('URL vidéo', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _videoUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'https://…',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Lire la vidéo',
                onPressed: _openVideo,
                icon: const Icon(LucideIcons.playCircle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Paramètres', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _ParamField(
            label: 'Répétitions',
            controller: _repsController,
            hint: 'ex. 3×10',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ParamField(
            label: 'Charge',
            controller: _loadController,
            hint: 'ex. 40 kg',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ParamField(
            label: 'Intensité',
            controller: _intensityController,
            hint: 'ex. RPE 8',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ParamField(
            label: 'Repos',
            controller: _restController,
            hint: 'ex. 90 s',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Note', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _noteController,
            minLines: 3,
            maxLines: null,
            keyboardType: TextInputType.multiline,
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
    );
  }
}

class _ParamField extends StatelessWidget {
  const _ParamField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
