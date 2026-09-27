import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_icons.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/skeletons.dart';
import 'learning_editor.dart';
import '../../../domain/providers/error_text.dart';

/// Course editor for teachers and sign language experts, who have no access
/// to the admin area.
class LearningManageScreen extends ConsumerWidget {
  const LearningManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = ref.watch(canEditLearningProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.learnManagePath)),
      body: PageContainer(
        padding: 0,
        child: canEdit.when(
          data: (allowed) => allowed
              ? const LearningEditorView()
              : AppEmptyState(
                  icon: AppIcons.locked,
                  title: l10n.adminAccessDenied,
                  message: l10n.adminLearningForbidden,
                ),
          loading: () => const SkeletonList(itemCount: 4, hasTrailing: true),
          error: (e, _) => AppEmptyState(
            icon: AppIcons.error,
            title: l10n.errorGeneric,
            message: ref.userErrorText(e, l10n),
          ),
        ),
      ),
    );
  }
}
