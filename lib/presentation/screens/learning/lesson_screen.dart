import 'package:flutter/material.dart';

class LessonScreen extends StatelessWidget {
  final String id;
  const LessonScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lesson $id')),
      body: const Center(child: Text('Lesson Screen')),
    );
  }
}
