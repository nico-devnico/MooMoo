import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import 'widgets/auth_form_error.dart';
import 'widgets/auth_layout.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _handleResetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (mounted) {
        AppSnackbar.showSuccess(context, l10n.forgotPasswordSent(email));
        _close();
      }
    } catch (e) {
      if (mounted) setState(() => _formError = '${l10n.errorGeneric} : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthLayout(
      title: l10n.forgotPasswordHeadline,
      subtitle: l10n.forgotPasswordSubtitle,
      onBack: _close,
      footer: Center(
        child: TextButton(
          onPressed: _close,
          child: Text(l10n.backToLogin),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormError(message: _formError),
            AppTextField(
              label: l10n.email,
              hintText: l10n.emailHint,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return l10n.requiredField;
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                  return l10n.invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              label: l10n.forgotPasswordSend,
              onPressed: _handleResetPassword,
              isLoading: _isLoading,
              stretchOnLargeScreens: true,
            ),
          ],
        ),
      ),
    );
  }
}
