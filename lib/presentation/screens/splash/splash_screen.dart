import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/onboarding_preferences.dart';
import '../../../domain/providers/app_settings_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/app_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final session = ref.read(currentSessionProvider);
    if (session != null) {
      context.goNamed(AppRoutes.homeName);
      return;
    }

    if (kIsWeb) {
      context.goNamed(AppRoutes.loginName);
      return;
    }

    final completed = await OnboardingPreferences().isCompleted();
    if (!mounted) return;
    if (completed) {
      context.goNamed(AppRoutes.loginName);
    } else {
      context.goNamed(AppRoutes.onboardingName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageContainer.form(
        child: Semantics(
          label: ref.watch(appNameProvider),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(width: 120, height: 120),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
