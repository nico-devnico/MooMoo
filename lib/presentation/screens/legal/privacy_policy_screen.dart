import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Politique de Confidentialité', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Dernière mise à jour : 21 Mai 2026',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.l),
            _buildSection(
              '1. Collecte des données',
              'Nous collectons les informations que vous nous fournissez directement, notamment lors de la création de votre compte (nom, email).',
            ),
            _buildSection(
              '2. Utilisation de la caméra',
              'L\'accès à la caméra est strictement utilisé pour la traduction en temps réel des signes. Aucune image n\'est enregistrée sur nos serveurs sans votre consentement explicite.',
            ),
            _buildSection(
              '3. Sécurité',
              'Nous mettons en œuvre des mesures de sécurité robustes pour protéger vos informations personnelles.',
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
