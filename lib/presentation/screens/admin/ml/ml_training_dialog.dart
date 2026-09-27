import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/ml_training.dart';
import '../../../../domain/providers/ml_training_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_snackbar.dart';
import 'ml_common.dart';
import 'ml_form_fields.dart';

const _optimizers = ['adam', 'adamw', 'rmsprop', 'sgd', 'nadam'];
const _losses = [
  'categorical_crossentropy',
  'sparse_categorical_crossentropy',
  'categorical_focal_crossentropy',
];
const _splitStrategies = ['auto', 'signer', 'stratified', 'predefined'];
const _quantizations = ['dynamic', 'float16', 'none'];

/// Datasets that can feed a training job.
List<MlDataset> mlTrainableDatasets(List<MlDataset> all) => all
    .where(
      (d) =>
          d.isTrainable &&
          (d.status == DatasetStatus.ready ||
              d.status == DatasetStatus.analyzed),
    )
    .toList();

/// Opens the training form. Resolves to true once a job has been queued.
Future<bool> showMlTrainingDialog(
  BuildContext context, {
  MlDataset? dataset,
  required List<MlDataset> datasets,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final queued = await showMlAdaptive<bool>(
    context,
    title: l10n.mlTrainTitle,
    maxWidth: 900,
    builder: (_) => MlTrainingForm(
      dataset: dataset,
      datasets: mlTrainableDatasets(datasets),
    ),
  );
  if (queued == true && context.mounted) {
    AppSnackbar.showSuccess(context, l10n.mlTrainQueued);
  }
  return queued == true;
}

String mlQuantizationLabel(AppLocalizations l10n, String q) => switch (q) {
  'float16' => l10n.mlQuantFloat16,
  'none' => l10n.mlQuantNone,
  _ => l10n.mlQuantDynamic,
};

String mlQuantizationHelp(AppLocalizations l10n, String q) => switch (q) {
  'float16' => l10n.mlQuantFloat16Help,
  'none' => l10n.mlQuantNoneHelp,
  _ => l10n.mlQuantDynamicHelp,
};

/// Lets the admin pick the TFLite quantization; null when dismissed.
Future<String?> showMlQuantizationDialog(
  BuildContext context, {
  required String title,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (final q in _quantizations)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(q),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.s,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mlQuantizationLabel(l10n, q),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    mlQuantizationHelp(l10n, q),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.s,
            AppSpacing.l,
            0,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ),
        ),
      ],
    ),
  );
}

class MlTrainingForm extends ConsumerStatefulWidget {
  const MlTrainingForm({super.key, this.dataset, required this.datasets});

  final MlDataset? dataset;
  final List<MlDataset> datasets;

  @override
  ConsumerState<MlTrainingForm> createState() => _MlTrainingFormState();
}

class _MlTrainingFormState extends ConsumerState<MlTrainingForm> {
  static const _defaults = {
    'seq': '30',
    'maxFrames': '96',
    'train': '70',
    'val': '15',
    'test': '15',
    'minPerClass': '2',
    'target': '30',
    'maxFactor': '5',
    'timeWarp': '0.2',
    'frameDrop': '0.1',
    'rotation': '10',
    'scale': '0.1',
    'translation': '0.05',
    'noise': '0.01',
    'lstm': '128,256,128',
    'dropout': '0.2',
    'dense': '',
    'lr': '0.001',
    'batch': '32',
    'epochs': '100',
    'smoothing': '0.0',
    'patience': '15',
    'lrPatience': '6',
    'sMaxEpochs': '81',
    'sEta': '3',
    'sTrials': '20',
    'sSeed': '42',
    'sLayers': '1,2,3',
    'sUnits': '64,128,256',
    'sDropMin': '0.0',
    'sDropMax': '0.5',
    'sDense': '0,1',
    'sDenseUnits': '64,128',
    'sLrMin': '0.0001',
    'sLrMax': '0.003',
    'sBatch': '16,32,64',
  };

  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c = {
    for (final e in _defaults.entries) e.key: TextEditingController(text: e.value),
  };

