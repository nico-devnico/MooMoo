import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/ml_training.dart';
import '../../../../domain/providers/ml_training_provider.dart';
import '../../../../domain/providers/sign_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_snackbar.dart';
import 'ml_common.dart';
import 'ml_form_fields.dart';

const _mediaFormats = ['auto', 'images', 'gif', 'video', 'mixed'];
const _otherLanguage = '__other__';
const _defaultLanguage = 'LSFB';

/// Parses `path = label` lines. Returns the 1-based number of the first
/// malformed line through [onError] and null in that case.
Map<String, String>? mlParseLabelMapping(
  String text, {
  void Function(int line)? onError,
}) {
  final mapping = <String, String>{};
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final sep = line.indexOf('=');
    if (sep <= 0) {
      onError?.call(i + 1);
      return null;
    }
    final path = line.substring(0, sep).trim();
    final label = line.substring(sep + 1).trim();
    if (path.isEmpty || label.isEmpty) {
      onError?.call(i + 1);
      return null;
    }
    mapping[path] = label;
  }
  return mapping;
}

String mlFormatLabelMapping(Map<String, String> mapping) =>
    mapping.entries.map((e) => '${e.key} = ${e.value}').join('\n');

FormFieldValidator<String> _mappingValidator(AppLocalizations l10n) {
  return (value) {
    int? bad;
    mlParseLabelMapping(value ?? '', onError: (line) => bad = line);
    return bad == null ? null : l10n.mlErrMappingLine(bad!);
  };
}

String mlMediaFormatLabel(AppLocalizations l10n, String f) => switch (f) {
  'images' => l10n.mlFormatImages,
  'gif' => l10n.mlFormatGif,
  'video' => l10n.mlFormatVideo,
  'mixed' => l10n.mlFormatMixed,
  _ => l10n.mlFormatAuto,
};

Future<bool> showMlAddDatasetDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final created = await showMlAdaptive<bool>(
    context,
    title: l10n.mlDatasetAdd,
    maxWidth: 640,
    builder: (_) => const _AddDatasetForm(),
  );
  if (created == true && context.mounted) {
    AppSnackbar.showSuccess(context, l10n.mlDatasetCreated);
  }
  return created == true;
}

class _AddDatasetForm extends ConsumerStatefulWidget {
  const _AddDatasetForm();

  @override
  ConsumerState<_AddDatasetForm> createState() => _AddDatasetFormState();
}

