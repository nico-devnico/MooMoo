import 'package:flutter/material.dart';

import '../learning/learning_editor.dart';
import 'admin_shell.dart';

class AdminLearningScreen extends StatelessWidget {
  const AdminLearningScreen({super.key, this.workspace = Workspace.admin});

  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      workspace: workspace,
      selectedIndex: switch (workspace) {
        Workspace.admin => 3,
        Workspace.teacher => 1,
        Workspace.expert => 3,
      },
      child: const LearningEditorView(),
    );
  }
}
