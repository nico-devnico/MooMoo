import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class AppLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;

  const AppLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.black12,
      highlightColor: isDark ? Colors.white24 : Colors.white60,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 20,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.s),
        ),
      ),
    );
  }

  static Widget card() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLoader(height: 200, borderRadius: 20),
        SizedBox(height: 12),
        AppLoader(width: 150, height: 20),
        SizedBox(height: 8),
        AppLoader(width: 100, height: 16),
      ],
    );
  }
}
