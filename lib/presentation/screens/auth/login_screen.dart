import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/google_auth.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'account_status_gate.dart';
import 'widgets/auth_error_message.dart';
import 'widgets/auth_form_error.dart';
import 'widgets/auth_layout.dart';
import 'widgets/google_web_button.dart';
import 'widgets/oauth_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _formError;

  /// Set on the web, where Google's own button replaces [OAuthButton].
  Future<void>? _googleWebReady;
  final List<StreamSubscription<Object>> _googleWebSubs = [];

  @override
  void initState() {
    super.initState();
    if (GoogleAuth.isSupported && GoogleAuth.usesRenderedButton) {
      final google = GoogleAuth.instance;
      _googleWebReady = google.ensureInitialized();
      _googleWebSubs
        ..add(google.webIdTokens.listen((idToken) {
          _handleOAuthSignIn(() async {
            await ref.read(authRepositoryProvider).signInWithGoogleIdToken(idToken);
          });
        }))
        ..add(google.webErrors.listen((error) {
          if (!mounted) return;
          setState(() {
            _formError = authErrorMessage(error, AppLocalizations.of(context)!);
          });
        }));
    }
  }

  @override
  void dispose() {
    for (final sub in _googleWebSubs) {
      sub.cancel();
    }
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.requiredField;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return l10n.invalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    final v = value ?? '';
    if (v.isEmpty) return l10n.requiredField;
    if (v.length < 6) return l10n.passwordTooShort;
    return null;
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmailPassword(_emailController.text.trim(), _passwordController.text);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      if (isAccountSuspendedError(e)) {
        _showBanned(_emailController.text);
      } else {
        setState(() => _formError = authErrorMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOAuthSignIn(Future<void> Function() method) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _formError = null;
      _isLoading = true;
    });
    try {
      await method();
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted || GoogleAuth.isCancellation(e)) return;
      if (isAccountSuspendedError(e)) {
        _showBanned(GoogleAuth.instance.lastEmail);
      } else {
        setState(() => _formError = authErrorMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBanned(String? email) {
    ref.read(suspensionNoticeProvider.notifier).show(email: email);
  }

  Widget _googleButton(AppLocalizations l10n) => OAuthButton(
        label: l10n.continueWithGoogle,
        assetName: 'assets/images/google_logo.png',
        fallbackIcon: Icons.g_mobiledata,
        onTap: _isLoading
            ? null
            : () => _handleOAuthSignIn(
                  ref.read(authRepositoryProvider).signInWithGoogle,
                ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthLayout(
      title: l10n.loginHeadline,
      subtitle: l10n.loginSubtitle,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              l10n.noAccountYet,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.pushNamed(AppRoutes.registerName),
            child: Text(l10n.createAccount),
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
              label: l10n.email,
              hintText: l10n.emailHint,
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => _validateEmail(v, l10n),
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              label: l10n.password,
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              prefixIcon: Icons.lock_outline,
              validator: (v) => _validatePassword(v, l10n),
              suffixIcon: IconButton(
                tooltip: _isPasswordVisible ? l10n.hidePassword : l10n.showPassword,
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondaryLight,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.pushNamed(AppRoutes.forgotPasswordName),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, kMinTouchTarget),
                ),
                child: Text(l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            AppButton(
              label: l10n.signIn,
              isLoading: _isLoading,
              onPressed: _handleLogin,
              fullWidth: true,
              stretchOnLargeScreens: true,
            ),
            const SizedBox(height: AppSpacing.l),
            _OrDivider(label: l10n.orDivider),
            const SizedBox(height: AppSpacing.l),
            if (_googleWebReady != null)
              FutureBuilder<void>(
                future: _googleWebReady,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return _googleButton(l10n);
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(height: 44);
                  }
                  return Center(
                    child: IgnorePointer(
                      ignoring: _isLoading,
                      child: googleWebButton(
                        locale: Localizations.localeOf(context).languageCode,
                        dark: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  );
                },
              )
            else
              _googleButton(l10n),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