  String _mode = 'train';
  String? _datasetId;
  bool _includeFace = false;
  bool _normalize = true;
  bool _augment = true;
  bool _classWeight = true;
  bool _layerNorm = false;
  bool _autoRegister = true;
  String _splitStrategy = 'auto';
  String _optimizer = 'adam';
  String _loss = 'categorical_crossentropy';
  String _quantization = 'dynamic';
  final Set<String> _searchOptimizers = {'adam', 'adamw'};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final preset = widget.dataset;
    if (preset != null && widget.datasets.any((d) => d.id == preset.id)) {
      _datasetId = preset.id;
    } else if (widget.datasets.isNotEmpty) {
      _datasetId = widget.datasets.first.id;
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  int _int(String key) => int.parse(_c[key]!.text.trim());
  double _double(String key) => mlParseDouble(_c[key]!.text)!;
  List<int> _ints(String key) => mlParseIntList(_c[key]!.text) ?? const [];

  MlDataset? get _dataset =>
      widget.datasets.where((d) => d.id == _datasetId).firstOrNull;

  String? _splitError(AppLocalizations l10n) {
    final parts = ['train', 'val', 'test']
        .map((k) => int.tryParse(_c[k]!.text.trim()))
        .toList();
    if (parts.any((p) => p == null)) return null;
    final sum = parts.fold<int>(0, (a, b) => a + b!);
    return sum == 100 ? null : l10n.mlErrSplitSum(sum);
  }

  Map<String, dynamic> _config() {
    final config = <String, dynamic>{
      'preprocessing': {
        'include_face': _includeFace,
        'max_frames': _int('maxFrames'),
        'model_complexity': 1,
        'require_hands': true,
      },
      'sequence_length': _int('seq'),
      'normalize': _normalize,
      'split': {
        'train': _int('train') / 100,
        'val': _int('val') / 100,
        'test': _int('test') / 100,
      },
      'split_strategy': _splitStrategy,
      'min_samples_per_class': _int('minPerClass'),
      'augmentation': {
        'enabled': _augment,
        'target_per_class': _int('target'),
        'max_factor': _int('maxFactor'),
        'time_warp': _double('timeWarp'),
        'frame_drop': _double('frameDrop'),
        'rotation_deg': _double('rotation'),
        'scale': _double('scale'),
        'translation': _double('translation'),
        'noise_std': _double('noise'),
      },
      'model': {
        'lstm_units': _ints('lstm'),
        'dropout': _double('dropout'),
        'dense_units': _ints('dense'),
        'optimizer': _optimizer,
        'learning_rate': _double('lr'),
        'batch_size': _int('batch'),
        'epochs': _int('epochs'),
        'loss': _loss,
        'label_smoothing': _double('smoothing'),
        'class_weight': _classWeight ? 'balanced' : 'none',
        'early_stopping_patience': _int('patience'),
        'reduce_lr_patience': _int('lrPatience'),
        'layer_norm': _layerNorm,
      },
      'quantization': _quantization,
      'auto_register': _autoRegister,
    };
    if (_mode == 'search') {
      config['search'] = {
        'max_epochs': _int('sMaxEpochs'),
        'eta': _int('sEta'),
        'max_trials': _int('sTrials'),
        'seed': _int('sSeed'),
        'space': {
          'lstm_layers': _ints('sLayers'),
          'lstm_units': _ints('sUnits'),
          'dropout': [_double('sDropMin'), _double('sDropMax')],
          'dense_layers': _ints('sDense'),
          'dense_units': _ints('sDenseUnits'),
          'learning_rate': [_double('sLrMin'), _double('sLrMax')],
          'batch_size': _ints('sBatch'),
          'optimizer': [
            for (final o in _optimizers)
              if (_searchOptimizers.contains(o)) o,
          ],
        },
      };
    }
    return config;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final dataset = _dataset;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || dataset == null || _splitError(l10n) != null) {
      AppSnackbar.showError(context, l10n.mlErrFixFields);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(mlTrainingRepositoryProvider)
          .enqueue(kind: _mode, dataset: dataset, config: _config());
      ref.invalidate(mlJobsProvider);
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

    if (widget.datasets.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MlNoticeLine(
            icon: AppIcons.warning,
            color: AppColors.warning,
            text: l10n.mlTrainNoDataset,
          ),
          const SizedBox(height: AppSpacing.l),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.mlClose),
            ),
          ),
        ],
      );
    }

    final dataset = _dataset;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              expandedInsets: EdgeInsets.zero,
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: 'train',
                  icon: const Icon(PhosphorIconsRegular.slidersHorizontal),
                  label: Text(l10n.mlModeManual, maxLines: 2),
                ),
                ButtonSegment(
                  value: 'search',
                  icon: const Icon(PhosphorIconsRegular.magicWand),
                  label: Text(l10n.mlModeSearch, maxLines: 2),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _busy
                  ? null
                  : (s) => setState(() => _mode = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            _mode == 'search' ? l10n.mlModeSearchHint : l10n.mlModeManualHint,
            style: AppTextStyles.bodySmall.copyWith(color: secondary),
          ),
          const SizedBox(height: AppSpacing.l),
          DropdownButtonFormField<String>(
            initialValue: _datasetId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.mlFieldDataset),
            items: [
              for (final d in widget.datasets)
                DropdownMenuItem(
                  value: d.id,
                  child: Text(
                    '${d.name} · ${d.languageCode}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _busy ? null : (v) => setState(() => _datasetId = v),
          ),
          if (dataset != null) ...[
            const SizedBox(height: AppSpacing.s),
            MlNoticeLine(
              icon: AppIcons.language,
              color: secondary,
              text: l10n.mlTrainLanguageNote(
                dataset.languageCode,
                dataset.classesCount,
                dataset.labeledSamples,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.l),
          MlFormSection(
            title: l10n.mlSectionData,
            icon: AppIcons.database,
            initiallyExpanded: true,
            children: [
              MlFieldGrid(
                children: [
                  MlNumberField(
                    controller: _c['seq']!,
                    label: l10n.mlFieldSequenceLength,
                    helper: l10n.mlFieldSequenceLengthHelp,
                    validator: mlIntValidator(l10n, min: 8, max: 256),
                  ),
                  MlNumberField(
                    controller: _c['maxFrames']!,
                    label: l10n.mlFieldMaxFrames,
                    validator: mlIntValidator(l10n, min: 8, max: 1000),
                  ),
                  MlNumberField(
                    controller: _c['minPerClass']!,
                    label: l10n.mlFieldMinPerClass,
                    validator: mlIntValidator(l10n, min: 1, max: 1000),
                  ),
                ],
              ),
              MlSwitchTile(
                title: l10n.mlFieldIncludeFace,
                subtitle: l10n.mlFieldIncludeFaceHelp,
                value: _includeFace,
                onChanged: (v) => setState(() => _includeFace = v),
              ),
              MlSwitchTile(
                title: l10n.mlFieldNormalize,
                value: _normalize,
                onChanged: (v) => setState(() => _normalize = v),
              ),
              MlFieldGrid(
                children: [
                  for (final k in ['train', 'val', 'test'])
                    MlNumberField(
                      controller: _c[k]!,
                      label: switch (k) {
                        'train' => l10n.mlFieldSplitTrain,
                        'val' => l10n.mlFieldSplitVal,
                        _ => l10n.mlFieldSplitTest,
                      },
                      validator: mlIntValidator(
                        l10n,
                        min: k == 'train' ? 10 : 0,
                        max: 90,
                      ),
                    ),
                ],
              ),
              ListenableBuilder(
                listenable: Listenable.merge([
                  _c['train']!,
                  _c['val']!,
                  _c['test']!,
                ]),
                builder: (context, _) {
                  final error = _splitError(l10n);
                  return error == null
                      ? const SizedBox.shrink()
                      : MlNoticeLine(
                          icon: AppIcons.error,
                          color: AppColors.error,
                          text: error,
                        );
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _splitStrategy,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.mlFieldSplitStrategy,
                  helperText: l10n.mlFieldSplitStrategyHelp,
                  helperMaxLines: 3,
                ),
                items: [
                  for (final s in _splitStrategies)
                    DropdownMenuItem(
                      value: s,
                      child: Text(switch (s) {
                        'signer' => l10n.mlSplitSigner,
                        'stratified' => l10n.mlSplitStratified,
                        'predefined' => l10n.mlSplitPredefined,
                        _ => l10n.mlSplitAuto,
                      }),
                    ),
                ],
                onChanged: (v) =>
                    setState(() => _splitStrategy = v ?? _splitStrategy),
              ),
            ],
          ),
          MlFormSection(
            title: l10n.mlSectionAugmentation,
            icon: PhosphorIconsRegular.shuffle,
            children: [
              MlSwitchTile(
                title: l10n.mlFieldAugment,
                subtitle: l10n.mlFieldAugmentHelp,
                value: _augment,
                onChanged: (v) => setState(() => _augment = v),
              ),
              MlFieldGrid(
                children: [
                  MlNumberField(
                    controller: _c['target']!,
                    label: l10n.mlFieldTargetPerClass,
                    validator: mlIntValidator(l10n, min: 1, max: 10000),
                  ),
                  MlNumberField(
                    controller: _c['maxFactor']!,
                    label: l10n.mlFieldMaxFactor,
                    validator: mlIntValidator(l10n, min: 1, max: 50),
                  ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                maintainState: true,
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  l10n.mlAdvancedSettings,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(bottom: AppSpacing.s),
                children: [
                  MlFieldGrid(
                    children: [
                      MlNumberField(
                        controller: _c['timeWarp']!,
                        label: l10n.mlFieldTimeWarp,
                        decimal: true,
                        validator: mlDoubleValidator(l10n, min: 0, max: 1),
                      ),
                      MlNumberField(
                        controller: _c['frameDrop']!,
                        label: l10n.mlFieldFrameDrop,
                        decimal: true,
                        validator: mlDoubleValidator(l10n, min: 0, max: 0.9),
                      ),
                      MlNumberField(
                        controller: _c['rotation']!,
                        label: l10n.mlFieldRotation,
                        decimal: true,
                        validator: mlDoubleValidator(l10n, min: 0, max: 45),
                      ),
                      MlNumberField(
                        controller: _c['scale']!,
                        label: l10n.mlFieldScale,
                        decimal: true,
                        validator: mlDoubleValidator(l10n, min: 0, max: 0.5),
                      ),
                      MlNumberField(
                        controller: _c['translation']!,
                        label: l10n.mlFieldTranslation,
                        decimal: true,
                        validator: mlDoubleValidator(l10n, min: 0, max: 0.5),
                      ),
                      MlNumberField(
                        controller: _c['noise']!,
                        label: l10n.mlFieldNoise,
                        decimal: true,
                        validator: mlDoubleValidator(l10n, min: 0, max: 0.2),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          MlFormSection(
            title: l10n.mlSectionModel,
            icon: AppIcons.model,
            children: [
              Text(
                l10n.mlModelDefaultArchitecture,
                style: AppTextStyles.bodySmall.copyWith(color: secondary),
              ),
              MlFieldGrid(
                children: [
                  MlNumberField(
                    controller: _c['lstm']!,
                    label: l10n.mlFieldLstmUnits,
                    helper: l10n.mlFieldListHelp,
                    text: true,
                    validator: mlIntListValidator(l10n, min: 8, max: 1024),
                  ),
                  MlNumberField(
                    controller: _c['dense']!,
                    label: l10n.mlFieldDenseUnits,
                    helper: l10n.mlFieldDenseHelp,
                    text: true,
                    validator: mlIntListValidator(
                      l10n,
                      min: 8,
                      max: 2048,
                      allowEmpty: true,
                    ),
                  ),
                  MlNumberField(
                    controller: _c['dropout']!,
                    label: l10n.mlFieldDropout,
                    decimal: true,
                    validator: mlDoubleValidator(l10n, min: 0, max: 0.9),
                  ),
                  MlNumberField(
                    controller: _c['lr']!,
                    label: l10n.mlFieldLearningRate,
                    decimal: true,
                    validator: mlDoubleValidator(l10n, min: 0.000001, max: 1),
                  ),
                  MlNumberField(
                    controller: _c['batch']!,
                    label: l10n.mlFieldBatchSize,
                    validator: mlIntValidator(l10n, min: 1, max: 1024),
                  ),
                  MlNumberField(
                    controller: _c['epochs']!,
                    label: l10n.mlFieldEpochs,
                    validator: mlIntValidator(l10n, min: 1, max: 2000),
                  ),
                  MlNumberField(
                    controller: _c['smoothing']!,
                    label: l10n.mlFieldLabelSmoothing,
                    decimal: true,
                    validator: mlDoubleValidator(l10n, min: 0, max: 0.5),
                  ),
                  MlNumberField(
                    controller: _c['patience']!,
                    label: l10n.mlFieldEarlyStopping,
                    validator: mlIntValidator(l10n, min: 1, max: 500),
                  ),
                  MlNumberField(
                    controller: _c['lrPatience']!,
                    label: l10n.mlFieldReduceLr,
                    validator: mlIntValidator(l10n, min: 1, max: 500),
                  ),
                ],
              ),
              MlFieldGrid(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _optimizer,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.mlFieldOptimizer),
                    items: [
                      for (final o in _optimizers)
                        DropdownMenuItem(value: o, child: Text(o)),
                    ],
                    onChanged: (v) => setState(() => _optimizer = v ?? _optimizer),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _loss,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.mlFieldLoss),
                    items: [
                      for (final o in _losses)
                        DropdownMenuItem(
                          value: o,
                          child: Text(o, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _loss = v ?? _loss),
                  ),
                ],
              ),
              MlSwitchTile(
                title: l10n.mlFieldClassWeight,
                subtitle: l10n.mlFieldClassWeightHelp,
                value: _classWeight,
                onChanged: (v) => setState(() => _classWeight = v),
              ),
              MlSwitchTile(
                title: l10n.mlFieldLayerNorm,
                value: _layerNorm,
                onChanged: (v) => setState(() => _layerNorm = v),
              ),
            ],
          ),
          if (_mode == 'search') _searchSection(l10n),
          MlFormSection(
            title: l10n.mlSectionExport,
            icon: PhosphorIconsRegular.export,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _quantization,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.mlFieldQuantization),
                items: [
                  for (final q in _quantizations)
                    DropdownMenuItem(
                      value: q,
                      child: Text(mlQuantizationLabel(l10n, q)),
                    ),
                ],
                onChanged: (v) =>
                    setState(() => _quantization = v ?? _quantization),
              ),
              MlSwitchTile(
                title: l10n.mlFieldAutoRegister,
                subtitle: l10n.mlFieldAutoRegisterHelp,
                value: _autoRegister,
                onChanged: (v) => setState(() => _autoRegister = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          MlFormActions(
            submitLabel: _mode == 'search'
                ? l10n.mlTrainSubmitSearch
                : l10n.mlTrainSubmit,
            submitIcon: AppIcons.play,
            busy: _busy,
            onSubmit: dataset == null ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _searchSection(AppLocalizations l10n) {
    return MlFormSection(
      title: l10n.mlSectionSearch,
      icon: PhosphorIconsRegular.magicWand,
      initiallyExpanded: true,
      children: [
        Text(
          l10n.mlSearchHelp,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary(context),
          ),
        ),
        MlFieldGrid(
          children: [
            MlNumberField(
              controller: _c['sMaxEpochs']!,
              label: l10n.mlFieldSearchMaxEpochs,
              validator: mlIntValidator(l10n, min: 3, max: 2000),
            ),
            MlNumberField(
              controller: _c['sEta']!,
              label: l10n.mlFieldSearchEta,
              validator: mlIntValidator(l10n, min: 2, max: 10),
            ),
            MlNumberField(
              controller: _c['sTrials']!,
              label: l10n.mlFieldSearchTrials,
              validator: mlIntValidator(l10n, min: 1, max: 500),
            ),
            MlNumberField(
              controller: _c['sSeed']!,
              label: l10n.mlFieldSearchSeed,
              validator: mlIntValidator(l10n, min: 0, max: 999999),
            ),
            MlNumberField(
              controller: _c['sLayers']!,
              label: l10n.mlFieldSpaceLstmLayers,
              helper: l10n.mlFieldListHelp,
              text: true,
              validator: mlIntListValidator(l10n, min: 1, max: 6),
            ),
            MlNumberField(
              controller: _c['sUnits']!,
              label: l10n.mlFieldSpaceLstmUnits,
              text: true,
              validator: mlIntListValidator(l10n, min: 8, max: 1024),
            ),
            MlNumberField(
              controller: _c['sDropMin']!,
              label: l10n.mlFieldSpaceDropoutMin,
              decimal: true,
              validator: mlDoubleValidator(l10n, min: 0, max: 0.9),
            ),
            MlNumberField(
              controller: _c['sDropMax']!,
              label: l10n.mlFieldSpaceDropoutMax,
              decimal: true,
              validator: (v) =>
                  mlDoubleValidator(l10n, min: 0, max: 0.9)(v) ??
                  _orderError(l10n, 'sDropMin', v),
            ),
            MlNumberField(
              controller: _c['sDense']!,
              label: l10n.mlFieldSpaceDenseLayers,
              text: true,
              validator: mlIntListValidator(l10n, min: 0, max: 4),
            ),
            MlNumberField(
              controller: _c['sDenseUnits']!,
              label: l10n.mlFieldSpaceDenseUnits,
              text: true,
              validator: mlIntListValidator(l10n, min: 8, max: 2048),
            ),
            MlNumberField(
              controller: _c['sLrMin']!,
              label: l10n.mlFieldSpaceLrMin,
              decimal: true,
              validator: mlDoubleValidator(l10n, min: 0.000001, max: 1),
            ),
            MlNumberField(
              controller: _c['sLrMax']!,
              label: l10n.mlFieldSpaceLrMax,
              decimal: true,
              validator: (v) =>
                  mlDoubleValidator(l10n, min: 0.000001, max: 1)(v) ??
                  _orderError(l10n, 'sLrMin', v),
            ),
            MlNumberField(
              controller: _c['sBatch']!,
              label: l10n.mlFieldSpaceBatch,
              text: true,
              validator: mlIntListValidator(l10n, min: 1, max: 1024),
            ),
          ],
        ),
        Text(l10n.mlFieldSpaceOptimizers, style: AppTextStyles.bodyMedium),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final o in _optimizers)
              FilterChip(
                label: Text(o),
                selected: _searchOptimizers.contains(o),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _searchOptimizers.add(o);
                  } else if (_searchOptimizers.length > 1) {
                    _searchOptimizers.remove(o);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  String? _orderError(AppLocalizations l10n, String minKey, String? maxText) {
    final min = mlParseDouble(_c[minKey]!.text);
    final max = mlParseDouble(maxText ?? '');
    if (min == null || max == null) return null;
    return max < min ? l10n.mlErrRangeOrder : null;
  }
}
