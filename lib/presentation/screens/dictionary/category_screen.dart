import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final String id;
  const CategoryScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Category $id')),
      body: const Center(child: Text('Category Screen')),
    );
  }
}
