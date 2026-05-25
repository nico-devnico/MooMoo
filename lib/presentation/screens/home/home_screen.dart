import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../domain/providers/sign_provider.dart';
import '../../../domain/providers/notification_provider.dart';
import '../../../data/models/sign_language.dart';
import '../../../data/models/notification.dart' as model;
import '../../widgets/app_card.dart';
import '../../widgets/app_loader.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Envoi de la notification de bienvenue lors de la première connexion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSendWelcomeNotification();
    });
  }

  Future<void> _checkAndSendWelcomeNotification() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repo = ref.read(notificationRepositoryProvider);
    final notifications = await repo.getNotifications(user.id);
    
    // Vérifier si une notification de bienvenue existe déjà
    final hasWelcome = notifications.any((n) => n.type == 'welcome');
    
    if (!hasWelcome) {
      final l10n = AppLocalizations.of(context)!;
      final welcomeNotif = model.Notification(
        id: const Uuid().v4(),
        userId: user.id,
        type: 'welcome',
        title: 'Bienvenue sur MooMoo ! 👐',
        body: 'Nous sommes ravis de vous compter parmi nous. Commencez à explorer la langue des signes dès maintenant !',
        isRead: false,
        createdAt: DateTime.now(),
      );
      
      // Note: Dans un vrai backend, cela se ferait côté serveur
      // Ici on simule l'insertion via Supabase
      try {
        await ref.read(supabaseClientProvider)
            .from('notifications')
            .insert(welcomeNotif.toJson());
      } catch (e) {
        debugPrint('Erreur lors de l\'envoi de la notification de bienvenue: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                  title: profileAsync.when(
                    data: (profile) => Text(
                      l10n.greeting(profile?.displayName ?? user?.email?.split('@').first ?? l10n.guest),
                      style: AppTextStyles.h3,
                    ),
                    loading: () => const AppLoader(width: 150, height: 20),
                    error: (_, __) => Text(l10n.hello, style: AppTextStyles.h3),
                  ),
                  background: Container(color: Theme.of(context).scaffoldBackgroundColor),
                ),
                actions: [
                  ref.watch(unreadNotificationsCountProvider).when(
                    data: (count) => IconButton(
                      icon: count > 0
                          ? Badge(
                              label: Text(count.toString()),
                              child: const Icon(Icons.notifications_outlined),
                            )
                          : const Icon(Icons.notifications_outlined),
                      onPressed: () => context.pushNamed(AppRoutes.notificationsName),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.pushNamed(AppRoutes.settingsName),
                  ),
                  const SizedBox(width: AppSpacing.m),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _LanguageSelector(),
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Main Actions
                    Row(
                      children: [
                        Expanded(
                          child: _MainActionCard(
                            title: l10n.signToText,
                            subtitle: l10n.viaCamera,
                            icon: Icons.videocam_outlined,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.goNamed(AppRoutes.translatorName),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: _MainActionCard(
                            title: l10n.textToSign,
                            subtitle: l10n.viaKeyboard,
                            icon: Icons.keyboard_alt_outlined,
                            gradient: const LinearGradient(
                              colors: [AppColors.secondary, Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () => context.goNamed(AppRoutes.translatorName),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xxl),
                    _SectionHeader(
                      title: l10n.learnByCategory,
                      onSeeAll: () => context.pushNamed(AppRoutes.dictionaryName),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    const _CategoriesSection(),

                    const SizedBox(height: AppSpacing.xxl),
                    _SectionHeader(title: l10n.recentSigns, onSeeAll: () {}),
                    const SizedBox(height: AppSpacing.m),
                    _RecentSignTile(title: l10n.helloSign, category: l10n.salutations, date: l10n.twoHoursAgo),
                    _RecentSignTile(title: l10n.merciSign, category: l10n.salutations, date: l10n.yesterday),
                    _RecentSignTile(title: l10n.pleaseSign, category: l10n.politesse, date: l10n.yesterday),
                    
                    const SizedBox(height: AppSpacing.xl),
                    if (user != null) const _ContributionBanner(),
                    const SizedBox(height: AppSpacing.xxxl),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final languagesAsync = ref.watch(signLanguagesProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final currentLangCode = profile?.preferredSignLanguage ?? 'LSF';
    
    // Find current language object to get its flag if possible
    final currentLang = languagesAsync.value?.firstWhere(
      (l) => l.code == currentLangCode,
      orElse: () => const SignLanguage(id: 0, code: 'LSF', name: 'LSF'),
    );
    
    final flag = currentLang?.flagEmoji ?? _getFlagForLanguage(currentLangCode);

    return InkWell(
      onTap: () {
        languagesAsync.whenData((languages) {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.signLanguage, style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.l),
                  ...languages.map((lang) => ListTile(
                    leading: Text(lang.flagEmoji ?? _getFlagForLanguage(lang.code), style: const TextStyle(fontSize: 24)),
                    title: Text(lang.name),
                    trailing: lang.code == currentLangCode ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () async {
                      if (profile != null) {
                        await ref.read(profileRepositoryProvider).updateProfile(
                          profile.copyWith(preferredSignLanguage: lang.code),
                        );
                        ref.invalidate(userProfileProvider);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  )),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              currentLangCode,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  String _getFlagForLanguage(String language) {
    switch (language.toUpperCase()) {
      case 'LSF':
        return '🇫🇷';
      case 'ASL':
        return '🇺🇸';
      case 'BSL':
        return '🇬🇧';
      case 'LSC':
      case 'CAM':
      case 'CMR':
        return '🇨🇲';
      default:
        return '🌎';
    }
  }
}

class _MainActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h3),
        TextButton(
          onPressed: onSeeAll,
          child: Row(
            children: [
              Text(l10n.seeAll),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.m),
      child: AppCard(
        onTap: onTap,
        width: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSection extends ConsumerWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final languagesAsync = ref.watch(signLanguagesProvider);
    final l10n = AppLocalizations.of(context)!;

    return languagesAsync.when(
      data: (languages) {
        final currentLangCode = profile?.preferredSignLanguage ?? 'LSF';
        final currentLang = languages.firstWhere(
          (l) => l.code == currentLangCode,
          orElse: () => languages.isNotEmpty ? languages.first : SignLanguage(id: 1, code: 'LSF', name: 'LSF'),
        );

        final categoriesAsync = ref.watch(signCategoriesProvider(currentLang.id));

        return SizedBox(
          height: 140,
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Center(child: Text(l10n.noCategory));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return _CategoryCard(
                    title: cat.name,
                    icon: _getCategoryIcon(cat.name),
                    onTap: () => context.pushNamed(
                      AppRoutes.categoryName,
                      pathParameters: {'id': cat.id.toString()},
                    ),
                  );
                },
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(right: AppSpacing.m),
                child: AppLoader(width: 120, height: 140, borderRadius: 20),
              ),
            ),
            error: (_, __) => Center(child: Text(l10n.errorLoadingCategories)),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.errorLoadingLanguages)),
    );
  }

  String _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('alphabet')) return '🅰️';
    if (lower.contains('nombre')) return '🔢';
    if (lower.contains('salut')) return '👋';
    if (lower.contains('famille')) return '👨‍👩‍👧‍👦';
    if (lower.contains('animal')) return '🐶';
    if (lower.contains('nourriture')) return '🍎';
    if (lower.contains('couleur')) return '🎨';
    return '📁';
  }
}

class _RecentSignTile extends StatelessWidget {
  final String title;
  final String category;
  final String date;

  const _RecentSignTile({
    required this.title,
    required this.category,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: AppCard(
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history, color: AppColors.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$category • $date'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {},
        ),
      ),
    );
  }
}

class _ContributionBanner extends StatelessWidget {
  const _ContributionBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.helpCommunity,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.contributeDescription,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pushNamed(AppRoutes.contributeName),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.contributeNow),
          ),
        ],
      ),
    );
  }
}
