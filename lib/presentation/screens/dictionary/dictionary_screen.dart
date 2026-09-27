import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/sign.dart';
import '../../../data/models/sign_category.dart';
import '../../../data/models/sign_language.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/favorite_provider.dart';
import '../../../domain/providers/learning_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/sign_card.dart';
import '../../widgets/skeletons.dart';
import '../../../domain/providers/error_text.dart';

/// Marges horizontales d'un sliver pour centrer son contenu sur [width] tout
/// en laissant la zone de défilement couvrir toute la fenêtre (molette active
/// hors de la colonne sur desktop).
EdgeInsets pageSliverInsets(double viewportWidth, [ContentWidth width = ContentWidth.dashboard]) {
  final gutter = gutterFor(viewportWidth);
  final side = viewportWidth.isFinite
      ? math.max(gutter, (viewportWidth - width.maxWidth) / 2)
      : gutter;
  return EdgeInsets.symmetric(horizontal: side);
}

/// Ajoute ou retire [sign] des favoris de l'utilisateur connecté.
Future<void> toggleSignFavorite(
  BuildContext context,
  WidgetRef ref,
  Sign sign, {
  required bool isFavorite,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final user = ref.read(currentUserProvider);
  if (user == null) {
    AppSnackbar.showWarning(context, l10n.loginToSave);
    return;
  }

  final repository = ref.read(favoriteRepositoryProvider);
  try {
    if (isFavorite) {
      await repository.removeFavorite(user.id, sign.id);
    } else {
      await repository.addFavorite(user.id, sign.id);
    }
    // Le ref d'un widget démonté n'est plus utilisable.
    if (!context.mounted) return;
    ref
      ..invalidate(userFavoritesProvider)
      ..invalidate(isSignFavoriteProvider(sign.id));
    AppSnackbar.showSuccess(
      context,
      isFavorite ? l10n.dictFavoriteRemoved : l10n.dictFavoriteAdded,
    );
  } catch (e) {
    if (context.mounted) {
      AppSnackbar.showError(context, ref.userErrorText(e, l10n));
    }
  }
}

SliverGridDelegate _signGridDelegate(BuildContext context, SignCardVariant variant) {
  if (variant == SignCardVariant.grid) {
    return adaptiveGridDelegate(maxItemWidth: 220, childAspectRatio: 0.8);
  }
  // Hauteur fixe plutôt qu'un ratio : la carte liste garde la même hauteur
  // quelle que soit la largeur de colonne, et suit la taille de texte choisie.
  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 560,
    mainAxisExtent: 136 * textScale.clamp(1.0, 1.6),
    crossAxisSpacing: AppSpacing.m,
    mainAxisSpacing: AppSpacing.m,
  );
}

