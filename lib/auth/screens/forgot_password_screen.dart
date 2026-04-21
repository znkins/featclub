import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../shared/providers/supabase_providers.dart';
import '../../theme/app_spacing.dart';
import '../utils/auth_validators.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      await ref
          .read(authServiceProvider)
          .sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        'Email envoyé. Vérifie ta boîte mail pour réinitialiser ton mot de passe.',
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/login');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Erreur inattendue : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Mot de passe oublié',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "Indique ton email, on t'envoie un lien pour le réinitialiser.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    validator: AuthValidators.email,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Envoyer le lien'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/login');
                            }
                          },
                    child: const Text('Retour à la connexion'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
