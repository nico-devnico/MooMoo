import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../widgets/skeletons.dart';

/// Mirrors a dataset / experiment / registry card: icon, two text lines,
/// badges, a row of metric chips and a row of actions.
class MlCardListSkeleton extends StatelessWidget {
  const MlCardListSkeleton({super.key, required this.label, this.count = 2});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: AppRadius.radiusL,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBlock(width: 44, height: 44, radius: AppRadius.m),
                      SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBlock(width: 180, height: 16),
                            SizedBox(height: AppSpacing.s),
                            SkeletonBlock(width: 240, height: 12),
                          ],
                        ),
                      ),
                      SkeletonBlock(width: 80, height: 26, radius: AppRadius.circular),
                    ],
                  ),
                  SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      SkeletonBlock(width: 110, height: 28, radius: AppRadius.s),
                      SkeletonBlock(width: 96, height: 28, radius: AppRadius.s),
                      SkeletonBlock(width: 130, height: 28, radius: AppRadius.s),
                      SkeletonBlock(width: 90, height: 28, radius: AppRadius.s),
                    ],
                  ),
                  SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      SkeletonBlock(width: 130, height: 40, radius: AppRadius.circular),
                      SkeletonBlock(width: 120, height: 40, radius: AppRadius.circular),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mirrors the job list: status icon, title, subtitle, progress bar.
class MlRowListSkeleton extends StatelessWidget {
  const MlRowListSkeleton({super.key, required this.label, this.count = 4});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: AppRadius.radiusL,
        ),
        child: Column(
          children: [
            for (var i = 0; i < count; i++)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock.circle(size: 24),
                    SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBlock(width: 200, height: 16),
                          SizedBox(height: AppSpacing.s),
                          SkeletonBlock(width: 150, height: 12),
                          SizedBox(height: AppSpacing.s),
                          SkeletonBlock(height: 6, radius: AppRadius.circular),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.m),
                    SkeletonBlock(width: 40, height: 14),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors a detail view: metric chips then chart blocks.
class MlDetailSkeleton extends StatelessWidget {
  const MlDetailSkeleton({super.key, required this.label, this.charts = 2});

  final String label;
  final int charts;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              SkeletonBlock(width: 110, height: 28, radius: AppRadius.s),
              SkeletonBlock(width: 96, height: 28, radius: AppRadius.s),
              SkeletonBlock(width: 130, height: 28, radius: AppRadius.s),
            ],
          ),
          for (var i = 0; i < charts; i++) ...[
            const SizedBox(height: AppSpacing.l),
            const SkeletonBlock(width: 160, height: 16),
            const SizedBox(height: AppSpacing.s),
            const SkeletonBlock(height: 200, radius: AppRadius.m),
          ],
        ],
      ),
    );
  }
}
