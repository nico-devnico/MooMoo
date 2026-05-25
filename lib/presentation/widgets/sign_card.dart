import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/sign.dart';
import 'app_card.dart';

enum SignCardVariant { grid, list }

class SignCard extends StatelessWidget {
  final Sign sign;
  final SignCardVariant variant;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const SignCard({
    super.key,
    required this.sign,
    this.variant = SignCardVariant.grid,
    required this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == SignCardVariant.list) {
      return _buildListVariant(context);
    }
    return _buildGridVariant(context);
  }

  Widget _buildGridVariant(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildThumbnail(),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FavoriteButton(
                    isFavorite: isFavorite,
                    onTap: onFavoriteTap,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: _DifficultyBadge(level: sign.difficultyLevel),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s),
            child: Text(
              sign.word,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListVariant(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusM,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildThumbnail(),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sign.word,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    _FavoriteButton(
                      isFavorite: isFavorite,
                      onTap: onFavoriteTap,
                      small: true,
                    ),
                  ],
                ),
                if (sign.description != null)
                  Text(
                    sign.description!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppSpacing.s),
                _DifficultyBadge(level: sign.difficultyLevel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (sign.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: sign.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: AppColors.neutralLight),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.neutralLight,
      child: const Icon(Icons.image_outlined, color: AppColors.textSecondaryLight),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onTap;
  final bool small;

  const _FavoriteButton({
    required this.isFavorite,
    this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(small ? 4 : 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.error : AppColors.textSecondaryLight,
          size: small ? 16 : 20,
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final int level;

  const _DifficultyBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (level) {
      case 1:
        color = AppColors.secondary;
        label = 'Facile';
        break;
      case 2:
        color = AppColors.warning;
        label = 'Moyen';
        break;
      case 3:
        color = AppColors.error;
        label = 'Difficile';
        break;
      default:
        color = AppColors.secondary;
        label = 'Facile';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
