import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/sign.dart';
import '../../data/models/sign_landmarks.dart';
import '../../data/services/media_url.dart';
import '../../l10n/app_localizations.dart';
import 'animated_network_image.dart';
import 'landmark_viewer/landmark_viewer.dart';

/// Shows how a sign is performed, with the richest medium available: a muted
/// looping video, then the thumbnail, then the recorded hand landmarks.
///
/// Muted on purpose: a sign is visual, and autoplay with sound is blocked on
/// the web anyway. Nothing here relies on audio, so deaf and hearing learners
/// get exactly the same information.
class SignMedia extends StatefulWidget {
  const SignMedia({
    super.key,
    required this.sign,
    this.autoplay = true,
    this.showReplay = true,
    this.preferStill = false,
    this.borderRadius,
  });

  final Sign sign;
  final bool autoplay;
  final bool showReplay;

  /// Uses the thumbnail when there is one instead of starting the video.
  /// For grids of answers, where several videos at once would be noisy.
  final bool preferStill;
  final BorderRadius? borderRadius;

  static bool hasVisual(Sign sign) =>
      sign.videoUrl != null ||
      sign.thumbnailUrl != null ||
      !SignLandmarks.parse(sign.landmarkData).isEmpty;

  /// GIFs are animated images, not videos: the video player can't decode
  /// them.
  static bool isAnimatedImage(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    final q = Uri.tryParse(url)?.queryParameters['url']?.toLowerCase() ?? '';
    return path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.endsWith('.apng') ||
        q.endsWith('.gif') ||
        q.endsWith('.webp') ||
        q.contains('.gif');
  }

  @override
  State<SignMedia> createState() => _SignMediaState();
}

class _SignMediaState extends State<SignMedia> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;
  bool _visible = true;
  SignLandmarks? _landmarks;

  SignLandmarks get _parsedLandmarks =>
      _landmarks ??= SignLandmarks.parse(widget.sign.landmarkData);

  String? get _rawGifUrl {
    final url = widget.sign.videoUrl;
    return url != null && SignMedia.isAnimatedImage(url) ? url : null;
  }

  String? get _gifUrl {
    final raw = _rawGifUrl;
    if (raw == null) return null;
    final resolved = resolveSignMediaUrl(raw);
    return resolved.isEmpty ? null : resolved;
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (!visible) {
      controller.pause();
    } else if (widget.autoplay) {
      controller.play();
    }
  }

  @override
  void didUpdateWidget(SignMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sign.id != widget.sign.id) {
      _controller?.dispose();
      _controller = null;
      _videoFailed = false;
      _landmarks = null;
      _initVideo();
    }
  }

  void _initVideo() {
    final url = widget.sign.videoUrl;
    if (url == null || _rawGifUrl != null) return;
    if (widget.preferStill && widget.sign.thumbnailUrl != null) return;
    final resolved = resolveSignMediaUrl(url);
    final controller = VideoPlayerController.networkUrl(Uri.parse(resolved));
    _controller = controller;
    controller.initialize().then((_) async {
      if (!mounted || _controller != controller) return;
      await controller.setVolume(0);
      await controller.setLooping(true);
      if (widget.autoplay && _visible) await controller.play();
      if (mounted) setState(() {});
    }).catchError((Object _) {
      if (mounted && _controller == controller) {
        setState(() => _videoFailed = true);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _replay() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller
      ..seekTo(Duration.zero)
      ..play();
  }

  bool get _playsVideo =>
      _controller != null && !_videoFailed && _controller!.value.isInitialized;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = widget.borderRadius ?? AppRadius.radiusL;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final media = ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: isDark ? AppColors.neutralDark : AppColors.neutralLight,
        child: _buildContent(context),
      ),
    );

    if (!widget.showReplay || _controller == null) return media;

    return Column(
      children: [
        Expanded(child: media),
        const SizedBox(height: AppSpacing.s),
        TextButton.icon(
          onPressed: _playsVideo ? _replay : null,
          icon: const Icon(AppIcons.refresh, size: 18),
          label: Text(l10n.lessonReplay),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;

    // GIF prioritaire : ne jamais passer par le lecteur vidéo.
    final gif = _gifUrl;
    if (gif != null) {
      return _GifPane(url: gif, fallback: _placeholder(l10n));
    }

    if (controller != null && !_videoFailed) {
      if (!controller.value.isInitialized) {
        return _thumbnailOr(const Center(child: CircularProgressIndicator()));
      }
      return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    final landmarks = _parsedLandmarks;
    final landmarkView = landmarks.isEmpty
        ? null
        : LandmarkViewer(landmarks: landmarks, showControls: widget.showReplay);
    final fallback = landmarkView ?? _placeholder(l10n);

    if (landmarks.isAnimated && !widget.preferStill) return landmarkView!;
    if (widget.sign.thumbnailUrl != null) return _thumbnailOr(fallback);
    return fallback;
  }

  Widget _thumbnailOr(Widget fallback) {
    final url = widget.sign.thumbnailUrl;
    if (url == null) return fallback;
    final resolved = resolveSignMediaUrl(url);
    if (resolved.isEmpty) return fallback;
    return _GifPane(url: resolved, fallback: fallback);
  }

  Widget _placeholder(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.signLanguage, size: 40, color: AppColors.textSecondary(context)),
            const SizedBox(height: AppSpacing.s),
            Text(
              l10n.lessonNoMedia,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Affiche un GIF/image réseau en préservant l'animation (pas CachedNetworkImage).
class _GifPane extends StatelessWidget {
  const _GifPane({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (SignMedia.isAnimatedImage(url)) {
      return AnimatedNetworkImage(
        url: url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      memCacheWidth: 720,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, url, error) => fallback,
    );
  }
}
