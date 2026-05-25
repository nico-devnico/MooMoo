import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.about),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            // App Logo
            Center(
              child: Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'MooMoo',
              style: AppTextStyles.h1.copyWith(color: AppColors.primary),
            ),
            Text(
              'Version 1.5.0',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Author Section
            _buildInfoCard(
              context,
              isDark,
              title: 'Auteur',
              content: 'OTILA Nicandre',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: AppSpacing.m),
            _buildInfoCard(
              context,
              isDark,
              title: 'Contact',
              content: 'nicodevnico@gmail.com',
              icon: Icons.email_outlined,
              onTap: () => _launchEmail('nicodevnico@gmail.com'),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Description
            Text(
              'MooMoo est une plateforme de traduction intelligente en langue des signes conçue pour briser les barrières de communication et favoriser l\'inclusion universelle.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            // Footer
            Text(
              '© 2026 MooMoo. Tous droits réservés.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String content,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : AppColors.neutralLight.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      content,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'À propos de MooMoo',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}
