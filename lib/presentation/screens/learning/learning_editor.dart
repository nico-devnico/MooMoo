import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/learning.dart';
import '../../../data/models/sign.dart';
import '../../../data/models/sign_language.dart';
import '../../../data/repositories/learning_repository.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/skeletons.dart';
import '../../../domain/providers/error_text.dart';

const double _editorMaxWidth = 820;
const List<int> _xpChoices = [5, 10, 15, 20, 30, 50];

/// Course editor shared by the admin area and the teachers' page. Row level
/// security decides who may write; this widget only assumes it may.
class LearningEditorView extends ConsumerStatefulWidget {
  const LearningEditorView({super.key});

  @override
  ConsumerState<LearningEditorView> createState() => _LearningEditorViewState();
}

class _LearningEditorViewState extends ConsumerState<LearningEditorView> {
  int? _languageId;

  LearningRepository get _repo => ref.read(learningRepositoryProvider);

  void _refresh() {
    final id = _languageId;
    if (id == null) return;
    ref
      ..invalidate(learningEditorPathProvider(id))
      ..invalidate(learningPathProvider(id));
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await action();
      _refresh();
      if (mounted) AppSnackbar.showSuccess(context, l10n.adminSaved);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, ref.userErrorText(e, l10n));
    }
  }

  Future<void> _editUnit({LearningUnit? unit, required int nextIndex}) async {
    final result = await showDialog<_UnitForm>(
      context: context,
      builder: (_) => _UnitDialog(unit: unit),
    );
    if (result == null) return;
    await _run(() => _repo.saveUnit(
          id: unit?.id,
          signLanguageId: _languageId!,
          title: result.title,
          description: result.description,
          iconName: result.iconName,
          isPublished: result.published,
          orderIndex: unit == null ? nextIndex : null,
        ));
  }

  Future<void> _deleteUnit(LearningUnit unit) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l10n.adminDeleteUnitConfirm(unit.title),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (ok) await _run(() => _repo.deleteUnit(unit.id));
  }

  Future<void> _editLesson({
    required LearningUnit unit,
    LearningLesson? lesson,
  }) async {
    final result = await showDialog<_LessonForm>(
      context: context,
      builder: (_) => _LessonDialog(lesson: lesson),
    );
    if (result == null) return;
    await _run(() => _repo.saveLesson(
          id: lesson?.id,
          unitId: unit.id,
          title: result.title,
          description: result.description,
          xpReward: result.xpReward,
          orderIndex: lesson == null ? unit.lessons.length : null,
        ));
  }

  Future<void> _deleteLesson(LearningLesson lesson) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l10n.adminDeleteLessonConfirm(lesson.title),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (ok) await _run(() => _repo.deleteLesson(lesson.id));
  }

  Future<void> _pickSigns(LearningLesson lesson) async {
    final ids = await showDialog<List<String>>(
      context: context,
      builder: (_) => _SignPickerDialog(lesson: lesson, languageId: _languageId!),
    );
    if (ids == null) return;
    ref.invalidate(lessonSignsProvider(lesson.id));
    await _run(() => _repo.setLessonSigns(lesson.id, ids));
  }

  Future<void> _move(String table, List<String> ids, int from, int to) async {
    if (to < 0 || to >= ids.length) return;
    final reordered = [...ids];
    final item = reordered.removeAt(from);
    reordered.insert(to, item);
    await _run(() => _repo.reorder(table, reordered));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languagesAsync = ref.watch(signLanguagesProvider);

    return languagesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.l),
        child: SkeletonList(itemCount: 4, hasTrailing: true),
      ),
      error: (e, _) => AppEmptyState(
        icon: AppIcons.error,
        title: l10n.errorGeneric,
        message: ref.userErrorText(e, l10n),
      ),
      data: (languages) {
        if (languages.isEmpty) {
          return AppEmptyState(
            icon: AppIcons.language,
            title: l10n.adminNoUnits,
            message: l10n.errorLoadingLanguages,
          );
        }
        final preferred = ref.watch(learningLanguageProvider).value;
        _languageId ??= preferred?.id ?? languages.first.id;
        final languageId = _languageId!;
        final unitsAsync = ref.watch(learningEditorPathProvider(languageId));

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _editorMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.adminLearning, style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.s),
                    Text(l10n.adminLearningSubtitle, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.l),
                    _LanguagePicker(
                      languages: languages,
                      selectedId: languageId,
                      onSelected: (id) => setState(() => _languageId = id),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    unitsAsync.when(
                      loading: () => const SkeletonList(itemCount: 3, hasTrailing: true),
                      error: (e, _) => AppEmptyState(
                        icon: AppIcons.error,
                        title: l10n.errorGeneric,
                        message: ref.userErrorText(e, l10n),
                        actionLabel: l10n.retry,
                        onAction: _refresh,
                      ),
                      data: (units) => _UnitsList(
                        units: units,
                        onAddUnit: () => _editUnit(nextIndex: units.length),
                        onEditUnit: (u) => _editUnit(unit: u, nextIndex: units.length),
                        onTogglePublished: (u) =>
                            _run(() => _repo.setUnitPublished(u.id, !u.isPublished)),
                        onDeleteUnit: _deleteUnit,
                        onMoveUnit: (from, to) => _move(
                          'learning_units',
                          [for (final u in units) u.id],
                          from,
                          to,
                        ),
                        onAddLesson: (u) => _editLesson(unit: u),
                        onEditLesson: (u, l) => _editLesson(unit: u, lesson: l),
                        onDeleteLesson: _deleteLesson,
                        onPickSigns: _pickSigns,
                        onMoveLesson: (u, from, to) => _move(
                          'learning_lessons',
                          [for (final l in u.lessons) l.id],
                          from,
                          to,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.languages,
    required this.selectedId,
    required this.onSelected,
  });

  final List<SignLanguage> languages;
  final int selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.adminLanguage,
      child: Wrap(
        spacing: AppSpacing.s,
        runSpacing: AppSpacing.s,
        children: [
          for (final language in languages)
            ChoiceChip(
              label: Text('${language.code} · ${language.name}'),
              selected: language.id == selectedId,
              onSelected: (_) => onSelected(language.id),
            ),
        ],
      ),
    );
  }
}

