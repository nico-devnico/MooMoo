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
    return ClipRRect(
      borderRadius: AppRadius.radiusXL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: AppRadius.radiusXL,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: size),
      onPressed: onTap,
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