class DictionaryScreen extends ConsumerStatefulWidget {
  final bool showOnlyFavorites;
  const DictionaryScreen({super.key, this.showOnlyFavorites = false});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final _searchController = TextEditingController();
  SignCardVariant _viewMode = SignCardVariant.grid;
  int? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _refresh(SignLanguage? language) async {
    if (widget.showOnlyFavorites) {
      ref.invalidate(userFavoritesProvider);
      return;
    }
    if (language == null) {
      ref.invalidate(learningLanguageProvider);
      return;
    }
    ref
      ..invalidate(signCategoriesProvider(language.id))
      ..invalidate(signSearchProvider(
        query: _searchQuery,
        languageId: language.id,
        categoryId: _selectedCategoryId,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageAsync = ref.watch(learningLanguageProvider);
    final language = languageAsync.value;

    return Scaffold(
      appBar: widget.showOnlyFavorites
          ? AppBar(
              title: Text(l10n.myFavorites),
              leading: context.canPop()
                  ? IconButton(
                      icon: const Icon(AppIcons.back),
                      tooltip: l10n.back,
                      onPressed: () => context.pop(),
                    )
                  : null,
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = pageSliverInsets(constraints.maxWidth);

            final Widget results;
            if (widget.showOnlyFavorites) {
              results = _FavoritesResults(variant: _viewMode);
            } else if (languageAsync.hasError && language == null) {
              results = SliverToBoxAdapter(
                child: AppEmptyState(
                  icon: AppIcons.error,
                  title: l10n.errorGeneric,
                  message: '${languageAsync.error}',
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(learningLanguageProvider),
                ),
              );
            } else if (language == null && !languageAsync.isLoading) {
              results = SliverToBoxAdapter(
                child: AppEmptyState(
                  icon: AppIcons.dictionary,
                  title: l10n.noSignsFound,
                  message: l10n.dictNoSignsMessage,
                ),
              );
            } else if (language == null) {
              results = SignResultsSkeleton(variant: _viewMode);
            } else {
              results = SignSearchResultsSliver(
                query: _searchQuery,
                languageId: language.id,
                categoryId: _selectedCategoryId,
                variant: _viewMode,
              );
            }

            return RefreshIndicator(
              onRefresh: () => _refresh(language),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (!widget.showOnlyFavorites) ...[
                    SliverPadding(
                      padding: insets.copyWith(top: AppSpacing.l),
                      sliver: SliverToBoxAdapter(
                        child: _DictionaryHeader(language: language),
                      ),
                    ),
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      toolbarHeight: 80,
                      titleSpacing: 0,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      surfaceTintColor: Colors.transparent,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      title: Padding(
                        padding: insets,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: _SearchField(
                              controller: _searchController,
                              query: _searchQuery,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              onClear: _clearSearch,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (language != null)
                      SliverPadding(
                        padding: insets,
                        sliver: SliverToBoxAdapter(
                          child: _CategoryFilter(
                            languageId: language.id,
                            selectedId: _selectedCategoryId,
                            onSelected: (id) => setState(() => _selectedCategoryId = id),
                          ),
                        ),
                      ),
                  ],
                  SliverPadding(
                    padding: insets.copyWith(top: AppSpacing.l),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                widget.showOnlyFavorites ? l10n.myFavorites : l10n.results,
                                style: AppTextStyles.h3,
                              ),
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
                    sliver: results,
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

class _DictionaryHeader extends StatelessWidget {
  const _DictionaryHeader({required this.language});

  final SignLanguage? language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.dictTitle, style: AppTextStyles.h1),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.dictSubtitle,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: secondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (language != null) ...[
                const SizedBox(height: AppSpacing.s),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.language, size: 16, color: secondary),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        l10n.dictLanguage(language!.name),
                        style: AppTextStyles.bodySmall.copyWith(color: secondary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        if (context.isMobile)
          IconButton(
            tooltip: l10n.myFavorites,
            constraints: const BoxConstraints(
              minWidth: kMinTouchTarget,
              minHeight: kMinTouchTarget,
            ),
            onPressed: () => context.pushNamed(AppRoutes.favoritesName),
            icon: const Icon(AppIcons.favorite),
          )
        else
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, kMinTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            ),
            onPressed: () => context.pushNamed(AppRoutes.favoritesName),
            icon: const Icon(AppIcons.favorite, size: 18),
            label: Text(l10n.myFavorites),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = OutlineInputBorder(
      borderRadius: AppRadius.radiusL,
      borderSide: BorderSide(color: AppColors.border(context)),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText: l10n.searchSign,
        prefixIcon: Icon(AppIcons.search, color: AppColors.textSecondary(context)),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                tooltip: l10n.dictClearSearch,
                icon: const Icon(AppIcons.close),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: AppColors.surface(context),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.m,
        ),
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter({
    required this.languageId,
    required this.selectedId,
    required this.onSelected,
  });

  final int languageId;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(signCategoriesProvider(languageId));

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        final chips = <Widget>[
          _CategoryChip(
            label: l10n.filterAll,
            icon: AppIcons.grid,
            color: AppColors.primary,
            selected: selectedId == null,
            onSelected: () => onSelected(null),
          ),
          for (final category in categories)
            _CategoryChip(
              label: category.name,
              icon: AppIcons.fromName(category.iconName),
              color: AppColors.fromHex(category.colorHex) ?? AppColors.primary,
              selected: selectedId == category.id,
              onSelected: () => onSelected(selectedId == category.id ? null : category.id),
            ),
        ];

        return Semantics(
          container: true,
          label: l10n.dictCategories,
          child: context.isMobile
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final chip in chips)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.s),
                          child: chip,
                        ),
                    ],
                  ),
                )
              // Sur desktop le défilement horizontal à la souris est peu
              // pratique : les catégories passent à la ligne.
              : Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: chips,
                ),
        );
      },
      loading: () => Skeleton(
        child: Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final width in const [64.0, 110.0, 92.0, 120.0, 84.0])
              SkeletonBlock(width: width, height: 40, radius: AppRadius.circular),
          ],
        ),
      ),
      // Le filtre est facultatif : la recherche reste utilisable sans lui.
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 18, color: selected ? AppColors.primary : color),
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => onSelected(),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      selectedColor: AppColors.primarySoft,
      backgroundColor: AppColors.surface(context),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border(context),
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.primaryDeep : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusCircular),
    );
  }
}

