import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Shared chrome for login, registration and password reset.
///
/// On a large screen the form sits in a card next to a branded panel, so the
/// page fills the window without stretching the inputs. Below the desktop
/// breakpoint the panel collapses into a compact header and the card loses its
/// surface, leaving a plain single column.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Pinned under the form, e.g. the "already have an account?" line.
  final Widget? footer;

  /// Shows a back affordance above the title when provided.
  final VoidCallback? onBack;

  static const double _cardMaxWidth = 460;

  @override
  Widget build(BuildContext context) {
    final split = context.hasSideNavigation;

    return Scaffold(
      backgroundColor: split
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).scaffoldBackgroundColor,
      body: split ? _buildSplit(context) : _buildStacked(context),
    );
  }

  Widget _buildSplit(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 5, child: _BrandPanel()),
        Expanded(
          flex: 6,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _cardMaxWidth),
                  child: _FormCard(
                    title: title,
                    subtitle: subtitle,
                    onBack: onBack,
                    footer: footer,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStacked(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: context.isMobile ? AppSpacing.l : AppSpacing.xl,
            vertical: AppSpacing.l,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _cardMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _CompactBrandHeader(),
                const SizedBox(height: AppSpacing.xl),
                _FormCard(
                  title: title,
                  subtitle: subtitle,
                  onBack: onBack,
                  footer: footer,
                  flat: true,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.onBack,
    this.flat = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onBack != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.back),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                minimumSize: const Size(0, kMinTouchTarget),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        Text(title, style: AppTextStyles.h1.copyWith(fontSize: 28)),
        const SizedBox(height: AppSpacing.s),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        child,
        if (footer != null) ...[
          const SizedBox(height: AppSpacing.l),
          footer!,
        ],
      ],
    );

    if (flat) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.neutralDark : AppColors.neutralLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: content,
      ),
    );
  }
}

/// Gradient column shown next to the form from the desktop breakpoint up.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(top: -80, right: -60, child: _Bubble(size: 260)),
          const Positioned(bottom: -100, left: -80, child: _Bubble(size: 320)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandMark(size: 64, onGradient: true),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.authBrandHeadline,
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      l10n.authBrandTagline,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _Feature(
                    icon: Icons.sign_language_outlined,
                    label: l10n.authFeatureTranslate,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _Feature(
                    icon: Icons.menu_book_outlined,
                    label: l10n.authFeatureLearn,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _Feature(
                    icon: Icons.groups_outlined,
                    label: l10n.authFeatureCommunity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo and wordmark shown above the form on tablet and mobile.
class _CompactBrandHeader extends StatelessWidget {
  const _CompactBrandHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const _BrandMark(size: 56),
        const SizedBox(height: AppSpacing.m),
        Text(
          l10n.authBrandTagline,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size, this.onGradient = false});

  final double size;
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'MooMoo',
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.14),
        decoration: BoxDecoration(
          color: onGradient
              ? Colors.white.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.sign_language,
            size: size * 0.5,
            color: onGradient ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft decorative circle behind the brand panel content.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
