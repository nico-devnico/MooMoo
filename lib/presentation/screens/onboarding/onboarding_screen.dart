import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/onboarding_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingPreferences _prefs = OnboardingPreferences();
  int _currentPage = 0;

  Future<void> _completeAndGo() async {
    await _prefs.setCompleted(true);
    if (!mounted) return;
    context.goNamed(AppRoutes.loginName);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = [
      OnboardingData(
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
        image: 'assets/images/onboarding/onboarding_1.gif',
        semanticsLabel: l10n.onboardingSemantics1,
      ),
      OnboardingData(
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        image: 'assets/images/onboarding/onboarding_2.gif',
        semanticsLabel: l10n.onboardingSemantics2,
      ),
      OnboardingData(
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
        image: 'assets/images/onboarding/onboarding_3.gif',
        semanticsLabel: l10n.onboardingSemantics3,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: PageContainer(
          width: ContentWidth.reading,
          padding: 0,
          child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Semantics(
                button: true,
                label: l10n.onboardingSkip,
                child: TextButton(
                  onPressed: _completeAndGo,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    l10n.onboardingSkip,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(data: pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                children: [
                  Semantics(
                    label: l10n.onboardingPageIndicator(_currentPage + 1, pages.length),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (index) => _buildDot(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: _currentPage == pages.length - 1
                        ? l10n.onboardingStart
                        : l10n.onboardingNext,
                    onPressed: () {
                      if (_currentPage < pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeAndGo();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final selected = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: selected ? 24 : 8,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  final String semanticsLabel;

  const OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.semanticsLabel,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Semantics(
              image: true,
              label: data.semanticsLabel,
              child: Image.asset(
                data.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.sign_language, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h2.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
