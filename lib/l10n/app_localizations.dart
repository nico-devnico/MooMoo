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
