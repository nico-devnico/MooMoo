import 'package:flutter/material.dart';
import '../../../core/layout/responsive.dart';

class LessonScreen extends StatelessWidget {
  final String id;
  const LessonScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lesson $id')),
      body: const PageContainer.reading(
        child: Center(child: Text('Lesson Screen')),
      ),
    );
  }
}
