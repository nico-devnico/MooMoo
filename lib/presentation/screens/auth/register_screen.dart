import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import 'widgets/auth_form_error.dart';
import 'widgets/auth_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isDeaf = false;
  bool _isLoading = false;
  double _passwordStrength = 0;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordStrength = 0;
      } else if (value.length < 6) {
        _passwordStrength = 0.25;
      } else if (value.length < 8) {
        _passwordStrength = 0.5;
      } else if (RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(value)) {
        _passwordStrength = 1.0;
      } else {
        _passwordStrength = 0.75;
      }
    });
  }

  Color _strengthColor() {
    if (_passwordStrength <= 0.25) return AppColors.error;
    if (_passwordStrength <= 0.5) return AppColors.warning;
    if (_passwordStrength <= 0.75) return AppColors.info;
    return AppColors.success;
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmailPassword(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
            isDeaf: _isDeaf,
          );

      if (mounted) {
        AppSnackbar.showSuccess(context, l10n.accountCreatedVerifyEmail);
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) setState(() => _formError = '${l10n.registerError} : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthLayout(
      title: l10n.registerHeadline,
      subtitle: l10n.registerSubtitle,
      onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              l10n.alreadyHaveAccount,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.login),
            child: Text(l10n.signIn),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormError(message: _formError),
            AppTextField(
              label: l10n.fullName,
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              label: l10n.email,
              hintText: l10n.emailHint,
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return l10n.requiredField;
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return l10n.invalidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              label: l10n.password,
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              prefixIcon: Icons.lock_outline,
              onChanged: _onPasswordChanged,
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.requiredField;
                if (v.length < 6) return l10n.passwordTooShort;
                return null;
              },
              suffixIcon: IconButton(
                tooltip: _isPasswordVisible ? l10n.hidePassword : l10n.showPassword,
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondaryLight,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Semantics(
              label: l10n.passwordStrength,
              value: '${(_passwordStrength * 100).round()}%',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: AppColors.neutralLight,
                  valueColor: AlwaysStoppedAnimation<Color>(_strengthColor()),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              label: l10n.confirmPassword,
              controller: _confirmPasswordController,
              obscureText: !_isPasswordVisible,
              prefixIcon: Icons.lock_reset_outlined,
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.requiredField;
                if (v != _passwordController.text) return l10n.passwordsDoNotMatch;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.m),
            _DeafToggle(
              value: _isDeaf,
              label: l10n.deafUser,
              onChanged: (v) => setState(() => _isDeaf = v),
            ),
            const SizedBox(height: AppSpacing.l),
            AppButton(
              label: l10n.signUp,
              isLoading: _isLoading,
              onPressed: _handleRegister,
              stretchOnLargeScreens: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeafToggle extends StatelessWidget {
  const _DeafToggle({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutralDark : AppColors.neutralLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
