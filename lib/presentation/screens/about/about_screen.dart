import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/app_settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_panel.dart';
import '../settings/settings_screen.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appName = ref.watch(appNameProvider);
    final secondary = AppColors.textSecondary(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.l,
          bottom: settingsBottomPadding(context),
        ),
        child: PageContainer.reading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPanel(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const AppLogo(
                      width: 88,
                      height: 88,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Semantics(
                      header: true,
                      child: Text(appName, style: AppTextStyles.h2),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.accountVersionLabel(kAppVersion),
                      style: AppTextStyles.bodySmall.copyWith(color: secondary),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      l10n.accountAboutTagline,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: AppIcons.profile,
                    title: l10n.accountAuthor,
                    value: 'OTILA Nicandre',
                  ),
                  SettingsTile(
                    icon: PhosphorIconsRegular.envelopeSimple,
                    title: l10n.accountContact,
                    subtitle: kSupportEmail,
                    trailing: Icon(
                      PhosphorIconsRegular.arrowSquareOut,
                      size: 18,
                      color: secondary,
                    ),
                    onTap: () => openSupportEmail(
                      context,
                      subject: '$appName · ${l10n.about}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.accountCopyright('${DateTime.now().year}'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
