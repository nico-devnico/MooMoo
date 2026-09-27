import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/sign_category.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/sign_card.dart';
import '../../widgets/skeletons.dart';
import 'dictionary_screen.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  final String id;
  const CategoryScreen({super.key, required this.id});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  SignCardVariant _viewMode = SignCardVariant.grid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoryId = int.tryParse(widget.id);
    final languageAsync = ref.watch(learningLanguageProvider);
    final language = languageAsync.value;
    final categoriesAsync = language == null
        ? null
        : ref.watch(signCategoriesProvider(language.id));
    final category = categoriesAsync?.value
        ?.where((c) => c.id == categoryId)
        .firstOrNull;
    final headerLoading = (languageAsync.isLoading && !languageAsync.hasValue) ||
        (categoriesAsync != null && categoriesAsync.isLoading && !categoriesAsync.hasValue);

    final leading = context.canPop()
        ? IconButton(
            icon: const Icon(AppIcons.back),
            tooltip: l10n.back,
            onPressed: () => context.pop(),
          )
        : null;

    if (categoryId == null) {
      return Scaffold(
        appBar: AppBar(leading: leading),
        body: AppEmptyState(
          icon: AppIcons.search,
          title: l10n.dictCategoryNotFound,
          message: l10n.dictNoSignsMessage,
          actionLabel: l10n.dictBrowseDictionary,
          onAction: () => context.goNamed(AppRoutes.dictionaryName),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Text(category?.name ?? l10n.dictTitle),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = pageSliverInsets(constraints.maxWidth);
            return RefreshIndicator(
              onRefresh: () async {
                if (language != null) {
                  ref.invalidate(signCategoriesProvider(language.id));
                }
                ref.invalidate(signSearchProvider(categoryId: categoryId));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: insets.copyWith(top: AppSpacing.l),
                    sliver: SliverToBoxAdapter(
                      child: headerLoading
                          ? const _HeaderSkeleton()
                          : _CategoryHeader(category: category),
                    ),
                  ),
                  SliverPadding(
                    padding: insets.copyWith(top: AppSpacing.xl),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(l10n.results, style: AppTextStyles.h3),
                            ),
                          ),
                          SignViewToggle(
                            value: _viewMode,
                            onChanged: (mode) => setState(() => _viewMode = mode),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: insets.copyWith(
                      top: AppSpacing.m,
                      bottom: AppSpacing.xxxl + AppSpacing.xl,
                    ),
                    // La catégorie appartient déjà à une langue : inutile de
                    // filtrer aussi par langue.
                    sliver: SignSearchResultsSliver(
                      categoryId: categoryId,
                      variant: _viewMode,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final SignCategory? category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = this.category;

    return Row(
      children: [
        if (category != null) ...[
          CategoryIconTile(category: category, size: 64),
          const SizedBox(width: AppSpacing.l),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  category?.name ?? l10n.learnByCategory,
                  style: AppTextStyles.h1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.dictCategorySubtitle,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      label: AppLocalizations.of(context)!.loading,
      child: const Row(
        children: [
          SkeletonBlock(width: 64, height: 64, radius: AppRadius.m),
          SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 200, height: 32),
                SizedBox(height: AppSpacing.s),
                SkeletonBlock(width: 260, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
