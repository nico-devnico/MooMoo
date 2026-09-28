import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/landmark_point.dart';
import '../../data/models/sign.dart';
import '../../l10n/app_localizations.dart';
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
      parseLandmarks(sign.landmarkData).isNotEmpty;

  static List<LandmarkPoint> parseLandmarks(Map<String, dynamic>? data) {
    final points = data?['points'];
    if (points is! List) return const [];
    return points
        .whereType<Map>()
        .map((p) => LandmarkPoint.fromJson(p.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  State<SignMedia> createState() => _SignMediaState();
}

class _SignMediaState extends State<SignMedia> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;
  bool _visible = true;
  List<LandmarkPoint>? _landmarks;

  List<LandmarkPoint> get _parsedLandmarks =>
      _landmarks ??= SignMedia.parseLandmarks(widget.sign.landmarkData);

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  /// The navigation shell keeps hidden tabs mounted: a looping video there
  /// would keep decoding frames for nobody.
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
    if (url == null) return;
    if (widget.preferStill && widget.sign.thumbnailUrl != null) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
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

    // Sous la vidéo, jamais par-dessus : le contrôle reste lisible quelle que
    // soit l'image, et ne masque pas les mains.
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
    if (widget.sign.thumbnailUrl != null) {
      return _thumbnailOr(_placeholder(l10n));
    }
    if (landmarks.isNotEmpty) {
      return LandmarkViewer(points: landmarks);
    }
    return _placeholder(l10n);
  }

  Widget _thumbnailOr(Widget fallback) {
    final url = widget.sign.thumbnailUrl;
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      memCacheWidth: 720,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => fallback,
    );
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
