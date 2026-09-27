/// Global configuration, the single row of `public.app_settings`.
class AppSettings {
  const AppSettings({
    this.appName = defaultName,
    this.logoUrl,
    this.maintenanceEnabled = false,
    this.maintenanceMessage,
    this.supportEmail,
    this.defaultSignLanguageId,
    this.contributionsEnabled = true,
    this.updatedAt,
  });

  static const defaultName = 'MooMoo';

  final String appName;
  final String? logoUrl;
  final bool maintenanceEnabled;
  final String? maintenanceMessage;
  final String? supportEmail;
  final int? defaultSignLanguageId;
  final bool contributionsEnabled;
  final DateTime? updatedAt;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final name = (json['app_name'] as String?)?.trim();
    return AppSettings(
      appName: name == null || name.isEmpty ? defaultName : name,
      logoUrl: _blankToNull(json['logo_url']),
      maintenanceEnabled: json['maintenance_enabled'] == true,
      maintenanceMessage: _blankToNull(json['maintenance_message']),
      supportEmail: _blankToNull(json['support_email']),
      defaultSignLanguageId: (json['default_sign_language_id'] as num?)?.toInt(),
      contributionsEnabled: json['contributions_enabled'] != false,
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'app_name': appName.trim(),
        'logo_url': logoUrl,
        'maintenance_enabled': maintenanceEnabled,
        'maintenance_message': maintenanceMessage,
        'support_email': supportEmail,
        'default_sign_language_id': defaultSignLanguageId,
        'contributions_enabled': contributionsEnabled,
      };

  AppSettings copyWith({
    String? appName,
    String? Function()? logoUrl,
    bool? maintenanceEnabled,
    String? Function()? maintenanceMessage,
    String? Function()? supportEmail,
    int? Function()? defaultSignLanguageId,
    bool? contributionsEnabled,
  }) {
    return AppSettings(
      appName: appName ?? this.appName,
      logoUrl: logoUrl != null ? logoUrl() : this.logoUrl,
      maintenanceEnabled: maintenanceEnabled ?? this.maintenanceEnabled,
      maintenanceMessage:
          maintenanceMessage != null ? maintenanceMessage() : this.maintenanceMessage,
      supportEmail: supportEmail != null ? supportEmail() : this.supportEmail,
      defaultSignLanguageId: defaultSignLanguageId != null
          ? defaultSignLanguageId()
          : this.defaultSignLanguageId,
      contributionsEnabled: contributionsEnabled ?? this.contributionsEnabled,
      updatedAt: updatedAt,
    );
  }

  static String? _blankToNull(Object? value) {
    final s = value?.toString().trim();
    return s == null || s.isEmpty ? null : s;
  }
}