class _AddDatasetFormState extends ConsumerState<_AddDatasetForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController(text: _defaultLanguage);
  final _uri = TextEditingController();
  final _mapping = TextEditingController();
  String? _language;
  String _source = 'local';
  String _format = 'auto';
  bool _structured = true;
  bool _labeled = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _uri.dispose();
    _mapping.dispose();
    super.dispose();
  }

  String get _languageCode =>
      (_language == null || _language == _otherLanguage)
          ? _code.text.trim().toUpperCase()
          : _language!;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref.read(mlTrainingRepositoryProvider).createDataset(
            name: _name.text,
            languageCode: _languageCode,
            sourceType: _source,
            uri: _uri.text,
            mediaFormat: _format,
            isStructured: _structured,
            isLabeled: _labeled,
            labelMapping: mlParseLabelMapping(_mapping.text) ?? const {},
          );
      ref
        ..invalidate(mlDatasetsProvider)
        ..invalidate(mlJobsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        AppSnackbar.showError(context, mlErrorText(l10n, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);
    final codes = (ref.watch(signLanguagesProvider).value ?? const [])
        .map((l) => (code: l.code.toUpperCase(), name: l.name))
        .toList();
    final language = _language ??
        (codes.any((c) => c.code == _defaultLanguage)
            ? _defaultLanguage
            : (codes.isNotEmpty ? codes.first.code : _otherLanguage));
    final showFreeCode = language == _otherLanguage;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.mlDatasetAddHint,
            style: AppTextStyles.bodySmall.copyWith(color: secondary),
          ),
          const SizedBox(height: AppSpacing.l),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.mlFieldName),
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? l10n.mlErrRequired : null,
          ),
          const SizedBox(height: AppSpacing.m),
          MlFieldGrid(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('lang-${codes.length}'),
                initialValue: language,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.mlFieldLanguage),
                items: [
                  for (final c in codes)
                    DropdownMenuItem(
                      value: c.code,
                      child: Text(
                        '${c.code} · ${c.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  DropdownMenuItem(
                    value: _otherLanguage,
                    child: Text(l10n.mlLanguageOther),
                  ),
                ],
                onChanged: _busy ? null : (v) => setState(() => _language = v),
              ),
              if (showFreeCode)
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.mlFieldLanguageCode,
                    helperText: l10n.mlFieldLanguageCodeHelp,
                    helperMaxLines: 2,
                  ),
                  validator: (v) =>
                      RegExp(r'^[A-Za-z]{2,10}$').hasMatch(v?.trim() ?? '')
                          ? null
                          : l10n.mlErrLanguageCode,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Text(l10n.mlFieldSource, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.s),
          SegmentedButton<String>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'local',
                icon: const Icon(PhosphorIconsRegular.folderOpen),
                label: Text(l10n.mlSourceLocal),
              ),
              ButtonSegment(
                value: 'url',
                icon: const Icon(PhosphorIconsRegular.link),
                label: Text(l10n.mlSourceUrl),
              ),
            ],
            selected: {_source},
            onSelectionChanged:
                _busy ? null : (s) => setState(() => _source = s.first),
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _uri,
            keyboardType:
                _source == 'url' ? TextInputType.url : TextInputType.text,
            decoration: InputDecoration(
              labelText: _source == 'url' ? l10n.mlFieldUrl : l10n.mlFieldPath,
              helperText: _source == 'url'
                  ? l10n.mlFieldUrlHelp
                  : l10n.mlFieldPathHelp,
              helperMaxLines: 3,
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return l10n.mlErrRequired;
              if (_source == 'url') {
                final uri = Uri.tryParse(value);
                if (uri == null ||
                    !(uri.scheme == 'http' || uri.scheme == 'https') ||
                    uri.host.isEmpty) {
                  return l10n.mlErrUrl;
                }
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.m),
          DropdownButtonFormField<String>(
            initialValue: _format,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.mlFieldFormat),
            items: [
              for (final f in _mediaFormats)
                DropdownMenuItem(
                  value: f,
                  child: Text(mlMediaFormatLabel(l10n, f)),
                ),
            ],
            onChanged: _busy ? null : (v) => setState(() => _format = v ?? _format),
          ),
          const SizedBox(height: AppSpacing.s),
          MlSwitchTile(
            title: l10n.mlFieldStructured,
            subtitle: l10n.mlFieldStructuredHelp,
            value: _structured,
            onChanged: _busy ? null : (v) => setState(() => _structured = v),
          ),
          MlSwitchTile(
            title: l10n.mlFieldLabeled,
            subtitle: l10n.mlFieldLabeledHelp,
            value: _labeled,
            onChanged: _busy ? null : (v) => setState(() => _labeled = v),
          ),
          const SizedBox(height: AppSpacing.s),
          _MappingField(controller: _mapping),
          const SizedBox(height: AppSpacing.l),
          MlFormActions(
            submitLabel: l10n.mlDatasetCreate,
            submitIcon: AppIcons.add,
            busy: _busy,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

class _MappingField extends StatelessWidget {
  const _MappingField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      minLines: 4,
      maxLines: 10,
      style: AppTextStyles.mono,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: l10n.mlFieldLabelMapping,
        helperText: l10n.mlFieldLabelMappingHelp,
        helperMaxLines: 3,
        errorMaxLines: 2,
        hintText: 'videos/bonjour_01.mp4 = BONJOUR',
        alignLabelWithHint: true,
      ),
      validator: _mappingValidator(l10n),
    );
  }
}

Future<void> showMlLabelMappingDialog(
  BuildContext context,
  MlDataset dataset,
) async {
  final l10n = AppLocalizations.of(context)!;
  final saved = await showMlAdaptive<bool>(
    context,
    title: l10n.mlMappingTitle(dataset.name),
    maxWidth: 640,
    builder: (_) => _MappingForm(dataset: dataset),
  );
  if (saved == true && context.mounted) {
    AppSnackbar.showSuccess(context, l10n.mlMappingSaved);
  }
}

