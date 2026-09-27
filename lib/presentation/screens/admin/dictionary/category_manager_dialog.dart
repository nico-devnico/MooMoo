import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/sign_category.dart';
import '../../../../data/models/sign_language.dart';
import '../../../../domain/providers/admin_provider.dart';
import '../../../../domain/providers/sign_provider.dart';
import '../../../../domain/providers/workspace_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/confirm_dialog.dart';

/// Create, rename and delete the categories of one sign language.
class CategoryManagerDialog extends ConsumerStatefulWidget {
  const CategoryManagerDialog({super.key, this.initialLanguageId});

  final int? initialLanguageId;

  @override
  ConsumerState<CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends ConsumerState<CategoryManagerDialog> {
  int? _languageId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _languageId = widget.initialLanguageId;
  }

  Future<String?> _askName({String? initial}) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initial ?? '');
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? l10n.dmNewCategory : l10n.dmRenameCategory),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(labelText: l10n.dmCategoryName),
            validator: (v) => (v ?? '').trim().isEmpty ? l10n.dmCategoryNameRequired : null,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim());
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, controller.text.trim());
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(manageableCategoriesProvider(_languageId!));
      if (mounted) AppSnackbar.show(context, message: success, type: AppSnackbarType.success);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, '${l10n.errorGeneric}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create(SignLanguage language, List<SignCategory> existing) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _askName();
    if (name == null || !mounted) return;
    if (existing.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      AppSnackbar.showError(context, l10n.dmCategoryExists(name));
      return;
    }
    await _run(
      () => ref.read(workspaceRepositoryProvider).saveCategory(
            name: name,
            languageId: language.id,
            languageCode: language.code,
          ),
      l10n.dmCategorySaved,
    );
  }

  Future<void> _rename(SignLanguage language, SignCategory category) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _askName(initial: category.name);
    if (name == null || name == category.name || !mounted) return;
    await _run(
      () => ref.read(workspaceRepositoryProvider).saveCategory(
            id: category.id,
            name: name,
            languageId: language.id,
            languageCode: language.code,
          ),
      l10n.dmCategorySaved,
    );
  }

  Future<void> _delete(SignCategory category) async {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(workspaceRepositoryProvider);
    int count;
    try {
      count = await repository.countSignsInCategory(category.id);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, '${l10n.errorGeneric}: $e');
      return;
    }
    if (!mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.dmDeleteCategory,
      message: l10n.dmDeleteCategoryConfirm(category.name, count),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(() => repository.deleteCategory(category.id), l10n.dmCategoryDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(isAdminProvider);
    final languages = ref.watch(signLanguagesProvider).value ?? const [];
    final language = languages.where((l) => l.id == _languageId).firstOrNull;
    final categoriesAsync =
        _languageId == null ? null : ref.watch(manageableCategoriesProvider(_languageId!));

    return AlertDialog(
      title: Text(l10n.dmCategories),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _languageId,
              decoration: InputDecoration(labelText: l10n.adminLanguage),
              items: [
                for (final l in languages) DropdownMenuItem(value: l.id, child: Text(l.name)),
              ],
              onChanged: _busy ? null : (v) => setState(() => _languageId = v),
            ),
            const SizedBox(height: AppSpacing.m),
            if (_busy) const LinearProgressIndicator(),
            if (categoriesAsync == null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Text(l10n.dmChooseLanguage, style: AppTextStyles.bodyMedium),
              )
            else
              Flexible(
                child: categoriesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.l),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('${l10n.errorGeneric}: $e',
                      style: const TextStyle(color: AppColors.error)),
                  data: (categories) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (categories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: Text(l10n.dmNoCategories, style: AppTextStyles.bodyMedium),
                        )
                      else
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final c in categories)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(c.name),
                                  subtitle: Text(c.slug),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: l10n.dmRenameCategory,
                                        icon: const Icon(AppIcons.edit),
                                        onPressed: _busy ? null : () => _rename(language!, c),
                                      ),
                                      if (isAdmin)
                                        IconButton(
                                          tooltip: l10n.dmDeleteCategory,
                                          icon: const Icon(AppIcons.delete, color: AppColors.error),
                                          onPressed: _busy ? null : () => _delete(c),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.s),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _busy || language == null
                              ? null
                              : () => _create(language, categories),
                          icon: const Icon(AppIcons.add),
                          label: Text(l10n.dmNewCategory),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
      ],
    );
  }
}