class _UnitsList extends StatelessWidget {
  const _UnitsList({
    required this.units,
    required this.onAddUnit,
    required this.onEditUnit,
    required this.onTogglePublished,
    required this.onDeleteUnit,
    required this.onMoveUnit,
    required this.onAddLesson,
    required this.onEditLesson,
    required this.onDeleteLesson,
    required this.onPickSigns,
    required this.onMoveLesson,
  });

  final List<LearningUnit> units;
  final VoidCallback onAddUnit;
  final ValueChanged<LearningUnit> onEditUnit;
  final ValueChanged<LearningUnit> onTogglePublished;
  final ValueChanged<LearningUnit> onDeleteUnit;
  final void Function(int from, int to) onMoveUnit;
  final ValueChanged<LearningUnit> onAddLesson;
  final void Function(LearningUnit unit, LearningLesson lesson) onEditLesson;
  final ValueChanged<LearningLesson> onDeleteLesson;
  final ValueChanged<LearningLesson> onPickSigns;
  final void Function(LearningUnit unit, int from, int to) onMoveLesson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final addButton = AppButton(
      label: l10n.adminAddUnit,
      icon: AppIcons.add,
      fullWidth: false,
      onPressed: onAddUnit,
    );

    if (units.isEmpty) {
      return AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminNoUnits, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.s),
            Text(
              l10n.adminNoUnitsMessage,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: AppSpacing.l),
            addButton,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        addButton,
        const SizedBox(height: AppSpacing.l),
        for (var i = 0; i < units.length; i++) ...[
          _UnitPanel(
            unit: units[i],
            number: i + 1,
            canMoveUp: i > 0,
            canMoveDown: i < units.length - 1,
            onEdit: () => onEditUnit(units[i]),
            onTogglePublished: () => onTogglePublished(units[i]),
            onDelete: () => onDeleteUnit(units[i]),
            onMoveUp: () => onMoveUnit(i, i - 1),
            onMoveDown: () => onMoveUnit(i, i + 1),
            onAddLesson: () => onAddLesson(units[i]),
            onEditLesson: (l) => onEditLesson(units[i], l),
            onDeleteLesson: onDeleteLesson,
            onPickSigns: onPickSigns,
            onMoveLesson: (from, to) => onMoveLesson(units[i], from, to),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
      ],
    );
  }
}

class _UnitPanel extends StatelessWidget {
  const _UnitPanel({
    required this.unit,
    required this.number,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onEdit,
    required this.onTogglePublished,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAddLesson,
    required this.onEditLesson,
    required this.onDeleteLesson,
    required this.onPickSigns,
    required this.onMoveLesson,
  });

