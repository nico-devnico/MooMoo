import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Layout breakpoints in logical pixels.
///
/// `mobile < 600 <= tablet < 1024 <= desktop`, with [wide] marking the point
/// where an extended navigation rail becomes comfortable.
class Breakpoints {
  Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wide = 1360;
}

enum FormFactor { mobile, tablet, desktop }

/// Maximum readable width for a kind of content.
///
/// Anything wider than these values on a large screen turns into edge-to-edge
/// text and stretched controls, which is what these caps exist to prevent.
enum ContentWidth {
  /// Login, registration, settings forms, single-column dialogs.
  form(480),

  /// Long-form prose: legal pages, help center, about.
  reading(720),

  /// Detail pages mixing media and text.
  detail(960),

  /// Dashboards, data tables, multi-column grids.
  dashboard(1280),

  /// Opt out of the cap (full-bleed media, camera, maps).
  full(double.infinity);

  const ContentWidth(this.maxWidth);

  final double maxWidth;
}

/// The smallest tappable size we accept on touch form factors.
const double kMinTouchTarget = 48.0;

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  FormFactor get formFactor {
    final width = screenWidth;
    if (width >= Breakpoints.desktop) return FormFactor.desktop;
    if (width >= Breakpoints.tablet) return FormFactor.tablet;
    return FormFactor.mobile;
  }

  bool get isMobile => formFactor == FormFactor.mobile;
  bool get isTablet => formFactor == FormFactor.tablet;
  bool get isDesktop => formFactor == FormFactor.desktop;

  /// True from the tablet breakpoint upwards.
  bool get isAtLeastTablet => !isMobile;

  /// True once a permanent side navigation fits comfortably.
  bool get hasSideNavigation => screenWidth >= Breakpoints.desktop;

  /// True once that side navigation can show labels next to the icons.
  bool get hasExtendedSideNavigation => screenWidth >= Breakpoints.wide;

  /// Picks a value per form factor, falling back to the next smaller one.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (formFactor) {
      case FormFactor.mobile:
        return mobile;
      case FormFactor.tablet:
        return tablet ?? mobile;
      case FormFactor.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Horizontal gutter for a given available width.
double gutterFor(double availableWidth) {
  if (availableWidth >= Breakpoints.desktop) return AppSpacing.xl;
  if (availableWidth >= Breakpoints.tablet) return AppSpacing.l;
  return AppSpacing.m;
}

/// Centers page content and caps it at a readable width.
///
/// Sizing is driven by the incoming constraints rather than the window, so it
/// behaves correctly inside a navigation rail or a split view. Vertical
/// constraints are passed through loosened, which keeps `Expanded`, slivers and
/// scroll views working exactly as they did before.
class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.width = ContentWidth.dashboard,
    this.padding,
    this.verticalPadding = 0,
    this.alignment = Alignment.topCenter,
  });

  /// Shorthand for auth screens and other single-column forms.
  const PageContainer.form({
    super.key,
    required this.child,
    this.padding,
    this.verticalPadding = AppSpacing.l,
    this.alignment = Alignment.center,
  }) : width = ContentWidth.form;

  /// Shorthand for long-form text screens.
  const PageContainer.reading({
    super.key,
    required this.child,
    this.padding,
    this.verticalPadding = 0,
    this.alignment = Alignment.topCenter,
  }) : width = ContentWidth.reading;

  final Widget child;
  final ContentWidth width;

  /// Overrides the adaptive horizontal gutter.
  final double? padding;
  final double verticalPadding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final horizontal = padding ?? gutterFor(available);
        final inner = available.isFinite
            ? (available - horizontal * 2).clamp(0.0, double.infinity)
            : width.maxWidth;
        final effective = inner < width.maxWidth ? inner : width.maxWidth;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: verticalPadding,
          ),
          child: Align(
            alignment: alignment,
            child: SizedBox(
              width: effective.isFinite ? effective : null,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Grid delegate that derives its column count from the available width
/// instead of hardcoding it.
SliverGridDelegate adaptiveGridDelegate({
  required double maxItemWidth,
  double childAspectRatio = 1,
  double spacing = AppSpacing.m,
  double? mainAxisSpacing,
}) {
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: maxItemWidth,
    crossAxisSpacing: spacing,
    mainAxisSpacing: mainAxisSpacing ?? spacing,
    childAspectRatio: childAspectRatio,
  );
}

/// Number of columns that fit in [availableWidth] for items of
/// [maxItemWidth], clamped to [min]..[max].
int adaptiveColumnCount(
  double availableWidth, {
  double maxItemWidth = 320,
  int min = 1,
  int max = 6,
}) {
  if (!availableWidth.isFinite || availableWidth <= 0) return min;
  final count = (availableWidth / maxItemWidth).floor();
  return count.clamp(min, max);
}
