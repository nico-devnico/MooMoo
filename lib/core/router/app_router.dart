import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_routes.dart';
import '../layout/responsive.dart';
import '../../domain/providers/auth_provider.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/translator/translator_screen.dart';
import '../../presentation/screens/dictionary/dictionary_screen.dart';
import '../../presentation/screens/dictionary/sign_detail_screen.dart';
import '../../presentation/screens/dictionary/category_screen.dart';
import '../../presentation/screens/learning/learning_screen.dart';
import '../../presentation/screens/learning/lesson_screen.dart';
import '../../presentation/screens/learning/progress_screen.dart';
import '../../presentation/screens/learning/learning_manage_screen.dart';
import '../../presentation/screens/admin/admin_learning_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/contribute/contribute_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/notifications/notification_screen.dart';
import '../../presentation/screens/about/about_screen.dart';
import '../../presentation/screens/legal/help_center_screen.dart';
import '../../presentation/screens/legal/privacy_policy_screen.dart';
import '../../presentation/screens/legal/terms_of_service_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_contributions_screen.dart';
import '../../presentation/screens/admin/admin_signs_screen.dart';
import '../../presentation/screens/admin/admin_users_screen.dart';
import '../../presentation/screens/admin/admin_models_screen.dart';
import '../../presentation/screens/admin/admin_settings_screen.dart';

import '../../presentation/screens/home/main_shell.dart';
import '../../presentation/widgets/app_empty_state.dart';
import '../../l10n/app_localizations.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final session = ref.watch(currentSessionProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        body: PageContainer.form(
          child: AppEmptyState(
            title: l10n?.pageNotFound ?? 'Page not found',
            message: l10n?.pageNotFoundMessage ?? 'Sorry, this page does not exist.',
            imagePath: 'assets/images/empty_state/empty_404.gif',
            isSvg: false,
            actionLabel: l10n?.backHome ?? 'Home',
            onAction: () => context.go(AppRoutes.home),
          ),
        ),
      );
    },
    redirect: (context, state) {
      final isLoggedIn = session != null;
      final isGoingToAuth = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.onboarding ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // Skip onboarding on Web
      if (kIsWeb && state.matchedLocation == AppRoutes.onboarding) {
        return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      }

      if (!isLoggedIn && !isGoingToAuth) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isGoingToAuth && state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboardingName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRoutes.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    name: AppRoutes.notificationsName,
                    builder: (context, state) => const NotificationScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.translator,
                name: AppRoutes.translatorName,
                builder: (context, state) => const TranslatorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dictionary,
                name: AppRoutes.dictionaryName,
                builder: (context, state) => const DictionaryScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    name: AppRoutes.signDetailName,
                    builder: (context, state) => SignDetailScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'category/:id',
                    name: AppRoutes.categoryName,
                    builder: (context, state) => CategoryScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'favorites',
                    name: AppRoutes.favoritesName,
                    builder: (context, state) => const DictionaryScreen(showOnlyFavorites: true),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.learning,
                name: AppRoutes.learningName,
                builder: (context, state) => const LearningScreen(),
                routes: [
                  GoRoute(
                    path: 'progress',
                    name: AppRoutes.progressName,
                    builder: (context, state) => const ProgressScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: AppRoutes.editProfileName,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'history',
                    name: AppRoutes.historyName,
                    builder: (context, state) => const HistoryScreen(),
                  ),
                  GoRoute(
                    path: 'contribute',
                    name: AppRoutes.contributeName,
                    builder: (context, state) => const ContributeScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: AppRoutes.settingsName,
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'help-center',
                    name: AppRoutes.helpCenterName,
                    builder: (context, state) => const HelpCenterScreen(),
                  ),
                  GoRoute(
                    path: 'privacy-policy',
                    name: AppRoutes.privacyPolicyName,
                    builder: (context, state) => const PrivacyPolicyScreen(),
                  ),
                  GoRoute(
                    path: 'terms-of-service',
                    name: AppRoutes.termsOfServiceName,
                    builder: (context, state) => const TermsOfServiceScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    name: AppRoutes.aboutName,
                    builder: (context, state) => const AboutScreen(),
                  ),
                ],
            ),
          ],
        ),
        ],
      ),
      // En plein écran, hors du shell : pendant une leçon, la barre de
      // navigation ne ferait que distraire et inviter à quitter par erreur.
      GoRoute(
        path: '/lesson/:id',
        name: AppRoutes.lessonName,
        builder: (context, state) => LessonScreen(
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/learning-manage',
        name: AppRoutes.learningManageName,
        builder: (context, state) => const LearningManageScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: AppRoutes.adminDashboardName,
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'contributions',
            name: AppRoutes.adminContributionsName,
            builder: (context, state) => const AdminContributionsScreen(),
          ),
          GoRoute(
            path: 'signs',
            name: AppRoutes.adminSignsName,
            builder: (context, state) => const AdminSignsScreen(),
          ),
          GoRoute(
            path: 'learning',
            name: AppRoutes.adminLearningName,
            builder: (context, state) => const AdminLearningScreen(),
          ),
          GoRoute(
            path: 'users',
            name: AppRoutes.adminUsersName,
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: 'models',
            name: AppRoutes.adminModelsName,
            builder: (context, state) => const AdminModelsScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: AppRoutes.adminSettingsName,
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
