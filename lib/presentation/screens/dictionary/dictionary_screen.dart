import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../domain/providers/favorite_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/sign_card.dart';
import '../../../l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(signCategoriesProvider(1));
    final favoritesAsync = ref.watch(userFavoritesProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final signsAsync = widget.showOnlyFavorites 
        ? favoritesAsync 
        : ref.watch(signSearchProvider(
            query: _searchQuery,
            languageId: 1,
            categoryId: _selectedCategoryId,
          ));

    return Scaffold(
      appBar: widget.showOnlyFavorites 
          ? AppBar(title: Text(l10n.myFavorites))
          : null,
      body: PageContainer(
        padding: 0,
        child: SafeArea(
            child: CustomScrollView(
              slivers: [
                if (!widget.showOnlyFavorites)
                  // Sticky Search Bar
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    title: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: l10n.searchSign,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.surfaceDark 
                            : AppColors.neutralLight.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),

                // Filters & View Mode
                if (!widget.showOnlyFavorites)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.surfaceDark 
                            : AppColors.neutralLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          categoriesAsync.when(
                            data: (categories) => SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.all(AppSpacing.m),
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text(l10n.filterAll),
                                    selected: _selectedCategoryId == null,
                                    onSelected: (val) => setState(() => _selectedCategoryId = null),
                                  ),
                                  const SizedBox(width: 8),
                                  ...categories.map((cat) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(cat.name),
                                          selected: _selectedCategoryId == cat.id,
                                          onSelected: (val) => setState(() => _selectedCategoryId = val ? cat.id : null),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            loading: () => const SizedBox(height: 50),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.m, right: AppSpacing.m, bottom: AppSpacing.m),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n.results, style: AppTextStyles.h3),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.grid_view, color: _viewMode == SignCardVariant.grid ? AppColors.primary : AppColors.textSecondaryLight),
                                      onPressed: () => setState(() => _viewMode = SignCardVariant.grid),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.list, color: _viewMode == SignCardVariant.list ? AppColors.primary : AppColors.textSecondaryLight),
                                      onPressed: () => setState(() => _viewMode = SignCardVariant.list),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Signs Grid/List
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  sliver: signsAsync.when(
                    data: (signs) {
                      if (signs.isEmpty) {
                        return SliverToBoxAdapter(
                          child: AppEmptyState(
                            title: widget.showOnlyFavorites
                                ? l10n.noFavoritesYet
                                : l10n.noSignsFound,
                            message: widget.showOnlyFavorites
                                ? l10n.noFavoritesYet
                                : l10n.noSignsFound,
                            imagePath: null,
                            icon: widget.showOnlyFavorites
                                ? Icons.favorite_border
                                : Icons.search_off,
                          ),
                        );
                      }

                      final isGrid = _viewMode == SignCardVariant.grid;
                      return SliverGrid(
                        // Column count follows the available width instead of
                        // a hardcoded value, so cards keep a sane size from a
                        // 390 px phone to a 1280 px desktop column.
                        gridDelegate: adaptiveGridDelegate(
                          maxItemWidth: isGrid ? 220 : 520,
                          childAspectRatio: isGrid ? 0.8 : 3.5,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final sign = signs[index];
                            final isFav = favoritesAsync.value?.any((s) => s.id == sign.id) ?? false;
                            
                            return SignCard(
                              sign: sign,
                              variant: _viewMode,
                              isFavorite: isFav,
                              onTap: () => context.pushNamed(
                                AppRoutes.signDetailName,
                                pathParameters: {'id': sign.id},
                              ),
                              onFavoriteTap: () async {
                                final user = ref.read(currentUserProvider);
                                if (user == null) return;
                                if (isFav) {
                                  await ref.read(favoriteRepositoryProvider).removeFavorite(user.id, sign.id);
                                } else {
                                  await ref.read(favoriteRepositoryProvider).addFavorite(user.id, sign.id);
                                }
                                ref.invalidate(userFavoritesProvider);
                              },
                            );
                          },
                          childCount: signs.length,
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(child: Center(child: AppLoader())),
                    error: (err, _) => SliverToBoxAdapter(
                      child: AppEmptyState(
                        title: l10n.errorGeneric,
                        message: '$err',
                        imagePath: null,
                        icon: Icons.error_outline,
                        actionLabel: l10n.retry,
                        onAction: () {
                          if (widget.showOnlyFavorites) {
                            ref.invalidate(userFavoritesProvider);
                          } else {
                            ref.invalidate(signSearchProvider(
                              query: _searchQuery,
                              languageId: 1,
                              categoryId: _selectedCategoryId,
                            ));
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
