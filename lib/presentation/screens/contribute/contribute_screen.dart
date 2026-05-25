import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_empty_state.dart';
import '../../../core/router/app_routes.dart';

class ContributeScreen extends StatelessWidget {
  const ContributeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppEmptyState(
        title: 'Bientôt disponible',
        message: 'La page de contribution est en cours de développement. Revenez plus tard !',
        imagePath: 'assets/images/empty_state/empty_404.gif',
        isSvg: false,
        actionLabel: 'Retour',
        onAction: () => context.pop(),
      ),
    );
  }
}
