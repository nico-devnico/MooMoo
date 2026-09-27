import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/ml_training.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_panel.dart';

/// Wide enough for training curves side by side, still readable on monitors.
const double kMlContentMaxWidth = 1100;

/// From this width, details open in a dialog instead of a full-screen page.
const double kMlDialogBreakpoint = 900;

String mlFormatDate(DateTime date) {
  final d = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

String mlFormatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '$h h ${m.toString().padLeft(2, '0')} min';
  if (m > 0) return '$m min ${s.toString().padLeft(2, '0')} s';
  return '$s s';
}

String mlFormatSeconds(double? seconds) => seconds == null
    ? '—'
    : mlFormatDuration(Duration(milliseconds: (seconds * 1000).round()));

String mlFormatBytes(AppLocalizations l10n, int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  if (bytes >= 1024 * 1024) {
    return l10n.mlUnitMb((bytes / (1024 * 1024)).toStringAsFixed(1));
  }
  if (bytes >= 1024) return l10n.mlUnitKb((bytes / 1024).toStringAsFixed(1));
  return l10n.mlUnitB(bytes.toString());
}

String mlPercent(double? value) =>
    value == null ? '—' : '${(value * 100).toStringAsFixed(1)} %';

String mlNumber(double? value, {int digits = 3}) =>
    value == null ? '—' : value.toStringAsFixed(digits);

/// Postgres refusals (RLS, stage transitions) carry a readable message.
String mlErrorText(AppLocalizations l10n, Object error) {
  if (error is PostgrestException) return error.message;
  return '${l10n.adminRlsOrNetworkError}: $error';
}

typedef MlStatusInfo = ({String label, Color color, IconData icon});

MlStatusInfo mlDatasetStatus(AppLocalizations l10n, DatasetStatus status) =>
    switch (status) {
      DatasetStatus.registered => (
        label: l10n.mlStatusRegistered,
        color: AppColors.info,
        icon: PhosphorIconsRegular.tray,
      ),
      DatasetStatus.analyzing => (
        label: l10n.mlStatusAnalyzing,
        color: AppColors.warning,
        icon: PhosphorIconsRegular.hourglassMedium,
      ),
      DatasetStatus.analyzed => (
        label: l10n.mlStatusAnalyzed,
        color: AppColors.info,
        icon: PhosphorIconsRegular.magnifyingGlass,
      ),
      DatasetStatus.preprocessing => (
        label: l10n.mlStatusPreprocessing,
        color: AppColors.warning,
        icon: PhosphorIconsRegular.hourglassMedium,
      ),
      DatasetStatus.ready => (
        label: l10n.mlStatusReady,
        color: AppColors.success,
        icon: AppIcons.success,
      ),
      DatasetStatus.failed => (
        label: l10n.mlStatusFailed,
        color: AppColors.error,
        icon: AppIcons.error,
      ),
    };

MlStatusInfo mlJobStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'running' => (
        label: l10n.mlJobRunning,
        color: AppColors.info,
        icon: PhosphorIconsRegular.hourglassMedium,
      ),
      'cancelling' => (
        label: l10n.mlJobCancelling,
        color: AppColors.warning,
        icon: PhosphorIconsRegular.hourglassMedium,
      ),
      'cancelled' => (
        label: l10n.mlJobCancelled,
        color: AppColors.textSecondaryLight,
        icon: AppIcons.blocked,
      ),
      'done' => (
        label: l10n.mlJobDone,
        color: AppColors.success,
        icon: AppIcons.success,
      ),
      'failed' => (
        label: l10n.mlJobFailed,
        color: AppColors.error,
        icon: AppIcons.error,
      ),
      _ => (
        label: l10n.mlJobQueued,
        color: AppColors.warning,
        icon: PhosphorIconsRegular.queue,
      ),
    };

MlStatusInfo mlExperimentStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'running' => (
        label: l10n.mlExpRunning,
        color: AppColors.info,
        icon: PhosphorIconsRegular.hourglassMedium,
      ),
      'completed' => (
        label: l10n.mlExpCompleted,
        color: AppColors.success,
        icon: AppIcons.success,
      ),
      'failed' => (
        label: l10n.mlExpFailed,
        color: AppColors.error,
        icon: AppIcons.error,
      ),
      'pruned' => (
        label: l10n.mlExpPruned,
        color: AppColors.textSecondaryLight,
        icon: PhosphorIconsRegular.scissors,
      ),
      'cancelled' => (
        label: l10n.mlExpCancelled,
        color: AppColors.textSecondaryLight,
        icon: AppIcons.blocked,
      ),
      _ => (
        label: l10n.mlExpQueued,
        color: AppColors.warning,
        icon: PhosphorIconsRegular.queue,
      ),
    };

