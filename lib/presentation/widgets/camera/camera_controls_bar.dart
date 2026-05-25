import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/camera_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class CameraControlsBar extends ConsumerWidget {
  const CameraControlsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(cameraSettingsProvider);
    final isRecording = settings['isRecording'] ?? false;

    return ClipRRect(
      borderRadius: AppRadius.radiusXL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: AppRadius.radiusXL,
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: Icons.flip_camera_ios_outlined,
                size: 24,
                onTap: () => ref.read(cameraStateProvider.notifier).switchCamera(),
              ),
              _ControlButton(
                icon: Icons.settings_outlined,
                size: 24,
                onTap: () => _showSettings(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaPreview(BuildContext context, String path, {required bool isVideo}) {
    // Miniature animée en bas à gauche (V1 placeholder)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isVideo ? 'Vidéo enregistrée' : 'Photo capturée'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'Voir', onPressed: () {}),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const CameraSettingsSheet(),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: onTap,
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CaptureButton({
    required this.isRecording,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isRecording ? AppColors.error : Colors.white,
            width: 3,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isRecording ? AppColors.error : Colors.white,
            borderRadius: BorderRadius.circular(isRecording ? 6 : 28),
          ),
        ),
      ),
    );
  }
}

class CameraSettingsSheet extends ConsumerWidget {
  const CameraSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(cameraSettingsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text('Paramètres caméra', style: AppTextStyles.h3.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.xl),
          SwitchListTile(
            title: const Text('Grille des tiers', style: TextStyle(color: Colors.white)),
            value: settings['showGrid'] ?? false,
            onChanged: (val) => ref.read(cameraSettingsProvider.notifier).toggleGrid(),
          ),
          // Add more settings as needed
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
