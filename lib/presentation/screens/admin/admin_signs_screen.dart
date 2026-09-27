import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/sign.dart';
import '../../../data/models/sign_category.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/skeletons.dart';
import 'admin_shell.dart';

const double _listMaxWidth = 820;
const double _thumbSize = 64;

class AdminSignsScreen extends ConsumerStatefulWidget {
  const AdminSignsScreen({super.key});

  @override
  ConsumerState<AdminSignsScreen> createState() => _AdminSignsScreenState();
}

class _AdminSignsScreenState extends ConsumerState<AdminSignsScreen> {
  final _searchController = TextEditingController();
  final Set<String> _busyIds = {};
  bool? _validatedFilter;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AdminSignsFilter get _filter =>
      AdminSignsFilter(query: _query, isValidated: _validatedFilter);

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signsAsync = ref.watch(adminSignsProvider(_filter));

    final filters = [
      (null, l10n.filterAll),
      (true, l10n.statusValidated),
      (false, l10n.statusNotValidated),
    ];

    return AdminShell(
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.m,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(l10n.adminSigns, style: AppTextStyles.h2),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      l10n.adminManageSignsDesc,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.searchSign,
                        prefixIcon: const Icon(AppIcons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: l10n.admxClearSearch,
                                icon: const Icon(AppIcons.close),
                                onPressed: _clearSearch,
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final f in filters)
                          ChoiceChip(
                            label: Text(f.$2),
                            selected: _validatedFilter == f.$1,
                            onSelected: (_) =>
                                setState(() => _validatedFilter = f.$1),
                          ),
                        AppButton(
                          label: l10n.adminAddSign,
                          icon: AppIcons.add,
                          fullWidth: false,
                          onPressed: () => _showSignEditor(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(adminSignsProvider(_filter).future),
              child: signsAsync.when(
                data: (signs) {
                  if (signs.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.l),
                      children: [
                        AppEmptyState(
                          icon: AppIcons.dictionary,
                          title: l10n.adminNoSigns,
                          message: l10n.adminNoSignsMessage,
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.s,
                      AppSpacing.l,
                      AppSpacing.xxl,
                    ),
                    itemCount: signs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) {
                      final sign = signs[index];
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _listMaxWidth,
                          ),
                          child: _SignAdminTile(
                            sign: sign,
                            busy: _busyIds.contains(sign.id),
                            onEdit: () => _showSignEditor(sign: sign),
                            onToggleValidated: () => _toggleValidated(sign),
                            onDelete: () => _deleteSign(sign),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.s,
                    AppSpacing.l,
                    AppSpacing.l,
                  ),
                  children: [_SignsSkeleton(label: l10n.loading)],
                ),
                error: (e, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.l),
                  children: [
                    AppEmptyState(
                      icon: AppIcons.error,
                      title: l10n.errorGeneric,
                      message: e.toString(),
                      actionLabel: l10n.retry,
                      onAction: () =>
                          ref.invalidate(adminSignsProvider(_filter)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _afterChange() {
    ref
      ..invalidate(adminSignsProvider)
      ..invalidate(adminStatsProvider);
  }

  Future<void> _run(
    Sign sign,
    Future<void> Function() action,
    String success,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busyIds.add(sign.id));
    try {
      await action();
      _afterChange();
      if (mounted) {
        AppSnackbar.show(
          context,
          message: success,
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: '${l10n.errorGeneric}: $e',
          type: AppSnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busyIds.remove(sign.id));
    }
  }

  Future<void> _toggleValidated(Sign sign) {
    final l10n = AppLocalizations.of(context)!;
    return _run(
      sign,
      () => ref
          .read(adminRepositoryProvider)
          .setSignValidated(sign.id, !sign.isValidated),
      l10n.signUpdated,
    );
  }

  Future<void> _deleteSign(Sign sign) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteSign,
      message: l10n.deleteSignConfirm(sign.word),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(
      sign,
      () => ref.read(adminRepositoryProvider).deleteSign(sign.id),
      l10n.signDeleted,
    );
  }

  Future<void> _showSignEditor({Sign? sign}) async {
    final l10n = AppLocalizations.of(context)!;
    final updated = await showDialog<Sign>(
      context: context,
      builder: (context) => _SignEditorDialog(sign: sign),
    );
    if (updated == null || !mounted) return;

    try {
      await ref.read(adminRepositoryProvider).upsertSign(updated);
      _afterChange();
      if (mounted) {
        AppSnackbar.show(
          context,
          message: l10n.signUpdated,
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: '${l10n.errorGeneric}: $e',
          type: AppSnackbarType.error,
        );
      }
    }
  }
}

class _SignEditorDialog extends ConsumerStatefulWidget {
  const _SignEditorDialog({this.sign});

  final Sign? sign;

  @override
  ConsumerState<_SignEditorDialog> createState() => _SignEditorDialogState();
}

class _SignEditorDialogState extends ConsumerState<_SignEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _word;
  late final TextEditingController _description;
  late final TextEditingController _videoUrl;
  late bool _validated;
  late int _difficulty;
  int? _languageId;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    final sign = widget.sign;
    _word = TextEditingController(text: sign?.word ?? '');
    _description = TextEditingController(text: sign?.description ?? '');
    _videoUrl = TextEditingController(text: sign?.videoUrl ?? '');
    _validated = sign?.isValidated ?? true;
    _difficulty = (sign?.difficultyLevel ?? 1).clamp(1, 5);
    _languageId = sign?.signLanguageId;
    _categoryId = sign?.categoryId;
  }

  @override
  void dispose() {
    _word.dispose();
    _description.dispose();
    _videoUrl.dispose();
    super.dispose();
  }

  String? _trimmedOrNull(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sign = widget.sign;
    final now = DateTime.now();
    final base = sign ?? Sign(id: const Uuid().v4(), word: '', createdAt: now);
    Navigator.pop(
      context,
      base.copyWith(
        word: _word.text.trim(),
        description: _trimmedOrNull(_description),
        videoUrl: _trimmedOrNull(_videoUrl),
        signLanguageId: _languageId,
        categoryId: _categoryId,
        difficultyLevel: _difficulty,
        isValidated: _validated,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languagesAsync = ref.watch(signLanguagesProvider);
    final languages = languagesAsync.value ?? const [];
    // Langue par défaut : la première renvoyée par Supabase, jamais un id en dur.
    final languageId =
        _languageId ?? (languages.isNotEmpty ? languages.first.id : null);
    final List<SignCategory> categories = languageId == null
        ? const []
        : ref.watch(signCategoriesProvider(languageId)).value ?? const [];

    return AlertDialog(
      title: Text(widget.sign == null ? l10n.adminAddSign : l10n.adminEditSign),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 380, maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _word,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.signWord),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.admxWordRequired : null,
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l10n.signDescription),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _videoUrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: l10n.signVideoUrl,
                    prefixIcon: const Icon(AppIcons.video),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                DropdownButtonFormField<int>(
                  key: ValueKey('lang_$languageId'),
                  initialValue: languages.any((l) => l.id == languageId)
                      ? languageId
                      : null,
                  decoration: InputDecoration(labelText: l10n.adminLanguage),
                  items: [
                    for (final language in languages)
                      DropdownMenuItem(
                        value: language.id,
                        child: Text(language.name),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _languageId = v;
                    _categoryId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.m),
                DropdownButtonFormField<int?>(
                  key: ValueKey('cat_${languageId}_${categories.length}'),
                  initialValue: categories.any((c) => c.id == _categoryId)
                      ? _categoryId
                      : null,
                  decoration: InputDecoration(labelText: l10n.admxCategory),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.admxNoCategory),
                    ),
                    for (final category in categories)
                      DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(l10n.difficultyLevel, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.s),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    for (var level = 1; level <= 5; level++)
                      ButtonSegment(
                        value: level,
                        label: Text('$level'),
                        tooltip: l10n.admxDifficultyValue(level),
                      ),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (v) =>
                      setState(() => _difficulty = v.first),
                ),
                const SizedBox(height: AppSpacing.m),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.statusValidated),
                  value: _validated,
                  onChanged: (v) => setState(() => _validated = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            _languageId ??= languageId;
            _submit();
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, kMinTouchTarget),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _SignAdminTile extends StatelessWidget {
  const _SignAdminTile({
    required this.sign,
    required this.busy,
    required this.onEdit,
    required this.onToggleValidated,
    required this.onDelete,
  });

  final Sign sign;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onToggleValidated;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final placeholder = Center(
      child: Icon(AppIcons.signLanguage, color: secondary, size: 24),
    );

    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.radiusM,
            child: ColoredBox(
              color: AppColors.neutral(context),
              child: SizedBox.square(
                dimension: _thumbSize,
                child: sign.thumbnailUrl == null
                    ? placeholder
                    : CachedNetworkImage(
                        imageUrl: sign.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const SizedBox.shrink(),
                        errorWidget: (_, _, _) => placeholder,
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      sign.word,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppBadge(
                      label: sign.isValidated
                          ? l10n.statusValidated
                          : l10n.statusNotValidated,
                      color: sign.isValidated
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
                if (sign.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    sign.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${l10n.admxDifficultyValue(sign.difficultyLevel)} · ${l10n.admxViewsCount(sign.viewCount)}',
                  style: AppTextStyles.bodySmall.copyWith(color: secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          if (busy)
            const SizedBox(
              width: kMinTouchTarget,
              height: kMinTouchTarget,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            IconButton(
              tooltip: l10n.adminEditSign,
              constraints: const BoxConstraints(
                minWidth: kMinTouchTarget,
                minHeight: kMinTouchTarget,
              ),
              onPressed: onEdit,
              icon: const Icon(AppIcons.edit),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.admxActions,
              icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
              onSelected: (value) {
                switch (value) {
                  case 'validate':
                    onToggleValidated();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'validate',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      sign.isValidated
                          ? AppIcons.blocked
                          : PhosphorIconsRegular.sealCheck,
                    ),
                    title: Text(
                      sign.isValidated ? l10n.unvalidate : l10n.validate,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      AppIcons.delete,
                      color: AppColors.error,
                    ),
                    title: Text(
                      l10n.delete,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Reprend la forme de [_SignAdminTile] : vignette carrée, deux lignes, actions.
class _SignsSkeleton extends StatelessWidget {
  const _SignsSkeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: label,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _listMaxWidth),
          child: Column(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.s),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: AppRadius.radiusL,
                  ),
                  child: const Row(
                    children: [
                      SkeletonBlock(
                        width: _thumbSize,
                        height: _thumbSize,
                        radius: AppRadius.m,
                      ),
                      SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBlock(width: 140, height: 16),
                            SizedBox(height: AppSpacing.s),
                            SkeletonBlock(height: 12),
                            SizedBox(height: AppSpacing.s),
                            SkeletonBlock(width: 110, height: 12),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSpacing.m),
                      SkeletonBlock.circle(size: 32),
                      SizedBox(width: AppSpacing.m),
                      SkeletonBlock.circle(size: 32),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