/// Bascule grille / liste des résultats.
class SignViewToggle extends StatelessWidget {
  const SignViewToggle({super.key, required this.value, required this.onChanged});

  final SignCardVariant value;
  final ValueChanged<SignCardVariant> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<SignCardVariant>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        selectedBackgroundColor: AppColors.primarySoft,
        selectedForegroundColor: AppColors.primary,
      ),
      segments: [
        ButtonSegment(
          value: SignCardVariant.grid,
          icon: const Icon(AppIcons.grid),
          tooltip: l10n.dictGridView,
        ),
        ButtonSegment(
          value: SignCardVariant.list,
          icon: const Icon(AppIcons.list),
          tooltip: l10n.dictListView,
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _FavoritesResults extends ConsumerWidget {
  const _FavoritesResults({required this.variant});

  final SignCardVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SignResultsSliver(
      signs: ref.watch(userFavoritesProvider),
      variant: variant,
      emptyIcon: AppIcons.favorite,
      emptyTitle: l10n.noFavoritesYet,
      emptyMessage: l10n.dictNoFavoritesMessage,
      emptyActionLabel: l10n.dictBrowseDictionary,
      onEmptyAction: () => context.goNamed(AppRoutes.dictionaryName),
      onRetry: () => ref.invalidate(userFavoritesProvider),
    );
  }
}

/// Résultats paginés de `signSearchProvider`, avec « Afficher plus ».
class SignSearchResultsSliver extends ConsumerStatefulWidget {
  const SignSearchResultsSliver({
    super.key,
    this.query,
    this.languageId,
    this.categoryId,
    required this.variant,
  });

  final String? query;
  final int? languageId;
  final int? categoryId;
  final SignCardVariant variant;

  @override
  ConsumerState<SignSearchResultsSliver> createState() => _SignSearchResultsSliverState();
}

class _SignSearchResultsSliverState extends ConsumerState<SignSearchResultsSliver> {
  bool _loadingMore = false;

  SignSearchProvider get _provider => signSearchProvider(
        query: widget.query,
        languageId: widget.languageId,
        categoryId: widget.categoryId,
      );

  Future<void> _loadMore() async {
    final provider = _provider;
    setState(() => _loadingMore = true);
    try {
      await ref.read(provider.notifier).loadMore();
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, ref.userErrorText(e, AppLocalizations.of(context)!));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = _provider;
    final signs = ref.watch(provider);
    final hasMore = signs.hasValue && ref.read(provider.notifier).hasMore;

    return SignResultsSliver(
      signs: signs,
      variant: widget.variant,
      emptyIcon: AppIcons.search,
      emptyTitle: l10n.noSignsFound,
      emptyMessage: l10n.dictNoSignsMessage,
      onRetry: () => ref.invalidate(provider),
      hasMore: hasMore,
      loadingMore: _loadingMore,
      onLoadMore: _loadMore,
    );
  }
}

/// Grille ou liste de [SignCard] avec ses états chargement / vide / erreur.
class SignResultsSliver extends ConsumerWidget {
  const SignResultsSliver({
    super.key,
    required this.signs,
    required this.variant,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onRetry,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.hasMore = false,
    this.loadingMore = false,
    this.onLoadMore,
  });

  final AsyncValue<List<Sign>> signs;
  final SignCardVariant variant;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final VoidCallback onRetry;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favoriteIds = {
      for (final sign in ref.watch(userFavoritesProvider).value ?? const <Sign>[]) sign.id,
    };

    return signs.when(
      data: (items) {
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: AppEmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              message: emptyMessage,
              actionLabel: emptyActionLabel,
              onAction: onEmptyAction,
            ),
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverGrid(
              gridDelegate: _signGridDelegate(context, variant),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sign = items[index];
                  final isFavorite = favoriteIds.contains(sign.id);
                  return SignCard(
                    sign: sign,
                    variant: variant,
                    isFavorite: isFavorite,
                    onTap: () => context.pushNamed(
                      AppRoutes.signDetailName,
                      pathParameters: {'id': sign.id},
                    ),
                    onFavoriteTap: () => toggleSignFavorite(
                      context,
                      ref,
                      sign,
                      isFavorite: isFavorite,
                    ),
                  );
                },
                childCount: items.length,
              ),
            ),
            if (hasMore && onLoadMore != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Center(
                    child: AppButton(
                      label: l10n.dictLoadMore,
                      icon: AppIcons.download,
                      variant: AppButtonVariant.secondary,
                      fullWidth: context.isMobile,
                      isLoading: loadingMore,
                      onPressed: loadingMore ? null : onLoadMore,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => SignResultsSkeleton(variant: variant),
      error: (error, _) => SliverToBoxAdapter(
        child: AppEmptyState(
          icon: AppIcons.error,
          title: l10n.errorGeneric,
          message: ref.userErrorText(error, l10n),
          actionLabel: l10n.retry,
          onAction: onRetry,
        ),
      ),
    );
  }
}

/// Squelette de la grille ou de la liste de signes, avec la même grille
/// adaptative que les résultats réels.
class SignResultsSkeleton extends StatelessWidget {
  const SignResultsSkeleton({super.key, required this.variant, this.itemCount = 8});

  final SignCardVariant variant;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: Skeleton(
        label: l10n.dictLoadingSigns,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: _signGridDelegate(context, variant),
          itemCount: itemCount,
          itemBuilder: (_, _) => variant == SignCardVariant.grid
              ? const _GridCardSkeleton()
              : const _ListCardSkeleton(),
        ),
      ),
    );
  }
}

