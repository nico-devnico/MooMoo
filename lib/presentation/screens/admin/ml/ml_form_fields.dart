import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Parses "128, 256,128" into integers; null when a token is not an integer.
List<int>? mlParseIntList(String text) {
  final tokens = text
      .split(RegExp(r'[,;\s]+'))
      .where((t) => t.trim().isNotEmpty)
      .toList();
  final values = <int>[];
  for (final t in tokens) {
    final v = int.tryParse(t.trim());
    if (v == null) return null;
    values.add(v);
  }
  return values;
}

double? mlParseDouble(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

FormFieldValidator<String> mlIntValidator(
  AppLocalizations l10n, {
  required int min,
  required int max,
}) {
  return (value) {
    final v = int.tryParse(value?.trim() ?? '');
    if (v == null || v < min || v > max) {
      return l10n.mlErrIntRange(min, max);
    }
    return null;
  };
}

FormFieldValidator<String> mlDoubleValidator(
  AppLocalizations l10n, {
  required double min,
  required double max,
}) {
  return (value) {
    final v = mlParseDouble(value ?? '');
    if (v == null || v < min || v > max) {
      return l10n.mlErrNumberRange(min.toString(), max.toString());
    }
    return null;
  };
}

FormFieldValidator<String> mlIntListValidator(
  AppLocalizations l10n, {
  required int min,
  required int max,
  bool allowEmpty = false,
}) {
  return (value) {
    final list = mlParseIntList(value ?? '');
    if (list == null) return l10n.mlErrIntList;
    if (list.isEmpty && !allowEmpty) return l10n.mlErrIntList;
    if (list.any((v) => v < min || v > max)) {
      return l10n.mlErrIntRange(min, max);
    }
    return null;
  };
}

class MlNumberField extends StatelessWidget {
  const MlNumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.helper,
    this.decimal = false,
    this.text = false,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final String? helper;
  final bool decimal;

  /// Comma-separated lists use the plain text keyboard.
  final bool text;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: text
          ? TextInputType.text
          : TextInputType.numberWithOptions(decimal: decimal),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      validator: validator,
    );
  }
}

/// Lays fields out in 1, 2 or 3 columns depending on the available width.
class MlFieldGrid extends StatelessWidget {
  const MlFieldGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 760 ? 3 : (width >= 480 ? 2 : 1);
        final itemWidth = (width - AppSpacing.m * (cols - 1)) / cols;
        return Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.m,
          children: [
            for (final c in children) SizedBox(width: itemWidth, child: c),
          ],
        );
      },
    );
  }
}

class MlSwitchTile extends StatelessWidget {
  const MlSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// A form section: always open on large screens, collapsible on phones.
/// Collapsed children stay mounted so their validators still run.
class MlFormSection extends StatelessWidget {
  const MlFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.m),
          children[i],
        ],
      ],
    );
    final heading = Row(
      children: [
        ExcludeSemantics(child: Icon(icon, size: 20, color: AppColors.primary)),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );

    if (context.isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.m),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border(context)),
          borderRadius: AppRadius.radiusM,
        ),
        child: ExpansionTile(
          title: heading,
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          shape: const Border(),
          collapsedShape: const Border(),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.m,
          ),
          children: [body],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.l),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border(context)),
        borderRadius: AppRadius.radiusM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [heading, const SizedBox(height: AppSpacing.m), body],
      ),
    );
  }
}

/// Cancel + primary action, right-aligned, never full width on desktop.
class MlFormActions extends StatelessWidget {
  const MlFormActions({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.busy = false,
    this.submitIcon,
  });

  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool busy;
  final IconData? submitIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, kMinTouchTarget),
          ),
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, kMinTouchTarget),
          ),
          onPressed: busy ? null : onSubmit,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(submitIcon, size: 18),
          label: Text(submitLabel),
        ),
      ],
    );
  }
}
