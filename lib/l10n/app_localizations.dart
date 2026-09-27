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

  /// No description provided for @translModelAlt.
  ///
  /// In fr, this message translates to:
  /// **'Avatar 3D de traduction en langue des signes'**
  String get translModelAlt;

  /// No description provided for @adminLearningForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Réservé aux administrateurs, enseignants et experts en langue des signes.'**
  String get adminLearningForbidden;
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
