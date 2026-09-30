import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/sign.dart';
import '../../../domain/providers/favorite_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_panel.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/sign_media.dart';
import '../../widgets/skeletons.dart';
import 'dictionary_screen.dart';
import '../../../domain/providers/error_text.dart';

/// Largeur à partir de laquelle la vidéo et le texte passent côte à côte.
const double _splitBreakpoint = 840;

class SignDetailScreen extends ConsumerWidget {
  final String id;
  const SignDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signAsync = ref.watch(signDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text(signAsync.value?.word ?? ''),
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          tooltip: l10n.back,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(AppRoutes.dictionaryName),
        ),
      ),
      body: SafeArea(
        top: false,
        child: signAsync.when(
          data: (sign) {
            if (sign == null) {
              return AppEmptyState(
                icon: AppIcons.search,
                title: l10n.dictSignNotFound,
                message: l10n.dictSignNotFoundMessage,
                actionLabel: l10n.dictBrowseDictionary,
                onAction: () => context.goNamed(AppRoutes.dictionaryName),
              );
            }
            return _SignDetailBody(sign: sign);
          },
          loading: () => const _Scroll(child: _DetailSkeleton()),
          error: (error, _) => AppEmptyState(
            icon: AppIcons.error,
            title: l10n.errorGeneric,
            message: ref.userErrorText(error, l10n),
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(signDetailProvider(id)),
          ),
        ),
      ),
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppSpacing.l, bottom: AppSpacing.xxxl),
      child: PageContainer(width: ContentWidth.detail, child: child),
    );
  }
}

class _SignDetailBody extends StatelessWidget {
  const _SignDetailBody({required this.sign});

  final Sign sign;

  @override
  Widget build(BuildContext context) {
    return _Scroll(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final split = constraints.maxWidth >= _splitBreakpoint;
          final media = AspectRatio(
            aspectRatio: split ? 0.95 : 1,
            child: Semantics(
              label: sign.word,
              image: true,
              child: SignMedia(sign: sign),
            ),
          );
          final info = _SignInfo(sign: sign);

          if (!split) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [media, const SizedBox(height: AppSpacing.xl), info],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 11, child: media),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(flex: 10, child: info),
            ],
          );
        },
      ),
    );
  }
}

class _SignInfo extends ConsumerStatefulWidget {
  const _SignInfo({required this.sign});

  final Sign sign;

  @override
  ConsumerState<_SignInfo> createState() => _SignInfoState();
}

