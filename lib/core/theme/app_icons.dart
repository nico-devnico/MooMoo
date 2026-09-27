import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// The app's icon vocabulary.
///
/// Every icon comes from Phosphor so the whole product shares one drawing
/// style and one stroke weight. Screens reference these names rather than the
/// package directly: that keeps the meaning in the call site and makes a
/// future restyle a single-file change.
///
/// Regular is the default weight. Fill is reserved for the selected state of
/// navigation, where the extra mass is what signals "you are here".
class AppIcons {
  AppIcons._();

  // Navigation
  static const IconData home = PhosphorIconsRegular.house;
  static const IconData homeActive = PhosphorIconsFill.house;
  static const IconData translate = PhosphorIconsRegular.translate;
  static const IconData translateActive = PhosphorIconsFill.translate;
  static const IconData dictionary = PhosphorIconsRegular.bookOpen;
  static const IconData dictionaryActive = PhosphorIconsFill.bookOpen;
  static const IconData learning = PhosphorIconsRegular.graduationCap;
  static const IconData learningActive = PhosphorIconsFill.graduationCap;
  static const IconData profile = PhosphorIconsRegular.user;
  static const IconData profileActive = PhosphorIconsFill.user;

  // Actions
  static const IconData add = PhosphorIconsRegular.plus;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData delete = PhosphorIconsRegular.trash;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData filter = PhosphorIconsRegular.funnel;
  static const IconData close = PhosphorIconsRegular.x;
  static const IconData back = PhosphorIconsRegular.arrowLeft;
  static const IconData forward = PhosphorIconsRegular.arrowRight;
  static const IconData chevron = PhosphorIconsRegular.caretRight;
  static const IconData upload = PhosphorIconsRegular.uploadSimple;
  static const IconData download = PhosphorIconsRegular.downloadSimple;
  static const IconData share = PhosphorIconsRegular.shareNetwork;
  static const IconData refresh = PhosphorIconsRegular.arrowsClockwise;
  static const IconData play = PhosphorIconsRegular.play;
  static const IconData stop = PhosphorIconsRegular.stop;

  // Status and feedback
  static const IconData success = PhosphorIconsRegular.checkCircle;
  static const IconData check = PhosphorIconsRegular.check;
  static const IconData warning = PhosphorIconsRegular.warning;
  static const IconData error = PhosphorIconsRegular.warningCircle;
  static const IconData info = PhosphorIconsRegular.info;
  static const IconData blocked = PhosphorIconsRegular.prohibit;
  static const IconData locked = PhosphorIconsRegular.lock;
  static const IconData empty = PhosphorIconsRegular.tray;

  // Content
  static const IconData favorite = PhosphorIconsRegular.heart;
  static const IconData favoriteActive = PhosphorIconsFill.heart;
  static const IconData bookmark = PhosphorIconsRegular.bookmarkSimple;
  static const IconData notification = PhosphorIconsRegular.bell;
  static const IconData settings = PhosphorIconsRegular.gear;
  static const IconData history = PhosphorIconsRegular.clockCounterClockwise;
  static const IconData language = PhosphorIconsRegular.globe;
  static const IconData grid = PhosphorIconsRegular.squaresFour;
  static const IconData list = PhosphorIconsRegular.list;
  static const IconData image = PhosphorIconsRegular.image;
  static const IconData video = PhosphorIconsRegular.videoCamera;
  static const IconData camera = PhosphorIconsRegular.camera;
  static const IconData keyboard = PhosphorIconsRegular.keyboard;
  static const IconData microphone = PhosphorIconsRegular.microphone;
  static const IconData speaker = PhosphorIconsRegular.speakerHigh;
  static const IconData signLanguage = PhosphorIconsRegular.handWaving;

  // Learning
  static const IconData lesson = PhosphorIconsRegular.bookBookmark;
  static const IconData exercise = PhosphorIconsRegular.listChecks;
  static const IconData streak = PhosphorIconsRegular.fire;
  static const IconData streakActive = PhosphorIconsFill.fire;
  static const IconData points = PhosphorIconsRegular.star;
  static const IconData pointsActive = PhosphorIconsFill.star;
  static const IconData trophy = PhosphorIconsFill.trophy;
  static const IconData checkBold = PhosphorIconsBold.check;
  static const IconData xBold = PhosphorIconsBold.x;
  static const IconData goal = PhosphorIconsRegular.target;
  static const IconData achievement = PhosphorIconsRegular.sparkle;
  static const IconData progress = PhosphorIconsRegular.chartLine;

