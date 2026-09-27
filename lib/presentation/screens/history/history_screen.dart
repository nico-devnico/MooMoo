import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/translation_entry.dart';
import '../../../domain/providers/session_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/skeletons.dart';
import '../settings/settings_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(userHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translationHistory)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(userHistoryProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: AppSpacing.l,
            bottom: settingsBottomPadding(context),
          ),
          child: PageContainer.reading(
            child: historyAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return AppEmptyState(
                    icon: AppIcons.history,
                    title: l10n.accountHistoryEmptyTitle,
                    message: l10n.accountHistoryEmptyMessage,
                    actionLabel: l10n.accountHistoryOpenTranslator,
                    onAction: () => context.goNamed(AppRoutes.translatorName),
                  );
                }
                return _HistoryList(sessions: sessions);
              },
              loading: () => const SettingsSkeleton(groups: [4, 3], lines: 2),
              error: (_, _) => AppEmptyState(
                icon: AppIcons.error,
                title: l10n.errorGeneric,
                message: l10n.accountLoadErrorMessage,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(userHistoryProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sessions regroupées par jour, du plus récent au plus ancien (ordre déjà
/// fourni par le dépôt).
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.sessions});

  final List<Map<String, dynamic>> sessions;

  String _dayTitle(BuildContext context, DateTime? day) {
    final l10n = AppLocalizations.of(context)!;
    if (day == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return l10n.accountToday;
    if (difference == 1) return l10n.yesterday;
    final locale = Localizations.localeOf(context).toString();
    final label = DateFormat.yMMMMEEEEd(locale).format(day);
    return label.isEmpty ? label : label[0].toUpperCase() + label.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final groups = <DateTime?, List<Map<String, dynamic>>>{};
    for (final session in sessions) {
      final date = _sessionDate(session);
      final day = date == null ? null : DateTime(date.year, date.month, date.day);
      groups.putIfAbsent(day, () => []).add(session);
    }

    final entries = groups.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xl),
          SettingsGroup(
            title: entries[i].key == null ? null : _dayTitle(context, entries[i].key),
            children: [
              for (final session in entries[i].value) _HistoryTile(session: session),
            ],
          ),
        ],
      ],
    );
  }
}

DateTime? _sessionDate(Map<String, dynamic> session) {
  final raw = session['created_at'];
  return raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.session});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    // Le dépôt ne joint que la dernière entrée de chaque session.
    final entries = session['translation_entries'] as List?;
    final lastText = entries != null && entries.isNotEmpty
        ? (entries.first as Map)['translated_text'] as String?
        : null;
    final sessionTitle = session['title'] as String?;
    final title = (lastText != null && lastText.trim().isNotEmpty)
        ? lastText.trim()
        : (sessionTitle != null && sessionTitle.trim().isNotEmpty)
            ? sessionTitle.trim()
            : l10n.accountUntitledSession;

    final isSignToText = session['session_type'] == 'sign_to_text';
    final direction = isSignToText ? l10n.accountSignToText : l10n.accountTextToSign;
    final total = (session['total_entries'] as num?)?.toInt() ?? 0;
    final date = _sessionDate(session);

    final subtitle = [
      if (date != null) DateFormat.Hm(locale).format(date),
      direction,
      l10n.accountSessionEntries(total),
    ].join(' · ');

    return SettingsTile(
      icon: isSignToText ? AppIcons.camera : AppIcons.keyboard,
      title: title,
      subtitle: subtitle,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        builder: (_) => _SessionSheet(
          sessionId: session['id'] as String,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }
}

class _SessionSheet extends ConsumerWidget {
  const _SessionSheet({
    required this.sessionId,
    required this.title,
    required this.subtitle,
  });

  final String sessionId;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(sessionEntriesProvider(sessionId));
    final secondary = AppColors.textSecondary(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: secondary)),
            const SizedBox(height: AppSpacing.l),
            Flexible(
              child: entriesAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                      child: Text(
                        l10n.accountSessionEmpty,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(color: secondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) => _EntryPanel(entry: entries[index]),
                  );
                },
                loading: () => Skeleton(
                  label: l10n.loading,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkeletonBlock(height: 88, radius: AppRadius.l),
                      SizedBox(height: AppSpacing.s),
                      SkeletonBlock(height: 88, radius: AppRadius.l),
                      SizedBox(height: AppSpacing.s),
                      SkeletonBlock(height: 88, radius: AppRadius.l),
                    ],
                  ),
                ),
                error: (_, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.accountLoadErrorMessage,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: secondary),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    TextButton.icon(
                      onPressed: () => ref.invalidate(sessionEntriesProvider(sessionId)),
                      icon: const Icon(AppIcons.refresh, size: 18),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryPanel extends StatelessWidget {
  const _EntryPanel({required this.entry});

  final TranslationEntry entry;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textSecondary(context);
    final locale = Localizations.localeOf(context).toString();
    final source = entry.sourceText?.trim();
    final translated = entry.translatedText?.trim();
    final hasSource = source != null && source.isNotEmpty;
    final hasTranslation = translated != null && translated.isNotEmpty;

    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSource)
            Text(source, style: AppTextStyles.bodySmall.copyWith(color: secondary)),
          if (hasSource && hasTranslation) const SizedBox(height: AppSpacing.xs),
          if (hasTranslation) Text(translated, style: AppTextStyles.bodyLarge),
          if (entry.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat.Hm(locale).format(entry.createdAt!.toLocal()),
              style: AppTextStyles.bodySmall.copyWith(color: secondary),
            ),
          ],
        ],
      ),
    );
  }
}
