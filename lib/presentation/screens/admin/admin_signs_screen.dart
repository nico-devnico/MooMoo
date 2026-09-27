import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/sign.dart';
import '../../../domain/providers/admin_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/adaptive_card_list.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_snackbar.dart';
import 'admin_shell.dart';

class AdminSignsScreen extends ConsumerStatefulWidget {
  const AdminSignsScreen({super.key});

  @override
  ConsumerState<AdminSignsScreen> createState() => _AdminSignsScreenState();
}

class _AdminSignsScreenState extends ConsumerState<AdminSignsScreen> {
  final _searchController = TextEditingController();
  bool? _validatedFilter;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AdminSignsFilter get _filter => AdminSignsFilter(query: _query, isValidated: _validatedFilter);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final signsAsync = ref.watch(adminSignsProvider(_filter));

    return AdminShell(
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l10n.adminSigns, style: AppTextStyles.h2)),
                    FilledButton.icon(
                      onPressed: () => _showSignEditor(),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.adminAddSign),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l10n.searchSign,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(l10n.filterAll),
                        selected: _validatedFilter == null,
                        onSelected: (_) => setState(() => _validatedFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(l10n.statusValidated),
                        selected: _validatedFilter == true,
                        onSelected: (_) => setState(() => _validatedFilter = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(l10n.statusNotValidated),
                        selected: _validatedFilter == false,
                        onSelected: (_) => setState(() => _validatedFilter = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminSignsProvider(_filter)),
              child: signsAsync.when(
                data: (signs) {
                  if (signs.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45,
                          child: AppEmptyState(
                            title: l10n.adminNoSigns,
                            message: l10n.adminNoSignsMessage,
                            imagePath: null,
                          ),
                        ),
                      ],
                    );
                  }
                  return AdaptiveCardList(
                    itemCount: signs.length,
                    itemBuilder: (context, index) => _SignAdminTile(
                      sign: signs[index],
                      onEdit: () => _showSignEditor(sign: signs[index]),
                      onToggleValidated: () => _toggleValidated(signs[index]),
                      onDelete: () => _deleteSign(signs[index]),
                    ),
                  );
                },
                loading: () => const Center(child: AppLoader()),
                error: (e, _) => AppEmptyState(
                  title: l10n.errorGeneric,
                  message: e.toString(),
                  imagePath: null,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(adminSignsProvider(_filter)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleValidated(Sign sign) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(adminRepositoryProvider).setSignValidated(sign.id, !sign.isValidated);
      ref.invalidate(adminSignsProvider(_filter));
      ref.invalidate(adminStatsProvider);
      if (mounted) {
        AppSnackbar.show(context, message: l10n.signUpdated, type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: '${l10n.errorGeneric}: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _deleteSign(Sign sign) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSign),
        content: Text(l10n.deleteSignConfirm(sign.word)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminRepositoryProvider).deleteSign(sign.id);
      ref.invalidate(adminSignsProvider(_filter));
      ref.invalidate(adminStatsProvider);
      if (mounted) {
        AppSnackbar.show(context, message: l10n.signDeleted, type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: '${l10n.errorGeneric}: $e', type: AppSnackbarType.error);
      }
    }
  }

  Future<void> _showSignEditor({Sign? sign}) async {
    final l10n = AppLocalizations.of(context)!;
    final wordController = TextEditingController(text: sign?.word ?? '');
    final descController = TextEditingController(text: sign?.description ?? '');
    final videoController = TextEditingController(text: sign?.videoUrl ?? '');
    var validated = sign?.isValidated ?? true;
    var difficulty = sign?.difficultyLevel ?? 1;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.l,
            right: AppSpacing.l,
            top: AppSpacing.m,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sign == null ? l10n.adminAddSign : l10n.adminEditSign,
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: wordController,
                      decoration: InputDecoration(labelText: l10n.signWord),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(labelText: l10n.signDescription),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: videoController,
                      decoration: InputDecoration(labelText: l10n.signVideoUrl),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(l10n.difficultyLevel, style: AppTextStyles.bodyMedium),
                    Slider(
                      value: difficulty.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$difficulty',
                      onChanged: (v) => setModalState(() => difficulty = v.round()),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.statusValidated),
                      value: validated,
                      onChanged: (v) => setModalState(() => validated = v),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    FilledButton(
                      onPressed: () {
                        if (wordController.text.trim().isEmpty) return;
                        Navigator.pop(context, true);
                      },
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (saved != true) return;

    final updated = Sign(
      id: sign?.id ?? const Uuid().v4(),
      signLanguageId: sign?.signLanguageId ?? 1,
      categoryId: sign?.categoryId,
      word: wordController.text.trim(),
      description: descController.text.trim().isEmpty ? null : descController.text.trim(),
      videoUrl: videoController.text.trim().isEmpty ? null : videoController.text.trim(),
      difficultyLevel: difficulty,
      isValidated: validated,
      thumbnailUrl: sign?.thumbnailUrl,
      model3dUrl: sign?.model3dUrl,
      landmarkData: sign?.landmarkData,
      tags: sign?.tags,
      exampleSentence: sign?.exampleSentence,
      contributorId: sign?.contributorId,
      viewCount: sign?.viewCount ?? 0,
      createdAt: sign?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(adminRepositoryProvider).upsertSign(updated);
      ref.invalidate(adminSignsProvider(_filter));
      ref.invalidate(adminStatsProvider);
      if (mounted) {
        AppSnackbar.show(context, message: l10n.signUpdated, type: AppSnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: '${l10n.errorGeneric}: $e', type: AppSnackbarType.error);
      }
    }
  }
}

class _SignAdminTile extends StatelessWidget {
  final Sign sign;
  final VoidCallback onEdit;
  final VoidCallback onToggleValidated;
  final VoidCallback onDelete;

  const _SignAdminTile({
    required this.sign,
    required this.onEdit,
    required this.onToggleValidated,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(sign.word, style: AppTextStyles.h3)),
              AppBadge(
                label: sign.isValidated ? l10n.statusValidated : l10n.statusNotValidated,
                color: sign.isValidated ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          if (sign.description != null && sign.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text(sign.description!, style: AppTextStyles.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: AppSpacing.s),
          Text(
            '${l10n.views}: ${sign.viewCount} · ${l10n.difficultyLevel}: ${sign.difficultyLevel}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.modify),
              ),
              TextButton.icon(
                onPressed: onToggleValidated,
                icon: Icon(sign.isValidated ? Icons.unpublished_outlined : Icons.verified_outlined, size: 18),
                label: Text(sign.isValidated ? l10n.unvalidate : l10n.validate),
              ),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: l10n.delete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