  // Administration
  static const IconData admin = PhosphorIconsRegular.shieldCheck;
  static const IconData users = PhosphorIconsRegular.users;
  static const IconData userAdd = PhosphorIconsRegular.userPlus;
  static const IconData userSuspend = PhosphorIconsRegular.userMinus;
  static const IconData roles = PhosphorIconsRegular.userGear;
  static const IconData moderation = PhosphorIconsRegular.notePencil;
  static const IconData model = PhosphorIconsRegular.cpu;
  static const IconData dashboard = PhosphorIconsRegular.chartBar;
  static const IconData database = PhosphorIconsRegular.database;
  static const IconData logout = PhosphorIconsRegular.signOut;

  /// Resolves an icon stored in the database, e.g. `sign_categories.icon_name`.
  ///
  /// Accepts the Phosphor name in kebab-case, snake_case or camelCase so the
  /// column can be filled from any of the usual sources. Unknown names fall
  /// back rather than throwing: a typo in a content row must never break a
  /// screen.
  static IconData fromName(String? name, {IconData fallback = bookmark}) {
    if (name == null || name.trim().isEmpty) return fallback;
    final key = name.trim().toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');
    return _byName[key] ?? fallback;
  }

  /// Names offered by content editors when they pick an icon, one per
  /// drawing (the map below also holds plural aliases).
  static const List<String> editorChoices = [
    'hand-waving',
    'alphabet',
    'numbers',
    'family',
    'food',
    'drink',
    'animal',
    'nature',
    'weather',
    'time',
    'calendar',
    'colors',
    'school',
    'work',
    'travel',
    'health',
    'sport',
    'music',
    'money',
    'emotions',
    'body',
    'transport',
    'places',
    'verbs',
    'question',
    'chat',
    'house',
    'heart',
    'star',
    'flag',
  ];

  static final Map<String, IconData> _byName = {
    'hand': PhosphorIconsRegular.hand,
    'handwaving': PhosphorIconsRegular.handWaving,
    'handshake': PhosphorIconsRegular.handshake,
    'heart': PhosphorIconsRegular.heart,
    'star': PhosphorIconsRegular.star,
    'house': PhosphorIconsRegular.house,
    'home': PhosphorIconsRegular.house,
    'family': PhosphorIconsRegular.usersThree,
    'people': PhosphorIconsRegular.users,
    'person': PhosphorIconsRegular.user,
    'food': PhosphorIconsRegular.forkKnife,
    'drink': PhosphorIconsRegular.coffee,
    'animal': PhosphorIconsRegular.pawPrint,
    'nature': PhosphorIconsRegular.tree,
    'weather': PhosphorIconsRegular.cloudSun,
    'time': PhosphorIconsRegular.clock,
    'calendar': PhosphorIconsRegular.calendar,
    'number': PhosphorIconsRegular.numberSquareOne,
    'numbers': PhosphorIconsRegular.numberSquareOne,
    'alphabet': PhosphorIconsRegular.textAa,
    'letters': PhosphorIconsRegular.textAa,
    'color': PhosphorIconsRegular.palette,
    'colors': PhosphorIconsRegular.palette,
    'school': PhosphorIconsRegular.graduationCap,
    'work': PhosphorIconsRegular.briefcase,
    'travel': PhosphorIconsRegular.airplaneTilt,
    'health': PhosphorIconsRegular.heartbeat,
    'sport': PhosphorIconsRegular.soccerBall,
    'music': PhosphorIconsRegular.musicNotes,
    'money': PhosphorIconsRegular.coins,
    'question': PhosphorIconsRegular.question,
    'greeting': PhosphorIconsRegular.handWaving,
    'greetings': PhosphorIconsRegular.handWaving,
    'politeness': PhosphorIconsRegular.handsPraying,
    'emotion': PhosphorIconsRegular.smiley,
    'emotions': PhosphorIconsRegular.smiley,
    'body': PhosphorIconsRegular.person,
    'transport': PhosphorIconsRegular.car,
    'place': PhosphorIconsRegular.mapPin,
    'places': PhosphorIconsRegular.mapPin,
    'verb': PhosphorIconsRegular.lightning,
    'verbs': PhosphorIconsRegular.lightning,
    'book': PhosphorIconsRegular.bookOpen,
    'chat': PhosphorIconsRegular.chatCircle,
    'globe': PhosphorIconsRegular.globe,
    'flag': PhosphorIconsRegular.flag,
  };
}
