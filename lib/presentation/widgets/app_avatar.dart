import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Profile picture with an initials fallback. Purely visual: callers that make
/// it interactive provide their own button and semantic label.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24,
  });

  static String initialsOf(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p.characters.first).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: size >= 64 ? 2 : 1,
          ),
        ),
        child: ClipOval(
          child: hasImage
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (_, _, _) => _buildPlaceholder(size),
                )
              : _buildPlaceholder(size),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Center(
      child: Text(
        initialsOf(name),
        style: AppTextStyles.h3.copyWith(
          color: AppColors.primary,
          fontSize: size * 0.38,
          height: 1,
        ),
      ),
    );
  }
}
