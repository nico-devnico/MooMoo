import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for splash animation
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!mounted) return;

    final authState = ref.read(authStateChangesProvider);
    
    // The redirect logic in GoRouter will handle the actual navigation
    // but we can trigger a refresh if needed.
    if (authState.value != null) {
      context.goNamed(AppRoutes.homeName);
    } else {
      if (kIsWeb) {
        context.goNamed(AppRoutes.loginName);
      } else {
        context.goNamed(AppRoutes.onboardingName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              // On s'assure que le logo est bien visible sur fond blanc
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF09090B)), // Zinc-ish dark for contrast
            ),
          ],
        ),
      ),
    );
  }
}
