class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Main shell routes
  static const String home = '/home';
  static const String translator = '/translator';
  static const String dictionary = '/dictionary';
  static const String learning = '/learning';
  static const String profile = '/profile';
  static const String history = '/history';
  static const String contribute = '/contribute';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String helpCenter = '/help-center';
  static const String userGuide = '/guide';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String about = '/about';
  static const String notifications = '/notifications';

  // Admin
  static const String admin = '/admin';
  static const String adminDashboard = '/admin';
  static const String adminContributions = '/admin/contributions';
  static const String adminSigns = '/admin/signs';
  static const String adminLearning = '/admin/learning';
  static const String adminUsers = '/admin/users';
  static const String adminModels = '/admin/models';
  static const String adminSettings = '/admin/settings';
  
  // Route Names (For pushNamed)
  static const String splashName = 'splash';
  static const String onboardingName = 'onboarding';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String forgotPasswordName = 'forgotPassword';
  static const String homeName = 'home';
  static const String translatorName = 'translator';
  static const String dictionaryName = 'dictionary';
  static const String learningName = 'learning';
  static const String profileName = 'profile';
  
  static const String signDetailName = 'signDetail';
  static const String signPracticeName = 'signPractice';
  static const String categoryName = 'category';
  static const String favoritesName = 'favorites';
  static const String lessonName = 'lesson';
  static const String progressName = 'progress';
  static const String learningManageName = 'learningManage';
  static const String adminLearningName = 'adminLearning';
  static const String historyName = 'history';
  static const String contributeName = 'contribute';
  static const String editProfileName = 'editProfile';
  static const String settingsName = 'settings';
  static const String helpCenterName = 'helpCenter';
  static const String userGuideName = 'userGuide';
  static const String privacyPolicyName = 'privacyPolicy';
  static const String termsOfServiceName = 'termsOfService';
  static const String aboutName = 'about';
  static const String notificationsName = 'notifications';
  static const String adminDashboardName = 'adminDashboard';
  static const String adminContributionsName = 'adminContributions';
  static const String adminSignsName = 'adminSigns';
  static const String adminUsersName = 'adminUsers';
  static const String adminModelsName = 'adminModels';
  static const String adminSettingsName = 'adminSettings';

  // Role spaces
  static const String teacherDashboard = '/teacher';
  static const String expertDashboard = '/expert';
  static const String teacherDashboardName = 'teacherDashboard';
  static const String teacherLearningName = 'teacherLearning';
  static const String expertDashboardName = 'expertDashboard';
  static const String expertContributionsName = 'expertContributions';
  static const String expertSignsName = 'expertSigns';
  static const String expertLearningName = 'expertLearning';
}
