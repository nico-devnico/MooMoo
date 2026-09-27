import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/providers/sign_provider.dart';
import '../../../../domain/providers/workspace_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/confirm_dialog.dart';

const _maxBytes = 10 * 1024 * 1024;
const _previewRows = 300;

enum _Step { file, preview, report }

/// Imports signs from CSV, TSV, JSON, NDJSON or XML. Parsing, validation,
/// duplicate detection and media download run on the API; nothing is written
/// before the explicit confirmation.
class DictionaryImportDialog extends ConsumerStatefulWidget {
  const DictionaryImportDialog({super.key});

  @override
  ConsumerState<DictionaryImportDialog> createState() => _DictionaryImportDialogState();
}

class _DictionaryImportDialogState extends ConsumerState<DictionaryImportDialog> {
  _Step _step = _Step.file;
  String? _filename;
  String? _content;
  int _size = 0;
  bool _busy = false;
  String? _error;

  int? _defaultLanguageId;
  bool _createCategories = false;
  bool _publish = false;
  bool _fetchMedia = true;
  String _duplicates = 'skip';

  Map<String, dynamic>? _preview;
  Map<String, String> _mapping = {};
  bool _dirty = false;
  String? _statusFilter;
  Map<String, dynamic>? _report;

  Map<String, dynamic> get _options => {
        'defaultLanguageId': ?_defaultLanguageId,
        'createCategories': _createCategories,
        'publish': _publish,
        'fetchMedia': _fetchMedia,
        'duplicates': _duplicates,
      };

