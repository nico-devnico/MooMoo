import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Centre d\'aide')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          _buildHelpItem(
            context,
            'Comment utiliser le traducteur ?',
            'Placez votre caméra devant vous et commencez à signer. L\'application détectera automatiquement les signes.',
          ),
          _buildHelpItem(
            context,
            'Comment ajouter des favoris ?',
            'Dans le dictionnaire, cliquez sur l\'icône coeur à côté d\'un signe pour l\'ajouter à vos favoris.',
          ),
          _buildHelpItem(
            context,
            'Modifier mon profil',
            'Allez dans l\'onglet Profil et cliquez sur "Modifier le profil" pour changer votre nom ou votre bio.',
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, String title, String description) {
    return ExpansionTile(
      title: Text(title, style: AppTextStyles.h3),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Text(description, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}
