import 'package:flutter/material.dart';

import '../learning/learning_editor.dart';
import 'admin_shell.dart';

class AdminLearningScreen extends StatelessWidget {
  const AdminLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      selectedIndex: 3,
      child: LearningEditorView(),
    );
  }
}