  final LearningUnit unit;
  final int number;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onAddLesson;
  final ValueChanged<LearningLesson> onEditLesson;
  final ValueChanged<LearningLesson> onDeleteLesson;
  final ValueChanged<LearningLesson> onPickSigns;
  final void Function(int from, int to) onMoveLesson;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.fromName(unit.iconName, fallback: AppIcons.lesson),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.learnUnitLabel(number),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      unit.title,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _StatusBadge(published: unit.isPublished),
              _RowMenu(
                items: [
                  _MenuItem(AppIcons.edit, l10n.commonEdit, onEdit),
                  _MenuItem(
                    unit.isPublished ? AppIcons.blocked : AppIcons.success,
                    unit.isPublished ? l10n.adminUnpublish : l10n.adminPublish,
                    onTogglePublished,
                  ),
                  if (canMoveUp) _MenuItem(Icons.arrow_upward, l10n.adminMoveUp, onMoveUp),
                  if (canMoveDown) _MenuItem(Icons.arrow_downward, l10n.adminMoveDown, onMoveDown),
                  _MenuItem(AppIcons.delete, l10n.delete, onDelete, destructive: true),
                ],
              ),
            ],
          ),
          if (unit.lessons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            const Divider(height: 1),
            for (var j = 0; j < unit.lessons.length; j++)
              _LessonRow(
                lesson: unit.lessons[j],
                canMoveUp: j > 0,
                canMoveDown: j < unit.lessons.length - 1,
                onEdit: () => onEditLesson(unit.lessons[j]),
                onDelete: () => onDeleteLesson(unit.lessons[j]),
                onPickSigns: () => onPickSigns(unit.lessons[j]),
                onMoveUp: () => onMoveLesson(j, j - 1),
                onMoveDown: () => onMoveLesson(j, j + 1),
              ),
          ],
          const SizedBox(height: AppSpacing.s),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddLesson,
              icon: const Icon(AppIcons.add, size: 18),
              label: Text(l10n.adminAddLesson),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onEdit,
    required this.onDelete,
    required this.onPickSigns,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final LearningLesson lesson;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPickSigns;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final needsSigns = lesson.signCount < 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.s),
          Icon(AppIcons.lesson, size: 20, color: AppColors.textSecondary(context)),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${l10n.learnLessonSigns(lesson.signCount)} · ${l10n.learnXpAmount(lesson.xpReward)}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context)),
                ),
                if (needsSigns)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.warning, size: 14, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            l10n.adminLessonNeedsSigns,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          if (!context.isMobile)
            TextButton.icon(
              onPressed: onPickSigns,
              icon: const Icon(AppIcons.signLanguage, size: 18),
              label: Text(l10n.adminLessonPickSigns),
            ),
          _RowMenu(
            items: [
              if (context.isMobile) _MenuItem(AppIcons.signLanguage, l10n.adminLessonPickSigns, onPickSigns),
              _MenuItem(AppIcons.edit, l10n.commonEdit, onEdit),
              if (canMoveUp) _MenuItem(Icons.arrow_upward, l10n.adminMoveUp, onMoveUp),
              if (canMoveDown) _MenuItem(Icons.arrow_downward, l10n.adminMoveDown, onMoveDown),
              _MenuItem(AppIcons.delete, l10n.delete, onDelete, destructive: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.published});

  final bool published;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = published ? AppColors.success : AppColors.textSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: published ? AppColors.successSoft : AppColors.neutral(context),
        borderRadius: AppRadius.radiusCircular,
      ),
      child: Text(
        published ? l10n.adminPublished : l10n.adminDraft,
        style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap, {this.destructive = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      onSelected: (i) => items[i].onTap(),
      itemBuilder: (context) => [
        for (var i = 0; i < items.length; i++)
          PopupMenuItem(
            value: i,
            child: Row(
              children: [
                Icon(
                  items[i].icon,
                  size: 18,
                  color: items[i].destructive ? AppColors.error : null,
                ),
                const SizedBox(width: AppSpacing.m),
                Text(
                  items[i].label,
                  style: items[i].destructive ? const TextStyle(color: AppColors.error) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

class _UnitForm {
  const _UnitForm(this.title, this.description, this.iconName, this.published);

  final String title;
  final String? description;
  final String? iconName;
  final bool published;
}

class _UnitDialog extends StatefulWidget {
  const _UnitDialog({this.unit});

  final LearningUnit? unit;

  @override
  State<_UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<_UnitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.unit?.title ?? '');
  late final _description = TextEditingController(text: widget.unit?.description ?? '');
  late String? _icon = widget.unit?.iconName;
  late bool _published = widget.unit?.isPublished ?? false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _UnitForm(_title.text, _description.text, _icon, _published),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.unit == null ? l10n.adminAddUnit : l10n.adminEditUnit),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SizedBox(
          width: 460,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    autofocus: true,
                    maxLength: 120,
                    decoration: InputDecoration(labelText: l10n.adminFieldTitle),
                    validator: (v) => (v ?? '').trim().isEmpty ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    controller: _description,
                    maxLength: 500,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(labelText: l10n.adminFieldDescription),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(l10n.adminFieldIcon, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.s),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      for (final name in AppIcons.editorChoices)
                        _IconChoice(
                          name: name,
                          selected: _icon == name,
                          onTap: () => setState(() => _icon = name),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminPublished),
                    value: _published,
                    onChanged: (v) => setState(() => _published = v),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.name, required this.selected, required this.onTap});

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusM,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusM,
          child: SizedBox(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
            child: Icon(
              AppIcons.fromName(name),
              color: selected ? AppColors.primary : AppColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonForm {
  const _LessonForm(this.title, this.description, this.xpReward);

  final String title;
  final String? description;
  final int xpReward;
}

class _LessonDialog extends StatefulWidget {
  const _LessonDialog({this.lesson});

  final LearningLesson? lesson;

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.lesson?.title ?? '');
  late final _description = TextEditingController(text: widget.lesson?.description ?? '');
  late int _xp = _xpChoices.contains(widget.lesson?.xpReward) ? widget.lesson!.xpReward : 10;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _LessonForm(_title.text, _description.text, _xp));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.lesson == null ? l10n.adminAddLesson : l10n.adminEditLesson),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  autofocus: true,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: l10n.adminFieldTitle),
                  validator: (v) => (v ?? '').trim().isEmpty ? l10n.requiredField : null,
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: _description,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(labelText: l10n.adminFieldDescription),
                ),
                const SizedBox(height: AppSpacing.s),
                DropdownButtonFormField<int>(
                  initialValue: _xp,
                  decoration: InputDecoration(labelText: l10n.adminXpReward),
                  items: [
                    for (final xp in _xpChoices)
                      DropdownMenuItem(value: xp, child: Text(l10n.learnXpAmount(xp))),
                  ],
                  onChanged: (v) => setState(() => _xp = v ?? _xp),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

class _SignPickerDialog extends ConsumerStatefulWidget {
  const _SignPickerDialog({required this.lesson, required this.languageId});

  final LearningLesson lesson;
  final int languageId;

  @override
  ConsumerState<_SignPickerDialog> createState() => _SignPickerDialogState();
}

class _SignPickerDialogState extends ConsumerState<_SignPickerDialog> {
  final _search = TextEditingController();
  String _query = '';

  /// Insertion order is the order signs are taught in the lesson.
  List<Sign>? _selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(Sign sign) {
    final selected = _selected!;
    setState(() {
      final index = selected.indexWhere((s) => s.id == sign.id);
      if (index >= 0) {
        selected.removeAt(index);
      } else {
        selected.add(sign);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initial = ref.watch(lessonSignsProvider(widget.lesson.id));
    if (_selected == null && initial.hasValue) {
      _selected = [...initial.value!];
    }
    final results = ref.watch(signSearchProvider(
      query: _query.isEmpty ? null : _query,
      languageId: widget.languageId,
    ));
    final selected = _selected;

    return AlertDialog(
      title: Text('${l10n.adminLessonPickSigns} · ${widget.lesson.title}'),
      content: SizedBox(
        width: 520,
        height: 520,
        child: selected == null
            ? const SkeletonList(itemCount: 5)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.adminSelectedSigns(selected.length),
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (selected.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        for (var i = 0; i < selected.length; i++)
                          InputChip(
                            label: Text('${i + 1}. ${selected[i].word}'),
                            onDeleted: () => _toggle(selected[i]),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.m),
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: l10n.adminSearchValidatedSigns,
                      prefixIcon: const Icon(AppIcons.search),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Expanded(
                    child: results.when(
                      loading: () => const SkeletonList(itemCount: 5, avatarSize: 24),
                      error: (e, _) => Center(child: Text(ref.userErrorText(e, l10n))),
                      data: (signs) {
                        if (signs.isEmpty) {
                          return Center(
                            child: Text(
                              l10n.adminNoSignsForLanguage,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: signs.length,
                          itemBuilder: (context, i) {
                            final sign = signs[i];
                            final checked = selected.any((s) => s.id == sign.id);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (_) => _toggle(sign),
                              title: Text(sign.word),
                              subtitle: sign.description == null
                                  ? null
                                  : Text(
                                      sign.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: selected == null
              ? null
              : () => Navigator.pop(context, [for (final s in selected) s.id]),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
