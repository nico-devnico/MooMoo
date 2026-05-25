import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../../l10n/app_localizations.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.learning)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              Text(l10n.yourProgress, style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.m),
              const _ProgressCard(),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.availableCourses, style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.m),
              const _CourseTile(
                title: 'L\'Alphabet LSF',
                subtitle: 'Les bases de la dactylologie',
                icon: '🅰️',
                progress: 0.8,
              ),
              const _CourseTile(
                title: 'Salutations de base',
                subtitle: 'Bonjour, Au revoir, Merci...',
                icon: '👋',
                progress: 0.3,
              ),
              const _CourseTile(
                title: 'Nombres et Chiffres',
                subtitle: 'Compter jusqu\'à 100',
                icon: '🔢',
                progress: 0.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('12 / 45', style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                    Text(l10n.signsMastered, style: AppTextStyles.bodySmall),
                  ],
                ),
                const Icon(Icons.workspace_premium, color: AppColors.warning, size: 40),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            LinearProgressIndicator(
              value: 0.26,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: AppColors.primary.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final double progress;

  const _CourseTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: AppCard(
        onTap: () {},
        child: ListTile(
          leading: Text(icon, style: const TextStyle(fontSize: 32)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
          trailing: const Icon(Icons.play_circle_outline, color: AppColors.primary),
        ),
      ),
    );
  }
}