class _GridCardSkeleton extends StatelessWidget {
  const _GridCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SkeletonBlock(height: double.infinity, radius: AppRadius.l)),
        Padding(
          padding: EdgeInsets.all(AppSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: kMinTouchTarget,
                child: Row(
                  children: [
                    Expanded(child: SkeletonBlock(height: 14)),
                    SizedBox(width: AppSpacing.m),
                    SkeletonBlock.circle(size: 18),
                    SizedBox(width: AppSpacing.m),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              SkeletonBlock(width: 56, height: 20, radius: AppRadius.circular),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListCardSkeleton extends StatelessWidget {
  const _ListCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s),
      child: Row(
        children: [
          SkeletonBlock(width: 80, height: 80, radius: AppRadius.m),
          SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 140, height: 16),
                SizedBox(height: AppSpacing.m),
                SkeletonParagraph(lines: 2, lineHeight: 10),
                SizedBox(height: AppSpacing.m),
                SkeletonBlock(width: 56, height: 20, radius: AppRadius.circular),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile d'en-tête d'une catégorie : icône et couleur issues de la base.
class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({super.key, required this.category, this.size = 56});

  final SignCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(category.colorHex) ?? AppColors.primary;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.radiusM,
        ),
        child: Icon(AppIcons.fromName(category.iconName), color: color, size: size * 0.5),
      ),
    );
  }
}
