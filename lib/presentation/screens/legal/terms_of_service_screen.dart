import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conditions d\'utilisation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conditions Générales d\'Utilisation', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Dernière mise à jour : 21 Mai 2026',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.l),
            _buildSection(
              '1. Acceptation des conditions',
              'En utilisant l\'application MooMoo, vous acceptez d\'être lié par les présentes conditions d\'utilisation.',
            ),
            _buildSection(
              '2. Utilisation du service',
              'Vous vous engagez à utiliser l\'application de manière licite et respectueuse des autres utilisateurs.',
            ),
            _buildSection(
              '3. Propriété intellectuelle',
              'Le contenu de l\'application, y compris les modèles de traduction, est la propriété exclusive de MooMoo.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.s),
          Text(content, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
