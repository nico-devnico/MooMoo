import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../data/models/landmark_point.dart';
import '../../widgets/landmark_viewer/landmark_viewer.dart';
import '../../widgets/sign_card.dart';

class SignDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const SignDetailScreen({super.key, required this.id});

  @override
  ConsumerState<SignDetailScreen> createState() => _SignDetailScreenState();
}

class _SignDetailScreenState extends ConsumerState<SignDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _initVideo(String url) {
    if (_videoController != null) return;
    
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: true,
      aspectRatio: 16 / 9,
      placeholder: Container(color: Colors.black),
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primary,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signAsync = ref.watch(signDetailProvider(widget.id));

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: signAsync.when(
            data: (sign) {
              if (sign == null) return const Center(child: Text('Signe non trouvé'));
              
              if (sign.videoUrl != null) _initVideo(sign.videoUrl!);

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 400,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : Container(color: Colors.black),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sign.word, style: AppTextStyles.h1),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _Badge(label: 'LSF', color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      _Badge(
                                        label: sign.difficultyLevel == 1 ? 'Facile' : sign.difficultyLevel == 2 ? 'Moyen' : sign.difficultyLevel == 3 ? 'Difficile' : 'Inconnu',
                                        color: sign.difficultyLevel == 1 ? AppColors.secondary : sign.difficultyLevel == 2 ? AppColors.warning : AppColors.error,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.favorite_border, color: AppColors.primary, size: 28),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        
                        Text('Visualisation Landmarks', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.m),
                        SizedBox(
                          height: 400,
                          child: LandmarkViewer(
                            points: _parseLandmarks(sign.landmarkData),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        Text('Description', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          sign.description ?? 'Aucune description disponible.',
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondaryLight),
                        ),
                        
                        if (sign.exampleSentence != null) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Text('Exemple de phrase', style: AppTextStyles.h3),
                          const SizedBox(height: AppSpacing.s),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                            ),
                            child: Text(
                              sign.exampleSentence!,
                              style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                        
                        if (sign.tags != null && sign.tags!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Wrap(
                            spacing: 8,
                            children: sign.tags!.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              backgroundColor: AppColors.neutralLight,
                            )).toList(),
                          ),
                        ],
                        
                        const SizedBox(height: AppSpacing.xxxl),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.share_outlined),
                                label: const Text('Partager'),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.school_outlined),
                                label: const Text('Pratiquer'),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ]),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erreur: $err')),
          ),
        ),
      ),
    );
  }

  List<LandmarkPoint> _parseLandmarks(Map<String, dynamic>? data) {
    if (data == null || data['points'] == null) return [];
    return (data['points'] as List).map((p) => LandmarkPoint.fromJson(p)).toList();
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
