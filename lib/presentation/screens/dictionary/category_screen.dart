import 'package:flutter/material.dart';
import '../../../core/layout/responsive.dart';

class CategoryScreen extends StatelessWidget {
  final String id;
  const CategoryScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Category $id')),
      body: const PageContainer.reading(
        child: Center(child: Text('Category Screen')),
      ),
    );
  }
}
