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
import '../../../domain/providers/app_settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_panel.dart';

/// Page d'accueil publique pour les visiteurs (Landing Page vitrine).
///
/// Présente la plateforme MooMoo, ses fonctionnalités de traduction par vision IA,
/// son dictionnaire collaboratif, son parcours d'apprentissage et oriente
/// les visiteurs vers la création de compte ou la connexion.
class VisitorHomeScreen extends ConsumerStatefulWidget {
  const VisitorHomeScreen({super.key});

  @override
  ConsumerState<VisitorHomeScreen> createState() => _VisitorHomeScreenState();
}

class _VisitorHomeScreenState extends ConsumerState<VisitorHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _demoKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _forEveryoneKey = GlobalKey();

  // État de la démo interactive
  int _activeDemoTab = 0; // 0: Traduction, 1: Dictionnaire, 2: Quiz
  String _selectedSignWord = 'Bonjour';
  int? _selectedQuizAnswer;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showMobileMenu(BuildContext context, AppLocalizations? l10n) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const AppLogo(width: 32, height: 32),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          ref.watch(appNameProvider),
                          style: AppTextStyles.h3,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(AppIcons.translate, color: AppColors.primary),
                  title: const Text('Fonctionnalités'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _scrollTo(_featuresKey);
                  },
                ),
                ListTile(
                  leading: const Icon(AppIcons.play, color: AppColors.primary),
                  title: const Text('Démonstration'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _scrollTo(_demoKey);
                  },
                ),
                ListTile(
                  leading: const Icon(AppIcons.progress, color: AppColors.primary),
                  title: const Text('Comment ça marche'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _scrollTo(_howItWorksKey);
                  },
                ),
                ListTile(
                  leading: const Icon(AppIcons.users, color: AppColors.primary),
                  title: const Text('Pour qui ?'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _scrollTo(_forEveryoneKey);
                  },
                ),
                const SizedBox(height: AppSpacing.m),
                AppButton(
                  label: l10n?.createAccount ?? 'Créer un compte',
                  icon: AppIcons.userAdd,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.pushNamed(AppRoutes.registerName);
                  },
                ),
                const SizedBox(height: AppSpacing.s),
                AppButton(
                  label: l10n?.signIn ?? 'Se connecter',
                  variant: AppButtonVariant.outline,
                  icon: AppIcons.profile,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.pushNamed(AppRoutes.loginName);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = context.isDesktop;
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Barre de navigation supérieure
          _buildNavbar(context, l10n, isDesktop),

          // Contenu principal avec défilement fluide
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? AppSpacing.l : AppSpacing.xl,
              ),
              child: PageContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Hero principal
                    _buildHero(context, l10n),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Section 2: Bandeau des indicateurs clés
                    _buildStatsStrip(context),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Section 3: Fonctionnalités majeures
                    Container(
                      key: _featuresKey,
                      child: _buildFeaturesSection(context),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Section 4: Simulateur interactif
                    Container(
                      key: _demoKey,
                      child: _buildInteractiveDemo(context),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Section 5: Comment ça marche (3 étapes)
                    Container(
                      key: _howItWorksKey,
                      child: _buildHowItWorksSection(context),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Section 6: Pensé pour tous les publics
                    Container(
                      key: _forEveryoneKey,
                      child: _buildForEveryoneSection(context, l10n),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Section 7: Grande bannière d'appel à l'action
                    _buildCtaBanner(context, l10n),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Section 8: Pied de page complet
                    _buildFooter(context, l10n),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION BAR
  // ===========================================================================
  Widget _buildNavbar(BuildContext context, AppLocalizations? l10n, bool isDesktop) {
    final appName = ref.watch(appNameProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          bottom: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? AppSpacing.m : AppSpacing.xl,
        vertical: AppSpacing.m,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo & Marque — ne grandit pas, ne rétrécit pas
            InkWell(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              borderRadius: AppRadius.radiusM,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(width: 36, height: 36),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      appName,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                        fontSize: 22,
                      ),
                    ),
                    // Badge LSF & WASL masqué sur mobile pour économiser la place
                    if (!context.isMobile) ...[
                      const SizedBox(width: AppSpacing.s),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: AppRadius.radiusCircular,
                        ),
                        child: Text(
                          'LSF & WASL',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Partie droite : liens d'ancrage + boutons d'action
            // Flexible absorbe la largeur restante et empêche tout overflow
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Liens d'ancrage (desktop / tablette large)
                  if (context.hasSideNavigation) ...[ // 1024 px+
                    _NavLink(
                      label: 'Fonctionnalités',
                      onTap: () => _scrollTo(_featuresKey),
                    ),
                    _NavLink(
                      label: 'Démonstration',
                      onTap: () => _scrollTo(_demoKey),
                    ),
                    _NavLink(
                      label: 'Comment ça marche',
                      onTap: () => _scrollTo(_howItWorksKey),
                    ),
                    _NavLink(
                      label: 'Pour qui ?',
                      onTap: () => _scrollTo(_forEveryoneKey),
                    ),
                    const SizedBox(width: AppSpacing.m),
                  ] else if (context.isTablet) ...[ // 600–1023 px
                    _NavLink(
                      label: 'Fonctionnalités',
                      onTap: () => _scrollTo(_featuresKey),
                    ),
                    _NavLink(
                      label: 'Démo',
                      onTap: () => _scrollTo(_demoKey),
                    ),
                    const SizedBox(width: AppSpacing.s),
                  ],

                  // Boutons d'action : mobile
                  if (context.isMobile) ...[ 
                    TextButton(
                      onPressed: () => context.pushNamed(AppRoutes.loginName),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s,
                          vertical: AppSpacing.s,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n?.signIn ?? 'Connexion',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.list),
                      onPressed: () => _showMobileMenu(context, l10n),
                      tooltip: 'Menu',
                      visualDensity: VisualDensity.compact,
                    ),

                  // Boutons d'action : tablette et desktop
                  ] else ...[ 
                    TextButton(
                      onPressed: () => context.pushNamed(AppRoutes.loginName),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.s,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n?.signIn ?? 'Se connecter',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    FilledButton(
                      onPressed: () => context.pushNamed(AppRoutes.registerName),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                          vertical: 14,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.radiusL,
                        ),
                      ),
                      child: Text(
                        l10n?.createAccount ?? 'Commencer',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: HERO
  // ===========================================================================
  Widget _buildHero(BuildContext context, AppLocalizations? l10n) {
    final isDesktop = context.hasSideNavigation;

    final heroText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge Eyebrow
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.radiusCircular,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.achievement, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'L\'intelligence artificielle au service de l\'inclusivité',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        // Titre d'impact
        Text(
          'La langue des signes à portée de main.',
          style: (isDesktop
                  ? AppTextStyles.h1.copyWith(fontSize: 48)
                  : AppTextStyles.h1.copyWith(fontSize: 32))
              .copyWith(
            height: 1.15,
            color: AppColors.primaryDeep,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // Sous-titre descriptif
        Text(
          'MooMoo brise les barrières entre personnes sourdes, malentendantes et entendantes. '
          'Traduisez en direct avec votre caméra, explorez un dictionnaire immersif en 3D et progressez chaque jour à votre rythme.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary(context),
            fontSize: isDesktop ? 18 : 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Boutons d'action principaux
        Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.m,
          children: [
            AppButton(
              label: 'Créer un compte gratuit',
              icon: AppIcons.forward,
              fullWidth: context.isMobile,
              onPressed: () => context.pushNamed(AppRoutes.registerName),
            ),
            AppButton(
              label: 'Se connecter',
              icon: AppIcons.profile,
              variant: AppButtonVariant.outline,
              fullWidth: context.isMobile,
              onPressed: () => context.pushNamed(AppRoutes.loginName),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // Puces d'assurance & accessibilité
        Wrap(
          spacing: AppSpacing.l,
          runSpacing: AppSpacing.s,
          children: const [
            _HeroBenefit(text: '100% Visuel & Sans obstacle'),
            _HeroBenefit(text: 'Reconnaissance gestuelle en direct'),
            _HeroBenefit(text: 'Accessible Web, Mobile & Bureau'),
          ],
        ),
      ],
    );

    final heroVisual = const _HeroVisualMockup();

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heroText,
          const SizedBox(height: AppSpacing.xxl),
          heroVisual,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 6, child: heroText),
        const SizedBox(width: AppSpacing.xxl),
        Expanded(flex: 5, child: heroVisual),
      ],
    );
  }

  // ===========================================================================
  // SECTION 2: STATS STRIP
  // ===========================================================================
  Widget _buildStatsStrip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.border(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;

          final items = [
            const _StatItem(
              value: '+3 500',
              label: 'Signes au dictionnaire',
              icon: AppIcons.dictionary,
            ),
            const _StatItem(
              value: '2 sens',
              label: 'Signes ⇄ Texte & Voix',
              icon: AppIcons.translate,
            ),
            const _StatItem(
              value: '60 FPS',
              label: 'Suivi IA temps réel',
              icon: AppIcons.camera,
            ),
            const _StatItem(
              value: '100%',
              label: 'Visuel & Inclusif',
              icon: AppIcons.signLanguage,
            ),
          ];

          if (isCompact) {
            return Wrap(
              spacing: AppSpacing.l,
              runSpacing: AppSpacing.l,
              alignment: WrapAlignment.spaceAround,
              children: items.map((e) => SizedBox(width: 140, child: e)).toList(),
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items,
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SECTION 3: FEATURES
  // ===========================================================================
  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          badge: 'FONCTIONNALITÉS ESSENTIELLES',
          title: 'Une technologie de pointe conçue pour rapprocher',
          subtitle:
              'MooMoo combine intelligence artificielle, linguistique des signes et pédagogie ludique pour vous offrir une expérience fluide.',
        ),
        const SizedBox(height: AppSpacing.xxl),
        GridView.count(
          crossAxisCount: context.responsive(mobile: 1, tablet: 2, desktop: 2),
          crossAxisSpacing: AppSpacing.l,
          mainAxisSpacing: AppSpacing.l,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: context.responsive(mobile: 1.35, tablet: 1.45, desktop: 1.55),
          children: [
            _FeatureCard(
              icon: AppIcons.camera,
              accentColor: AppColors.primary,
              title: 'Traduction Caméra (Signes → Texte)',
              body:
                  'Activez votre caméra. Notre modèle de vision par ordinateur suit les mouvements des mains et du visage pour transcrire instantanément vos signes en mots clairs.',
              tag: 'Inférence temps réel',
            ),
            _FeatureCard(
              icon: AppIcons.signLanguage,
              accentColor: AppColors.secondary,
              title: 'Génération 3D & Vidéos (Texte → Signes)',
              body:
                  'Saisissez du texte ou dictez à la voix. MooMoo anime un avatar 3D fluide ou diffuse des vidéos de référence certifiées pour vous montrer le geste exact.',
              tag: 'Avatar 3D & Vidéos HD',
            ),
            _FeatureCard(
              icon: AppIcons.dictionary,
              accentColor: AppColors.warning,
              title: 'Dictionnaire Collaboratif & Pratique',
              body:
                  'Explorez des milliers de signes classés par thématiques. Ralentissez la vidéo, pratiquez devant la caméra avec retour en direct et enregistrez vos favoris.',
              tag: 'Validé par experts sourds',
            ),
            _FeatureCard(
              icon: AppIcons.learning,
              accentColor: AppColors.success,
              title: 'Parcours d\'Apprentissage Gamifié',
              body:
                  'Apprenez la langue des signes pas à pas avec des leçons courtes, des quiz dynamiques, des séries quotidiennes (streaks) et des récompenses stimulantes.',
              tag: 'Progression quotidienne',
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 4: INTERACTIVE DEMO SIMULATOR
  // ===========================================================================
  Widget _buildInteractiveDemo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          badge: 'ESSAYEZ MAINTENANT',
          title: 'Découvrez l\'expérience MooMoo en un clic',
          subtitle:
              'Testez sans attendre la richesse de nos fonctionnalités avant même de créer votre compte.',
        ),
        const SizedBox(height: AppSpacing.xl),

        // Sélecteur d'onglets de démo
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.neutral(context),
              borderRadius: AppRadius.radiusCircular,
            ),
            child: Wrap(
              spacing: 4,
              children: [
                _DemoTabButton(
                  label: 'Traduire en direct',
                  icon: AppIcons.translate,
                  isSelected: _activeDemoTab == 0,
                  onTap: () => setState(() => _activeDemoTab = 0),
                ),
                _DemoTabButton(
                  label: 'Consulter le dictionnaire',
                  icon: AppIcons.dictionary,
                  isSelected: _activeDemoTab == 1,
                  onTap: () => setState(() => _activeDemoTab = 1),
                ),
                _DemoTabButton(
                  label: 'Tester un exercice',
                  icon: AppIcons.learning,
                  isSelected: _activeDemoTab == 2,
                  onTap: () => setState(() => _activeDemoTab = 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Contenu interactif selon l'onglet
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildDemoContent(context),
        ),
      ],
    );
  }

  Widget _buildDemoContent(BuildContext context) {
    switch (_activeDemoTab) {
      case 0:
        return _buildTranslationDemo(context);
      case 1:
        return _buildDictionaryDemo(context);
      case 2:
      default:
        return _buildQuizDemo(context);
    }
  }

  Widget _buildTranslationDemo(BuildContext context) {
    final sampleSigns = ['Bonjour', 'Merci', 'Comment vas-tu ?', 'Au revoir'];

    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadius.radiusM,
                ),
                child: const Icon(AppIcons.camera, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simulateur de Traduction Gestuelle', style: AppTextStyles.h3),
                    Text(
                      'Sélectionnez un signe ci-dessous pour visualiser la détection IA instantanée :',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // Choix des signes
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: sampleSigns.map((sign) {
              final isSelected = _selectedSignWord == sign;
              return ChoiceChip(
                label: Text(sign),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedSignWord = sign);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.l),

          // Résultat interactif simulé
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: AppColors.neutral(context),
              borderRadius: AppRadius.radiusL,
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.signLanguage,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successSoft,
                              borderRadius: AppRadius.radiusCircular,
                            ),
                            child: Text(
                              'Détecté à 99.4% • LSF',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Temps réel : 14ms',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '« $_selectedSignWord »',
                        style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDictionaryDemo(BuildContext context) {
    final categories = [
      ('Salutations', AppIcons.signLanguage, '12 signes'),
      ('Famille', AppIcons.users, '24 signes'),
      ('Émotions', AppIcons.achievement, '18 signes'),
      ('Travail & Études', AppIcons.learning, '32 signes'),
    ];

    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: AppRadius.radiusM,
                ),
                child: const Icon(AppIcons.dictionary, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aperçu du Dictionnaire Visuel', style: AppTextStyles.h3),
                    Text(
                      'Recherchez et filtrez parmi plus de 3 500 entrées certifiées avec vidéos et 3D :',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: AppSpacing.m,
                mainAxisSpacing: AppSpacing.m,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.4 : 1.3,
                children: categories.map((cat) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: AppRadius.radiusL,
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat.$2, color: AppColors.primary, size: 24),
                        const SizedBox(height: 8),
                        Text(cat.$1, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                        Text(cat.$3, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary(context))),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.m),
          Center(
            child: TextButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.registerName),
              icon: const Icon(AppIcons.forward, size: 16),
              label: const Text('Créer un compte pour explorer l\'intégralité du dictionnaire'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizDemo(BuildContext context) {
    final options = ['Bonjour', 'Merci', 'S\'il vous plaît', 'Pardon'];
    const correctIndex = 1; // "Merci"

    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: AppRadius.radiusM,
                ),
                child: const Icon(AppIcons.exercise, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mini-Quiz Interactif d\'Apprentissage', style: AppTextStyles.h3),
                    Text(
                      'Quel est le mot correspondant au geste de la main portée au menton puis avancée vers l\'interlocuteur ?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // Options de quiz
          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.m,
            children: List.generate(options.length, (index) {
              final opt = options[index];
              final isChosen = _selectedQuizAnswer == index;
              final isCorrect = index == correctIndex;

              Color bg = AppColors.surface(context);
              Color border = AppColors.border(context);
              Color textCol = AppColors.textPrimaryLight;

              if (isChosen) {
                if (isCorrect) {
                  bg = AppColors.successSoft;
                  border = AppColors.success;
                  textCol = AppColors.success;
                } else {
                  bg = AppColors.errorSoft;
                  border = AppColors.error;
                  textCol = AppColors.error;
                }
              }

              return InkWell(
                onTap: () => setState(() => _selectedQuizAnswer = index),
                borderRadius: AppRadius.radiusL,
                child: Container(
                  width: context.isMobile ? double.infinity : 220,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: AppRadius.radiusL,
                    border: Border.all(color: border, width: isChosen ? 2 : 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(opt, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: textCol)),
                      if (isChosen && isCorrect)
                        const Icon(AppIcons.check, color: AppColors.success, size: 18)
                      else if (isChosen && !isCorrect)
                        const Icon(AppIcons.close, color: AppColors.error, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ),

          if (_selectedQuizAnswer != null) ...[
            const SizedBox(height: AppSpacing.l),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: _selectedQuizAnswer == correctIndex ? AppColors.successSoft : AppColors.errorSoft,
                borderRadius: AppRadius.radiusM,
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedQuizAnswer == correctIndex ? AppIcons.success : AppIcons.error,
                    color: _selectedQuizAnswer == correctIndex ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      _selectedQuizAnswer == correctIndex
                          ? 'Bravo ! C\'est exactement le signe pour « Merci ». Vous gagnez +10 XP !'
                          : 'Pas tout à fait ! Ce geste correspond à « Merci ». Réessayez !',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _selectedQuizAnswer == correctIndex ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 5: COMMENT ÇA MARCHE (HOW IT WORKS)
  // ===========================================================================
  Widget _buildHowItWorksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          badge: 'SIMPLICITÉ & ACCESSIBILITÉ',
          title: 'Comment ça marche ?',
          subtitle:
              'Prêt en moins d\'une minute, sans matériel spécifique en dehors d\'une webcam ou de votre smartphone.',
        ),
        const SizedBox(height: AppSpacing.xxl),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            final steps = [
              const _StepCard(
                stepNumber: '01',
                title: 'Inscrivez-vous gratuitement',
                description:
                    'Créez votre profil en quelques clics sans carte bancaire. Choisissez votre langue de référence et vos préférences visuelles.',
                icon: AppIcons.userAdd,
              ),
              const _StepCard(
                stepNumber: '02',
                title: 'Activez vos outils',
                description:
                    'Lancez la caméra pour traduire vos signes en direct, ou saisissez du texte pour voir l\'avatar 3D l\'interpréter.',
                icon: AppIcons.camera,
              ),
              const _StepCard(
                stepNumber: '03',
                title: 'Communiquez & Progressez',
                description:
                    'Échangez librement, enrichissez votre vocabulaire avec le dictionnaire et suivez vos séries de leçons quotidiennes.',
                icon: AppIcons.streakActive,
              ),
            ];

            if (!isDesktop) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: steps
                    .expand((s) => [s, const SizedBox(height: AppSpacing.l)])
                    .toList()
                  ..removeLast(),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: steps[0]),
                const SizedBox(width: AppSpacing.l),
                Expanded(child: steps[1]),
                const SizedBox(width: AppSpacing.l),
                Expanded(child: steps[2]),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 6: PENSÉ POUR TOUS LES PUBLICS
  // ===========================================================================
  Widget _buildForEveryoneSection(BuildContext context, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          badge: 'POUR TOUTE LA COMMUNAUTÉ',
          title: 'Pensé pour chacun d\'entre nous',
          subtitle:
              'MooMoo est bâti avec et pour les personnes sourdes, avec une ergonomie inclusive adaptée à tous les besoins.',
        ),
        const SizedBox(height: AppSpacing.xxl),
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            final cards = [
              _AudienceCard(
                icon: AppIcons.signLanguage,
                title: 'Sourds & Malentendants',
                body:
                    'Une interface 100% visuelle sans aucun piège sonore. Un espace pour échanger, proposer de nouveaux signes et faire vivre la culture sourde.',
                color: AppColors.primary,
              ),
              _AudienceCard(
                icon: AppIcons.users,
                title: 'Entendants & Proches',
                body:
                    'L\'outil idéal pour communiquer avec des collègues, des amis ou des membres de votre famille, sans appréhension et avec bienveillance.',
                color: AppColors.secondary,
              ),
              _AudienceCard(
                icon: AppIcons.learning,
                title: 'Écoles & Enseignants',
                body:
                    'Des espaces dédiés pour formateurs et experts sourds pour créer des leçons, valider des contributions et suivre des apprenants.',
                color: AppColors.warning,
              ),
            ];

            if (!isDesktop) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cards
                    .expand((c) => [c, const SizedBox(height: AppSpacing.l)])
                    .toList()
                  ..removeLast(),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.l),
                Expanded(child: cards[1]),
                const SizedBox(width: AppSpacing.l),
                Expanded(child: cards[2]),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 7: CTA BANNER FINAL
  // ===========================================================================
  Widget _buildCtaBanner(BuildContext context, AppLocalizations? l10n) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? AppSpacing.xl : AppSpacing.xxxl,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: AppRadius.radiusXL,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(AppIcons.signLanguage, color: Colors.white, size: 36),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            'Prêt à communiquer sans barrière ?',
            textAlign: TextAlign.center,
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontSize: context.isMobile ? 26 : 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Rejoignez dès aujourd\'hui MooMoo. '
              'Apprenez, traduisez et faites partie d\'une communauté inclusive engagée pour l\'accessibilité universelle.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.m,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => context.pushNamed(AppRoutes.registerName),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
                  textStyle: AppTextStyles.button,
                ),
                icon: const Icon(AppIcons.forward, size: 18),
                label: const Text('Créer mon compte gratuit'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.pushNamed(AppRoutes.loginName),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusL),
                  textStyle: AppTextStyles.button,
                ),
                icon: const Icon(AppIcons.profile, size: 18),
                label: const Text('J\'ai déjà un compte'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 8: FOOTER
  // ===========================================================================
  Widget _buildFooter(BuildContext context, AppLocalizations? l10n) {
    final appName = ref.watch(appNameProvider);
    final secondary = AppColors.textSecondary(context);

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.l),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;

              final brandCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppLogo(width: 32, height: 32),
                      const SizedBox(width: AppSpacing.s),
                      Text(appName, style: AppTextStyles.h3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      'La plateforme inclusive de traduction et d\'apprentissage de la langue des signes (LSF & WASL).',
                      style: AppTextStyles.bodyMedium.copyWith(color: secondary),
                    ),
                  ),
                ],
              );

              final linksCol1 = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Navigation', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.s),
                  _FooterLink(label: 'Fonctionnalités', onTap: () => _scrollTo(_featuresKey)),
                  _FooterLink(label: 'Démonstration', onTap: () => _scrollTo(_demoKey)),
                  _FooterLink(label: 'Comment ça marche', onTap: () => _scrollTo(_howItWorksKey)),
                  _FooterLink(label: 'Pour qui ?', onTap: () => _scrollTo(_forEveryoneKey)),
                ],
              );

              final linksCol2 = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Accès rapide', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.s),
                  _FooterLink(label: 'Connexion', onTap: () => context.pushNamed(AppRoutes.loginName)),
                  _FooterLink(label: 'Inscription', onTap: () => context.pushNamed(AppRoutes.registerName)),
                  _FooterLink(label: 'Mot de passe oublié', onTap: () => context.pushNamed(AppRoutes.forgotPasswordName)),
                ],
              );

              final linksCol3 = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informations', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.s),
                  _FooterLink(label: 'Culture sourde & Inclusion', onTap: () => _scrollTo(_forEveryoneKey)),
                  _FooterLink(label: 'Reconnaissance IA WASL/LSFB', onTap: () => _scrollTo(_featuresKey)),
                  _FooterLink(label: 'Assistance & FAQ', onTap: () => _showHelpInfo(context)),
                ],
              );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    brandCol,
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: linksCol1),
                        Expanded(child: linksCol2),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    linksCol3,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: brandCol),
                  Expanded(flex: 2, child: linksCol1),
                  Expanded(flex: 2, child: linksCol2),
                  Expanded(flex: 2, child: linksCol3),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Divider(),
          const SizedBox(height: AppSpacing.l),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '© 2026 $appName. Fait avec passion pour l\'inclusivité.',
                  style: AppTextStyles.bodySmall.copyWith(color: secondary),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.favorite, size: 16, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text('100% Inclusif', style: AppTextStyles.bodySmall.copyWith(color: secondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHelpInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assistance MooMoo'),
        content: const Text(
          'Besoin d\'aide ou d\'informations complémentaires sur MooMoo ?\n\n'
          'Une fois connecté(e), vous aurez accès au guide utilisateur complet, au centre d\'aide et au formulaire de contact direct avec nos équipes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pushNamed(AppRoutes.registerName);
            },
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMPOSANTS LOCAUX ET AFFICHAGES VISUELS
// =============================================================================

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HeroBenefit extends StatelessWidget {
  const _HeroBenefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(AppIcons.check, size: 18, color: AppColors.success),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

/// Carte de démonstration visuelle dans le Hero montrant la simulation IA
class _HeroVisualMockup extends StatelessWidget {
  const _HeroVisualMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.border(context), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barre supérieure de la fausse interface
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
            color: AppColors.primaryDeep,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Vision IA Active • 60 FPS',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.radiusCircular,
                  ),
                  child: Text(
                    'WASL & LSFB',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Zone visuelle centrale simulant la détection caméra
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primarySoft,
                  AppColors.surface(context),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Illustration stylisée de la détection de main
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      AppIcons.signLanguage,
                      color: AppColors.primary,
                      size: 64,
                    ),
                  ),
                ),

                // Repères de squelette / points clés
                Positioned(
                  top: 28,
                  left: 36,
                  child: _LandmarkPill(label: 'Index: 98%'),
                ),
                Positioned(
                  bottom: 30,
                  right: 36,
                  child: _LandmarkPill(label: 'Pouce: 99%'),
                ),

                // Badge de reconnaissance centrale
                Positioned(
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep,
                      borderRadius: AppRadius.radiusCircular,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.check, color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Signe : BONJOUR (99.4%)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Boîte de traduction texte résultat
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            color: AppColors.surface(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadius.radiusM,
                  ),
                  child: const Icon(AppIcons.translate, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Traduction instantanée :',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '« Bonjour ! Ravi de vous rencontrer. »',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandmarkPill extends StatelessWidget {
  const _LandmarkPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface(context).withValues(alpha: 0.9),
        borderRadius: AppRadius.radiusCircular,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.primaryDeep,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.badge,
    required this.title,
    required this.subtitle,
  });

  final String badge;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.radiusCircular,
          ),
          child: Text(
            badge,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.h1.copyWith(
            fontSize: context.isMobile ? 24 : 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDeep,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.body,
    required this.tag,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String body;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusM,
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neutral(context),
                  borderRadius: AppRadius.radiusCircular,
                ),
                child: Text(
                  tag,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary(context),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.s),
          Expanded(
            child: Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTabButton extends StatelessWidget {
  const _DemoTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.surface(context) : Colors.transparent,
      borderRadius: AppRadius.radiusCircular,
      elevation: isSelected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusCircular,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String stepNumber;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepNumber,
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadius.radiusM,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.s),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusL,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.s),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }
}
