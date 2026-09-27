import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Loading placeholders shaped like the content they stand in for.
///
/// A spinner tells the user to wait; a skeleton tells them what is coming and
/// keeps the layout from jumping once the data lands. Every skeleton here
/// mirrors the real widget it replaces, so the two occupy the same space.
///
/// Wrap a group in a single [Skeleton] rather than shimmering each shape on
/// its own: one sweep across the whole block reads as one object loading.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, required this.child, this.label});

  final Widget child;

  /// Announced to screen readers in place of the placeholder shapes.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: label,
      liveRegion: label != null,
      child: ExcludeSemantics(
        child: Shimmer.fromColors(
          baseColor: isDark ? AppColors.neutralDark : AppColors.neutralLight,
          highlightColor:
              isDark ? AppColors.borderDark : AppColors.surfaceLight,
          child: child,
        ),
      ),
    );
  }
}

/// A plain rounded rectangle. Only meaningful inside a [Skeleton].
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    this.height = 16,
    this.radius,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonBlock.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = null,
        shape = BoxShape.circle;

  final double? width;
  final double height;
  final double? radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius ?? AppRadius.s),
      ),
    );
  }
}

/// A run of text lines, the last one short so it reads like a paragraph.
class SkeletonParagraph extends StatelessWidget {
  const SkeletonParagraph({
    super.key,
    this.lines = 2,
    this.lineHeight = 12,
    this.spacing = AppSpacing.s,
    this.lastLineFactor = 0.6,
  });

  final int lines;
  final double lineHeight;
  final double spacing;
  final double lastLineFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < lines; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              SkeletonBlock(
                width: i == lines - 1 ? width * lastLineFactor : width,
                height: lineHeight,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Matches a list row made of a round avatar, a title and a subtitle.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({
    super.key,
    this.avatarSize = 44,
    this.hasTrailing = false,
  });

  final double avatarSize;
  final bool hasTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          SkeletonBlock.circle(size: avatarSize),
          const SizedBox(width: AppSpacing.m),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 160, height: 14),
                SizedBox(height: AppSpacing.s),
                SkeletonBlock(width: 220, height: 12),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: AppSpacing.m),
            const SkeletonBlock(width: 72, height: 32, radius: AppRadius.circular),
          ],
        ],
      ),
    );
  }
}

/// A column of [SkeletonListTile], separated like the real list.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.avatarSize = 44,
    this.hasTrailing = false,
    this.label,
  });

  final int itemCount;
  final double avatarSize;
  final bool hasTrailing;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++)
            SkeletonListTile(avatarSize: avatarSize, hasTrailing: hasTrailing),
        ],
      ),
    );
  }
}

/// Matches the grid variant of a sign card: media block then a short caption.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.mediaAspectRatio = 1.0});

  final double mediaAspectRatio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: mediaAspectRatio,
            child: const SkeletonBlock(
              height: double.infinity,
              radius: AppRadius.l,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        const SkeletonBlock(width: 96, height: 14),
      ],
    );
  }
}

/// Grid of [SkeletonCard] using the same adaptive column count as the real
/// grid, so the placeholder and the content line up.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    this.itemCount = 8,
    this.maxItemWidth = 200,
    this.childAspectRatio = 0.78,
    this.label,
  });

  final int itemCount;
  final double maxItemWidth;
  final double childAspectRatio;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: adaptiveGridDelegate(
          maxItemWidth: maxItemWidth,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const SkeletonCard(),
      ),
    );
  }
}

/// Matches a row of dashboard stat cards.
class SkeletonStatCards extends StatelessWidget {
  const SkeletonStatCards({super.key, this.itemCount = 4, this.label});

  final int itemCount;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: adaptiveGridDelegate(
          maxItemWidth: 260,
          childAspectRatio: 1.9,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.radiusL,
          ),
        ),
      ),
    );
  }
}

/// Matches a detail screen: a media block, a heading and a paragraph.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key, this.mediaHeight = 220, this.label});

  final double mediaHeight;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(height: mediaHeight, radius: AppRadius.l),
          const SizedBox(height: AppSpacing.l),
          const SkeletonBlock(width: 200, height: 24),
          const SizedBox(height: AppSpacing.m),
          const SkeletonParagraph(lines: 3),
        ],
      ),
    );
  }
}