String mlStageLabel(AppLocalizations l10n, String stage) => switch (stage) {
  'training' => l10n.mlStageTraining,
  'trained' => l10n.mlStageTrained,
  'evaluated' => l10n.mlStageEvaluated,
  'validated' => l10n.mlStageValidated,
  'staging' => l10n.mlStageStaging,
  'production' => l10n.mlStageProduction,
  'archived' => l10n.mlStageArchived,
  _ => stage.toUpperCase(),
};

MlStatusInfo mlStageStatus(AppLocalizations l10n, String stage) {
  final label = mlStageLabel(l10n, stage);
  return switch (stage) {
    'production' => (
      label: label,
      color: AppColors.primary,
      icon: PhosphorIconsRegular.rocketLaunch,
    ),
    'staging' => (
      label: label,
      color: AppColors.warning,
      icon: PhosphorIconsRegular.flask,
    ),
    'validated' => (label: label, color: AppColors.success, icon: AppIcons.success),
    'archived' => (
      label: label,
      color: AppColors.textSecondaryLight,
      icon: PhosphorIconsRegular.archive,
    ),
    'training' => (
      label: label,
      color: AppColors.warning,
      icon: PhosphorIconsRegular.hourglassMedium,
    ),
    _ => (label: label, color: AppColors.info, icon: AppIcons.model),
  };
}

String mlJobKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'analyze' => l10n.mlKindAnalyze,
  'preprocess' => l10n.mlKindPreprocess,
  'train' => l10n.mlKindTrain,
  'search' => l10n.mlKindSearch,
  'evaluate' => l10n.mlKindEvaluate,
  'convert' => l10n.mlKindConvert,
  _ => kind,
};

/// Constrains a block to [kMlContentMaxWidth], aligned like the rest of the
/// admin pages.
class MlConstrained extends StatelessWidget {
  const MlConstrained({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMlContentMaxWidth),
        child: child,
      ),
    );
  }
}

class MlSectionTitle extends StatelessWidget {
  const MlSectionTitle(this.text, {super.key, this.small = false});

  final String text;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: small
            ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)
            : AppTextStyles.h3,
      ),
    );
  }
}

/// Section header of a tab: title, explanation and optional actions, stacked
/// on narrow screens so nothing overlaps.
class MlTabHeader extends StatelessWidget {
  const MlTabHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MlSectionTitle(title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
    final actionRow = Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: actions,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (actions.isEmpty) return text;
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: AppSpacing.m), actionRow],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: text),
            const SizedBox(width: AppSpacing.l),
            actionRow,
          ],
        );
      },
    );
  }
}

class MlMetricChip extends StatelessWidget {
  const MlMetricChip({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ?? AppColors.neutral(context),
        borderRadius: AppRadius.radiusS,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}

/// A status always shown as icon + text, never as colour alone.
class MlStatusBadge extends StatelessWidget {
  const MlStatusBadge({super.key, required this.info});

  final MlStatusInfo info;

  @override
  Widget build(BuildContext context) {
    final color = info.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusCircular,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(info.icon, size: 14, color: color)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            info.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One warning, recommendation or error line: icon + text in the same colour.
class MlNoticeLine extends StatelessWidget {
  const MlNoticeLine({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ExcludeSemantics(child: Icon(icon, size: 16, color: color)),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class MlErrorPanel extends StatelessWidget {
  const MlErrorPanel({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPanel(
      child: AppEmptyState(
        icon: PhosphorIconsRegular.cloudSlash,
        title: l10n.errorGeneric,
        message: mlErrorText(l10n, error),
        actionLabel: l10n.retry,
        onAction: onRetry,
      ),
    );
  }
}

/// Minimum-size icon button with a mandatory tooltip.
class MlIconButton extends StatelessWidget {
  const MlIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints(
        minWidth: kMinTouchTarget,
        minHeight: kMinTouchTarget,
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: color),
    );
  }
}

/// Opens [builder] as a dialog on large screens, as a full-screen page on
/// phones where a dialog would leave no room for tables and charts.
Future<T?> showMlAdaptive<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  double maxWidth = 960,
}) {
  final l10n = AppLocalizations.of(context)!;
  final wide = MediaQuery.sizeOf(context).width >= kMlDialogBreakpoint;
  if (wide) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.l),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.m,
                  AppSpacing.s,
                  AppSpacing.s,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(title, style: AppTextStyles.h3),
                      ),
                    ),
                    MlIconButton(
                      icon: AppIcons.close,
                      tooltip: l10n.mlClose,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.border(context)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: builder(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: MlIconButton(
            icon: AppIcons.close,
            tooltip: l10n.mlClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.m,
            AppSpacing.m,
            AppSpacing.xxl,
          ),
          child: builder(context),
        ),
      ),
    ),
  );
}

/// A block of titled content inside a detail view.
class MlDetailSection extends StatelessWidget {
  const MlDetailSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MlSectionTitle(title, small: true),
          const SizedBox(height: AppSpacing.s),
          child,
        ],
      ),
    );
  }
}
