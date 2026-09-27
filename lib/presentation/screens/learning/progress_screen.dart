import 'package:flutter/material.dart';
import '../../../core/layout/responsive.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const PageContainer.reading(
        child: Center(child: Text('Progress Screen')),
      ),
    );
  }
}
