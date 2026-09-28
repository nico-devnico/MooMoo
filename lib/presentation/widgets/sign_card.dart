import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_icons.dart';
import '../../data/models/sign.dart';
import '../../l10n/app_localizations.dart';
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

  /// Media on top, text underneath. Nothing floats over the thumbnail: the
  /// favourite control and the difficulty chip live in the caption, where they
  /// stay legible whatever the image behind them looks like.
  Widget _buildGridVariant(BuildContext context) {
    return Semantics(
      button: true,
      label: sign.word,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildThumbnail()),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sign.word,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _FavoriteButton(
                        isFavorite: isFavorite,
                        onTap: onFavoriteTap,
                        small: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DifficultyBadge(level: sign.difficultyLevel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListVariant(BuildContext context) {
    return Semantics(
      button: true,
      label: sign.word,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.s),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: AppRadius.radiusM,
                child: _buildThumbnail(),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sign.word,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      style: AppTextStyles.bodySmall
                          .copyWith(color: _secondaryText(context)),
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
      ),
    );
  }

  Widget _buildThumbnail() {
    return ExcludeSemantics(
      child: Builder(
        builder: (context) {
          if (sign.thumbnailUrl != null) {
            return CachedNetworkImage(
              imageUrl: sign.thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              // Grid tiles never show more than this; decoding the full frame
              // for every card wastes memory while scrolling.
              memCacheWidth: 480,
              placeholder: (context, url) =>
                  Container(color: AppColors.neutral(context)),
              errorWidget: (context, url, error) => _buildPlaceholder(context),
            );
          }
          return _buildPlaceholder(context);
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.neutral(context),
      child: Icon(AppIcons.signLanguage, color: _secondaryText(context)),
    );
  }
}

Color _secondaryText(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

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
    if (onTap == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      onPressed: onTap,
      tooltip: isFavorite ? l10n.dictRemoveFavorite : l10n.dictAddFavorite,
      isSelected: isFavorite,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(
        minWidth: kMinTouchTarget,
        minHeight: kMinTouchTarget,
      ),
      padding: EdgeInsets.zero,
      icon: Icon(
        isFavorite ? AppIcons.favoriteActive : AppIcons.favorite,
        color: isFavorite ? AppColors.error : _secondaryText(context),
        size: small ? 18 : 22,
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

    final l10n = AppLocalizations.of(context)!;

    switch (level) {
      case 2:
        color = AppColors.warningLedge;
        label = l10n.difficultyMedium;
      case 3:
        color = AppColors.error;
        label = l10n.difficultyHard;
      default:
        color = AppColors.successLedge;
        label = l10n.difficultyEasy;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.radiusCircular,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
