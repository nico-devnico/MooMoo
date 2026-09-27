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

  /// No description provided for @deleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteAccount;

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
  /// **'Comment devenir admin'**
  String get adminHowToGrant;

  /// No description provided for @adminHowToGrantBody.
  ///
  /// In fr, this message translates to:
  /// **'Définissez is_admin = true sur le profil dans Supabase, ou role = admin dans les métadonnées utilisateur. Un admin peut ensuite promouvoir d\'autres comptes depuis cet écran.'**
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