class _SignInfoState extends ConsumerState<_SignInfo> {
  final _shareKey = GlobalKey();
  bool _togglingFavorite = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(dictionaryRepositoryProvider)
        .incrementViewCount(widget.sign.id)
        .catchError((Object e) => debugPrint('record sign view: $e'));
  }

  Future<void> _toggleFavorite(bool isFavorite) async {
    setState(() => _togglingFavorite = true);
    await toggleSignFavorite(context, ref, widget.sign, isFavorite: isFavorite);
    if (mounted) setState(() => _togglingFavorite = false);
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context)!;
    final sign = widget.sign;
    final description = sign.description?.trim();
    final text = [
      l10n.dictShareText(sign.word),
      if (description != null && description.isNotEmpty) description,
    ].join('\n\n');

    // Requis sur iPad / macOS pour ancrer la feuille de partage au bouton.
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(ShareParams(
        text: text,
        subject: sign.word,
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, ref.userErrorText(e, l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sign = widget.sign;
    final secondary = AppColors.textSecondary(context);

    final language = ref
        .watch(signLanguagesProvider)
        .value
        ?.where((l) => l.id == sign.signLanguageId)
        .firstOrNull;
    final category = sign.signLanguageId == null || sign.categoryId == null
        ? null
        : ref
            .watch(signCategoriesProvider(sign.signLanguageId!))
            .value
            ?.where((c) => c.id == sign.categoryId)
            .firstOrNull;
    final isFavorite = ref.watch(isSignFavoriteProvider(sign.id)).value ?? false;

    final (difficultyLabel, difficultyColor, difficultyBackground) = switch (sign.difficultyLevel) {
      2 => (l10n.difficultyMedium, AppColors.warningLedge, AppColors.warningSoft),
      3 => (l10n.difficultyHard, AppColors.error, AppColors.errorSoft),
      _ => (l10n.difficultyEasy, AppColors.successLedge, AppColors.successSoft),
    };

    final description = sign.description?.trim();
    final example = sign.exampleSentence?.trim();
    final rawTags = sign.tags ?? const <String>[];
    final gloss = rawTags.isNotEmpty && !rawTags.first.startsWith('source:')
        ? rawTags.first
        : null;
    final tags = [
      for (final tag in rawTags)
        if (tag != gloss && !tag.startsWith('source:')) tag,
    ];
    final sourceUrl = rawTags
        .where((t) => t.startsWith('source:'))
        .map((t) => t.substring('source:'.length))
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(sign.word, style: AppTextStyles.h1),
        ),
        if (gloss != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            '${l10n.dictGloss} : $gloss',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (language != null)
              Tooltip(
                message: language.name,
                child: _Pill(
                  label: language.code.toUpperCase(),
                  semanticLabel: l10n.dictLanguage(language.name),
                  icon: AppIcons.language,
                  color: AppColors.primary,
                  background: AppColors.primarySoft,
                ),
              ),
            _Pill(
              label: difficultyLabel,
              semanticLabel: l10n.dictDifficulty(difficultyLabel),
              color: difficultyColor,
              background: difficultyBackground,
            ),
            if (category != null)
              ActionChip(
                avatar: Icon(
                  AppIcons.fromName(category.iconName),
                  size: 16,
                  color: AppColors.fromHex(category.colorHex) ?? AppColors.primary,
                ),
                label: Text(category.name),
                tooltip: category.name,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                backgroundColor: AppColors.surface(context),
                side: BorderSide(color: AppColors.border(context)),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusCircular),
                onPressed: () => context.pushNamed(
                  AppRoutes.categoryName,
                  pathParameters: {'id': category.id.toString()},
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.m,
          children: [
            AppButton(
              label: l10n.dictPractice,
              icon: AppIcons.learning,
              fullWidth: false,
              onPressed: () => context.goNamed(AppRoutes.learningName),
            ),
            AppButton(
              label: isFavorite ? l10n.dictRemoveFavorite : l10n.dictAddFavorite,
              icon: isFavorite ? AppIcons.favoriteActive : AppIcons.favorite,
              variant: AppButtonVariant.outline,
              fullWidth: false,
              onPressed: _togglingFavorite ? null : () => _toggleFavorite(isFavorite),
            ),
            KeyedSubtree(
              key: _shareKey,
              child: AppButton(
                label: l10n.dictShare,
                icon: AppIcons.share,
                variant: AppButtonVariant.ghost,
                fullWidth: false,
                onPressed: _share,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SectionTitle(l10n.signDescription),
        const SizedBox(height: AppSpacing.s),
        Text(
          description == null || description.isEmpty ? l10n.dictNoDescription : description,
          style: AppTextStyles.bodyLarge.copyWith(
            color: secondary,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
        if (example != null && example.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(l10n.dictExampleSentence),
          const SizedBox(height: AppSpacing.m),
          AppPanel(
            color: AppColors.primarySoft,
            borderColor: AppColors.primarySoft,
            child: Text(
              example,
              style: AppTextStyles.bodyLarge.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(l10n.dictTranslations),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final tag in tags)
                _Pill(
                  label: tag,
                  color: AppColors.textSecondary(context),
                  background: AppColors.neutral(context),
                ),
            ],
          ),
        ],
        if (sourceUrl != null && sourceUrl.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(l10n.dictTags),
          const SizedBox(height: AppSpacing.s),
          SelectableText(
            sourceUrl,
            style: AppTextStyles.bodySmall.copyWith(color: secondary),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(header: true, child: Text(title, style: AppTextStyles.h3));
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.radiusCircular,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: AppLocalizations.of(context)!.loading,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final split = constraints.maxWidth >= _splitBreakpoint;
          final media = AspectRatio(
            aspectRatio: split ? 0.95 : 1,
            child: const SkeletonBlock(height: double.infinity, radius: AppRadius.l),
          );
          const info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(width: 220, height: 36),
              SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  SkeletonBlock(width: 64, height: 28, radius: AppRadius.circular),
                  SizedBox(width: AppSpacing.s),
                  SkeletonBlock(width: 72, height: 28, radius: AppRadius.circular),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.m,
                runSpacing: AppSpacing.m,
                children: [
                  SkeletonBlock(width: 160, height: AppButton.height, radius: AppRadius.l),
                  SkeletonBlock(width: 200, height: AppButton.height, radius: AppRadius.l),
                ],
              ),
              SizedBox(height: AppSpacing.xxl),
              SkeletonBlock(width: 140, height: 22),
              SizedBox(height: AppSpacing.m),
              SkeletonParagraph(lines: 3, lineHeight: 14),
            ],
          );

          if (!split) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [media, const SizedBox(height: AppSpacing.xl), info],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 11, child: media),
              const SizedBox(width: AppSpacing.xxl),
              const Expanded(flex: 10, child: info),
            ],
          );
        },
      ),
    );
  }
}
