import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get hello;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur MooMoo'**
  String get welcome;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @translate.
  ///
  /// In fr, this message translates to:
  /// **'Traduire'**
  String get translate;

  /// No description provided for @dictionary.
  ///
  /// In fr, this message translates to:
  /// **'Dico'**
  String get dictionary;

  /// No description provided for @learning.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre'**
  String get learning;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @signToText.
  ///
  /// In fr, this message translates to:
  /// **'Signe → Texte'**
  String get signToText;

  /// No description provided for @textToSign.
  ///
  /// In fr, this message translates to:
  /// **'Texte → Signe'**
  String get textToSign;

  /// No description provided for @signLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue des signes'**
  String get signLanguage;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get system;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer les modifications'**
  String get apply;

  /// No description provided for @greeting.
  ///
  /// In fr, this message translates to:
  /// **'Salut, {name} 👋'**
  String greeting(String name);

  /// No description provided for @guest.
  ///
  /// In fr, this message translates to:
  /// **'Invité'**
  String get guest;

  /// No description provided for @viaCamera.
  ///
  /// In fr, this message translates to:
  /// **'Via caméra'**
  String get viaCamera;

  /// No description provided for @viaKeyboard.
  ///
  /// In fr, this message translates to:
  /// **'Via clavier'**
  String get viaKeyboard;

  /// No description provided for @accountSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Compte & Sécurité'**
  String get accountSecurity;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// No description provided for @displayPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences d\'affichage'**
  String get displayPreferences;

  /// No description provided for @defaultView.
  ///
  /// In fr, this message translates to:
  /// **'Vue par défaut'**
  String get defaultView;

  /// No description provided for @appLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue de l\'application'**
  String get appLanguage;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications Push'**
  String get pushNotifications;

  /// No description provided for @newsletter.
  ///
  /// In fr, this message translates to:
  /// **'Newsletter'**
  String get newsletter;

  /// No description provided for @supportLegal.
  ///
  /// In fr, this message translates to:
  /// **'Support & Légal'**
  String get supportLegal;

  /// No description provided for @helpCenter.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get helpCenter;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get termsOfService;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @signs.
  ///
  /// In fr, this message translates to:
  /// **'Signes'**
  String get signs;

  /// No description provided for @textAudio.
  ///
  /// In fr, this message translates to:
  /// **'Texte/Audio'**
  String get textAudio;

  /// No description provided for @myAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get myAccount;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @translationHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des traductions'**
  String get translationHistory;

  /// No description provided for @myFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Mes favoris'**
  String get myFavorites;

  /// No description provided for @preferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get preferences;

  /// No description provided for @community.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get community;

  /// No description provided for @myContributions.
  ///
  /// In fr, this message translates to:
  /// **'Mes contributions'**
  String get myContributions;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @loginToSave.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour sauvegarder vos données'**
  String get loginToSave;

  /// No description provided for @profileUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil mise à jour'**
  String get profileUpdated;

  /// No description provided for @uploadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'upload'**
  String get uploadError;

  /// No description provided for @profileNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Profil non trouvé'**
  String get profileNotFound;

  /// No description provided for @yourProgress.
  ///
  /// In fr, this message translates to:
  /// **'Votre progression'**
  String get yourProgress;

  /// No description provided for @availableCourses.
  ///
  /// In fr, this message translates to:
  /// **'Cours disponibles'**
  String get availableCourses;

  /// No description provided for @signsMastered.
  ///
  /// In fr, this message translates to:
  /// **'Signes maîtrisés'**
  String get signsMastered;

  /// No description provided for @searchSign.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un signe...'**
  String get searchSign;

  /// No description provided for @learnByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre par catégorie'**
  String get learnByCategory;

  /// No description provided for @recentSigns.
  ///
  /// In fr, this message translates to:
  /// **'Signes récents'**
  String get recentSigns;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get seeAll;

  /// No description provided for @helpCommunity.
  ///
  /// In fr, this message translates to:
  /// **'Aidez la communauté ! 🤝'**
  String get helpCommunity;

  /// No description provided for @contributeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Contribuez en enregistrant de nouveaux signes pour enrichir notre dictionnaire.'**
  String get contributeDescription;

  /// No description provided for @contributeNow.
  ///
  /// In fr, this message translates to:
  /// **'Contribuer maintenant'**
  String get contributeNow;

  /// No description provided for @noCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie disponible'**
  String get noCategory;

  /// No description provided for @loadingCategories.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des catégories...'**
  String get loadingCategories;

  /// No description provided for @errorLoadingCategories.
  ///
  /// In fr, this message translates to:
  /// **'Erreur chargement catégories'**
  String get errorLoadingCategories;

  /// No description provided for @errorLoadingLanguages.
  ///
  /// In fr, this message translates to:
  /// **'Erreur chargement langues'**
  String get errorLoadingLanguages;

  /// No description provided for @displayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'affichage'**
  String get displayName;

  /// No description provided for @bio.
  ///
  /// In fr, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès'**
  String get profileUpdateSuccess;

  /// No description provided for @requiredField.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get requiredField;

  /// No description provided for @settings3D.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres 3D'**
  String get settings3D;

  /// No description provided for @manualControl.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle manuel'**
  String get manualControl;

  /// No description provided for @manualControlDesc.
  ///
  /// In fr, this message translates to:
  /// **'Permet de faire tourner le modèle'**
  String get manualControlDesc;

  /// No description provided for @zoomEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Zoom activé'**
  String get zoomEnabled;

  /// No description provided for @zoomEnabledDesc.
  ///
  /// In fr, this message translates to:
  /// **'Permet de zoomer sur le modèle'**
  String get zoomEnabledDesc;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @modify.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modify;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est trop court'**
  String get passwordTooShort;

  /// No description provided for @passwordUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour'**
  String get passwordUpdated;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @min6Chars.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get min6Chars;

  /// No description provided for @model3D.
  ///
  /// In fr, this message translates to:
  /// **'Modèle 3D'**
  String get model3D;

  /// No description provided for @video.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get video;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// No description provided for @lsf.
  ///
  /// In fr, this message translates to:
  /// **'Langue des Signes Française'**
  String get lsf;

  /// No description provided for @asl.
  ///
  /// In fr, this message translates to:
  /// **'American Sign Language'**
  String get asl;

  /// No description provided for @bsl.
  ///
  /// In fr, this message translates to:
  /// **'British Sign Language'**
  String get bsl;

  /// No description provided for @lsc.
  ///
  /// In fr, this message translates to:
  /// **'Langue des Signes Camerounaise'**
  String get lsc;

  /// No description provided for @viewMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode d\'affichage'**
  String get viewMode;

  /// No description provided for @landmarks.
  ///
  /// In fr, this message translates to:
  /// **'Landmarks'**
  String get landmarks;

  /// No description provided for @videoMode.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get videoMode;

  /// No description provided for @threeDModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle 3D'**
  String get threeDModel;

  /// No description provided for @noNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get noNotifications;

  /// No description provided for @chooseCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un personnage'**
  String get chooseCharacter;

  /// No description provided for @character3D.
  ///
  /// In fr, this message translates to:
  /// **'Personnage 3D'**
  String get character3D;

  /// No description provided for @helloSign.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get helloSign;

  /// No description provided for @merciSign.
  ///
  /// In fr, this message translates to:
  /// **'Merci'**
  String get merciSign;

  /// No description provided for @pleaseSign.
  ///
  /// In fr, this message translates to:
  /// **'S\'il vous plaît'**
  String get pleaseSign;

  /// No description provided for @salutations.
  ///
  /// In fr, this message translates to:
  /// **'Salutations'**
  String get salutations;

  /// No description provided for @politesse.
  ///
  /// In fr, this message translates to:
  /// **'Politesse'**
  String get politesse;

  /// No description provided for @twoHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a 2h'**
  String get twoHoursAgo;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @typeWordPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Tapez un mot ou une phrase...'**
  String get typeWordPhrase;

  /// No description provided for @videoWaiting.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo en attente de génération...'**
  String get videoWaiting;

  /// No description provided for @numbers.
  ///
  /// In fr, this message translates to:
  /// **'Numéros'**
  String get numbers;

  /// No description provided for @labels.
  ///
  /// In fr, this message translates to:
  /// **'Étiquettes'**
  String get labels;

  /// No description provided for @noLandmarkData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée de landmark'**
  String get noLandmarkData;

  /// No description provided for @pageNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Page non trouvée'**
  String get pageNotFound;

  /// No description provided for @pageNotFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Désolé, la page que vous recherchez n\'existe pas.'**
  String get pageNotFoundMessage;

  /// No description provided for @backHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backHome;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorGeneric;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get filterAll;

  /// No description provided for @results.
  ///
  /// In fr, this message translates to:
  /// **'Résultats'**
  String get results;

  /// No description provided for @noFavoritesYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori pour le moment'**
  String get noFavoritesYet;

  /// No description provided for @noSignsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signe trouvé'**
  String get noSignsFound;

  /// No description provided for @adminPanel.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get adminPanel;

  /// No description provided for @adminDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get adminDashboard;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble de la plateforme MooMoo'**
  String get adminDashboardSubtitle;

  /// No description provided for @adminModeration.
  ///
  /// In fr, this message translates to:
  /// **'Modération'**
  String get adminModeration;

  /// No description provided for @adminModerationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Examinez et validez les contributions de la communauté'**
  String get adminModerationSubtitle;

  /// No description provided for @adminSigns.
  ///
  /// In fr, this message translates to:
  /// **'Signes'**
  String get adminSigns;

  /// No description provided for @adminUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get adminUsers;

  /// No description provided for @adminUsersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les profils et gérez les droits administrateur'**
  String get adminUsersSubtitle;

  /// No description provided for @adminSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres admin'**
  String get adminSettings;

  /// No description provided for @adminSettingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations et notes pour l\'équipe d\'administration'**
  String get adminSettingsSubtitle;

  /// No description provided for @adminAccessDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé'**
  String get adminAccessDenied;

  /// No description provided for @adminAccessDeniedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas les droits administrateur pour accéder à cet espace.'**
  String get adminAccessDeniedMessage;

  /// No description provided for @backToProfile.
  ///
  /// In fr, this message translates to:
  /// **'Retour au profil'**
  String get backToProfile;

  /// No description provided for @backToApp.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'application'**
  String get backToApp;

  /// No description provided for @navMenu.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get navMenu;

  /// No description provided for @adminStatUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get adminStatUsers;

  /// No description provided for @adminStatSigns.
  ///
  /// In fr, this message translates to:
  /// **'Signes'**
  String get adminStatSigns;

  /// No description provided for @adminStatPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get adminStatPending;

  /// No description provided for @adminStatValidated.
  ///
  /// In fr, this message translates to:
  /// **'Signes validés'**
  String get adminStatValidated;

  /// No description provided for @adminQuickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get adminQuickActions;

  /// No description provided for @adminReviewPending.
  ///
  /// In fr, this message translates to:
  /// **'Modérer les contributions'**
  String get adminReviewPending;

  /// No description provided for @adminReviewPendingDesc.
  ///
  /// In fr, this message translates to:
  /// **'{count} contribution(s) en attente'**
  String adminReviewPendingDesc(int count);

  /// No description provided for @adminManageSigns.
  ///
  /// In fr, this message translates to:
  /// **'Gérer le dictionnaire'**
  String get adminManageSigns;

  /// No description provided for @adminManageSignsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter, valider ou supprimer des signes'**
  String get adminManageSignsDesc;

  /// No description provided for @adminManageUsers.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les utilisateurs'**
  String get adminManageUsers;

  /// No description provided for @adminManageUsersDesc.
  ///
  /// In fr, this message translates to:
  /// **'Voir les profils et attribuer le rôle admin'**
  String get adminManageUsersDesc;

  /// No description provided for @adminContributionsOverview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu des contributions'**
  String get adminContributionsOverview;

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In fr, this message translates to:
  /// **'Approuvée'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejetée'**
  String get statusRejected;

  /// No description provided for @statusValidated.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get statusValidated;

  /// No description provided for @statusNotValidated.
  ///
  /// In fr, this message translates to:
  /// **'Non validé'**
  String get statusNotValidated;

  /// No description provided for @adminNoContributions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune contribution'**
  String get adminNoContributions;

  /// No description provided for @adminNoContributionsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'y a rien à modérer pour ce filtre.'**
  String get adminNoContributionsMessage;

  /// No description provided for @approveContribution.
  ///
  /// In fr, this message translates to:
  /// **'Approuver la contribution'**
  String get approveContribution;

  /// No description provided for @rejectContribution.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter la contribution'**
  String get rejectContribution;

  /// No description provided for @reviewerNote.
  ///
  /// In fr, this message translates to:
  /// **'Note du modérateur'**
  String get reviewerNote;

  /// No description provided for @reviewerNoteHint.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire optionnel pour le contributeur'**
  String get reviewerNoteHint;

  /// No description provided for @approve.
  ///
  /// In fr, this message translates to:
  /// **'Approuver'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get reject;

  /// No description provided for @contributionApproved.
  ///
  /// In fr, this message translates to:
  /// **'Contribution approuvée'**
  String get contributionApproved;

  /// No description provided for @contributionRejected.
  ///
  /// In fr, this message translates to:
  /// **'Contribution rejetée'**
  String get contributionRejected;

  /// No description provided for @submittedAt.
  ///
  /// In fr, this message translates to:
  /// **'Soumise le {date}'**
  String submittedAt(String date);

  /// No description provided for @submittedAtUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Date de soumission inconnue'**
  String get submittedAtUnknown;

  /// No description provided for @adminAddSign.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get adminAddSign;

  /// No description provided for @adminEditSign.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le signe'**
  String get adminEditSign;

  /// No description provided for @adminNoSigns.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signe'**
  String get adminNoSigns;

  /// No description provided for @adminNoSignsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signe ne correspond à ces critères.'**
  String get adminNoSignsMessage;

  /// No description provided for @signWord.
  ///
  /// In fr, this message translates to:
  /// **'Mot / glosse'**
  String get signWord;

  /// No description provided for @signWordHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex. Bonjour'**
  String get signWordHint;

  /// No description provided for @signDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get signDescription;

  /// No description provided for @signVideoUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de la vidéo'**
  String get signVideoUrl;

  /// No description provided for @difficultyLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau de difficulté'**
  String get difficultyLevel;

  /// No description provided for @difficultyEasy.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get difficultyHard;

  /// No description provided for @views.
  ///
  /// In fr, this message translates to:
  /// **'Vues'**
  String get views;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @unvalidate.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la validation'**
  String get unvalidate;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deleteSign.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le signe'**
  String get deleteSign;

  /// No description provided for @deleteSignConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement « {word} » ?'**
  String deleteSignConfirm(String word);

  /// No description provided for @signUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Signe mis à jour'**
  String get signUpdated;

  /// No description provided for @signDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Signe supprimé'**
  String get signDeleted;

  /// No description provided for @searchUsers.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un utilisateur...'**
  String get searchUsers;

  /// No description provided for @adminNoUsers.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur'**
  String get adminNoUsers;

  /// No description provided for @adminNoUsersMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil ne correspond à votre recherche.'**
  String get adminNoUsersMessage;

  /// No description provided for @grantAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Accorder le rôle admin'**
  String get grantAdmin;

  /// No description provided for @revokeAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le rôle admin'**
  String get revokeAdmin;

  /// No description provided for @grantAdminConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Accorder les droits administrateur à {name} ?'**
  String grantAdminConfirm(String name);

  /// No description provided for @revokeAdminConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retirer les droits administrateur à {name} ?'**
  String revokeAdminConfirm(String name);

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @userUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur mis à jour'**
  String get userUpdated;

  /// No description provided for @you.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get you;

  /// No description provided for @adminRole.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get adminRole;

  /// No description provided for @roleTeacher.
  ///
  /// In fr, this message translates to:
  /// **'Enseignant'**
  String get roleTeacher;

  /// No description provided for @roleExpert.
  ///
  /// In fr, this message translates to:
  /// **'Expert en langue des signes'**
  String get roleExpert;

  /// No description provided for @roleOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get roleOwner;

  /// No description provided for @ownerProtectedHint.
  ///
  /// In fr, this message translates to:
  /// **'Compte du propriétaire du système : il ne peut être ni modifié, ni suspendu, ni supprimé.'**
  String get ownerProtectedHint;

  /// No description provided for @ownerOnlyAdminHint.
  ///
  /// In fr, this message translates to:
  /// **'Seul le propriétaire du système peut accorder ou retirer le rôle admin, et gérer les comptes administrateurs.'**
  String get ownerOnlyAdminHint;

  /// No description provided for @ownerOnlySettings.
  ///
  /// In fr, this message translates to:
  /// **'Seul le propriétaire du système peut modifier ces réglages.'**
  String get ownerOnlySettings;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get statusActive;

  /// No description provided for @statusSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Suspendu'**
  String get statusSuspended;

  /// No description provided for @addUser.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un utilisateur'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editUser;

  /// No description provided for @manageRoles.
  ///
  /// In fr, this message translates to:
  /// **'Rôles'**
  String get manageRoles;

  /// No description provided for @suspendAccount.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre'**
  String get suspendAccount;

  /// No description provided for @unsuspendAccount.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver'**
  String get unsuspendAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement le compte de {name} ? Cette action est irréversible.'**
  String deleteAccountConfirm(String name);

  /// No description provided for @suspendReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif de la suspension'**
  String get suspendReason;

  /// No description provided for @suspendConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre {name}'**
  String suspendConfirm(String name);

  /// No description provided for @userCreated.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur créé'**
  String get userCreated;

  /// No description provided for @userDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Compte supprimé'**
  String get userDeleted;

  /// No description provided for @userSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Compte suspendu'**
  String get userSuspended;

  /// No description provided for @userReactivated.
  ///
  /// In fr, this message translates to:
  /// **'Compte réactivé'**
  String get userReactivated;

  /// No description provided for @deafUser.
  ///
  /// In fr, this message translates to:
  /// **'Sourd / Malentendant'**
  String get deafUser;

  /// No description provided for @adminPlatformInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations plateforme'**
  String get adminPlatformInfo;

  /// No description provided for @adminBackend.
  ///
  /// In fr, this message translates to:
  /// **'Backend'**
  String get adminBackend;

  /// No description provided for @adminRlsNoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité Supabase (RLS)'**
  String get adminRlsNoteTitle;

  /// No description provided for @adminRlsNoteBody.
  ///
  /// In fr, this message translates to:
  /// **'Les actions admin nécessitent des politiques RLS adaptées (lecture/écriture sur profiles, signs et contributions pour les comptes is_admin). Sans ces politiques, certaines opérations échoueront côté client.'**
  String get adminRlsNoteBody;

  /// No description provided for @adminHowToGrant.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des comptes'**
  String get adminHowToGrant;

  /// No description provided for @adminHowToGrantBody.
  ///
  /// In fr, this message translates to:
  /// **'Depuis Utilisateurs, ouvrez le menu d\'un compte pour lui accorder les rôles administrateur, enseignant ou expert, le suspendre ou le supprimer. Un admin ne peut ni se retirer lui-même ni retirer le dernier admin.'**
  String get adminHowToGrantBody;

  /// No description provided for @contributeFormTitle.
  ///
  /// In fr, this message translates to:
  /// **'Proposer un signe'**
  String get contributeFormTitle;

  /// No description provided for @contributeFormSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre proposition sera examinée par un administrateur avant publication.'**
  String get contributeFormSubtitle;

  /// No description provided for @submitContribution.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la contribution'**
  String get submitContribution;

  /// No description provided for @contributionSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Contribution envoyée'**
  String get contributionSubmitted;

  /// No description provided for @mySubmissions.
  ///
  /// In fr, this message translates to:
  /// **'Mes soumissions'**
  String get mySubmissions;

  /// No description provided for @noContributionsYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de contribution'**
  String get noContributionsYet;

  /// No description provided for @noContributionsYetMessage.
  ///
  /// In fr, this message translates to:
  /// **'Proposez un premier signe pour enrichir le dictionnaire.'**
  String get noContributionsYetMessage;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom & Nom'**
  String get fullName;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @orDivider.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccountYet;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Brisons les barrières ensemble'**
  String get loginSubtitle;

  /// No description provided for @registerHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez la communauté MooMoo'**
  String get registerHeadline;

  /// No description provided for @registerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Commencez votre voyage vers une communication plus inclusive.'**
  String get registerSubtitle;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get invalidEmail;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// No description provided for @accountCreatedVerifyEmail.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé ! Veuillez vérifier votre e-mail.'**
  String get accountCreatedVerifyEmail;

  /// No description provided for @registerError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'inscription'**
  String get registerError;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'E-mail ou mot de passe incorrect'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre e-mail avant de vous connecter'**
  String get authEmailNotConfirmed;

  /// No description provided for @authNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Problème réseau. Vérifiez votre connexion.'**
  String get authNetworkError;

  /// No description provided for @showPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @passwordStrength.
  ///
  /// In fr, this message translates to:
  /// **'Force du mot de passe'**
  String get passwordStrength;

  /// No description provided for @authEmailAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse e-mail est déjà associée à un compte. Connectez-vous ou utilisez une autre adresse.'**
  String get authEmailAlreadyUsed;

  /// No description provided for @authWeakPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop faible. Respectez tous les critères indiqués sous le champ.'**
  String get authWeakPassword;

  /// No description provided for @authRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez quelques minutes avant de réessayer.'**
  String get authRateLimited;

  /// No description provided for @authSignupDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Les inscriptions sont désactivées sur ce serveur.'**
  String get authSignupDisabled;

  /// No description provided for @passwordRequirementsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir :'**
  String get passwordRequirementsTitle;

  /// No description provided for @passwordRuleLength.
  ///
  /// In fr, this message translates to:
  /// **'6 caractères'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleLowercase.
  ///
  /// In fr, this message translates to:
  /// **'une minuscule'**
  String get passwordRuleLowercase;

  /// No description provided for @passwordRuleUppercase.
  ///
  /// In fr, this message translates to:
  /// **'une majuscule'**
  String get passwordRuleUppercase;

  /// No description provided for @passwordRuleDigit.
  ///
  /// In fr, this message translates to:
  /// **'un chiffre'**
  String get passwordRuleDigit;

  /// No description provided for @passwordRuleSymbol.
  ///
  /// In fr, this message translates to:
  /// **'un symbole'**
  String get passwordRuleSymbol;

  /// No description provided for @passwordDoesNotMeetPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe ne respecte pas tous les critères'**
  String get passwordDoesNotMeetPolicy;

  /// No description provided for @authBrandHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Parlez avec vos mains'**
  String get authBrandHeadline;

  /// No description provided for @authBrandTagline.
  ///
  /// In fr, this message translates to:
  /// **'Traduisez, apprenez et partagez la langue des signes, où que vous soyez.'**
  String get authBrandTagline;

  /// No description provided for @authFeatureTranslate.
  ///
  /// In fr, this message translates to:
  /// **'Traduction en direct par la caméra'**
  String get authFeatureTranslate;

  /// No description provided for @authFeatureLearn.
  ///
  /// In fr, this message translates to:
  /// **'Dictionnaire et cours guidés'**
  String get authFeatureLearn;

  /// No description provided for @authFeatureCommunity.
  ///
  /// In fr, this message translates to:
  /// **'Une communauté qui enrichit le dictionnaire'**
  String get authFeatureCommunity;

  /// No description provided for @loginHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Content de vous revoir'**
  String get loginHeadline;

  /// No description provided for @forgotPasswordHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get forgotPasswordHeadline;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre adresse e-mail : nous vous enverrons un lien pour choisir un nouveau mot de passe.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get forgotPasswordSend;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In fr, this message translates to:
  /// **'Lien de réinitialisation envoyé à {email}'**
  String forgotPasswordSent(String email);

  /// No description provided for @backToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get backToLogin;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'vous@exemple.com'**
  String get emailHint;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @onboardingTitle1.
  ///
  /// In fr, this message translates to:
  /// **'MooMoo, parlez avec vos mains'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez une nouvelle façon de communiquer grâce à la langue des signes.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In fr, this message translates to:
  /// **'Traduisez en un geste'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In fr, this message translates to:
  /// **'Pointez la caméra sur vos mains pour obtenir une traduction assistée par le modèle actif.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In fr, this message translates to:
  /// **'Apprenez et contribuez'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In fr, this message translates to:
  /// **'Explorez le dictionnaire, suivez des cours et enrichissez la communauté.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingSemantics1.
  ///
  /// In fr, this message translates to:
  /// **'Illustration : langue des signes et communication'**
  String get onboardingSemantics1;

  /// No description provided for @onboardingSemantics2.
  ///
  /// In fr, this message translates to:
  /// **'Illustration : traduction caméra et reconnaissance'**
  String get onboardingSemantics2;

  /// No description provided for @onboardingSemantics3.
  ///
  /// In fr, this message translates to:
  /// **'Illustration : apprentissage et communauté'**
  String get onboardingSemantics3;

  /// No description provided for @onboardingPageIndicator.
  ///
  /// In fr, this message translates to:
  /// **'Page {current} sur {total}'**
  String onboardingPageIndicator(int current, int total);

  /// No description provided for @adminModels.
  ///
  /// In fr, this message translates to:
  /// **'Modèles IA'**
  String get adminModels;

  /// No description provided for @adminModelsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Performances, modèle actif et jobs de réentraînement (WASL / LSFB)'**
  String get adminModelsSubtitle;

  /// No description provided for @adminModelsList.
  ///
  /// In fr, this message translates to:
  /// **'Modèles disponibles'**
  String get adminModelsList;

  /// No description provided for @adminModelActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get adminModelActive;

  /// No description provided for @adminSetActiveModel.
  ///
  /// In fr, this message translates to:
  /// **'Activer ce modèle'**
  String get adminSetActiveModel;

  /// No description provided for @adminModelActivated.
  ///
  /// In fr, this message translates to:
  /// **'Modèle actif mis à jour'**
  String get adminModelActivated;

  /// No description provided for @adminRequestRetrain.
  ///
  /// In fr, this message translates to:
  /// **'Demander un réentraînement'**
  String get adminRequestRetrain;

  /// No description provided for @adminRetrainHint.
  ///
  /// In fr, this message translates to:
  /// **'Crée un job en file (queued). Aucun entraînement GPU dans l\'app — le worker backend traitera le job.'**
  String get adminRetrainHint;

  /// No description provided for @adminStartRetrain.
  ///
  /// In fr, this message translates to:
  /// **'Lancer le réentraînement'**
  String get adminStartRetrain;

  /// No description provided for @adminRetrainFromModel.
  ///
  /// In fr, this message translates to:
  /// **'Réentraîner à partir de ce modèle'**
  String get adminRetrainFromModel;

  /// No description provided for @adminRetrainQueued.
  ///
  /// In fr, this message translates to:
  /// **'Job de réentraînement ajouté à la file'**
  String get adminRetrainQueued;

  /// No description provided for @adminTrainingJobs.
  ///
  /// In fr, this message translates to:
  /// **'Historique des jobs'**
  String get adminTrainingJobs;

  /// No description provided for @adminNoJobs.
  ///
  /// In fr, this message translates to:
  /// **'Aucun job pour le moment'**
  String get adminNoJobs;

  /// No description provided for @adminNoModels.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle'**
  String get adminNoModels;

  /// No description provided for @adminNoModelsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Appliquez la migration AI puis rechargez. Les modèles seed WASL/LSFB apparaîtront ici.'**
  String get adminNoModelsMessage;

  /// No description provided for @adminNoMetrics.
  ///
  /// In fr, this message translates to:
  /// **'Pas de métriques'**
  String get adminNoMetrics;

  /// No description provided for @adminAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision'**
  String get adminAccuracy;

  /// No description provided for @adminLatency.
  ///
  /// In fr, this message translates to:
  /// **'Latence'**
  String get adminLatency;

  /// No description provided for @adminInferences.
  ///
  /// In fr, this message translates to:
  /// **'Inférences'**
  String get adminInferences;

  /// No description provided for @adminDataset.
  ///
  /// In fr, this message translates to:
  /// **'Dataset'**
  String get adminDataset;

  /// No description provided for @adminRlsOrNetworkError.
  ///
  /// In fr, this message translates to:
  /// **'Action refusée (RLS) ou backend indisponible'**
  String get adminRlsOrNetworkError;

  /// No description provided for @inferenceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Reconnaissance indisponible'**
  String get inferenceUnavailable;

  /// No description provided for @inferenceUnavailableMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le backend d\'inférence ne répond pas. Réessayez plus tard ou vérifiez le modèle actif.'**
  String get inferenceUnavailableMessage;

  /// No description provided for @inferenceFallbackLabel.
  ///
  /// In fr, this message translates to:
  /// **'Traduction locale (repli)'**
  String get inferenceFallbackLabel;

  /// No description provided for @translatingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Traduction en cours...'**
  String get translatingInProgress;

  /// No description provided for @readyToTranslate.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à traduire'**
  String get readyToTranslate;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @stopTranslation.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get stopTranslation;

  /// No description provided for @navigationMenu.
  ///
  /// In fr, this message translates to:
  /// **'Menu de navigation'**
  String get navigationMenu;

  /// No description provided for @expandMenu.
  ///
  /// In fr, this message translates to:
  /// **'Déployer le menu'**
  String get expandMenu;

  /// No description provided for @collapseMenu.
  ///
  /// In fr, this message translates to:
  /// **'Replier le menu'**
  String get collapseMenu;

  /// No description provided for @adminTableView.
  ///
  /// In fr, this message translates to:
  /// **'Vue tableau'**
  String get adminTableView;

  /// No description provided for @adminCardView.
  ///
  /// In fr, this message translates to:
  /// **'Vue cartes'**
  String get adminCardView;

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @homeHeroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Communiquez sans barrière, en langue des signes'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Traduisez les signes en texte avec la caméra, transformez un texte en signes et progressez chaque jour à votre rythme.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeTranslateNow.
  ///
  /// In fr, this message translates to:
  /// **'Traduire maintenant'**
  String get homeTranslateNow;

  /// No description provided for @homeContinueLearning.
  ///
  /// In fr, this message translates to:
  /// **'Continuer l\'apprentissage'**
  String get homeContinueLearning;

  /// No description provided for @homeWaysTitle.
  ///
  /// In fr, this message translates to:
  /// **'Deux façons de communiquer'**
  String get homeWaysTitle;

  /// No description provided for @homeSignToTextDesc.
  ///
  /// In fr, this message translates to:
  /// **'Signez devant la caméra, MooMoo affiche le texte correspondant.'**
  String get homeSignToTextDesc;

  /// No description provided for @homeTextToSignDesc.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez une phrase, MooMoo vous la montre en signes.'**
  String get homeTextToSignDesc;

  /// No description provided for @homeOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get homeOpen;

  /// No description provided for @homeLearningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre apprentissage'**
  String get homeLearningTitle;

  /// No description provided for @homeLearningSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques minutes par jour suffisent pour progresser.'**
  String get homeLearningSubtitle;

  /// No description provided for @homeForEveryoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pensé pour tout le monde'**
  String get homeForEveryoneTitle;

  /// No description provided for @homeDeafTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sourds et malentendants'**
  String get homeDeafTitle;

  /// No description provided for @homeDeafBody.
  ///
  /// In fr, this message translates to:
  /// **'Tout est visuel : vidéos, couleurs et icônes. Aucune information ne passe uniquement par le son.'**
  String get homeDeafBody;

  /// No description provided for @homeHearingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entendants'**
  String get homeHearingTitle;

  /// No description provided for @homeHearingBody.
  ///
  /// In fr, this message translates to:
  /// **'Apprenez les signes du quotidien avec des leçons courtes et des vidéos en boucle.'**
  String get homeHearingBody;

  /// No description provided for @homeCommunityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une communauté'**
  String get homeCommunityTitle;

  /// No description provided for @homeCommunityBody.
  ///
  /// In fr, this message translates to:
  /// **'Proposez vos signes : des experts les vérifient avant leur publication.'**
  String get homeCommunityBody;

  /// No description provided for @homeNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get homeNotifications;

  /// No description provided for @dictTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dictionnaire'**
  String get dictTitle;

  /// No description provided for @dictSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherchez un mot pour voir comment il se signe.'**
  String get dictSubtitle;

  /// No description provided for @dictClearSearch.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la recherche'**
  String get dictClearSearch;

  /// No description provided for @dictCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get dictCategories;

  /// No description provided for @dictGridView.
  ///
  /// In fr, this message translates to:
  /// **'Affichage en grille'**
  String get dictGridView;

  /// No description provided for @dictListView.
  ///
  /// In fr, this message translates to:
  /// **'Affichage en liste'**
  String get dictListView;

  /// No description provided for @dictLoadMore.
  ///
  /// In fr, this message translates to:
  /// **'Afficher plus de signes'**
  String get dictLoadMore;

  /// No description provided for @dictLoadingSigns.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des signes'**
  String get dictLoadingSigns;

  /// No description provided for @dictNoSignsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre mot ou une autre catégorie.'**
  String get dictNoSignsMessage;

  /// No description provided for @dictNoFavoritesMessage.
  ///
  /// In fr, this message translates to:
  /// **'Touchez le cœur d\'un signe pour le retrouver ici.'**
  String get dictNoFavoritesMessage;

  /// No description provided for @dictBrowseDictionary.
  ///
  /// In fr, this message translates to:
  /// **'Parcourir le dictionnaire'**
  String get dictBrowseDictionary;

  /// No description provided for @dictAddFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get dictAddFavorite;

  /// No description provided for @dictRemoveFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get dictRemoveFavorite;

  /// No description provided for @dictFavoriteAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté à vos favoris'**
  String get dictFavoriteAdded;

  /// No description provided for @dictFavoriteRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Retiré de vos favoris'**
  String get dictFavoriteRemoved;

  /// No description provided for @dictSignNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Signe introuvable'**
  String get dictSignNotFound;

  /// No description provided for @dictSignNotFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce signe n\'existe pas ou a été retiré du dictionnaire.'**
  String get dictSignNotFoundMessage;

  /// No description provided for @dictHowToSign.
  ///
  /// In fr, this message translates to:
  /// **'Comment le signer'**
  String get dictHowToSign;

  /// No description provided for @dictNoDescription.
  ///
  /// In fr, this message translates to:
  /// **'Aucune description disponible.'**
  String get dictNoDescription;

  /// No description provided for @dictExampleSentence.
  ///
  /// In fr, this message translates to:
  /// **'Exemple de phrase'**
  String get dictExampleSentence;

  /// No description provided for @dictTags.
  ///
  /// In fr, this message translates to:
  /// **'Mots-clés'**
  String get dictTags;

  /// No description provided for @dictShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get dictShare;

  /// No description provided for @dictShareText.
  ///
  /// In fr, this message translates to:
  /// **'« {word} » en langue des signes'**
  String dictShareText(String word);

  /// No description provided for @dictPractice.
  ///
  /// In fr, this message translates to:
  /// **'S\'entraîner'**
  String get dictPractice;

  /// No description provided for @dictDifficulty.
  ///
  /// In fr, this message translates to:
  /// **'Difficulté : {level}'**
  String dictDifficulty(String level);

  /// No description provided for @dictLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue des signes : {language}'**
  String dictLanguage(String language);

  /// No description provided for @dictCategoryNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie introuvable'**
  String get dictCategoryNotFound;

  /// No description provided for @dictCategorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tous les signes de cette catégorie.'**
  String get dictCategorySubtitle;

  /// No description provided for @dictVideoUrlHint.
  ///
  /// In fr, this message translates to:
  /// **'https://… (lien vers votre vidéo)'**
  String get dictVideoUrlHint;

  /// No description provided for @dictInvalidUrl.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un lien commençant par http:// ou https://'**
  String get dictInvalidUrl;

  /// No description provided for @dictSubmittedOn.
  ///
  /// In fr, this message translates to:
  /// **'Envoyée le {date}'**
  String dictSubmittedOn(String date);

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement en cours'**
  String get loading;

  /// No description provided for @learnCourseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Parcours {language}'**
  String learnCourseTitle(String language);

  /// No description provided for @learnChangeCourse.
  ///
  /// In fr, this message translates to:
  /// **'Changer de langue'**
  String get learnChangeCourse;

  /// No description provided for @accountClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get accountClose;

  /// No description provided for @accountSeeMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get accountSeeMore;

  /// No description provided for @accountLoadErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion puis réessayez.'**
  String get accountLoadErrorMessage;

  /// No description provided for @accountSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer. Vérifiez votre connexion puis réessayez.'**
  String get accountSaveError;

  /// No description provided for @accountLearningSection.
  ///
  /// In fr, this message translates to:
  /// **'Apprentissage'**
  String get accountLearningSection;

  /// No description provided for @accountAccessibility.
  ///
  /// In fr, this message translates to:
  /// **'Accessibilité'**
  String get accountAccessibility;

  /// No description provided for @accountDeafSwitch.
  ///
  /// In fr, this message translates to:
  /// **'Je suis sourd ou malentendant'**
  String get accountDeafSwitch;

  /// No description provided for @accountDeafSwitchHint.
  ///
  /// In fr, this message translates to:
  /// **'Indique que vous communiquez surtout en langue des signes. L\'application reste entièrement visuelle, quel que soit votre choix.'**
  String get accountDeafSwitchHint;

  /// No description provided for @accountHearingUser.
  ///
  /// In fr, this message translates to:
  /// **'Entendant'**
  String get accountHearingUser;

  /// No description provided for @accountAvatarLabel.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil de {name}, modifier le profil'**
  String accountAvatarLabel(String name);

  /// No description provided for @accountPhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get accountPhotoTitle;

  /// No description provided for @accountPhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une image carrée, idéalement un portrait bien éclairé.'**
  String get accountPhotoHint;

  /// No description provided for @accountChangePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get accountChangePhoto;

  /// No description provided for @accountSignOutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get accountSignOutTitle;

  /// No description provided for @accountSignOutMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre progression reste enregistrée. Vous pourrez vous reconnecter à tout moment.'**
  String get accountSignOutMessage;

  /// No description provided for @accountDangerZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone sensible'**
  String get accountDangerZone;

  /// No description provided for @accountDeleteRequest.
  ///
  /// In fr, this message translates to:
  /// **'Demander la suppression du compte'**
  String get accountDeleteRequest;

  /// No description provided for @accountDeleteRequestHint.
  ///
  /// In fr, this message translates to:
  /// **'Un e-mail prérempli s\'ouvre pour transmettre votre demande à l\'équipe MooMoo.'**
  String get accountDeleteRequestHint;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer votre compte ?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'équipe MooMoo supprimera votre compte, votre progression et vos contributions. Cette action est irréversible.'**
  String get accountDeleteMessage;

  /// No description provided for @accountDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la demande'**
  String get accountDeleteConfirm;

  /// No description provided for @accountDeleteMailSubject.
  ///
  /// In fr, this message translates to:
  /// **'Suppression de mon compte MooMoo'**
  String get accountDeleteMailSubject;

  /// No description provided for @accountDeleteMailBody.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, je souhaite supprimer mon compte MooMoo associé à l\'adresse {email}.'**
  String accountDeleteMailBody(String email);

  /// No description provided for @accountMailUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune application e-mail trouvée. Écrivez-nous à {email}.'**
  String accountMailUnavailable(String email);

  /// No description provided for @accountCharacterUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Personnage indisponible'**
  String get accountCharacterUnavailable;

  /// No description provided for @accountToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get accountToday;

  /// No description provided for @accountHistoryEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune traduction pour l\'instant'**
  String get accountHistoryEmptyTitle;

  /// No description provided for @accountHistoryEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vos sessions de traduction apparaîtront ici.'**
  String get accountHistoryEmptyMessage;

  /// No description provided for @accountHistoryOpenTranslator.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le traducteur'**
  String get accountHistoryOpenTranslator;

  /// No description provided for @accountSignToText.
  ///
  /// In fr, this message translates to:
  /// **'Signes vers texte'**
  String get accountSignToText;

  /// No description provided for @accountTextToSign.
  ///
  /// In fr, this message translates to:
  /// **'Texte vers signes'**
  String get accountTextToSign;

  /// No description provided for @accountUntitledSession.
  ///
  /// In fr, this message translates to:
  /// **'Session sans texte'**
  String get accountUntitledSession;

  /// No description provided for @accountSessionEntries.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune phrase} =1{1 phrase} other{{count} phrases}}'**
  String accountSessionEntries(int count);

  /// No description provided for @accountSessionEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Cette session ne contient aucune phrase.'**
  String get accountSessionEmpty;

  /// No description provided for @accountMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get accountMarkAllRead;

  /// No description provided for @accountUnread.
  ///
  /// In fr, this message translates to:
  /// **'Non lue'**
  String get accountUnread;

  /// No description provided for @accountNotificationsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les nouvelles leçons et le suivi de vos contributions apparaîtront ici.'**
  String get accountNotificationsEmptyMessage;

  /// No description provided for @accountVersionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String accountVersionLabel(String version);

  /// No description provided for @accountAboutTagline.
  ///
  /// In fr, this message translates to:
  /// **'MooMoo est une plateforme de traduction et d\'apprentissage de la langue des signes, conçue pour lever les barrières de communication entre personnes sourdes et entendantes.'**
  String get accountAboutTagline;

  /// No description provided for @accountAuthor.
  ///
  /// In fr, this message translates to:
  /// **'Auteur'**
  String get accountAuthor;

  /// No description provided for @accountContact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get accountContact;

  /// No description provided for @accountCopyright.
  ///
  /// In fr, this message translates to:
  /// **'© {year} MooMoo. Tous droits réservés.'**
  String accountCopyright(String year);

  /// No description provided for @accountHelpIntro.
  ///
  /// In fr, this message translates to:
  /// **'Les réponses aux questions les plus fréquentes.'**
  String get accountHelpIntro;

  /// No description provided for @accountHelpTranslatorQ.
  ///
  /// In fr, this message translates to:
  /// **'Comment utiliser le traducteur ?'**
  String get accountHelpTranslatorQ;

  /// No description provided for @accountHelpTranslatorA.
  ///
  /// In fr, this message translates to:
  /// **'Placez votre caméra devant vous et commencez à signer : l\'application détecte les signes et affiche le texte correspondant. Dans l\'autre sens, écrivez une phrase pour la voir en signes.'**
  String get accountHelpTranslatorA;

  /// No description provided for @accountHelpLearningQ.
  ///
  /// In fr, this message translates to:
  /// **'Comment fonctionne l\'apprentissage ?'**
  String get accountHelpLearningQ;

  /// No description provided for @accountHelpLearningA.
  ///
  /// In fr, this message translates to:
  /// **'Le parcours est découpé en unités et en leçons courtes. Chaque leçon terminée rapporte de l\'XP et entretient votre série de jours consécutifs.'**
  String get accountHelpLearningA;

  /// No description provided for @accountHelpSignLanguageQ.
  ///
  /// In fr, this message translates to:
  /// **'Comment changer de langue des signes ?'**
  String get accountHelpSignLanguageQ;

  /// No description provided for @accountHelpSignLanguageA.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez Paramètres, puis Préférences d\'affichage et Langue des signes. Votre parcours d\'apprentissage suit ce choix.'**
  String get accountHelpSignLanguageA;

  /// No description provided for @accountHelpFavoritesQ.
  ///
  /// In fr, this message translates to:
  /// **'Comment ajouter des favoris ?'**
  String get accountHelpFavoritesQ;

  /// No description provided for @accountHelpFavoritesA.
  ///
  /// In fr, this message translates to:
  /// **'Dans le dictionnaire, touchez l\'icône cœur d\'un signe pour l\'ajouter à vos favoris. Retrouvez-les ensuite depuis votre profil.'**
  String get accountHelpFavoritesA;

  /// No description provided for @accountHelpProfileQ.
  ///
  /// In fr, this message translates to:
  /// **'Comment modifier mon profil ?'**
  String get accountHelpProfileQ;

  /// No description provided for @accountHelpProfileA.
  ///
  /// In fr, this message translates to:
  /// **'Dans l\'onglet Profil, choisissez « Modifier le profil » pour changer votre photo, votre nom, votre bio ou indiquer si vous êtes sourd ou malentendant.'**
  String get accountHelpProfileA;

  /// No description provided for @accountHelpAccessibilityQ.
  ///
  /// In fr, this message translates to:
  /// **'L\'application est-elle utilisable sans le son ?'**
  String get accountHelpAccessibilityQ;

  /// No description provided for @accountHelpAccessibilityA.
  ///
  /// In fr, this message translates to:
  /// **'Oui. Toutes les informations sont visuelles : vidéos, texte, icônes et couleurs. Aucune information ne passe uniquement par le son.'**
  String get accountHelpAccessibilityA;

  /// No description provided for @accountHelpContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d\'aide ?'**
  String get accountHelpContactTitle;

  /// No description provided for @accountHelpContactBody.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez à l\'équipe MooMoo, nous vous répondrons par e-mail.'**
  String get accountHelpContactBody;

  /// No description provided for @accountHelpContactAction.
  ///
  /// In fr, this message translates to:
  /// **'Nous écrire'**
  String get accountHelpContactAction;

  /// No description provided for @accountLegalUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : {date}'**
  String accountLegalUpdated(String date);

  /// No description provided for @accountPrivacyDataTitle.
  ///
  /// In fr, this message translates to:
  /// **'1. Collecte des données'**
  String get accountPrivacyDataTitle;

  /// No description provided for @accountPrivacyDataBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous collectons les informations que vous nous fournissez directement, notamment lors de la création de votre compte (nom, e-mail), ainsi que les données liées à votre usage : progression d\'apprentissage, favoris et contributions.'**
  String get accountPrivacyDataBody;

  /// No description provided for @accountPrivacyCameraTitle.
  ///
  /// In fr, this message translates to:
  /// **'2. Utilisation de la caméra'**
  String get accountPrivacyCameraTitle;

  /// No description provided for @accountPrivacyCameraBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès à la caméra sert uniquement à la traduction des signes en temps réel. Aucune image n\'est enregistrée sur nos serveurs sans votre consentement explicite.'**
  String get accountPrivacyCameraBody;

  /// No description provided for @accountPrivacySecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'3. Sécurité'**
  String get accountPrivacySecurityTitle;

  /// No description provided for @accountPrivacySecurityBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous mettons en œuvre des mesures de sécurité robustes pour protéger vos informations personnelles.'**
  String get accountPrivacySecurityBody;

  /// No description provided for @accountPrivacyRightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'4. Vos droits'**
  String get accountPrivacyRightsTitle;

  /// No description provided for @accountPrivacyRightsBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez modifier vos informations à tout moment depuis votre profil et demander la suppression de votre compte depuis les paramètres.'**
  String get accountPrivacyRightsBody;

  /// No description provided for @accountTermsAcceptTitle.
  ///
  /// In fr, this message translates to:
  /// **'1. Acceptation des conditions'**
  String get accountTermsAcceptTitle;

  /// No description provided for @accountTermsAcceptBody.
  ///
  /// In fr, this message translates to:
  /// **'En utilisant l\'application MooMoo, vous acceptez d\'être lié par les présentes conditions d\'utilisation.'**
  String get accountTermsAcceptBody;

  /// No description provided for @accountTermsUseTitle.
  ///
  /// In fr, this message translates to:
  /// **'2. Utilisation du service'**
  String get accountTermsUseTitle;

  /// No description provided for @accountTermsUseBody.
  ///
  /// In fr, this message translates to:
  /// **'Vous vous engagez à utiliser l\'application de manière licite et respectueuse des autres utilisateurs.'**
  String get accountTermsUseBody;

  /// No description provided for @accountTermsIpTitle.
  ///
  /// In fr, this message translates to:
  /// **'3. Propriété intellectuelle'**
  String get accountTermsIpTitle;

  /// No description provided for @accountTermsIpBody.
  ///
  /// In fr, this message translates to:
  /// **'Le contenu de l\'application, y compris les modèles de traduction, est la propriété exclusive de MooMoo.'**
  String get accountTermsIpBody;

  /// No description provided for @learnStreakDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Pas de série} =1{1 jour de série} other{{count} jours de série}}'**
  String learnStreakDays(int count);

  /// No description provided for @learnXpAmount.
  ///
  /// In fr, this message translates to:
  /// **'{xp} XP'**
  String learnXpAmount(int xp);

  /// No description provided for @learnDailyGoal.
  ///
  /// In fr, this message translates to:
  /// **'Objectif du jour'**
  String get learnDailyGoal;

  /// No description provided for @learnDailyGoalProgress.
  ///
  /// In fr, this message translates to:
  /// **'{current} / {goal} XP'**
  String learnDailyGoalProgress(int current, int goal);

  /// No description provided for @learnDailyGoalReached.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint, bravo !'**
  String get learnDailyGoalReached;

  /// No description provided for @learnUnitLabel.
  ///
  /// In fr, this message translates to:
  /// **'Unité {number}'**
  String learnUnitLabel(int number);

  /// No description provided for @learnStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get learnStart;

  /// No description provided for @learnReview.
  ///
  /// In fr, this message translates to:
  /// **'Réviser'**
  String get learnReview;

  /// No description provided for @learnLessonLocked.
  ///
  /// In fr, this message translates to:
  /// **'Terminez la leçon précédente pour débloquer celle-ci.'**
  String get learnLessonLocked;

  /// No description provided for @learnLessonEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get learnLessonEmpty;

  /// No description provided for @learnLessonSigns.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun signe} =1{1 signe} other{{count} signes}}'**
  String learnLessonSigns(int count);

  /// No description provided for @learnStateCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get learnStateCompleted;

  /// No description provided for @learnStatePerfect.
  ///
  /// In fr, this message translates to:
  /// **'Sans faute'**
  String get learnStatePerfect;

  /// No description provided for @learnStateCurrent.
  ///
  /// In fr, this message translates to:
  /// **'À faire'**
  String get learnStateCurrent;

  /// No description provided for @learnStateLocked.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillée'**
  String get learnStateLocked;

  /// No description provided for @learnNoCourseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le parcours arrive bientôt'**
  String get learnNoCourseTitle;

  /// No description provided for @learnNoCourseMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune leçon n\'est encore publiée pour cette langue. En attendant, explorez le dictionnaire.'**
  String get learnNoCourseMessage;

  /// No description provided for @learnNoCourseEditorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune unité publiée pour cette langue. Créez la première depuis la gestion du parcours.'**
  String get learnNoCourseEditorMessage;

  /// No description provided for @learnManagePath.
  ///
  /// In fr, this message translates to:
  /// **'Gérer le parcours'**
  String get learnManagePath;

  /// No description provided for @learnOpenDictionary.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le dictionnaire'**
  String get learnOpenDictionary;

  /// No description provided for @learnViewProgress.
  ///
  /// In fr, this message translates to:
  /// **'Ma progression'**
  String get learnViewProgress;

  /// No description provided for @lessonQuit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la leçon'**
  String get lessonQuit;

  /// No description provided for @lessonQuitConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la leçon ?'**
  String get lessonQuitConfirmTitle;

  /// No description provided for @lessonQuitConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vos réponses dans cette leçon ne seront pas enregistrées.'**
  String get lessonQuitConfirmMessage;

  /// No description provided for @lessonQuitConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get lessonQuitConfirm;

  /// No description provided for @lessonKeepGoing.
  ///
  /// In fr, this message translates to:
  /// **'Continuer la leçon'**
  String get lessonKeepGoing;

  /// No description provided for @lessonNewSign.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau signe'**
  String get lessonNewSign;

  /// No description provided for @lessonWhatSign.
  ///
  /// In fr, this message translates to:
  /// **'Que signifie ce signe ?'**
  String get lessonWhatSign;

  /// No description provided for @lessonFindSign.
  ///
  /// In fr, this message translates to:
  /// **'Quel signe veut dire « {word} » ?'**
  String lessonFindSign(String word);

  /// No description provided for @lessonCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get lessonCheck;

  /// No description provided for @lessonContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get lessonContinue;

  /// No description provided for @lessonCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse !'**
  String get lessonCorrect;

  /// No description provided for @lessonIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait'**
  String get lessonIncorrect;

  /// No description provided for @lessonCorrectAnswer.
  ///
  /// In fr, this message translates to:
  /// **'La bonne réponse était : {word}'**
  String lessonCorrectAnswer(String word);

  /// No description provided for @lessonProgressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Question {current} sur {total}'**
  String lessonProgressLabel(int current, int total);

  /// No description provided for @lessonNoMedia.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de vidéo pour ce signe'**
  String get lessonNoMedia;

  /// No description provided for @lessonReplay.
  ///
  /// In fr, this message translates to:
  /// **'Revoir le signe'**
  String get lessonReplay;

  /// No description provided for @lessonOptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réponse {index}'**
  String lessonOptionLabel(int index);

  /// No description provided for @lessonCompleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Leçon terminée !'**
  String get lessonCompleteTitle;

  /// No description provided for @lessonCompletePerfect.
  ///
  /// In fr, this message translates to:
  /// **'Sans faute, impressionnant !'**
  String get lessonCompletePerfect;

  /// No description provided for @lessonXpEarned.
  ///
  /// In fr, this message translates to:
  /// **'+{xp} XP'**
  String lessonXpEarned(int xp);

  /// No description provided for @lessonAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision'**
  String get lessonAccuracy;

  /// No description provided for @lessonStreak.
  ///
  /// In fr, this message translates to:
  /// **'Série'**
  String get lessonStreak;

  /// No description provided for @lessonXp.
  ///
  /// In fr, this message translates to:
  /// **'XP gagnés'**
  String get lessonXp;

  /// No description provided for @lessonFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get lessonFinish;

  /// No description provided for @lessonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get lessonRetry;

  /// No description provided for @lessonSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer le résultat. Vérifiez votre connexion puis réessayez.'**
  String get lessonSaveError;

  /// No description provided for @lessonNotEnoughSigns.
  ///
  /// In fr, this message translates to:
  /// **'Cette leçon n\'a pas encore de signe à pratiquer.'**
  String get lessonNotEnoughSigns;

  /// No description provided for @lessonDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour} other{{count} jours}}'**
  String lessonDays(int count);

  /// No description provided for @progressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma progression'**
  String get progressTitle;

  /// No description provided for @progressTotalXp.
  ///
  /// In fr, this message translates to:
  /// **'XP total'**
  String get progressTotalXp;

  /// No description provided for @progressCurrentStreak.
  ///
  /// In fr, this message translates to:
  /// **'Série actuelle'**
  String get progressCurrentStreak;

  /// No description provided for @progressLongestStreak.
  ///
  /// In fr, this message translates to:
  /// **'Meilleure série'**
  String get progressLongestStreak;

  /// No description provided for @progressLessonsDone.
  ///
  /// In fr, this message translates to:
  /// **'Leçons terminées'**
  String get progressLessonsDone;

  /// No description provided for @progressDailyGoalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectif quotidien'**
  String get progressDailyGoalTitle;

  /// No description provided for @progressDailyGoalHint.
  ///
  /// In fr, this message translates to:
  /// **'Combien d\'XP visez-vous chaque jour ?'**
  String get progressDailyGoalHint;

  /// No description provided for @progressGoalCasual.
  ///
  /// In fr, this message translates to:
  /// **'Détente'**
  String get progressGoalCasual;

  /// No description provided for @progressGoalRegular.
  ///
  /// In fr, this message translates to:
  /// **'Régulier'**
  String get progressGoalRegular;

  /// No description provided for @progressGoalSerious.
  ///
  /// In fr, this message translates to:
  /// **'Sérieux'**
  String get progressGoalSerious;

  /// No description provided for @progressGoalIntense.
  ///
  /// In fr, this message translates to:
  /// **'Intense'**
  String get progressGoalIntense;

  /// No description provided for @progressGoalOption.
  ///
  /// In fr, this message translates to:
  /// **'{xp} XP par jour'**
  String progressGoalOption(int xp);

  /// No description provided for @progressGoalSaved.
  ///
  /// In fr, this message translates to:
  /// **'Objectif mis à jour'**
  String get progressGoalSaved;

  /// No description provided for @adminLearning.
  ///
  /// In fr, this message translates to:
  /// **'Parcours'**
  String get adminLearning;

  /// No description provided for @adminLearningSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Unités, leçons et signes enseignés dans l\'onglet Apprendre'**
  String get adminLearningSubtitle;

  /// No description provided for @adminAddUnit.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une unité'**
  String get adminAddUnit;

  /// No description provided for @adminEditUnit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'unité'**
  String get adminEditUnit;

  /// No description provided for @adminAddLesson.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une leçon'**
  String get adminAddLesson;

  /// No description provided for @adminEditLesson.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la leçon'**
  String get adminEditLesson;

  /// No description provided for @adminFieldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get adminFieldTitle;

  /// No description provided for @adminFieldDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description (facultatif)'**
  String get adminFieldDescription;

  /// No description provided for @adminFieldIcon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get adminFieldIcon;

  /// No description provided for @adminXpReward.
  ///
  /// In fr, this message translates to:
  /// **'Récompense (XP)'**
  String get adminXpReward;

  /// No description provided for @adminPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publiée'**
  String get adminPublished;

  /// No description provided for @adminDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get adminDraft;

  /// No description provided for @adminPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get adminPublish;

  /// No description provided for @adminUnpublish.
  ///
  /// In fr, this message translates to:
  /// **'Repasser en brouillon'**
  String get adminUnpublish;

  /// No description provided for @adminDeleteUnitConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'unité « {title} » et toutes ses leçons ?'**
  String adminDeleteUnitConfirm(String title);

  /// No description provided for @adminDeleteLessonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la leçon « {title} » ?'**
  String adminDeleteLessonConfirm(String title);

  /// No description provided for @adminLessonPickSigns.
  ///
  /// In fr, this message translates to:
  /// **'Choisir les signes'**
  String get adminLessonPickSigns;

  /// No description provided for @adminSearchValidatedSigns.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un signe validé'**
  String get adminSearchValidatedSigns;

  /// No description provided for @adminSelectedSigns.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun signe choisi} =1{1 signe choisi} other{{count} signes choisis}}'**
  String adminSelectedSigns(int count);

  /// No description provided for @adminLessonNeedsSigns.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins 2 signes pour générer des exercices.'**
  String get adminLessonNeedsSigns;

  /// No description provided for @adminNoUnits.
  ///
  /// In fr, this message translates to:
  /// **'Aucune unité'**
  String get adminNoUnits;

  /// No description provided for @adminNoUnitsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Créez une première unité, ajoutez-y des leçons puis choisissez les signes enseignés.'**
  String get adminNoUnitsMessage;

  /// No description provided for @adminNoSignsForLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signe validé pour cette langue. Ajoutez-en depuis la gestion des signes.'**
  String get adminNoSignsForLanguage;

  /// No description provided for @adminSaved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get adminSaved;

  /// No description provided for @adminMoveUp.
  ///
  /// In fr, this message translates to:
  /// **'Monter'**
  String get adminMoveUp;

  /// No description provided for @adminMoveDown.
  ///
  /// In fr, this message translates to:
  /// **'Descendre'**
  String get adminMoveDown;

  /// No description provided for @adminLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get adminLanguage;

  /// No description provided for @translCameraUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Caméra indisponible : importez une vidéo ou une image pour la traduire.'**
  String get translCameraUnavailable;

  /// No description provided for @translDone.
  ///
  /// In fr, this message translates to:
  /// **'Traduction terminée'**
  String get translDone;

  /// No description provided for @admxSignsValidation.
  ///
  /// In fr, this message translates to:
  /// **'Validation du dictionnaire'**
  String get admxSignsValidation;

  /// No description provided for @admxSignsValidatedOf.
  ///
  /// In fr, this message translates to:
  /// **'{validated} signes validés sur {total}'**
  String admxSignsValidatedOf(int validated, int total);

  /// No description provided for @admxContributionsTotal.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune contribution} =1{1 contribution au total} other{{count} contributions au total}}'**
  String admxContributionsTotal(int count);

  /// No description provided for @admxNoModelsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle n\'est enregistré dans Supabase pour le moment. Lancez un réentraînement : le modèle produit apparaîtra ici.'**
  String get admxNoModelsMessage;

  /// No description provided for @admxNoJobsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les demandes de réentraînement apparaîtront ici avec leur progression.'**
  String get admxNoJobsMessage;

  /// No description provided for @admxJobQueued.
  ///
  /// In fr, this message translates to:
  /// **'En file'**
  String get admxJobQueued;

  /// No description provided for @admxJobRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get admxJobRunning;

  /// No description provided for @admxJobDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get admxJobDone;

  /// No description provided for @admxJobFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échoué'**
  String get admxJobFailed;

  /// No description provided for @admxActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get admxActions;

  /// No description provided for @admxViewMedia.
  ///
  /// In fr, this message translates to:
  /// **'Voir la vidéo'**
  String get admxViewMedia;

  /// No description provided for @admxCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get admxCategory;

  /// No description provided for @admxNoCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get admxNoCategory;

  /// No description provided for @admxWordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot est obligatoire'**
  String get admxWordRequired;

  /// No description provided for @admxClearSearch.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la recherche'**
  String get admxClearSearch;

  /// No description provided for @admxDifficultyValue.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level}'**
  String admxDifficultyValue(int level);

  /// No description provided for @admxViewsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune vue} =1{1 vue} other{{count} vues}}'**
  String admxViewsCount(int count);

  /// No description provided for @admxApiUrl.
  ///
  /// In fr, this message translates to:
  /// **'API backend'**
  String get admxApiUrl;

  /// No description provided for @admxActiveModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle actif'**
  String get admxActiveModel;

  /// No description provided for @admxNoActiveModel.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle actif'**
  String get admxNoActiveModel;

  /// No description provided for @admxCreatedOn.
  ///
  /// In fr, this message translates to:
  /// **'Créé le {date}'**
  String admxCreatedOn(String date);

  /// No description provided for @admxRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get admxRefresh;

  /// No description provided for @translDirectionSignToText.
  ///
  /// In fr, this message translates to:
  /// **'Signes vers texte'**
  String get translDirectionSignToText;

  /// No description provided for @translDirectionTextToSign.
  ///
  /// In fr, this message translates to:
  /// **'Texte vers signes'**
  String get translDirectionTextToSign;

  /// No description provided for @translSwapDirection.
  ///
  /// In fr, this message translates to:
  /// **'Inverser le sens de traduction'**
  String get translSwapDirection;

  /// No description provided for @translStart.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la traduction'**
  String get translStart;

  /// No description provided for @translRestart.
  ///
  /// In fr, this message translates to:
  /// **'Relancer'**
  String get translRestart;

  /// No description provided for @translImportVideo.
  ///
  /// In fr, this message translates to:
  /// **'Importer une vidéo'**
  String get translImportVideo;

  /// No description provided for @translImportImage.
  ///
  /// In fr, this message translates to:
  /// **'Importer une image'**
  String get translImportImage;

  /// No description provided for @translRemoveFile.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le fichier et revenir à la caméra'**
  String get translRemoveFile;

  /// No description provided for @translFileSelected.
  ///
  /// In fr, this message translates to:
  /// **'Fichier sélectionné : {name}'**
  String translFileSelected(String name);

  /// No description provided for @translResultLabel.
  ///
  /// In fr, this message translates to:
  /// **'Texte traduit'**
  String get translResultLabel;

  /// No description provided for @translResultPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Le texte traduit s\'affichera ici.'**
  String get translResultPlaceholder;

  /// No description provided for @translSpellingHint.
  ///
  /// In fr, this message translates to:
  /// **'Montrez chaque lettre clairement devant la caméra. La traduction lit le flux vidéo en continu (« space » = espace, « del » = effacer).'**
  String get translSpellingHint;

  /// No description provided for @translLastLetter.
  ///
  /// In fr, this message translates to:
  /// **'Lettre : {letter}'**
  String translLastLetter(String letter);

  /// No description provided for @translConfidence.
  ///
  /// In fr, this message translates to:
  /// **'Confiance : {percent} %'**
  String translConfidence(int percent);

  /// No description provided for @translModelUsed.
  ///
  /// In fr, this message translates to:
  /// **'Modèle : {model}'**
  String translModelUsed(String model);

  /// No description provided for @translSpeak.
  ///
  /// In fr, this message translates to:
  /// **'Lire à voix haute'**
  String get translSpeak;

  /// No description provided for @translListening.
  ///
  /// In fr, this message translates to:
  /// **'Écoute en cours…'**
  String get translListening;

  /// No description provided for @translStartDictation.
  ///
  /// In fr, this message translates to:
  /// **'Dicter au micro'**
  String get translStartDictation;

  /// No description provided for @translStopDictation.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la dictée'**
  String get translStopDictation;

  /// No description provided for @translInputLabel.
  ///
  /// In fr, this message translates to:
  /// **'Texte à traduire en signes'**
  String get translInputLabel;

  /// No description provided for @translInputHint.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur Entrée pour traduire'**
  String get translInputHint;

  /// No description provided for @translSearching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche du signe…'**
  String get translSearching;

  /// No description provided for @translComposing.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement des vidéos et extraction des landmarks…'**
  String get translComposing;

  /// No description provided for @translComposeFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de composer la séquence de signes.'**
  String get translComposeFailed;

  /// No description provided for @translComposePartial.
  ///
  /// In fr, this message translates to:
  /// **'Certains mots n\'ont pas pu être inclus : {words}'**
  String translComposePartial(String words);

  /// No description provided for @translEmptyPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez un mot ou une phrase pour voir le signe correspondant.'**
  String get translEmptyPrompt;

  /// No description provided for @translNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun signe trouvé pour « {query} »'**
  String translNoMatch(String query);

  /// No description provided for @translNoMatchHint.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un autre mot ou vérifiez l\'orthographe.'**
  String get translNoMatchHint;

  /// No description provided for @translMatches.
  ///
  /// In fr, this message translates to:
  /// **'Signes correspondants'**
  String get translMatches;

  /// No description provided for @translShownSign.
  ///
  /// In fr, this message translates to:
  /// **'Signe affiché : {word}'**
  String translShownSign(String word);

  /// No description provided for @translCharacterNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Personnage introuvable'**
  String get translCharacterNotFound;

  /// No description provided for @translLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l\'affichage'**
  String get translLoadError;

  /// No description provided for @translAvatarNote.
  ///
  /// In fr, this message translates to:
  /// **'L\'avatar 3D ne reproduit pas encore les signes : choisissez Vidéo ou Landmarks pour voir le geste.'**
  String get translAvatarNote;

  /// No description provided for @translCameraIdleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Caméra en veille'**
  String get translCameraIdleTitle;

  /// No description provided for @translCameraIdleMessage.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur « Traduire » pour activer la caméra, ou importez une vidéo.'**
  String get translCameraIdleMessage;

  /// No description provided for @translSwitchCamera.
  ///
  /// In fr, this message translates to:
  /// **'Changer de caméra'**
  String get translSwitchCamera;

  /// No description provided for @translImportTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Importer une vidéo ou une image'**
  String get translImportTooltip;

  /// No description provided for @translBackToCamera.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à la caméra'**
  String get translBackToCamera;

  /// No description provided for @translCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier le texte'**
  String get translCopy;

  /// No description provided for @translCopied.
  ///
  /// In fr, this message translates to:
  /// **'Texte copié'**
  String get translCopied;

  /// No description provided for @translClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le texte'**
  String get translClear;

  /// No description provided for @translStatusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get translStatusReady;

  /// No description provided for @translPickWord.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un mot'**
  String get translPickWord;

  /// No description provided for @translViewModeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Affichage du signe'**
  String get translViewModeLabel;

  /// No description provided for @translModelAlt.
  ///
  /// In fr, this message translates to:
  /// **'Avatar 3D de traduction en langue des signes'**
  String get translModelAlt;

  /// No description provided for @landmarksLabel.
  ///
  /// In fr, this message translates to:
  /// **'Repères animés du signe : main droite en bleu, main gauche en orange'**
  String get landmarksLabel;

  /// No description provided for @landmarksPlay.
  ///
  /// In fr, this message translates to:
  /// **'Lire l\'animation'**
  String get landmarksPlay;

  /// No description provided for @landmarksPause.
  ///
  /// In fr, this message translates to:
  /// **'Mettre l\'animation en pause'**
  String get landmarksPause;

  /// No description provided for @masteryNone.
  ///
  /// In fr, this message translates to:
  /// **'Pas commencée'**
  String get masteryNone;

  /// No description provided for @masteryFragile.
  ///
  /// In fr, this message translates to:
  /// **'À revoir'**
  String get masteryFragile;

  /// No description provided for @masteryLearning.
  ///
  /// In fr, this message translates to:
  /// **'En cours d\'acquisition'**
  String get masteryLearning;

  /// No description provided for @masteryAcquired.
  ///
  /// In fr, this message translates to:
  /// **'Acquise'**
  String get masteryAcquired;

  /// No description provided for @masteryMastered.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrisée'**
  String get masteryMastered;

  /// No description provided for @learnMasteryLegend.
  ///
  /// In fr, this message translates to:
  /// **'Niveau d\'acquisition'**
  String get learnMasteryLegend;

  /// No description provided for @learnLessonMastery.
  ///
  /// In fr, this message translates to:
  /// **'{level}, {percent} %'**
  String learnLessonMastery(String level, int percent);

  /// No description provided for @learnStartBubble.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti !'**
  String get learnStartBubble;

  /// No description provided for @learnUnitProgress.
  ///
  /// In fr, this message translates to:
  /// **'{done} / {total} leçons'**
  String learnUnitProgress(int done, int total);

  /// No description provided for @learnUnitTrophy.
  ///
  /// In fr, this message translates to:
  /// **'Trophée de l\'unité'**
  String get learnUnitTrophy;

  /// No description provided for @learnUnitTrophyLocked.
  ///
  /// In fr, this message translates to:
  /// **'Terminez toutes les leçons de l\'unité pour gagner ce trophée.'**
  String get learnUnitTrophyLocked;

  /// No description provided for @learnUnitTrophyEarned.
  ///
  /// In fr, this message translates to:
  /// **'Trophée gagné : unité terminée !'**
  String get learnUnitTrophyEarned;

  /// No description provided for @learnPracticeIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Avec exercice pratique'**
  String get learnPracticeIncluded;

  /// No description provided for @learnPracticeStop.
  ///
  /// In fr, this message translates to:
  /// **'Exercice'**
  String get learnPracticeStop;

  /// No description provided for @learnPracticeStopLabel.
  ///
  /// In fr, this message translates to:
  /// **'Exercice pratique de la leçon {title}'**
  String learnPracticeStopLabel(String title);

  /// No description provided for @learnPracticeAfterLesson.
  ///
  /// In fr, this message translates to:
  /// **'À la fin de la leçon'**
  String get learnPracticeAfterLesson;

  /// No description provided for @lessonSpeakWord.
  ///
  /// In fr, this message translates to:
  /// **'Écouter le mot'**
  String get lessonSpeakWord;

  /// No description provided for @lessonCombo.
  ///
  /// In fr, this message translates to:
  /// **'{count} d\'affilée !'**
  String lessonCombo(int count);

  /// No description provided for @lessonStarsLabel.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 étoile sur 3} other{{count} étoiles sur 3}}'**
  String lessonStarsLabel(int count);

  /// No description provided for @lessonMasteryReached.
  ///
  /// In fr, this message translates to:
  /// **'Niveau atteint : {level}'**
  String lessonMasteryReached(String level);

  /// No description provided for @practiceSession.
  ///
  /// In fr, this message translates to:
  /// **'Exercice pratique · {number}/{total}'**
  String practiceSession(int number, int total);

  /// No description provided for @practiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reproduisez ce signe'**
  String get practiceTitle;

  /// No description provided for @practiceReference.
  ///
  /// In fr, this message translates to:
  /// **'Modèle à imiter'**
  String get practiceReference;

  /// No description provided for @practiceYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get practiceYou;

  /// No description provided for @practiceCameraHint.
  ///
  /// In fr, this message translates to:
  /// **'Placez-vous face à la caméra, dans un endroit bien éclairé, les mains bien visibles.'**
  String get practiceCameraHint;

  /// No description provided for @practiceEnableCamera.
  ///
  /// In fr, this message translates to:
  /// **'Activer la caméra'**
  String get practiceEnableCamera;

  /// No description provided for @practiceNoCamera.
  ///
  /// In fr, this message translates to:
  /// **'Je ne peux pas utiliser la caméra'**
  String get practiceNoCamera;

  /// No description provided for @practiceStart.
  ///
  /// In fr, this message translates to:
  /// **'Je signe !'**
  String get practiceStart;

  /// No description provided for @practiceCountdown.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement dans {count}'**
  String practiceCountdown(int count);

  /// No description provided for @practiceRecording.
  ///
  /// In fr, this message translates to:
  /// **'Signez maintenant !'**
  String get practiceRecording;

  /// No description provided for @practiceAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de votre signe…'**
  String get practiceAnalyzing;

  /// No description provided for @practiceSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Bravo, signe reconnu !'**
  String get practiceSuccess;

  /// No description provided for @practiceFailure.
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait…'**
  String get practiceFailure;

  /// No description provided for @practiceFailureHint.
  ///
  /// In fr, this message translates to:
  /// **'Revoyez le modèle puis réessayez, ou continuez.'**
  String get practiceFailureHint;

  /// No description provided for @practiceRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get practiceRetry;

  /// No description provided for @practiceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La reconnaissance automatique est indisponible pour le moment.'**
  String get practiceUnavailable;

  /// No description provided for @practiceSelfCheckTitle.
  ///
  /// In fr, this message translates to:
  /// **'Évaluez-vous'**
  String get practiceSelfCheckTitle;

  /// No description provided for @practiceSelfCheckMessage.
  ///
  /// In fr, this message translates to:
  /// **'Reproduisez le signe comme sur le modèle, par exemple devant un miroir, puis indiquez si vous l\'avez réussi.'**
  String get practiceSelfCheckMessage;

  /// No description provided for @practiceSelfYes.
  ///
  /// In fr, this message translates to:
  /// **'Je l\'ai réussi'**
  String get practiceSelfYes;

  /// No description provided for @practiceSelfNo.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore'**
  String get practiceSelfNo;

  /// No description provided for @practiceSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get practiceSkip;

  /// No description provided for @practiceSelfRated.
  ///
  /// In fr, this message translates to:
  /// **'Auto-évaluation enregistrée'**
  String get practiceSelfRated;

  /// No description provided for @adminLearningForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Réservé aux administrateurs, enseignants et experts en langue des signes.'**
  String get adminLearningForbidden;

  /// No description provided for @mlScreenSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Datasets, entraînements, expériences, registre et modèles d\'épellation ASL'**
  String get mlScreenSubtitle;

  /// No description provided for @mlTabDatasets.
  ///
  /// In fr, this message translates to:
  /// **'Datasets'**
  String get mlTabDatasets;

  /// No description provided for @mlTabJobs.
  ///
  /// In fr, this message translates to:
  /// **'Entraînements'**
  String get mlTabJobs;

  /// No description provided for @mlTabExperiments.
  ///
  /// In fr, this message translates to:
  /// **'Expériences'**
  String get mlTabExperiments;

  /// No description provided for @mlTabRegistry.
  ///
  /// In fr, this message translates to:
  /// **'Registre'**
  String get mlTabRegistry;

  /// No description provided for @mlTabFingerspell.
  ///
  /// In fr, this message translates to:
  /// **'Épellation'**
  String get mlTabFingerspell;

  /// No description provided for @mlFingerspellTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modèles d\'épellation ASL'**
  String get mlFingerspellTitle;

  /// No description provided for @mlFingerspellSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Activez la version utilisée pour la traduction lettres → texte, et consultez les courbes d\'entraînement.'**
  String get mlFingerspellSubtitle;

  /// No description provided for @mlFingerspellEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle d\'épellation'**
  String get mlFingerspellEmptyTitle;

  /// No description provided for @mlFingerspellEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Démarrez le service ML (uvicorn) pour charger les versions depuis ml/models/fingerspell.'**
  String get mlFingerspellEmptyMessage;

  /// No description provided for @mlFingerspellActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get mlFingerspellActive;

  /// No description provided for @mlFingerspellActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer ce modèle'**
  String get mlFingerspellActivate;

  /// No description provided for @mlFingerspellActivated.
  ///
  /// In fr, this message translates to:
  /// **'{name} est maintenant le modèle actif'**
  String mlFingerspellActivated(String name);

  /// No description provided for @mlFingerspellAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision test : {value} %'**
  String mlFingerspellAccuracy(String value);

  /// No description provided for @mlFingerspellPerfTitle.
  ///
  /// In fr, this message translates to:
  /// **'Performances'**
  String get mlFingerspellPerfTitle;

  /// No description provided for @mlFingerspellChartAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision par époque'**
  String get mlFingerspellChartAccuracy;

  /// No description provided for @mlFingerspellTestAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision (holdout)'**
  String get mlFingerspellTestAccuracy;

  /// No description provided for @mlFingerspellTop3.
  ///
  /// In fr, this message translates to:
  /// **'Top-3 (holdout)'**
  String get mlFingerspellTop3;

  /// No description provided for @mlFingerspellDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fiche du modèle'**
  String get mlFingerspellDetailsTitle;

  /// No description provided for @mlFingerspellFieldId.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get mlFingerspellFieldId;

  /// No description provided for @mlFingerspellFieldVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get mlFingerspellFieldVersion;

  /// No description provided for @mlFingerspellFieldDataset.
  ///
  /// In fr, this message translates to:
  /// **'Dataset'**
  String get mlFingerspellFieldDataset;

  /// No description provided for @mlFingerspellFieldDatasetDir.
  ///
  /// In fr, this message translates to:
  /// **'Dossier dataset'**
  String get mlFingerspellFieldDatasetDir;

  /// No description provided for @mlFingerspellFieldArchitecture.
  ///
  /// In fr, this message translates to:
  /// **'Architecture'**
  String get mlFingerspellFieldArchitecture;

  /// No description provided for @mlFingerspellFieldInput.
  ///
  /// In fr, this message translates to:
  /// **'Entrée'**
  String get mlFingerspellFieldInput;

  /// No description provided for @mlFingerspellFieldClasses.
  ///
  /// In fr, this message translates to:
  /// **'Classes'**
  String get mlFingerspellFieldClasses;

  /// No description provided for @mlFingerspellFieldEpochs.
  ///
  /// In fr, this message translates to:
  /// **'Époques'**
  String get mlFingerspellFieldEpochs;

  /// No description provided for @mlFingerspellFieldMaxPerClass.
  ///
  /// In fr, this message translates to:
  /// **'Images / classe'**
  String get mlFingerspellFieldMaxPerClass;

  /// No description provided for @mlFingerspellFieldRuntime.
  ///
  /// In fr, this message translates to:
  /// **'Runtime'**
  String get mlFingerspellFieldRuntime;

  /// No description provided for @mlFingerspellFieldSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille TFLite'**
  String get mlFingerspellFieldSize;

  /// No description provided for @mlFingerspellFieldValAcc.
  ///
  /// In fr, this message translates to:
  /// **'Précision validation'**
  String get mlFingerspellFieldValAcc;

  /// No description provided for @mlFingerspellFieldTflite.
  ///
  /// In fr, this message translates to:
  /// **'TFLite disponible'**
  String get mlFingerspellFieldTflite;

  /// No description provided for @mlFingerspellNoHistory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune courbe d\'entraînement disponible pour cette version.'**
  String get mlFingerspellNoHistory;

  /// No description provided for @mlFingerspellTrainTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement'**
  String get mlFingerspellTrainTitle;

  /// No description provided for @mlFingerspellTrainSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Relance l\'entraînement CNN-BiLSTM sur ml/dataset, publie une nouvelle version et l\'active. La précision holdout (~99 %) mesure les crops dataset, pas la caméra pleine frame.'**
  String get mlFingerspellTrainSubtitle;

  /// No description provided for @mlFingerspellTrainStart.
  ///
  /// In fr, this message translates to:
  /// **'Relancer l\'entraînement'**
  String get mlFingerspellTrainStart;

  /// No description provided for @mlFingerspellTrainRunning.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement en cours…'**
  String get mlFingerspellTrainRunning;

  /// No description provided for @mlFingerspellTrainIdle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun entraînement en cours'**
  String get mlFingerspellTrainIdle;

  /// No description provided for @mlFingerspellTrainSucceeded.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement terminé — version {id} publiée'**
  String mlFingerspellTrainSucceeded(String id);

  /// No description provided for @mlFingerspellTrainFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'entraînement'**
  String get mlFingerspellTrainFailed;

  /// No description provided for @mlFingerspellTrainRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser le statut'**
  String get mlFingerspellTrainRefresh;

  /// No description provided for @mlFingerspellTrainLog.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get mlFingerspellTrainLog;

  /// No description provided for @mlFingerspellAccuracyNote.
  ///
  /// In fr, this message translates to:
  /// **'Note : la précision holdout est mesurée sur des images déjà cadrées (comme le dataset). Sur caméra, le prétraitement (crop main) compte autant que le modèle.'**
  String get mlFingerspellAccuracyNote;

  /// No description provided for @mlNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get mlNo;

  /// No description provided for @dictGloss.
  ///
  /// In fr, this message translates to:
  /// **'Glosse'**
  String get dictGloss;

  /// No description provided for @dictTranslations.
  ///
  /// In fr, this message translates to:
  /// **'Traductions'**
  String get dictTranslations;

  /// No description provided for @mlClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get mlClose;

  /// No description provided for @mlYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get mlYes;

  /// No description provided for @mlUnitB.
  ///
  /// In fr, this message translates to:
  /// **'{value} o'**
  String mlUnitB(String value);

  /// No description provided for @mlUnitKb.
  ///
  /// In fr, this message translates to:
  /// **'{value} Ko'**
  String mlUnitKb(String value);

  /// No description provided for @mlUnitMb.
  ///
  /// In fr, this message translates to:
  /// **'{value} Mo'**
  String mlUnitMb(String value);

  /// No description provided for @mlStatusRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get mlStatusRegistered;

  /// No description provided for @mlStatusAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en cours'**
  String get mlStatusAnalyzing;

  /// No description provided for @mlStatusAnalyzed.
  ///
  /// In fr, this message translates to:
  /// **'Analysé'**
  String get mlStatusAnalyzed;

  /// No description provided for @mlStatusPreprocessing.
  ///
  /// In fr, this message translates to:
  /// **'Prétraitement en cours'**
  String get mlStatusPreprocessing;

  /// No description provided for @mlStatusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get mlStatusReady;

  /// No description provided for @mlStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get mlStatusFailed;

  /// No description provided for @mlJobQueued.
  ///
  /// In fr, this message translates to:
  /// **'En file'**
  String get mlJobQueued;

  /// No description provided for @mlJobRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get mlJobRunning;

  /// No description provided for @mlJobCancelling.
  ///
  /// In fr, this message translates to:
  /// **'Annulation…'**
  String get mlJobCancelling;

  /// No description provided for @mlJobCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get mlJobCancelled;

  /// No description provided for @mlJobDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get mlJobDone;

  /// No description provided for @mlJobFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get mlJobFailed;

  /// No description provided for @mlExpQueued.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get mlExpQueued;

  /// No description provided for @mlExpRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get mlExpRunning;

  /// No description provided for @mlExpCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get mlExpCompleted;

  /// No description provided for @mlExpFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get mlExpFailed;

  /// No description provided for @mlExpPruned.
  ///
  /// In fr, this message translates to:
  /// **'Élaguée'**
  String get mlExpPruned;

  /// No description provided for @mlExpCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get mlExpCancelled;

  /// No description provided for @mlStageTraining.
  ///
  /// In fr, this message translates to:
  /// **'ENTRAÎNEMENT'**
  String get mlStageTraining;

  /// No description provided for @mlStageTrained.
  ///
  /// In fr, this message translates to:
  /// **'ENTRAÎNÉ'**
  String get mlStageTrained;

  /// No description provided for @mlStageEvaluated.
  ///
  /// In fr, this message translates to:
  /// **'ÉVALUÉ'**
  String get mlStageEvaluated;

  /// No description provided for @mlStageValidated.
  ///
  /// In fr, this message translates to:
  /// **'VALIDÉ'**
  String get mlStageValidated;

  /// No description provided for @mlStageStaging.
  ///
  /// In fr, this message translates to:
  /// **'STAGING'**
  String get mlStageStaging;

  /// No description provided for @mlStageProduction.
  ///
  /// In fr, this message translates to:
  /// **'PRODUCTION'**
  String get mlStageProduction;

  /// No description provided for @mlStageArchived.
  ///
  /// In fr, this message translates to:
  /// **'ARCHIVÉ'**
  String get mlStageArchived;

  /// No description provided for @mlKindAnalyze.
  ///
  /// In fr, this message translates to:
  /// **'Analyse'**
  String get mlKindAnalyze;

  /// No description provided for @mlKindPreprocess.
  ///
  /// In fr, this message translates to:
  /// **'Prétraitement'**
  String get mlKindPreprocess;

  /// No description provided for @mlKindTrain.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement'**
  String get mlKindTrain;

  /// No description provided for @mlKindSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche d\'hyperparamètres'**
  String get mlKindSearch;

  /// No description provided for @mlKindEvaluate.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement'**
  String get mlKindEvaluate;

  /// No description provided for @mlKindConvert.
  ///
  /// In fr, this message translates to:
  /// **'Conversion TFLite'**
  String get mlKindConvert;

  /// No description provided for @mlDatasetsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Chaque dataset appartient à une seule langue des signes. Il est analysé automatiquement avant tout entraînement.'**
  String get mlDatasetsSubtitle;

  /// No description provided for @mlDatasetAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un dataset'**
  String get mlDatasetAdd;

  /// No description provided for @mlDatasetAddHint.
  ///
  /// In fr, this message translates to:
  /// **'Le worker ML lit le dossier local (sur sa machine) ou télécharge l\'archive depuis l\'URL, puis lance l\'analyse.'**
  String get mlDatasetAddHint;

  /// No description provided for @mlDatasetCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer et analyser'**
  String get mlDatasetCreate;

  /// No description provided for @mlDatasetCreated.
  ///
  /// In fr, this message translates to:
  /// **'Dataset enregistré, analyse en file'**
  String get mlDatasetCreated;

  /// No description provided for @mlDatasetsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dataset'**
  String get mlDatasetsEmpty;

  /// No description provided for @mlDatasetsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez un dataset (dossier local ou URL) pour commencer à entraîner un modèle.'**
  String get mlDatasetsEmptyMessage;

  /// No description provided for @mlDatasetTrainable.
  ///
  /// In fr, this message translates to:
  /// **'Entraînable'**
  String get mlDatasetTrainable;

  /// No description provided for @mlDatasetDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le dataset ?'**
  String get mlDatasetDeleteTitle;

  /// No description provided for @mlDatasetDeleteMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera retiré de la plateforme. Les fichiers sources ne sont pas supprimés.'**
  String mlDatasetDeleteMessage(String name);

  /// No description provided for @mlDatasetDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Dataset supprimé'**
  String get mlDatasetDeleted;

  /// No description provided for @mlAnalysisPending.
  ///
  /// In fr, this message translates to:
  /// **'Analyse pas encore disponible : elle démarre dès qu\'un worker est actif.'**
  String get mlAnalysisPending;

  /// No description provided for @mlUnstructured.
  ///
  /// In fr, this message translates to:
  /// **'Non structuré'**
  String get mlUnstructured;

  /// No description provided for @mlMappingCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 règle de label} other{{count} règles de label}}'**
  String mlMappingCount(int count);

  /// No description provided for @mlShowClasses.
  ///
  /// In fr, this message translates to:
  /// **'Voir la répartition des classes ({count})'**
  String mlShowClasses(int count);

  /// No description provided for @mlHideClasses.
  ///
  /// In fr, this message translates to:
  /// **'Masquer la répartition des classes'**
  String get mlHideClasses;

  /// No description provided for @mlMoreClasses.
  ///
  /// In fr, this message translates to:
  /// **'+ {count} autres classes'**
  String mlMoreClasses(int count);

  /// No description provided for @mlClassBarSemantics.
  ///
  /// In fr, this message translates to:
  /// **'{label} : {count} exemples'**
  String mlClassBarSemantics(String label, int count);

  /// No description provided for @mlMediaSummary.
  ///
  /// In fr, this message translates to:
  /// **'{mean}{suffix} (min {min}, max {max})'**
  String mlMediaSummary(String mean, String min, String max, String suffix);

  /// No description provided for @mlStatFiles.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers'**
  String get mlStatFiles;

  /// No description provided for @mlStatClasses.
  ///
  /// In fr, this message translates to:
  /// **'Classes'**
  String get mlStatClasses;

  /// No description provided for @mlStatLabeled.
  ///
  /// In fr, this message translates to:
  /// **'Échantillons labellisés'**
  String get mlStatLabeled;

  /// No description provided for @mlStatUnlabeled.
  ///
  /// In fr, this message translates to:
  /// **'Sans label'**
  String get mlStatUnlabeled;

  /// No description provided for @mlStatSigners.
  ///
  /// In fr, this message translates to:
  /// **'Signataires'**
  String get mlStatSigners;

  /// No description provided for @mlStatInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Invalides'**
  String get mlStatInvalid;

  /// No description provided for @mlStatDuplicates.
  ///
  /// In fr, this message translates to:
  /// **'Groupes de doublons'**
  String get mlStatDuplicates;

  /// No description provided for @mlStatImbalance.
  ///
  /// In fr, this message translates to:
  /// **'Déséquilibre max/min'**
  String get mlStatImbalance;

  /// No description provided for @mlStatPrepared.
  ///
  /// In fr, this message translates to:
  /// **'Séquences préparées'**
  String get mlStatPrepared;

  /// No description provided for @mlStatRejected.
  ///
  /// In fr, this message translates to:
  /// **'Séquences rejetées'**
  String get mlStatRejected;

  /// No description provided for @mlStatFps.
  ///
  /// In fr, this message translates to:
  /// **'FPS'**
  String get mlStatFps;

  /// No description provided for @mlStatDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get mlStatDuration;

  /// No description provided for @mlStatResolutions.
  ///
  /// In fr, this message translates to:
  /// **'Résolutions'**
  String get mlStatResolutions;

  /// No description provided for @mlActionTrain.
  ///
  /// In fr, this message translates to:
  /// **'Entraîner'**
  String get mlActionTrain;

  /// No description provided for @mlActionPreprocess.
  ///
  /// In fr, this message translates to:
  /// **'Prétraiter'**
  String get mlActionPreprocess;

  /// No description provided for @mlActionReanalyze.
  ///
  /// In fr, this message translates to:
  /// **'Réanalyser'**
  String get mlActionReanalyze;

  /// No description provided for @mlActionEditMapping.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le mapping de labels'**
  String get mlActionEditMapping;

  /// No description provided for @mlActionDeleteDataset.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le dataset'**
  String get mlActionDeleteDataset;

  /// No description provided for @mlTrainDisabledHint.
  ///
  /// In fr, this message translates to:
  /// **'Dataset non entraînable : il faut au moins 2 classes et 4 échantillons labellisés après analyse.'**
  String get mlTrainDisabledHint;

  /// No description provided for @mlJobQueuedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tâche ajoutée à la file du worker'**
  String get mlJobQueuedMessage;

  /// No description provided for @mlFieldName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get mlFieldName;

  /// No description provided for @mlFieldLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue des signes'**
  String get mlFieldLanguage;

  /// No description provided for @mlLanguageOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre code…'**
  String get mlLanguageOther;

  /// No description provided for @mlFieldLanguageCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de langue'**
  String get mlFieldLanguageCode;

  /// No description provided for @mlFieldLanguageCodeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Par exemple LSC, BSL, DGS (2 à 10 lettres)'**
  String get mlFieldLanguageCodeHelp;

  /// No description provided for @mlFieldSource.
  ///
  /// In fr, this message translates to:
  /// **'Source'**
  String get mlFieldSource;

  /// No description provided for @mlSourceLocal.
  ///
  /// In fr, this message translates to:
  /// **'Dossier local'**
  String get mlSourceLocal;

  /// No description provided for @mlSourceUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL'**
  String get mlSourceUrl;

  /// No description provided for @mlFieldPath.
  ///
  /// In fr, this message translates to:
  /// **'Chemin du dossier'**
  String get mlFieldPath;

  /// No description provided for @mlFieldPathHelp.
  ///
  /// In fr, this message translates to:
  /// **'Chemin absolu sur la machine du worker, ex. D:/datasets/lsfb'**
  String get mlFieldPathHelp;

  /// No description provided for @mlFieldUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de l\'archive'**
  String get mlFieldUrl;

  /// No description provided for @mlFieldUrlHelp.
  ///
  /// In fr, this message translates to:
  /// **'Lien http(s) vers une archive .zip ou .tar.gz'**
  String get mlFieldUrlHelp;

  /// No description provided for @mlFieldFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format des médias'**
  String get mlFieldFormat;

  /// No description provided for @mlFormatAuto.
  ///
  /// In fr, this message translates to:
  /// **'Détection automatique'**
  String get mlFormatAuto;

  /// No description provided for @mlFormatImages.
  ///
  /// In fr, this message translates to:
  /// **'Images'**
  String get mlFormatImages;

  /// No description provided for @mlFormatGif.
  ///
  /// In fr, this message translates to:
  /// **'GIF'**
  String get mlFormatGif;

  /// No description provided for @mlFormatVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos'**
  String get mlFormatVideo;

  /// No description provided for @mlFormatMixed.
  ///
  /// In fr, this message translates to:
  /// **'Mixte'**
  String get mlFormatMixed;

  /// No description provided for @mlFieldStructured.
  ///
  /// In fr, this message translates to:
  /// **'Structuré'**
  String get mlFieldStructured;

  /// No description provided for @mlFieldStructuredHelp.
  ///
  /// In fr, this message translates to:
  /// **'Un dossier par classe (le nom du dossier est le label)'**
  String get mlFieldStructuredHelp;

  /// No description provided for @mlFieldLabeled.
  ///
  /// In fr, this message translates to:
  /// **'Labellisé'**
  String get mlFieldLabeled;

  /// No description provided for @mlFieldLabeledHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les labels viennent des dossiers, de labels.csv ou du mapping ci-dessous ; ils ne sont jamais devinés.'**
  String get mlFieldLabeledHelp;

  /// No description provided for @mlFieldLabelMapping.
  ///
  /// In fr, this message translates to:
  /// **'Mapping de labels (optionnel)'**
  String get mlFieldLabelMapping;

  /// No description provided for @mlFieldLabelMappingHelp.
  ///
  /// In fr, this message translates to:
  /// **'Une règle par ligne : chemin = label. Les lignes vides ou commençant par # sont ignorées.'**
  String get mlFieldLabelMappingHelp;

  /// No description provided for @mlMappingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mapping de labels · {name}'**
  String mlMappingTitle(String name);

  /// No description provided for @mlMappingReanalyze.
  ///
  /// In fr, this message translates to:
  /// **'Relancer l\'analyse après enregistrement'**
  String get mlMappingReanalyze;

  /// No description provided for @mlMappingSaved.
  ///
  /// In fr, this message translates to:
  /// **'Mapping de labels enregistré'**
  String get mlMappingSaved;

  /// No description provided for @mlPreprocessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prétraiter · {name}'**
  String mlPreprocessTitle(String name);

  /// No description provided for @mlPreprocessHint.
  ///
  /// In fr, this message translates to:
  /// **'Extraction des landmarks MediaPipe (mains, pose et visage en option) pour chaque échantillon. Les séquences sans mains détectées peuvent être rejetées.'**
  String get mlPreprocessHint;

  /// No description provided for @mlFieldMaxFrames.
  ///
  /// In fr, this message translates to:
  /// **'Images max par échantillon'**
  String get mlFieldMaxFrames;

  /// No description provided for @mlFieldMaxFramesHelp.
  ///
  /// In fr, this message translates to:
  /// **'Les vidéos plus longues sont échantillonnées uniformément.'**
  String get mlFieldMaxFramesHelp;

  /// No description provided for @mlFieldIncludeFace.
  ///
  /// In fr, this message translates to:
  /// **'Inclure le visage'**
  String get mlFieldIncludeFace;

  /// No description provided for @mlFieldIncludeFaceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute les landmarks du visage (expressions), au prix de séquences plus lourdes.'**
  String get mlFieldIncludeFaceHelp;

  /// No description provided for @mlFieldRequireHands.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter les séquences sans mains'**
  String get mlFieldRequireHands;

  /// No description provided for @mlErrRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get mlErrRequired;

  /// No description provided for @mlErrUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL http(s) invalide'**
  String get mlErrUrl;

  /// No description provided for @mlErrLanguageCode.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide : 2 à 10 lettres'**
  String get mlErrLanguageCode;

  /// No description provided for @mlErrMappingLine.
  ///
  /// In fr, this message translates to:
  /// **'Ligne {line} invalide : format attendu « chemin = label »'**
  String mlErrMappingLine(int line);

  /// No description provided for @mlErrIntRange.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un entier entre {min} et {max}'**
  String mlErrIntRange(int min, int max);

  /// No description provided for @mlErrNumberRange.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un nombre entre {min} et {max}'**
  String mlErrNumberRange(String min, String max);

  /// No description provided for @mlErrIntList.
  ///
  /// In fr, this message translates to:
  /// **'Entrez des entiers séparés par des virgules, ex. 128,256,128'**
  String get mlErrIntList;

  /// No description provided for @mlErrSplitSum.
  ///
  /// In fr, this message translates to:
  /// **'La somme train + validation + test doit faire 100 % (actuellement {sum} %)'**
  String mlErrSplitSum(int sum);

  /// No description provided for @mlErrRangeOrder.
  ///
  /// In fr, this message translates to:
  /// **'Le maximum doit être supérieur ou égal au minimum'**
  String get mlErrRangeOrder;

  /// No description provided for @mlErrFixFields.
  ///
  /// In fr, this message translates to:
  /// **'Corrigez les champs en erreur avant de lancer'**
  String get mlErrFixFields;

  /// No description provided for @mlJobsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Les tâches tournent sur le worker ML : fermer l\'application ne les interrompt pas.'**
  String get mlJobsSubtitle;

  /// No description provided for @mlTrainNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel entraînement'**
  String get mlTrainNew;

  /// No description provided for @mlJobsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune tâche'**
  String get mlJobsEmpty;

  /// No description provided for @mlJobsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les analyses, prétraitements et entraînements lancés apparaîtront ici avec leur progression.'**
  String get mlJobsEmptyMessage;

  /// No description provided for @mlWorkerMissingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun worker actif'**
  String get mlWorkerMissingTitle;

  /// No description provided for @mlWorkerMissingMessage.
  ///
  /// In fr, this message translates to:
  /// **'Des tâches attendent mais aucun worker n\'a donné signe de vie depuis 2 minutes. Lancez python -m moomoo_ml.worker dans le dossier ml/ :'**
  String get mlWorkerMissingMessage;

  /// No description provided for @mlWorkerLastSeen.
  ///
  /// In fr, this message translates to:
  /// **'Dernier signal du worker : {date}'**
  String mlWorkerLastSeen(String date);

  /// No description provided for @mlWorkerActive.
  ///
  /// In fr, this message translates to:
  /// **'Worker actif · dernier signal {date}'**
  String mlWorkerActive(String date);

  /// No description provided for @mlJobEpoch.
  ///
  /// In fr, this message translates to:
  /// **'Époque {current} / {total}'**
  String mlJobEpoch(int current, int total);

  /// No description provided for @mlJobElapsed.
  ///
  /// In fr, this message translates to:
  /// **'Durée : {duration}'**
  String mlJobElapsed(String duration);

  /// No description provided for @mlJobAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Tentative n° {count}'**
  String mlJobAttempts(int count);

  /// No description provided for @mlActionCancelJob.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la tâche'**
  String get mlActionCancelJob;

  /// No description provided for @mlJobCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la tâche ?'**
  String get mlJobCancelTitle;

  /// No description provided for @mlJobCancelQueuedMessage.
  ///
  /// In fr, this message translates to:
  /// **'La tâche sera retirée de la file.'**
  String get mlJobCancelQueuedMessage;

  /// No description provided for @mlJobCancelRunningMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le worker arrêtera la tâche à la fin de l\'époque en cours. Les expériences terminées sont conservées.'**
  String get mlJobCancelRunningMessage;

  /// No description provided for @mlJobCancelRequested.
  ///
  /// In fr, this message translates to:
  /// **'Annulation demandée'**
  String get mlJobCancelRequested;

  /// No description provided for @mlProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression'**
  String get mlProgress;

  /// No description provided for @mlAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Tentatives'**
  String get mlAttempts;

  /// No description provided for @mlLogs.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get mlLogs;

  /// No description provided for @mlLogsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun message pour le moment.'**
  String get mlLogsEmpty;

  /// No description provided for @mlExperimentsNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune expérience pour cette tâche pour le moment.'**
  String get mlExperimentsNone;

  /// No description provided for @mlColCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get mlColCode;

  /// No description provided for @mlColStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get mlColStatus;

  /// No description provided for @mlColRung.
  ///
  /// In fr, this message translates to:
  /// **'Palier'**
  String get mlColRung;

  /// No description provided for @mlColEpochs.
  ///
  /// In fr, this message translates to:
  /// **'Époques'**
  String get mlColEpochs;

  /// No description provided for @mlColBestValAcc.
  ///
  /// In fr, this message translates to:
  /// **'Meilleure précision val.'**
  String get mlColBestValAcc;

  /// No description provided for @mlColBestValLoss.
  ///
  /// In fr, this message translates to:
  /// **'Meilleure perte val.'**
  String get mlColBestValLoss;

  /// No description provided for @mlColTestAcc.
  ///
  /// In fr, this message translates to:
  /// **'Exactitude test'**
  String get mlColTestAcc;

  /// No description provided for @mlColMacroF1.
  ///
  /// In fr, this message translates to:
  /// **'F1 macro'**
  String get mlColMacroF1;

  /// No description provided for @mlColDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get mlColDuration;

  /// No description provided for @mlColLabel.
  ///
  /// In fr, this message translates to:
  /// **'Label'**
  String get mlColLabel;

  /// No description provided for @mlColSupport.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get mlColSupport;

  /// No description provided for @mlTrainTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lancer un entraînement'**
  String get mlTrainTitle;

  /// No description provided for @mlTrainQueued.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement ajouté à la file du worker'**
  String get mlTrainQueued;

  /// No description provided for @mlTrainNoDataset.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dataset entraînable. Ajoutez un dataset et attendez la fin de son analyse (au moins 2 classes et 4 échantillons labellisés).'**
  String get mlTrainNoDataset;

  /// No description provided for @mlModeManual.
  ///
  /// In fr, this message translates to:
  /// **'Configuration précise'**
  String get mlModeManual;

  /// No description provided for @mlModeSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche automatique'**
  String get mlModeSearch;

  /// No description provided for @mlModeManualHint.
  ///
  /// In fr, this message translates to:
  /// **'Un seul modèle, entraîné avec exactement les paramètres ci-dessous.'**
  String get mlModeManualHint;

  /// No description provided for @mlModeSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Random Search + Hyperband : plusieurs configurations tirées dans l\'espace de recherche, les moins prometteuses sont arrêtées tôt.'**
  String get mlModeSearchHint;

  /// No description provided for @mlFieldDataset.
  ///
  /// In fr, this message translates to:
  /// **'Dataset'**
  String get mlFieldDataset;

  /// No description provided for @mlTrainLanguageNote.
  ///
  /// In fr, this message translates to:
  /// **'Langue {language} · {classes} classes · {samples} échantillons. Un modèle n\'est jamais entraîné sur plusieurs langues.'**
  String mlTrainLanguageNote(String language, int classes, int samples);

  /// No description provided for @mlSectionData.
  ///
  /// In fr, this message translates to:
  /// **'Données'**
  String get mlSectionData;

  /// No description provided for @mlSectionAugmentation.
  ///
  /// In fr, this message translates to:
  /// **'Augmentation'**
  String get mlSectionAugmentation;

  /// No description provided for @mlSectionModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get mlSectionModel;

  /// No description provided for @mlSectionSearch.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get mlSectionSearch;

  /// No description provided for @mlSectionExport.
  ///
  /// In fr, this message translates to:
  /// **'Export'**
  String get mlSectionExport;

  /// No description provided for @mlFieldSequenceLength.
  ///
  /// In fr, this message translates to:
  /// **'Longueur de séquence'**
  String get mlFieldSequenceLength;

  /// No description provided for @mlFieldSequenceLengthHelp.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'images par séquence envoyée au modèle'**
  String get mlFieldSequenceLengthHelp;

  /// No description provided for @mlFieldMinPerClass.
  ///
  /// In fr, this message translates to:
  /// **'Échantillons min. par classe'**
  String get mlFieldMinPerClass;

  /// No description provided for @mlFieldNormalize.
  ///
  /// In fr, this message translates to:
  /// **'Normaliser les landmarks'**
  String get mlFieldNormalize;

  /// No description provided for @mlFieldSplitTrain.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement (%)'**
  String get mlFieldSplitTrain;

  /// No description provided for @mlFieldSplitVal.
  ///
  /// In fr, this message translates to:
  /// **'Validation (%)'**
  String get mlFieldSplitVal;

  /// No description provided for @mlFieldSplitTest.
  ///
  /// In fr, this message translates to:
  /// **'Test (%)'**
  String get mlFieldSplitTest;

  /// No description provided for @mlFieldSplitStrategy.
  ///
  /// In fr, this message translates to:
  /// **'Stratégie de découpage'**
  String get mlFieldSplitStrategy;

  /// No description provided for @mlFieldSplitStrategyHelp.
  ///
  /// In fr, this message translates to:
  /// **'Automatique : indépendant des signataires si ≥ 3 signataires, sinon stratifié par classe.'**
  String get mlFieldSplitStrategyHelp;

  /// No description provided for @mlSplitAuto.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get mlSplitAuto;

  /// No description provided for @mlSplitSigner.
  ///
  /// In fr, this message translates to:
  /// **'Par signataire'**
  String get mlSplitSigner;

  /// No description provided for @mlSplitStratified.
  ///
  /// In fr, this message translates to:
  /// **'Stratifié par classe'**
  String get mlSplitStratified;

  /// No description provided for @mlSplitPredefined.
  ///
  /// In fr, this message translates to:
  /// **'Prédéfini par le dataset'**
  String get mlSplitPredefined;

  /// No description provided for @mlFieldAugment.
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'augmentation'**
  String get mlFieldAugment;

  /// No description provided for @mlFieldAugmentHelp.
  ///
  /// In fr, this message translates to:
  /// **'Appliquée au jeu d\'entraînement uniquement, pour compléter les classes peu représentées.'**
  String get mlFieldAugmentHelp;

  /// No description provided for @mlFieldTargetPerClass.
  ///
  /// In fr, this message translates to:
  /// **'Cible par classe'**
  String get mlFieldTargetPerClass;

  /// No description provided for @mlFieldMaxFactor.
  ///
  /// In fr, this message translates to:
  /// **'Facteur max.'**
  String get mlFieldMaxFactor;

  /// No description provided for @mlAdvancedSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres avancés'**
  String get mlAdvancedSettings;

  /// No description provided for @mlFieldTimeWarp.
  ///
  /// In fr, this message translates to:
  /// **'Déformation temporelle'**
  String get mlFieldTimeWarp;

  /// No description provided for @mlFieldFrameDrop.
  ///
  /// In fr, this message translates to:
  /// **'Suppression d\'images'**
  String get mlFieldFrameDrop;

  /// No description provided for @mlFieldRotation.
  ///
  /// In fr, this message translates to:
  /// **'Rotation (degrés)'**
  String get mlFieldRotation;

  /// No description provided for @mlFieldScale.
  ///
  /// In fr, this message translates to:
  /// **'Échelle'**
  String get mlFieldScale;

  /// No description provided for @mlFieldTranslation.
  ///
  /// In fr, this message translates to:
  /// **'Translation'**
  String get mlFieldTranslation;

  /// No description provided for @mlFieldNoise.
  ///
  /// In fr, this message translates to:
  /// **'Bruit (écart-type)'**
  String get mlFieldNoise;

  /// No description provided for @mlModelDefaultArchitecture.
  ///
  /// In fr, this message translates to:
  /// **'Architecture par défaut : LSTM(128) → LSTM(256) → LSTM(128) → Dense(classes, softmax).'**
  String get mlModelDefaultArchitecture;

  /// No description provided for @mlFieldLstmUnits.
  ///
  /// In fr, this message translates to:
  /// **'Unités LSTM'**
  String get mlFieldLstmUnits;

  /// No description provided for @mlFieldListHelp.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs séparées par des virgules'**
  String get mlFieldListHelp;

  /// No description provided for @mlFieldDenseUnits.
  ///
  /// In fr, this message translates to:
  /// **'Couches denses'**
  String get mlFieldDenseUnits;

  /// No description provided for @mlFieldDenseHelp.
  ///
  /// In fr, this message translates to:
  /// **'Vide = aucune couche dense cachée'**
  String get mlFieldDenseHelp;

  /// No description provided for @mlFieldDropout.
  ///
  /// In fr, this message translates to:
  /// **'Dropout'**
  String get mlFieldDropout;

  /// No description provided for @mlFieldLearningRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'apprentissage'**
  String get mlFieldLearningRate;

  /// No description provided for @mlFieldBatchSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille de batch'**
  String get mlFieldBatchSize;

  /// No description provided for @mlFieldEpochs.
  ///
  /// In fr, this message translates to:
  /// **'Époques'**
  String get mlFieldEpochs;

  /// No description provided for @mlFieldLabelSmoothing.
  ///
  /// In fr, this message translates to:
  /// **'Lissage des labels'**
  String get mlFieldLabelSmoothing;

  /// No description provided for @mlFieldEarlyStopping.
  ///
  /// In fr, this message translates to:
  /// **'Patience arrêt anticipé'**
  String get mlFieldEarlyStopping;

  /// No description provided for @mlFieldReduceLr.
  ///
  /// In fr, this message translates to:
  /// **'Patience réduction du taux'**
  String get mlFieldReduceLr;

  /// No description provided for @mlFieldOptimizer.
  ///
  /// In fr, this message translates to:
  /// **'Optimiseur'**
  String get mlFieldOptimizer;

  /// No description provided for @mlFieldLoss.
  ///
  /// In fr, this message translates to:
  /// **'Fonction de perte'**
  String get mlFieldLoss;

  /// No description provided for @mlFieldClassWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids de classes équilibrés'**
  String get mlFieldClassWeight;

  /// No description provided for @mlFieldClassWeightHelp.
  ///
  /// In fr, this message translates to:
  /// **'Compense le déséquilibre entre classes pendant l\'entraînement.'**
  String get mlFieldClassWeightHelp;

  /// No description provided for @mlFieldLayerNorm.
  ///
  /// In fr, this message translates to:
  /// **'Normalisation de couche'**
  String get mlFieldLayerNorm;

  /// No description provided for @mlSearchHelp.
  ///
  /// In fr, this message translates to:
  /// **'Hyperband alloue plus d\'époques aux configurations prometteuses. Les listes définissent les choix possibles, les min/max des plages continues.'**
  String get mlSearchHelp;

  /// No description provided for @mlFieldSearchMaxEpochs.
  ///
  /// In fr, this message translates to:
  /// **'Époques max. par essai'**
  String get mlFieldSearchMaxEpochs;

  /// No description provided for @mlFieldSearchEta.
  ///
  /// In fr, this message translates to:
  /// **'Facteur de réduction (eta)'**
  String get mlFieldSearchEta;

  /// No description provided for @mlFieldSearchTrials.
  ///
  /// In fr, this message translates to:
  /// **'Nombre max. d\'essais'**
  String get mlFieldSearchTrials;

  /// No description provided for @mlFieldSearchSeed.
  ///
  /// In fr, this message translates to:
  /// **'Graine aléatoire'**
  String get mlFieldSearchSeed;

  /// No description provided for @mlFieldSpaceLstmLayers.
  ///
  /// In fr, this message translates to:
  /// **'Nombres de couches LSTM'**
  String get mlFieldSpaceLstmLayers;

  /// No description provided for @mlFieldSpaceLstmUnits.
  ///
  /// In fr, this message translates to:
  /// **'Unités LSTM possibles'**
  String get mlFieldSpaceLstmUnits;

  /// No description provided for @mlFieldSpaceDropoutMin.
  ///
  /// In fr, this message translates to:
  /// **'Dropout min.'**
  String get mlFieldSpaceDropoutMin;

  /// No description provided for @mlFieldSpaceDropoutMax.
  ///
  /// In fr, this message translates to:
  /// **'Dropout max.'**
  String get mlFieldSpaceDropoutMax;

  /// No description provided for @mlFieldSpaceDenseLayers.
  ///
  /// In fr, this message translates to:
  /// **'Nombres de couches denses'**
  String get mlFieldSpaceDenseLayers;

  /// No description provided for @mlFieldSpaceDenseUnits.
  ///
  /// In fr, this message translates to:
  /// **'Unités denses possibles'**
  String get mlFieldSpaceDenseUnits;

  /// No description provided for @mlFieldSpaceLrMin.
  ///
  /// In fr, this message translates to:
  /// **'Taux min. (échelle log)'**
  String get mlFieldSpaceLrMin;

  /// No description provided for @mlFieldSpaceLrMax.
  ///
  /// In fr, this message translates to:
  /// **'Taux max. (échelle log)'**
  String get mlFieldSpaceLrMax;

  /// No description provided for @mlFieldSpaceBatch.
  ///
  /// In fr, this message translates to:
  /// **'Tailles de batch possibles'**
  String get mlFieldSpaceBatch;

  /// No description provided for @mlFieldSpaceOptimizers.
  ///
  /// In fr, this message translates to:
  /// **'Optimiseurs possibles'**
  String get mlFieldSpaceOptimizers;

  /// No description provided for @mlFieldQuantization.
  ///
  /// In fr, this message translates to:
  /// **'Quantification TFLite'**
  String get mlFieldQuantization;

  /// No description provided for @mlQuantDynamic.
  ///
  /// In fr, this message translates to:
  /// **'Dynamique (int8)'**
  String get mlQuantDynamic;

  /// No description provided for @mlQuantFloat16.
  ///
  /// In fr, this message translates to:
  /// **'Float16'**
  String get mlQuantFloat16;

  /// No description provided for @mlQuantNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune (float32)'**
  String get mlQuantNone;

  /// No description provided for @mlQuantDynamicHelp.
  ///
  /// In fr, this message translates to:
  /// **'Modèle environ 4 fois plus léger, légère perte de précision possible.'**
  String get mlQuantDynamicHelp;

  /// No description provided for @mlQuantFloat16Help.
  ///
  /// In fr, this message translates to:
  /// **'Modèle 2 fois plus léger, précision quasi identique.'**
  String get mlQuantFloat16Help;

  /// No description provided for @mlQuantNoneHelp.
  ///
  /// In fr, this message translates to:
  /// **'Précision maximale, fichier le plus lourd.'**
  String get mlQuantNoneHelp;

  /// No description provided for @mlFieldAutoRegister.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer automatiquement le meilleur modèle'**
  String get mlFieldAutoRegister;

  /// No description provided for @mlFieldAutoRegisterHelp.
  ///
  /// In fr, this message translates to:
  /// **'Évalue, convertit en TFLite et ajoute au registre au stade ÉVALUÉ.'**
  String get mlFieldAutoRegisterHelp;

  /// No description provided for @mlTrainSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Lancer l\'entraînement'**
  String get mlTrainSubmit;

  /// No description provided for @mlTrainSubmitSearch.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la recherche'**
  String get mlTrainSubmitSearch;

  /// No description provided for @mlExperimentsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Chaque entraînement produit une ou plusieurs expériences. Sélectionnez-en jusqu\'à 4 pour les comparer.'**
  String get mlExperimentsSubtitle;

  /// No description provided for @mlExperimentsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune expérience'**
  String get mlExperimentsEmpty;

  /// No description provided for @mlExperimentsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Lancez un entraînement ou une recherche automatique pour voir les expériences et leurs courbes.'**
  String get mlExperimentsEmptyMessage;

  /// No description provided for @mlFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les langues'**
  String get mlFilterAll;

  /// No description provided for @mlRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get mlRegistered;

  /// No description provided for @mlCompare.
  ///
  /// In fr, this message translates to:
  /// **'Comparer'**
  String get mlCompare;

  /// No description provided for @mlClearSelection.
  ///
  /// In fr, this message translates to:
  /// **'Effacer la sélection'**
  String get mlClearSelection;

  /// No description provided for @mlCompareSelection.
  ///
  /// In fr, this message translates to:
  /// **'{count} / {max} sélectionnées'**
  String mlCompareSelection(int count, int max);

  /// No description provided for @mlCompareMax.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez comparer au maximum {max} expériences'**
  String mlCompareMax(int max);

  /// No description provided for @mlCompareSelect.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner {code} pour la comparaison'**
  String mlCompareSelect(String code);

  /// No description provided for @mlCompareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison'**
  String get mlCompareTitle;

  /// No description provided for @mlCompareValAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision de validation par époque'**
  String get mlCompareValAccuracy;

  /// No description provided for @mlCompareSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Courbes de précision de validation de {count} expériences superposées'**
  String mlCompareSemantics(int count);

  /// No description provided for @mlCompareMetric.
  ///
  /// In fr, this message translates to:
  /// **'Métrique'**
  String get mlCompareMetric;

  /// No description provided for @mlCompareBestHint.
  ///
  /// In fr, this message translates to:
  /// **'★ meilleure valeur de la ligne'**
  String get mlCompareBestHint;

  /// No description provided for @mlExperimentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Expérience {code}'**
  String mlExperimentTitle(String code);

  /// No description provided for @mlMetricAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Exactitude'**
  String get mlMetricAccuracy;

  /// No description provided for @mlMetricAccuracyVal.
  ///
  /// In fr, this message translates to:
  /// **'Exactitude (validation)'**
  String get mlMetricAccuracyVal;

  /// No description provided for @mlMetricPrecision.
  ///
  /// In fr, this message translates to:
  /// **'Précision'**
  String get mlMetricPrecision;

  /// No description provided for @mlMetricRecall.
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get mlMetricRecall;

  /// No description provided for @mlMetricF1.
  ///
  /// In fr, this message translates to:
  /// **'F1'**
  String get mlMetricF1;

  /// No description provided for @mlMetricParams.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get mlMetricParams;

  /// No description provided for @mlMetricSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get mlMetricSize;

  /// No description provided for @mlActionRegister.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer dans le registre'**
  String get mlActionRegister;

  /// No description provided for @mlRegisterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quantification pour le registre'**
  String get mlRegisterTitle;

  /// No description provided for @mlRegisterQueued.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement du modèle ajouté à la file'**
  String get mlRegisterQueued;

  /// No description provided for @mlChartAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Exactitude'**
  String get mlChartAccuracy;

  /// No description provided for @mlChartLoss.
  ///
  /// In fr, this message translates to:
  /// **'Perte'**
  String get mlChartLoss;

  /// No description provided for @mlChartLearningRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'apprentissage'**
  String get mlChartLearningRate;

  /// No description provided for @mlChartTrain.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement'**
  String get mlChartTrain;

  /// No description provided for @mlChartVal.
  ///
  /// In fr, this message translates to:
  /// **'Validation'**
  String get mlChartVal;

  /// No description provided for @mlChartNoData.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de données'**
  String get mlChartNoData;

  /// No description provided for @mlChartAccuracySemantics.
  ///
  /// In fr, this message translates to:
  /// **'Courbes d\'exactitude entraînement et validation sur {epochs} époques'**
  String mlChartAccuracySemantics(int epochs);

  /// No description provided for @mlChartLossSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Courbes de perte entraînement et validation sur {epochs} époques'**
  String mlChartLossSemantics(int epochs);

  /// No description provided for @mlChartLearningRateSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Évolution du taux d\'apprentissage sur {epochs} époques'**
  String mlChartLearningRateSemantics(int epochs);

  /// No description provided for @mlConfusionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Matrice de confusion'**
  String get mlConfusionTitle;

  /// No description provided for @mlConfusionPredicted.
  ///
  /// In fr, this message translates to:
  /// **'Classe prédite →'**
  String get mlConfusionPredicted;

  /// No description provided for @mlConfusionActual.
  ///
  /// In fr, this message translates to:
  /// **'Classe réelle ↓'**
  String get mlConfusionActual;

  /// No description provided for @mlConfusionCell.
  ///
  /// In fr, this message translates to:
  /// **'Réel {actual} → prédit {predicted} : {count}'**
  String mlConfusionCell(String actual, String predicted, int count);

  /// No description provided for @mlConfusionSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Matrice de confusion de {classes} classes : {correct} prédictions correctes sur {total} ({accuracy} %)'**
  String mlConfusionSemantics(
    int classes,
    int correct,
    int total,
    String accuracy,
  );

  /// No description provided for @mlPerClassTitle.
  ///
  /// In fr, this message translates to:
  /// **'Métriques par classe'**
  String get mlPerClassTitle;

  /// No description provided for @mlDataWarnings.
  ///
  /// In fr, this message translates to:
  /// **'Avertissements sur les données'**
  String get mlDataWarnings;

  /// No description provided for @mlArtifacts.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers produits'**
  String get mlArtifacts;

  /// No description provided for @mlConfigJson.
  ///
  /// In fr, this message translates to:
  /// **'Configuration (JSON)'**
  String get mlConfigJson;

  /// No description provided for @mlRegistrySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un seul modèle en production par langue. Promouvoir un modèle archive automatiquement l\'ancien.'**
  String get mlRegistrySubtitle;

  /// No description provided for @mlRegistryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Registre vide'**
  String get mlRegistryEmpty;

  /// No description provided for @mlRegistryEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les modèles évalués apparaissent ici après un entraînement avec enregistrement automatique ou depuis une expérience.'**
  String get mlRegistryEmptyMessage;

  /// No description provided for @mlRegistryLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue {language}'**
  String mlRegistryLanguage(String language);

  /// No description provided for @mlRegistryCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 modèle} other{{count} modèles}}'**
  String mlRegistryCount(int count);

  /// No description provided for @mlRegistryNoProduction.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle en production pour cette langue.'**
  String get mlRegistryNoProduction;

  /// No description provided for @mlClassesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 classe} other{{count} classes}}'**
  String mlClassesCount(int count);

  /// No description provided for @mlInputShape.
  ///
  /// In fr, this message translates to:
  /// **'Entrée {shape}'**
  String mlInputShape(String shape);

  /// No description provided for @mlTrainingDuration.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement : {duration}'**
  String mlTrainingDuration(String duration);

  /// No description provided for @mlPromotedOn.
  ///
  /// In fr, this message translates to:
  /// **'Promu le {date}'**
  String mlPromotedOn(String date);

  /// No description provided for @mlPipelineSemantics.
  ///
  /// In fr, this message translates to:
  /// **'Cycle de vie du modèle, étape actuelle : {stage}'**
  String mlPipelineSemantics(String stage);

  /// No description provided for @mlMetricKerasSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille Keras'**
  String get mlMetricKerasSize;

  /// No description provided for @mlMetricTfliteSize.
  ///
  /// In fr, this message translates to:
  /// **'Taille TFLite'**
  String get mlMetricTfliteSize;

  /// No description provided for @mlMetricTfliteLatency.
  ///
  /// In fr, this message translates to:
  /// **'Latence TFLite moy.'**
  String get mlMetricTfliteLatency;

  /// No description provided for @mlMetricTfliteAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Exactitude TFLite'**
  String get mlMetricTfliteAccuracy;

  /// No description provided for @mlMetricAgreement.
  ///
  /// In fr, this message translates to:
  /// **'Accord avec Keras'**
  String get mlMetricAgreement;

  /// No description provided for @mlMetricMobile.
  ///
  /// In fr, this message translates to:
  /// **'Compatible mobile'**
  String get mlMetricMobile;

  /// No description provided for @mlFlexRequired.
  ///
  /// In fr, this message translates to:
  /// **'délégué Flex requis'**
  String get mlFlexRequired;

  /// No description provided for @mlActionValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get mlActionValidate;

  /// No description provided for @mlActionStaging.
  ///
  /// In fr, this message translates to:
  /// **'Passer en staging'**
  String get mlActionStaging;

  /// No description provided for @mlActionRestoreStaging.
  ///
  /// In fr, this message translates to:
  /// **'Remettre en staging'**
  String get mlActionRestoreStaging;

  /// No description provided for @mlActionPromote.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir en production'**
  String get mlActionPromote;

  /// No description provided for @mlActionArchive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get mlActionArchive;

  /// No description provided for @mlActionConvert.
  ///
  /// In fr, this message translates to:
  /// **'Convertir en TFLite'**
  String get mlActionConvert;

  /// No description provided for @mlConvertTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quantification de la conversion'**
  String get mlConvertTitle;

  /// No description provided for @mlPromoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en production ({language}) ?'**
  String mlPromoteTitle(String language);

  /// No description provided for @mlPromoteMessage.
  ///
  /// In fr, this message translates to:
  /// **'La version {version} deviendra le modèle de production {language}. La version {current}, actuellement en production, sera archivée.'**
  String mlPromoteMessage(String version, String current, String language);

  /// No description provided for @mlPromoteMessageNoCurrent.
  ///
  /// In fr, this message translates to:
  /// **'La version {version} deviendra le modèle de production {language}.'**
  String mlPromoteMessageNoCurrent(String version, String language);

  /// No description provided for @mlArchiveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Archiver le modèle ?'**
  String get mlArchiveTitle;

  /// No description provided for @mlArchiveMessage.
  ///
  /// In fr, this message translates to:
  /// **'La version {version} ne sera plus proposée. Elle pourra être remise en staging plus tard.'**
  String mlArchiveMessage(String version);

  /// No description provided for @mlStageChanged.
  ///
  /// In fr, this message translates to:
  /// **'Modèle passé au stade {stage}'**
  String mlStageChanged(String stage);

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @teacherSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace enseignant'**
  String get teacherSpace;

  /// No description provided for @expertSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace expert'**
  String get expertSpace;

  /// No description provided for @teacherSpaceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos leçons et la progression des apprenants.'**
  String get teacherSpaceSubtitle;

  /// No description provided for @expertSpaceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Qualité du dictionnaire et contributions à relire.'**
  String get expertSpaceSubtitle;

  /// No description provided for @roleSpaceDeniedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cet espace est réservé au rôle correspondant. Demandez à un administrateur de vous l\'attribuer.'**
  String get roleSpaceDeniedMessage;

  /// No description provided for @wsMySpaces.
  ///
  /// In fr, this message translates to:
  /// **'Mes espaces'**
  String get wsMySpaces;

  /// No description provided for @wsAdminSpaceHint.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs, dictionnaire, modèles et configuration'**
  String get wsAdminSpaceHint;

  /// No description provided for @wsTeacherSpaceHint.
  ///
  /// In fr, this message translates to:
  /// **'Leçons, apprenants et statistiques'**
  String get wsTeacherSpaceHint;

  /// No description provided for @wsExpertSpaceHint.
  ///
  /// In fr, this message translates to:
  /// **'Dictionnaire, catégories et modération'**
  String get wsExpertSpaceHint;

  /// No description provided for @wsUnitsPublished.
  ///
  /// In fr, this message translates to:
  /// **'Unités publiées'**
  String get wsUnitsPublished;

  /// No description provided for @wsLessons.
  ///
  /// In fr, this message translates to:
  /// **'Leçons'**
  String get wsLessons;

  /// No description provided for @wsLearners.
  ///
  /// In fr, this message translates to:
  /// **'Apprenants'**
  String get wsLearners;

  /// No description provided for @wsCompletions7d.
  ///
  /// In fr, this message translates to:
  /// **'Leçons terminées (7 j) · {total} au total'**
  String wsCompletions7d(int total);

  /// No description provided for @wsAverageScore.
  ///
  /// In fr, this message translates to:
  /// **'Score moyen'**
  String get wsAverageScore;

  /// No description provided for @wsLessonStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques par leçon'**
  String get wsLessonStats;

  /// No description provided for @wsNoLessons.
  ///
  /// In fr, this message translates to:
  /// **'Aucune leçon'**
  String get wsNoLessons;

  /// No description provided for @wsNoLessonsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Créez des unités et des leçons depuis l\'onglet Apprentissage.'**
  String get wsNoLessonsMessage;

  /// No description provided for @wsLastCompletion.
  ///
  /// In fr, this message translates to:
  /// **'Dernière réussite : {date}'**
  String wsLastCompletion(String date);

  /// No description provided for @wsCompletionsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune réussite} =1{1 réussite} other{{count} réussites}}'**
  String wsCompletionsCount(int count);

  /// No description provided for @wsLearnersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun apprenant} =1{1 apprenant} other{{count} apprenants}}'**
  String wsLearnersCount(int count);

  /// No description provided for @wsReviewedByMe.
  ///
  /// In fr, this message translates to:
  /// **'Relues par moi'**
  String get wsReviewedByMe;

  /// No description provided for @wsSignsWithoutVideo.
  ///
  /// In fr, this message translates to:
  /// **'Signes sans vidéo'**
  String get wsSignsWithoutVideo;

  /// No description provided for @wsSignsWithoutCategory.
  ///
  /// In fr, this message translates to:
  /// **'Signes sans catégorie'**
  String get wsSignsWithoutCategory;

  /// No description provided for @wsByLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Par langue'**
  String get wsByLanguage;

  /// No description provided for @wsLanguageCounts.
  ///
  /// In fr, this message translates to:
  /// **'{signs} signes · {published} publiés'**
  String wsLanguageCounts(int signs, int published);

  /// No description provided for @dmPublished.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get dmPublished;

  /// No description provided for @dmDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get dmDraft;

  /// No description provided for @dmCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get dmCategories;

  /// No description provided for @dmImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer'**
  String get dmImport;

  /// No description provided for @dmUnpublish.
  ///
  /// In fr, this message translates to:
  /// **'Dépublier'**
  String get dmUnpublish;

  /// No description provided for @dmUnpublishConfirm.
  ///
  /// In fr, this message translates to:
  /// **'« {word} » ne sera plus visible dans le dictionnaire public. Continuer ?'**
  String dmUnpublishConfirm(String word);

  /// No description provided for @dmUnpublished.
  ///
  /// In fr, this message translates to:
  /// **'Signe dépublié'**
  String get dmUnpublished;

  /// No description provided for @dmPublishedDone.
  ///
  /// In fr, this message translates to:
  /// **'Signe publié'**
  String get dmPublishedDone;

  /// No description provided for @dmPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get dmPublish;

  /// No description provided for @dmInvalidUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL invalide (http ou https attendu)'**
  String get dmInvalidUrl;

  /// No description provided for @dmFileTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux (max {mb} Mo)'**
  String dmFileTooLarge(int mb);

  /// No description provided for @dmDuplicateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signe déjà présent'**
  String get dmDuplicateTitle;

  /// No description provided for @dmDuplicateMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un signe « {word} » existe déjà pour cette langue. L\'enregistrer quand même ?'**
  String dmDuplicateMessage(String word);

  /// No description provided for @dmUploadVideo.
  ///
  /// In fr, this message translates to:
  /// **'Téléverser une vidéo'**
  String get dmUploadVideo;

  /// No description provided for @dmUploadImage.
  ///
  /// In fr, this message translates to:
  /// **'Téléverser une image'**
  String get dmUploadImage;

  /// No description provided for @dmLanguageRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une langue'**
  String get dmLanguageRequired;

  /// No description provided for @dmThumbnailUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de la miniature'**
  String get dmThumbnailUrl;

  /// No description provided for @dmExampleSentence.
  ///
  /// In fr, this message translates to:
  /// **'Phrase d\'exemple'**
  String get dmExampleSentence;

  /// No description provided for @dmTags.
  ///
  /// In fr, this message translates to:
  /// **'Mots-clés'**
  String get dmTags;

  /// No description provided for @dmTagsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Séparés par des virgules'**
  String get dmTagsHelp;

  /// No description provided for @dmPublishedHelp.
  ///
  /// In fr, this message translates to:
  /// **'Visible dans le dictionnaire public'**
  String get dmPublishedHelp;

  /// No description provided for @dmNoVideo.
  ///
  /// In fr, this message translates to:
  /// **'Sans vidéo'**
  String get dmNoVideo;

  /// No description provided for @dmNewCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get dmNewCategory;

  /// No description provided for @dmRenameCategory.
  ///
  /// In fr, this message translates to:
  /// **'Renommer la catégorie'**
  String get dmRenameCategory;

  /// No description provided for @dmCategoryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie'**
  String get dmCategoryName;

  /// No description provided for @dmCategoryNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire'**
  String get dmCategoryNameRequired;

  /// No description provided for @dmCategoryExists.
  ///
  /// In fr, this message translates to:
  /// **'La catégorie « {name} » existe déjà'**
  String dmCategoryExists(String name);

  /// No description provided for @dmCategorySaved.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie enregistrée'**
  String get dmCategorySaved;

  /// No description provided for @dmDeleteCategory.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la catégorie'**
  String get dmDeleteCategory;

  /// No description provided for @dmDeleteCategoryConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ? {count, plural, =0{Aucun signe n\'y est rattaché.} =1{1 signe perdra sa catégorie.} other{{count} signes perdront leur catégorie.}}'**
  String dmDeleteCategoryConfirm(String name, int count);

  /// No description provided for @dmCategoryDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie supprimée'**
  String get dmCategoryDeleted;

  /// No description provided for @dmChooseLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue des signes'**
  String get dmChooseLanguage;

  /// No description provided for @dmNoCategories.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie pour cette langue'**
  String get dmNoCategories;

  /// No description provided for @dmApiRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'import passe par l\'API MooMoo, qui ne répond pas. Démarrez le serveur backend puis réessayez.'**
  String get dmApiRequired;

  /// No description provided for @dmImportConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lancer l\'import ?'**
  String get dmImportConfirmTitle;

  /// No description provided for @dmImportConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'{count} signe(s) seront enregistrés en « {status} ». {errors} ligne(s) en erreur seront ignorées.'**
  String dmImportConfirmMessage(int count, int errors, String status);

  /// No description provided for @dmImportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer des signes'**
  String get dmImportTitle;

  /// No description provided for @dmImportPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get dmImportPreview;

  /// No description provided for @dmImportReport.
  ///
  /// In fr, this message translates to:
  /// **'Rapport'**
  String get dmImportReport;

  /// No description provided for @dmAnalyse.
  ///
  /// In fr, this message translates to:
  /// **'Analyser'**
  String get dmAnalyse;

  /// No description provided for @dmReanalyse.
  ///
  /// In fr, this message translates to:
  /// **'Réanalyser'**
  String get dmReanalyse;

  /// No description provided for @dmDefaultLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue par défaut'**
  String get dmDefaultLanguage;

  /// No description provided for @dmDefaultLanguageHelp.
  ///
  /// In fr, this message translates to:
  /// **'Utilisée quand une ligne n\'indique pas de langue'**
  String get dmDefaultLanguageHelp;

  /// No description provided for @dmNoDefaultLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune (la langue doit figurer dans le fichier)'**
  String get dmNoDefaultLanguage;

  /// No description provided for @dmCreateCategories.
  ///
  /// In fr, this message translates to:
  /// **'Créer les catégories manquantes'**
  String get dmCreateCategories;

  /// No description provided for @dmFetchMedia.
  ///
  /// In fr, this message translates to:
  /// **'Récupérer les médias'**
  String get dmFetchMedia;

  /// No description provided for @dmFetchMediaHelp.
  ///
  /// In fr, this message translates to:
  /// **'Télécharge les vidéos et images depuis leurs URL publiques et les stocke dans MooMoo. En cas d\'échec, l\'URL d\'origine est conservée.'**
  String get dmFetchMediaHelp;

  /// No description provided for @dmPublishImported.
  ///
  /// In fr, this message translates to:
  /// **'Publier directement'**
  String get dmPublishImported;

  /// No description provided for @dmDuplicatesStrategy.
  ///
  /// In fr, this message translates to:
  /// **'Doublons existants'**
  String get dmDuplicatesStrategy;

  /// No description provided for @dmSkipDuplicates.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get dmSkipDuplicates;

  /// No description provided for @dmUpdateDuplicates.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get dmUpdateDuplicates;

  /// No description provided for @dmImportHelp.
  ///
  /// In fr, this message translates to:
  /// **'Formats acceptés : CSV, TSV, JSON, NDJSON, XML (10 Mo max). Les champs sont détectés automatiquement ; vous pourrez ajuster la correspondance avant l\'import. Aucune donnée manquante n\'est inventée.'**
  String get dmImportHelp;

  /// No description provided for @dmChooseFile.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get dmChooseFile;

  /// No description provided for @dmFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get dmFormat;

  /// No description provided for @dmRecordsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} enregistrement(s)'**
  String dmRecordsCount(int count);

  /// No description provided for @dmTruncated.
  ///
  /// In fr, this message translates to:
  /// **'Limité à {max} lignes'**
  String dmTruncated(int max);

  /// No description provided for @dmMapping.
  ///
  /// In fr, this message translates to:
  /// **'Correspondance des champs'**
  String get dmMapping;

  /// No description provided for @dmMappingHelp.
  ///
  /// In fr, this message translates to:
  /// **'Associez chaque champ MooMoo à une colonne du fichier.'**
  String get dmMappingHelp;

  /// No description provided for @dmIgnoreField.
  ///
  /// In fr, this message translates to:
  /// **'— Ignorer —'**
  String get dmIgnoreField;

  /// No description provided for @dmOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get dmOptions;

  /// No description provided for @dmReanalyseHint.
  ///
  /// In fr, this message translates to:
  /// **'La correspondance ou les options ont changé : réanalysez avant d\'importer.'**
  String get dmReanalyseHint;

  /// No description provided for @dmValidCount.
  ///
  /// In fr, this message translates to:
  /// **'Valides ({count})'**
  String dmValidCount(int count);

  /// No description provided for @dmDuplicateCount.
  ///
  /// In fr, this message translates to:
  /// **'Doublons ({count})'**
  String dmDuplicateCount(int count);

  /// No description provided for @dmErrorCount.
  ///
  /// In fr, this message translates to:
  /// **'Erreurs ({count})'**
  String dmErrorCount(int count);

  /// No description provided for @dmCategoriesToCreate.
  ///
  /// In fr, this message translates to:
  /// **'Catégories à créer : {names}'**
  String dmCategoriesToCreate(String names);

  /// No description provided for @dmMoreRows.
  ///
  /// In fr, this message translates to:
  /// **'… et {count} autre(s) ligne(s)'**
  String dmMoreRows(int count);

  /// No description provided for @dmReportImported.
  ///
  /// In fr, this message translates to:
  /// **'{count} importé(s)'**
  String dmReportImported(int count);

  /// No description provided for @dmReportUpdated.
  ///
  /// In fr, this message translates to:
  /// **'{count} mis à jour'**
  String dmReportUpdated(int count);

  /// No description provided for @dmReportSkipped.
  ///
  /// In fr, this message translates to:
  /// **'{count} ignoré(s)'**
  String dmReportSkipped(int count);

  /// No description provided for @dmReportRejected.
  ///
  /// In fr, this message translates to:
  /// **'{count} rejeté(s)'**
  String dmReportRejected(int count);

  /// No description provided for @dmReportMedia.
  ///
  /// In fr, this message translates to:
  /// **'Médias : {fetched} récupéré(s), {failed} échec(s)'**
  String dmReportMedia(int fetched, int failed);

  /// No description provided for @dmCategoriesCreated.
  ///
  /// In fr, this message translates to:
  /// **'Catégories créées : {names}'**
  String dmCategoriesCreated(String names);

  /// No description provided for @dmReportAllGood.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les lignes ont été traitées sans avertissement.'**
  String get dmReportAllGood;

  /// No description provided for @dmLine.
  ///
  /// In fr, this message translates to:
  /// **'Ligne {line}'**
  String dmLine(int line);

  /// No description provided for @dmStatusValid.
  ///
  /// In fr, this message translates to:
  /// **'Valide'**
  String get dmStatusValid;

  /// No description provided for @dmStatusDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Doublon'**
  String get dmStatusDuplicate;

  /// No description provided for @dmStatusError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get dmStatusError;

  /// No description provided for @dmHasVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get dmHasVideo;

  /// No description provided for @cfgIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Identité de l\'application'**
  String get cfgIdentity;

  /// No description provided for @cfgAppName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'application'**
  String get cfgAppName;

  /// No description provided for @cfgAppNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire'**
  String get cfgAppNameRequired;

  /// No description provided for @cfgLogo.
  ///
  /// In fr, this message translates to:
  /// **'Logo'**
  String get cfgLogo;

  /// No description provided for @cfgChangeLogo.
  ///
  /// In fr, this message translates to:
  /// **'Changer le logo'**
  String get cfgChangeLogo;

  /// No description provided for @cfgDefaultLogo.
  ///
  /// In fr, this message translates to:
  /// **'Logo par défaut'**
  String get cfgDefaultLogo;

  /// No description provided for @cfgLogoHelp.
  ///
  /// In fr, this message translates to:
  /// **'PNG, JPG, WebP ou GIF, 2 Mo max. Idéalement carré.'**
  String get cfgLogoHelp;

  /// No description provided for @cfgSupportEmail.
  ///
  /// In fr, this message translates to:
  /// **'E-mail de support'**
  String get cfgSupportEmail;

  /// No description provided for @cfgSupportEmailHelp.
  ///
  /// In fr, this message translates to:
  /// **'Adresse affichée aux utilisateurs pour nous contacter'**
  String get cfgSupportEmailHelp;

  /// No description provided for @cfgInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get cfgInvalidEmail;

  /// No description provided for @cfgMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'Mode maintenance'**
  String get cfgMaintenance;

  /// No description provided for @cfgMaintenanceEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Activer la maintenance'**
  String get cfgMaintenanceEnabled;

  /// No description provided for @cfgMaintenanceHelp.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les administrateurs peuvent utiliser l\'application ; les écritures des autres comptes sont refusées par le serveur.'**
  String get cfgMaintenanceHelp;

  /// No description provided for @cfgMaintenanceMessage.
  ///
  /// In fr, this message translates to:
  /// **'Message affiché pendant la maintenance'**
  String get cfgMaintenanceMessage;

  /// No description provided for @cfgMaintenanceOnTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer la maintenance ?'**
  String get cfgMaintenanceOnTitle;

  /// No description provided for @cfgMaintenanceOnMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tous les utilisateurs non administrateurs perdront immédiatement l\'accès à l\'application.'**
  String get cfgMaintenanceOnMessage;

  /// No description provided for @cfgMaintenanceOffTitle.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la maintenance ?'**
  String get cfgMaintenanceOffTitle;

  /// No description provided for @cfgMaintenanceOffMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'application redeviendra accessible à tous les utilisateurs.'**
  String get cfgMaintenanceOffMessage;

  /// No description provided for @cfgDefaults.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres par défaut'**
  String get cfgDefaults;

  /// No description provided for @cfgDefaultSignLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue des signes par défaut'**
  String get cfgDefaultSignLanguage;

  /// No description provided for @cfgNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get cfgNone;

  /// No description provided for @cfgContributionsEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Contributions ouvertes'**
  String get cfgContributionsEnabled;

  /// No description provided for @cfgContributionsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Autorise les utilisateurs à proposer de nouveaux signes'**
  String get cfgContributionsHelp;

  /// No description provided for @cfgSaved.
  ///
  /// In fr, this message translates to:
  /// **'Configuration enregistrée'**
  String get cfgSaved;

  /// No description provided for @cfgSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible'**
  String get cfgSaveError;

  /// No description provided for @cfgLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la configuration'**
  String get cfgLoadError;

  /// No description provided for @accountSuspendedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte a été banni'**
  String get accountSuspendedTitle;

  /// No description provided for @accountSuspendedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un administrateur a banni votre compte : vous n\'avez plus accès à l\'application. Pour comprendre pourquoi, ou si vous pensez qu\'il s\'agit d\'une erreur, contactez l\'administrateur.'**
  String get accountSuspendedMessage;

  /// No description provided for @accountSuspendedReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif : {reason}'**
  String accountSuspendedReason(String reason);

  /// No description provided for @accountSuspendedAck.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get accountSuspendedAck;

  /// No description provided for @appealContactAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Contacter l\'administrateur'**
  String get appealContactAdmin;

  /// No description provided for @appealFormIntro.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez votre situation. Un administrateur examinera votre demande et vous répondra par e-mail.'**
  String get appealFormIntro;

  /// No description provided for @appealEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre adresse e-mail'**
  String get appealEmailLabel;

  /// No description provided for @appealMessageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre message'**
  String get appealMessageLabel;

  /// No description provided for @appealMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, je souhaite comprendre pourquoi mon compte a été banni…'**
  String get appealMessageHint;

  /// No description provided for @appealMessageTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Écrivez au moins 10 caractères.'**
  String get appealMessageTooShort;

  /// No description provided for @appealSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get appealSend;

  /// No description provided for @appealBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get appealBack;

  /// No description provided for @appealSentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Message envoyé'**
  String get appealSentTitle;

  /// No description provided for @appealSentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un administrateur va examiner votre demande et vous répondra à l\'adresse {email}.'**
  String appealSentMessage(String email);

  /// No description provided for @appealSendFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le message n\'a pas pu être envoyé. Vérifiez votre connexion puis réessayez.'**
  String get appealSendFailed;

  /// No description provided for @appealBadge.
  ///
  /// In fr, this message translates to:
  /// **'Recours'**
  String get appealBadge;

  /// No description provided for @appealView.
  ///
  /// In fr, this message translates to:
  /// **'Voir le recours'**
  String get appealView;

  /// No description provided for @appealDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recours de {name}'**
  String appealDialogTitle(String name);

  /// No description provided for @appealReplyTo.
  ///
  /// In fr, this message translates to:
  /// **'Répondre à : {email}'**
  String appealReplyTo(String email);

  /// No description provided for @appealResolve.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme traité'**
  String get appealResolve;

  /// No description provided for @appealResolved.
  ///
  /// In fr, this message translates to:
  /// **'Recours marqué comme traité'**
  String get appealResolved;

  /// No description provided for @authAccountSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte est suspendu. Contactez le support si vous pensez que c\'est une erreur.'**
  String get authAccountSuspended;

  /// No description provided for @maintenanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Maintenance en cours'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceDefaultMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'application est momentanément indisponible. Merci de réessayer un peu plus tard.'**
  String get maintenanceDefaultMessage;

  /// No description provided for @maintenanceAdminLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion administrateur'**
  String get maintenanceAdminLogin;

  /// No description provided for @contributionsClosed.
  ///
  /// In fr, this message translates to:
  /// **'Les contributions sont momentanément fermées. Vous pouvez toujours consulter vos propositions ci-dessous.'**
  String get contributionsClosed;

  /// No description provided for @errNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre accès à Internet puis réessayez.'**
  String get errNetwork;

  /// No description provided for @errServiceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le service est momentanément indisponible. Réessayez dans quelques instants.'**
  String get errServiceUnavailable;

  /// No description provided for @errMaintenance.
  ///
  /// In fr, this message translates to:
  /// **'L\'application est en maintenance. Merci de réessayer un peu plus tard.'**
  String get errMaintenance;

  /// No description provided for @errSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Reconnectez-vous pour continuer.'**
  String get errSessionExpired;

  /// No description provided for @errPermission.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas les droits nécessaires pour cette action.'**
  String get errPermission;

  /// No description provided for @errNotFound.
  ///
  /// In fr, this message translates to:
  /// **'L\'élément demandé est introuvable ou n\'existe plus.'**
  String get errNotFound;

  /// No description provided for @errConflict.
  ///
  /// In fr, this message translates to:
  /// **'Cet élément existe déjà.'**
  String get errConflict;

  /// No description provided for @errTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier est trop volumineux.'**
  String get errTooLarge;

  /// No description provided for @errUnsupportedFormat.
  ///
  /// In fr, this message translates to:
  /// **'Ce format de fichier n\'est pas pris en charge.'**
  String get errUnsupportedFormat;

  /// No description provided for @errInvalidData.
  ///
  /// In fr, this message translates to:
  /// **'Certaines informations sont invalides. Vérifiez-les puis réessayez.'**
  String get errInvalidData;

  /// No description provided for @errUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue. Réessayez plus tard.'**
  String get errUnknown;

  /// No description provided for @errTechnicalDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail technique (admin) : {detail}'**
  String errTechnicalDetail(String detail);

  /// No description provided for @errCamera.
  ///
  /// In fr, this message translates to:
  /// **'La caméra n\'est pas accessible. Autorisez son accès dans les réglages de votre appareil ou de votre navigateur.'**
  String get errCamera;

  /// No description provided for @authUnknownError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vous connecter pour l\'instant. Réessayez plus tard.'**
  String get authUnknownError;

  /// No description provided for @accountAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get accountAddPhoto;

  /// No description provided for @accountPhotoRules.
  ///
  /// In fr, this message translates to:
  /// **'JPG, PNG, WebP, GIF ou BMP. La photo est redimensionnée automatiquement.'**
  String get accountPhotoRules;

  /// No description provided for @accountPhotoSending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi de la photo…'**
  String get accountPhotoSending;

  /// No description provided for @accountPhotoPickError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'image. Essayez avec un autre fichier.'**
  String get accountPhotoPickError;

  /// No description provided for @accountPhotoTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Cette image dépasse 25 Mo. Choisissez une image plus légère.'**
  String get accountPhotoTooLarge;

  /// No description provided for @accountPhotoBadFormat.
  ///
  /// In fr, this message translates to:
  /// **'Cette image n\'a pas pu être lue. Utilisez une photo JPG, PNG, WebP, GIF ou BMP.'**
  String get accountPhotoBadFormat;

  /// No description provided for @accountPhotoUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil mise à jour.'**
  String get accountPhotoUpdated;

  /// No description provided for @accountPhotoUploadError.
  ///
  /// In fr, this message translates to:
  /// **'La photo n\'a pas pu être envoyée. Réessayez.'**
  String get accountPhotoUploadError;

  /// No description provided for @accountRemovePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get accountRemovePhoto;

  /// No description provided for @accountRemovePhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo de profil ?'**
  String get accountRemovePhotoTitle;

  /// No description provided for @accountRemovePhotoMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vos initiales seront affichées à la place.'**
  String get accountRemovePhotoMessage;

  /// No description provided for @accountPhotoRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil supprimée.'**
  String get accountPhotoRemoved;

  /// No description provided for @accountPhotoRemoveError.
  ///
  /// In fr, this message translates to:
  /// **'La photo n\'a pas pu être supprimée. Réessayez.'**
  String get accountPhotoRemoveError;

  /// No description provided for @userGuide.
  ///
  /// In fr, this message translates to:
  /// **'Guide utilisateur'**
  String get userGuide;

  /// No description provided for @guideHeroTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans MooMoo'**
  String get guideHeroTitle;

  /// No description provided for @guideHeroBody.
  ///
  /// In fr, this message translates to:
  /// **'Ce guide présente, étape par étape, tout ce que vous pouvez faire dans l\'application : traduire, explorer le dictionnaire, apprendre la langue des signes et gérer votre compte.'**
  String get guideHeroBody;

  /// No description provided for @guideContents.
  ///
  /// In fr, this message translates to:
  /// **'Sommaire'**
  String get guideContents;

  /// No description provided for @guideOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir : {section}'**
  String guideOpen(String section);

  /// No description provided for @guideMoreHelpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Besoin d\'aide supplémentaire ?'**
  String get guideMoreHelpTitle;

  /// No description provided for @guideMoreHelpBody.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les questions fréquentes ou écrivez à l\'équipe depuis le centre d\'aide.'**
  String get guideMoreHelpBody;

  /// No description provided for @guideAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get guideAccountTitle;

  /// No description provided for @guideAccountIntro.
  ///
  /// In fr, this message translates to:
  /// **'Un compte permet de sauvegarder vos favoris, votre progression et votre historique.'**
  String get guideAccountIntro;

  /// No description provided for @guideAccountSteps.
  ///
  /// In fr, this message translates to:
  /// **'Sur l\'écran d\'accueil, choisissez « Créer un compte ».\nRenseignez votre nom, votre adresse e-mail et un mot de passe.\nSi un e-mail de confirmation vous est envoyé, ouvrez le lien qu\'il contient.\nVous pouvez ensuite compléter votre profil à tout moment.'**
  String get guideAccountSteps;

  /// No description provided for @guideLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get guideLoginTitle;

  /// No description provided for @guideLoginIntro.
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez vos données sur tous vos appareils.'**
  String get guideLoginIntro;

  /// No description provided for @guideLoginSteps.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre adresse e-mail et votre mot de passe, puis validez.\nMot de passe oublié ? Touchez « Mot de passe oublié » pour recevoir un lien de réinitialisation par e-mail.\nPour vous déconnecter, ouvrez votre profil puis « Se déconnecter ».'**
  String get guideLoginSteps;

  /// No description provided for @guideNavigationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se repérer dans l\'application'**
  String get guideNavigationTitle;

  /// No description provided for @guideNavigationIntro.
  ///
  /// In fr, this message translates to:
  /// **'La barre de navigation donne accès aux quatre espaces principaux.'**
  String get guideNavigationIntro;

  /// No description provided for @guideNavigationSteps.
  ///
  /// In fr, this message translates to:
  /// **'Accueil : raccourcis et suggestions du jour.\nDico : le dictionnaire des signes.\nApprendre : votre parcours de leçons.\nTraduire : la traduction entre signes et texte.\nProfil : sur téléphone, le dernier onglet de la barre du bas ; sur ordinateur et tablette, votre photo en haut à droite.\nSur téléphone, le bouton rond au centre de la barre du bas ouvre la traduction ; touchez-le à nouveau pour démarrer ou arrêter la capture.'**
  String get guideNavigationSteps;

  /// No description provided for @guideTranslateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Traduire'**
  String get guideTranslateTitle;

  /// No description provided for @guideTranslateIntro.
  ///
  /// In fr, this message translates to:
  /// **'Traduisez des signes en texte, ou du texte en signes.'**
  String get guideTranslateIntro;

  /// No description provided for @guideTranslateSteps.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez l\'onglet Traduire et choisissez le sens de traduction.\nSignes vers texte : autorisez l\'accès à la caméra, placez-vous bien éclairé et cadré, puis signez.\nTexte vers signes : saisissez ou dictez une phrase pour voir les signes correspondants.\nSi la reconnaissance est momentanément indisponible, un message vous l\'indique : réessayez un peu plus tard.'**
  String get guideTranslateSteps;

  /// No description provided for @guideDictionaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Dictionnaire'**
  String get guideDictionaryTitle;

  /// No description provided for @guideDictionaryIntro.
  ///
  /// In fr, this message translates to:
  /// **'Explorez les signes par recherche ou par catégorie.'**
  String get guideDictionaryIntro;

  /// No description provided for @guideDictionarySteps.
  ///
  /// In fr, this message translates to:
  /// **'Tapez un mot dans la barre de recherche ou parcourez les catégories.\nTouchez un signe pour voir sa vidéo et sa description.\nAjoutez-le à vos favoris pour le retrouver facilement depuis votre profil.'**
  String get guideDictionarySteps;

  /// No description provided for @guideLearningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre'**
  String get guideLearningTitle;

  /// No description provided for @guideLearningIntro.
  ///
  /// In fr, this message translates to:
  /// **'Progressez à votre rythme grâce à des leçons courtes.'**
  String get guideLearningIntro;

  /// No description provided for @guideLearningSteps.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez l\'onglet Apprendre pour voir votre parcours.\nChoisissez la leçon disponible et suivez les exercices jusqu\'au bout.\nVotre progression est enregistrée automatiquement.\nConsultez vos statistiques depuis l\'écran de progression.'**
  String get guideLearningSteps;

  /// No description provided for @guideProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil et photo'**
  String get guideProfileTitle;

  /// No description provided for @guideProfileIntro.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisez les informations visibles sur votre compte.'**
  String get guideProfileIntro;

  /// No description provided for @guideProfileSteps.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez votre profil puis « Modifier le profil ».\nTouchez « Ajouter une photo » ou « Changer la photo » et choisissez une image (JPG, PNG, WebP, GIF ou BMP).\nElle est recadrée à la bonne taille automatiquement, même s\'il s\'agit d\'une grande photo d\'appareil.\nLa photo est enregistrée et affichée immédiatement.\nPour la retirer, touchez « Supprimer la photo » puis confirmez.\nN\'oubliez pas d\'enregistrer vos autres modifications.'**
  String get guideProfileSteps;

  /// No description provided for @guideHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get guideHistoryTitle;

  /// No description provided for @guideHistoryIntro.
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez vos traductions précédentes.'**
  String get guideHistoryIntro;

  /// No description provided for @guideHistorySteps.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez votre profil puis « Historique des traductions ».\nParcourez vos traductions récentes, de la plus récente à la plus ancienne.\nL\'historique est lié à votre compte : connectez-vous pour le retrouver.'**
  String get guideHistorySteps;

  /// No description provided for @guideSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get guideSettingsTitle;

  /// No description provided for @guideSettingsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Adaptez l\'application à vos préférences.'**
  String get guideSettingsIntro;

  /// No description provided for @guideSettingsSteps.
  ///
  /// In fr, this message translates to:
  /// **'Thème clair ou sombre et langue de l\'application.\nLangue des signes utilisée pour la traduction et le dictionnaire.\nVue par défaut et réglages du personnage 3D.\nOptions d\'accessibilité et sécurité du compte (changement de mot de passe).'**
  String get guideSettingsSteps;

  /// No description provided for @guideRolesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rôles'**
  String get guideRolesTitle;

  /// No description provided for @guideRolesIntro.
  ///
  /// In fr, this message translates to:
  /// **'Certaines fonctions dépendent du rôle attribué à votre compte.'**
  String get guideRolesIntro;

  /// No description provided for @guideRolesSteps.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur : traduire, consulter le dictionnaire, apprendre et proposer des signes.\nEnseignant : gérer les contenus d\'apprentissage depuis son espace.\nExpert : vérifier les signes et les contributions proposées.\nAdministrateur : gérer les utilisateurs, le dictionnaire et les réglages de l\'application.\nVos espaces disponibles apparaissent dans votre profil.'**
  String get guideRolesSteps;

  /// No description provided for @guideErrorsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreurs courantes'**
  String get guideErrorsTitle;

  /// No description provided for @guideErrorsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Que faire si quelque chose ne fonctionne pas ?'**
  String get guideErrorsIntro;

  /// No description provided for @guideErrorsSteps.
  ///
  /// In fr, this message translates to:
  /// **'« Connexion impossible » : vérifiez votre accès à Internet puis réessayez.\n« Session expirée » : reconnectez-vous.\n« Caméra non accessible » : autorisez la caméra dans les réglages de l\'appareil ou du navigateur.\n« Image trop volumineuse ou format non pris en charge » : choisissez une image JPG, PNG ou WebP de moins de 2 Mo.\n« Maintenance en cours » : l\'application revient bientôt, réessayez plus tard.\nLe problème persiste ? Contactez-nous depuis le centre d\'aide.'**
  String get guideErrorsSteps;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