  static String _decode(List<int> bytes) {
    final utf = utf8.decode(bytes, allowMalformed: true);
    // Spreadsheet exports are often Windows-1252/Latin-1 rather than UTF-8.
    final text = utf.contains('\uFFFD') ? latin1.decode(bytes) : utf;
    return text.replaceFirst('\uFEFF', '');
  }

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'tsv', 'txt', 'json', 'ndjson', 'jsonl', 'xml'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;
    if (file.size > _maxBytes) {
      setState(() => _error = l10n.dmFileTooLarge(10));
      return;
    }
    setState(() {
      _filename = file.name;
      _size = file.size;
      _content = _decode(file.bytes!);
      _error = null;
      _preview = null;
      _mapping = {};
    });
  }

  String _message(Object e) {
    final l10n = AppLocalizations.of(context)!;
    if (e is ApiUnreachableException) return l10n.dmApiRequired;
    return '$e';
  }

  Future<void> _analyse({bool withMapping = false}) async {
    if (_content == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(workspaceRepositoryProvider).previewImport(
            filename: _filename ?? 'import.csv',
            content: _content!,
            mapping: withMapping ? _mapping : null,
            options: _options,
          );
      if (!mounted) return;
      setState(() {
        _preview = result;
        _mapping = {
          for (final e in (result['mapping'] as Map? ?? const {}).entries) '${e.key}': '${e.value}',
        };
        _dirty = false;
        _step = _Step.preview;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commit() async {
    final l10n = AppLocalizations.of(context)!;
    final summary = Map<String, dynamic>.from(_preview!['summary'] as Map);
    final valid = summary['valid'] as int? ?? 0;
    final duplicates = summary['duplicates'] as int? ?? 0;
    final count = valid + (_duplicates == 'update' ? duplicates : 0);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.dmImportConfirmTitle,
      message: l10n.dmImportConfirmMessage(
        count,
        summary['errors'] as int? ?? 0,
        _publish ? l10n.dmPublished : l10n.dmDraft,
      ),
      confirmLabel: l10n.dmImport,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(workspaceRepositoryProvider).commitImport(
            filename: _filename ?? 'import.csv',
            content: _content!,
            mapping: _mapping,
            options: _options,
          );
      if (!mounted) return;
      setState(() {
        _report = Map<String, dynamic>.from(result['report'] as Map);
        _step = _Step.report;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _targetLabel(AppLocalizations l10n, String target) => switch (target) {
        'word' => l10n.signWord,
        'description' => l10n.signDescription,
        'category' => l10n.admxCategory,
        'language' => l10n.adminLanguage,
        'video_url' => l10n.signVideoUrl,
        'thumbnail_url' => l10n.dmThumbnailUrl,
        'tags' => l10n.dmTags,
        'example_sentence' => l10n.dmExampleSentence,
        'difficulty_level' => l10n.difficultyLevel,
        _ => target,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);

    return AlertDialog(
      title: Text(switch (_step) {
        _Step.file => l10n.dmImportTitle,
        _Step.preview => l10n.dmImportPreview,
        _Step.report => l10n.dmImportReport,
      }),
      content: SizedBox(
        width: size.width < 760 ? size.width : 720,
        height: size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
            Expanded(
              child: switch (_step) {
                _Step.file => _fileStep(l10n),
                _Step.preview => _previewStep(l10n),
                _Step.report => _reportStep(l10n),
              },
            ),
          ],
        ),
      ),
      actions: switch (_step) {
        _Step.file => [
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: _busy || _content == null ? null : () => _analyse(),
              child: Text(l10n.dmAnalyse),
            ),
          ],
        _Step.preview => [
            TextButton(
              onPressed: _busy ? null : () => setState(() => _step = _Step.file),
              child: Text(l10n.back),
            ),
            if (_dirty)
              OutlinedButton(
                onPressed: _busy ? null : () => _analyse(withMapping: true),
                child: Text(l10n.dmReanalyse),
              ),
            FilledButton(
              onPressed: _busy || _dirty || !_canImport() ? null : _commit,
              child: Text(l10n.dmImport),
            ),
          ],
        _Step.report => [
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.close),
            ),
          ],
      },
    );
  }

  bool _canImport() {
    final summary = _preview?['summary'] as Map?;
    if (summary == null) return false;
    final valid = summary['valid'] as int? ?? 0;
    final duplicates = summary['duplicates'] as int? ?? 0;
    return valid > 0 || (_duplicates == 'update' && duplicates > 0);
  }

  Widget _optionsForm(AppLocalizations l10n, {required bool afterPreview}) {
    final languages = ref.watch(signLanguagesProvider).value ?? const [];
    void changed(VoidCallback f) => setState(() {
          f();
          if (afterPreview) _dirty = true;
        });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int?>(
          initialValue: _defaultLanguageId,
          decoration: InputDecoration(
            labelText: l10n.dmDefaultLanguage,
            helperText: l10n.dmDefaultLanguageHelp,
            helperMaxLines: 2,
          ),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(l10n.dmNoDefaultLanguage)),
            for (final l in languages) DropdownMenuItem<int?>(value: l.id, child: Text(l.name)),
          ],
          onChanged: _busy ? null : (v) => changed(() => _defaultLanguageId = v),
        ),
        const SizedBox(height: AppSpacing.s),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.dmCreateCategories),
          value: _createCategories,
          onChanged: _busy ? null : (v) => changed(() => _createCategories = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.dmFetchMedia),
          subtitle: Text(l10n.dmFetchMediaHelp),
          value: _fetchMedia,
          onChanged: _busy ? null : (v) => setState(() => _fetchMedia = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.dmPublishImported),
          value: _publish,
          onChanged: _busy ? null : (v) => setState(() => _publish = v),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(l10n.dmDuplicatesStrategy, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'skip', label: Text(l10n.dmSkipDuplicates)),
            ButtonSegment(value: 'update', label: Text(l10n.dmUpdateDuplicates)),
          ],
          selected: {_duplicates},
          onSelectionChanged: _busy ? null : (v) => setState(() => _duplicates = v.first),
        ),
      ],
    );
  }

  Widget _fileStep(AppLocalizations l10n) {
    return ListView(
      children: [
        Text(l10n.dmImportHelp, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.m),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pick,
          icon: const Icon(AppIcons.upload),
          label: Text(_filename == null
              ? l10n.dmChooseFile
              : '$_filename (${(_size / 1024).toStringAsFixed(1)} Ko)'),
        ),
        const SizedBox(height: AppSpacing.l),
        _optionsForm(l10n, afterPreview: false),
      ],
    );
  }

  Widget _previewStep(AppLocalizations l10n) {
    final preview = _preview!;
    final fields = [for (final f in (preview['fields'] as List? ?? const [])) '$f'];
    final targets = [for (final t in (preview['target_fields'] as List? ?? const [])) '$t'];
    final summary = Map<String, dynamic>.from(preview['summary'] as Map);
    final rows = [
      for (final r in (preview['rows'] as List? ?? const [])) Map<String, dynamic>.from(r as Map),
    ];
    final visible = rows
        .where((r) => _statusFilter == null || r['status'] == _statusFilter)
        .take(_previewRows)
        .toList();
    final toCreate = (summary['categories_to_create'] as List? ?? const []);

    return ListView(
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            AppBadge(label: '${l10n.dmFormat} : ${'${preview['format']}'.toUpperCase()}', color: AppColors.primary),
            AppBadge(label: l10n.dmRecordsCount(summary['total'] as int? ?? 0), color: AppColors.primary),
            if (summary['truncated'] == true)
              AppBadge(label: l10n.dmTruncated(preview['max_rows'] as int? ?? 0), color: AppColors.warning),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Text(l10n.dmMapping, style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.dmMappingHelp, style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.s,
          children: [
            for (final target in targets)
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('map_${target}_${_mapping[target]}'),
                  initialValue: fields.contains(_mapping[target]) ? _mapping[target] : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _targetLabel(l10n, target) + (target == 'word' ? ' *' : ''),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(l10n.dmIgnoreField)),
                    for (final f in fields)
                      DropdownMenuItem<String?>(value: f, child: Text(f, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                            if (v == null) {
                              _mapping.remove(target);
                            } else {
                              _mapping[target] = v;
                            }
                            _dirty = true;
                          }),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(l10n.dmOptions),
          children: [_optionsForm(l10n, afterPreview: true)],
        ),
        if (_dirty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Text(l10n.dmReanalyseHint, style: const TextStyle(color: AppColors.warning)),
          ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            ChoiceChip(
              label: Text('${l10n.filterAll} (${rows.length})'),
              selected: _statusFilter == null,
              onSelected: (_) => setState(() => _statusFilter = null),
            ),
            ChoiceChip(
              label: Text(l10n.dmValidCount(summary['valid'] as int? ?? 0)),
              selected: _statusFilter == 'valid',
              onSelected: (_) => setState(() => _statusFilter = 'valid'),
            ),
            ChoiceChip(
              label: Text(l10n.dmDuplicateCount(summary['duplicates'] as int? ?? 0)),
              selected: _statusFilter == 'duplicate',
              onSelected: (_) => setState(() => _statusFilter = 'duplicate'),
            ),
            ChoiceChip(
              label: Text(l10n.dmErrorCount(summary['errors'] as int? ?? 0)),
              selected: _statusFilter == 'error',
              onSelected: (_) => setState(() => _statusFilter = 'error'),
            ),
          ],
        ),
        if (toCreate.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            l10n.dmCategoriesToCreate(toCreate.map((c) => (c as Map)['name']).join(', ')),
            style: AppTextStyles.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.s),
        for (final row in visible) _RowTile(row: row),
        if (rows.length > _previewRows && _statusFilter == null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s),
            child: Text(l10n.dmMoreRows(rows.length - _previewRows), style: AppTextStyles.bodySmall),
          ),
      ],
    );
  }

  Widget _reportStep(AppLocalizations l10n) {
    final r = _report!;
    final rows = [
      for (final row in (r['rows'] as List? ?? const [])) Map<String, dynamic>.from(row as Map),
    ];
    final notable = rows
        .where((row) => row['result'] != 'imported' || (row['warnings'] as List? ?? const []).isNotEmpty)
        .toList();
    final created = (r['categories_created'] as List? ?? const []);

    return ListView(
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            AppBadge(label: l10n.dmReportImported(r['imported'] as int? ?? 0), color: AppColors.success),
            AppBadge(label: l10n.dmReportUpdated(r['updated'] as int? ?? 0), color: AppColors.primary),
            AppBadge(label: l10n.dmReportSkipped(r['skipped'] as int? ?? 0), color: AppColors.warning),
            AppBadge(label: l10n.dmReportRejected(r['rejected'] as int? ?? 0), color: AppColors.error),
            if (_fetchMedia)
              AppBadge(
                label: l10n.dmReportMedia(r['media_fetched'] as int? ?? 0, r['media_failed'] as int? ?? 0),
                color: AppColors.primary,
              ),
          ],
        ),
        if (created.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          Text(l10n.dmCategoriesCreated(created.map((c) => (c as Map)['name']).join(', '))),
        ],
        const SizedBox(height: AppSpacing.m),
        if (notable.isEmpty)
          Text(l10n.dmReportAllGood, style: AppTextStyles.bodyMedium)
        else
          for (final row in notable)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                switch (row['result']) {
                  'imported' || 'updated' => AppIcons.success,
                  'skipped' => AppIcons.info,
                  _ => AppIcons.error,
                },
                color: switch (row['result']) {
                  'imported' || 'updated' => AppColors.success,
                  'skipped' => AppColors.warning,
                  _ => AppColors.error,
                },
              ),
              title: Text('${l10n.dmLine((row['index'] as int? ?? 0) + 1)} · ${row['word'] ?? '—'}'),
              subtitle: Text([
                if (row['message'] != null) '${row['message']}',
                ...(row['warnings'] as List? ?? const []).map((w) => '$w'),
              ].join('\n')),
            ),
      ],
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = Map<String, dynamic>.from(row['data'] as Map? ?? const {});
    final status = row['status'] as String?;
    final (label, color) = switch (status) {
      'valid' => (l10n.dmStatusValid, AppColors.success),
      'duplicate' => (l10n.dmStatusDuplicate, AppColors.warning),
      _ => (l10n.dmStatusError, AppColors.error),
    };
    final details = [
      if (data['language_code'] != null) '${data['language_code']}',
      if (data['category_name'] != null) '${data['category_name']}',
      if (data['video_url'] != null) l10n.dmHasVideo,
    ].join(' · ');
    final messages = [
      ...(row['errors'] as List? ?? const []).map((e) => '$e'),
      ...(row['warnings'] as List? ?? const []).map((w) => '$w'),
    ];

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Flexible(
            child: Text(
              '${l10n.dmLine((row['index'] as int? ?? 0) + 1)} · ${data['word'] ?? '—'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          AppBadge(label: label, color: color),
        ],
      ),
      subtitle: Text([if (details.isNotEmpty) details, ...messages].join('\n')),
    );
  }
}
