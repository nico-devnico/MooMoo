import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/app_settings_provider.dart';

/// Logo configured in the admin settings, or the bundled one.
class AppLogo extends ConsumerWidget {
  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.excludeFromSemantics = false,
  });

  static const asset = 'assets/images/logo.png';

  final double? width;
  final double? height;
  final BoxFit fit;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(appSettingsProvider).value?.logoUrl;
    final fallback = Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      excludeFromSemantics: excludeFromSemantics,
    );
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, _) => SizedBox(width: width, height: height),
      errorWidget: (_, _, _) => fallback,
    );
  }
}
