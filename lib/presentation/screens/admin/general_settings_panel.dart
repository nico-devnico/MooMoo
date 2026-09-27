import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/app_settings.dart';
import '../../../domain/providers/app_settings_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/skeletons.dart';

const int _maxLogoBytes = 2 * 1024 * 1024;

/// Editable global configuration: identity, maintenance and defaults.
class GeneralSettingsPanel extends ConsumerWidget {
  const GeneralSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      loading: () => const AppPanel(
        child: Skeleton(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(width: 180, height: 18),
              SizedBox(height: AppSpacing.l),
              SkeletonBlock(height: 48),
              SizedBox(height: AppSpacing.m),
              SkeletonBlock(height: 48),
            ],
          ),
        ),
      ),
      error: (e, _) => AppPanel(
        child: Row(
          children: [
            const Icon(AppIcons.error, color: AppColors.error),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: Text('${l10n.cfgLoadError}\n$e')),
            TextButton(
              onPressed: () => ref.invalidate(appSettingsProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      // Keyed on the saved version so a save (or a change made elsewhere)
      // resets the form to what is actually stored.
      data: (settings) => _GeneralSettingsForm(
        key: ValueKey(settings.updatedAt),
        initial: settings,
      ),
    );
  }
}

class _GeneralSettingsForm extends ConsumerStatefulWidget {
  const _GeneralSettingsForm({super.key, required this.initial});

  final AppSettings initial;

  @override
  ConsumerState<_GeneralSettingsForm> createState() => _GeneralSettingsFormState();
}

class _GeneralSettingsFormState extends ConsumerState<_GeneralSettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _message;
  late String? _logoUrl;
  late bool _maintenance;
  late bool _contributions;
  late int? _defaultLanguageId;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s.appName)..addListener(_touch);
    _email = TextEditingController(text: s.supportEmail ?? '')..addListener(_touch);
    _message = TextEditingController(text: s.maintenanceMessage ?? '')..addListener(_touch);
    _logoUrl = s.logoUrl;
    _maintenance = s.maintenanceEnabled;
    _contributions = s.contributionsEnabled;
    _defaultLanguageId = s.defaultSignLanguageId;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void _touch() => setState(() {});

  AppSettings get _draft => widget.initial.copyWith(
        appName: _name.text.trim(),
        logoUrl: () => _logoUrl,
        maintenanceEnabled: _maintenance,
        maintenanceMessage: () => _blankToNull(_message.text),
        supportEmail: () => _blankToNull(_email.text),
        defaultSignLanguageId: () => _defaultLanguageId,
        contributionsEnabled: _contributions,
      );

  bool get _dirty {
    final a = _draft.toUpdateJson();
    final b = widget.initial.toUpdateJson();
    return a.keys.any((k) => a[k] != b[k]);
  }

  static String? _blankToNull(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _pickLogo() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null || !mounted) return;
    if (file.size > _maxLogoBytes) {
      AppSnackbar.showError(context, l10n.dmFileTooLarge(2));
      return;
    }
    setState(() => _uploading = true);
    try {
      final url = await ref
          .read(appSettingsRepositoryProvider)
          .uploadLogo(file.bytes!, file.extension ?? '');
      if (mounted) setState(() => _logoUrl = url);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, '${l10n.errorGeneric}: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;

    final turningOn = _maintenance && !widget.initial.maintenanceEnabled;
    final turningOff = !_maintenance && widget.initial.maintenanceEnabled;
    if (turningOn || turningOff) {
      final ok = await showConfirmDialog(
        context,
        title: turningOn ? l10n.cfgMaintenanceOnTitle : l10n.cfgMaintenanceOffTitle,
        message: turningOn ? l10n.cfgMaintenanceOnMessage : l10n.cfgMaintenanceOffMessage,
        confirmLabel: l10n.confirm,
        cancelLabel: l10n.cancel,
        destructive: turningOn,
      );
      if (!ok || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(appSettingsRepositoryProvider).save(_draft);
      ref.invalidate(appSettingsProvider);
      if (mounted) AppSnackbar.showSuccess(context, l10n.cfgSaved);
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, '${l10n.cfgSaveError}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    final s = widget.initial;
    setState(() {
      _name.text = s.appName;
      _email.text = s.supportEmail ?? '';
      _message.text = s.maintenanceMessage ?? '';
      _logoUrl = s.logoUrl;
      _maintenance = s.maintenanceEnabled;
      _contributions = s.contributionsEnabled;
      _defaultLanguageId = s.defaultSignLanguageId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languages = ref.watch(signLanguagesProvider).value ?? const [];
    final secondary = AppColors.textSecondary(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PanelTitle(icon: AppIcons.settings, title: l10n.cfgIdentity),
                const SizedBox(height: AppSpacing.l),
                TextFormField(
                  controller: _name,
                  maxLength: 40,
                  decoration: InputDecoration(labelText: l10n.cfgAppName),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.cfgAppNameRequired : null,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(l10n.cfgLogo, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(AppSpacing.s),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border(context)),
                        borderRadius: AppRadius.radiusM,
                      ),
                      child: _logoUrl == null
                          ? const AppLogo(excludeFromSemantics: true)
                          : CachedNetworkImage(
                              imageUrl: _logoUrl!,
                              fit: BoxFit.contain,
                              errorWidget: (_, _, _) =>
                                  const Icon(AppIcons.error, color: AppColors.error),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.s,
                        runSpacing: AppSpacing.s,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _uploading || _saving ? null : _pickLogo,
                            icon: _uploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(AppIcons.upload, size: 18),
                            label: Text(l10n.cfgChangeLogo),
                          ),
                          if (_logoUrl != null)
                            TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _logoUrl = null),
                              child: Text(l10n.cfgDefaultLogo),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.cfgLogoHelp,
                  style: AppTextStyles.bodySmall.copyWith(color: secondary),
                ),
                const SizedBox(height: AppSpacing.l),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.cfgSupportEmail,
                    helperText: l10n.cfgSupportEmailHelp,
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                        ? null
                        : l10n.cfgInvalidEmail;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PanelTitle(icon: AppIcons.warning, title: l10n.cfgMaintenance),
                const SizedBox(height: AppSpacing.s),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _maintenance,
                  onChanged: _saving ? null : (v) => setState(() => _maintenance = v),
                  title: Text(l10n.cfgMaintenanceEnabled),
                  subtitle: Text(l10n.cfgMaintenanceHelp),
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: _message,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: l10n.cfgMaintenanceMessage,
                    hintText: l10n.maintenanceDefaultMessage,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PanelTitle(icon: AppIcons.dictionary, title: l10n.cfgDefaults),
                const SizedBox(height: AppSpacing.l),
                DropdownButtonFormField<int?>(
                  key: ValueKey('default_lang_${languages.length}_$_defaultLanguageId'),
                  initialValue: languages.any((l) => l.id == _defaultLanguageId)
                      ? _defaultLanguageId
                      : null,
                  decoration: InputDecoration(labelText: l10n.cfgDefaultSignLanguage),
                  items: [
                    DropdownMenuItem<int?>(value: null, child: Text(l10n.cfgNone)),
                    for (final language in languages)
                      DropdownMenuItem<int?>(
                        value: language.id,
                        child: Text(language.name),
                      ),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _defaultLanguageId = v),
                ),
                const SizedBox(height: AppSpacing.s),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _contributions,
                  onChanged: _saving ? null : (v) => setState(() => _contributions = v),
                  title: Text(l10n.cfgContributionsEnabled),
                  subtitle: Text(l10n.cfgContributionsHelp),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _dirty && !_saving ? _reset : null,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: AppSpacing.s),
              FilledButton.icon(
                onPressed: _dirty && !_saving && !_uploading ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(AppIcons.check, size: 18),
                label: Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.radiusM,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