class _MappingForm extends ConsumerStatefulWidget {
  const _MappingForm({required this.dataset});

  final MlDataset dataset;

  @override
  ConsumerState<_MappingForm> createState() => _MappingFormState();
}

class _MappingFormState extends ConsumerState<_MappingForm> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: mlFormatLabelMapping(widget.dataset.labelMapping),
  );
  bool _reanalyze = true;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(mlTrainingRepositoryProvider);
      await repo.updateLabelMapping(
        widget.dataset.id,
        mlParseLabelMapping(_controller.text) ?? const {},
      );
      if (_reanalyze) {
        await repo.enqueue(kind: 'analyze', dataset: widget.dataset);
      }
      ref
        ..invalidate(mlDatasetsProvider)
        ..invalidate(mlJobsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        AppSnackbar.showError(context, mlErrorText(l10n, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MappingField(controller: _controller),
          const SizedBox(height: AppSpacing.s),
          MlSwitchTile(
            title: l10n.mlMappingReanalyze,
            value: _reanalyze,
            onChanged: _busy ? null : (v) => setState(() => _reanalyze = v),
          ),
          const SizedBox(height: AppSpacing.l),
          MlFormActions(
            submitLabel: l10n.save,
            submitIcon: AppIcons.check,
            busy: _busy,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

/// Asks for the landmark extraction settings, then queues the job.
Future<bool> showMlPreprocessDialog(
  BuildContext context,
  MlDataset dataset,
) async {
  final l10n = AppLocalizations.of(context)!;
  final queued = await showMlAdaptive<bool>(
    context,
    title: l10n.mlPreprocessTitle(dataset.name),
    maxWidth: 560,
    builder: (_) => _PreprocessForm(dataset: dataset),
  );
  if (queued == true && context.mounted) {
    AppSnackbar.showSuccess(context, l10n.mlJobQueuedMessage);
  }
  return queued == true;
}

class _PreprocessForm extends ConsumerStatefulWidget {
  const _PreprocessForm({required this.dataset});

  final MlDataset dataset;

  @override
  ConsumerState<_PreprocessForm> createState() => _PreprocessFormState();
}

class _PreprocessFormState extends ConsumerState<_PreprocessForm> {
  final _formKey = GlobalKey<FormState>();
  final _maxFrames = TextEditingController(text: '96');
  bool _includeFace = false;
  bool _requireHands = true;
  bool _busy = false;

  @override
  void dispose() {
    _maxFrames.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref.read(mlTrainingRepositoryProvider).enqueue(
        kind: 'preprocess',
        dataset: widget.dataset,
        config: {
          'preprocessing': {
            'include_face': _includeFace,
            'max_frames': int.parse(_maxFrames.text.trim()),
            'model_complexity': 1,
            'require_hands': _requireHands,
          },
        },
      );
      ref
        ..invalidate(mlDatasetsProvider)
        ..invalidate(mlJobsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        AppSnackbar.showError(context, mlErrorText(l10n, e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.mlPreprocessHint,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          MlNumberField(
            controller: _maxFrames,
            label: l10n.mlFieldMaxFrames,
            helper: l10n.mlFieldMaxFramesHelp,
            validator: mlIntValidator(l10n, min: 8, max: 1000),
          ),
          const SizedBox(height: AppSpacing.s),
          MlSwitchTile(
            title: l10n.mlFieldIncludeFace,
            subtitle: l10n.mlFieldIncludeFaceHelp,
            value: _includeFace,
            onChanged: _busy ? null : (v) => setState(() => _includeFace = v),
          ),
          MlSwitchTile(
            title: l10n.mlFieldRequireHands,
            value: _requireHands,
            onChanged: _busy ? null : (v) => setState(() => _requireHands = v),
          ),
          const SizedBox(height: AppSpacing.l),
          MlFormActions(
            submitLabel: l10n.mlActionPreprocess,
            submitIcon: AppIcons.play,
            busy: _busy,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}
