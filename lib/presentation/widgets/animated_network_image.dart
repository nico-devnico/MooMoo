import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Affiche une image réseau en préservant l'animation GIF/WebP.
///
/// [CachedNetworkImage] décode souvent uniquement la 1ʳᵉ frame (surtout sur
/// le web / CanvasKit). [Image.network] + stratégie HTML sur le web restaure
/// le mouvement.
class AnimatedNetworkImage extends StatelessWidget {
  const AnimatedNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholder,
    this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      // Sur le web, le décodeur HTML anime les GIF ; CanvasKit les fige.
      webHtmlElementStrategy:
          kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder?.call(context) ??
            const Center(child: CircularProgressIndicator());
      },
      errorBuilder: errorBuilder ??
          (context, error, stack) =>
              placeholder?.call(context) ?? const SizedBox.shrink(),
    );
  }
}
