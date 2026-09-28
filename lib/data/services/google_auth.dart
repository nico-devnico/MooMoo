import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google sign-in that stays inside the app.
///
/// Android shows the system account picker, iOS the Google SDK sheet and the
/// web the Google Identity Services button / popup rendered in the page. The
/// resulting ID token is exchanged with Supabase (`signInWithIdToken`), so no
/// browser tab or redirect is involved.
///
/// Client IDs are public values; override them at build time with
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=…` / `GOOGLE_IOS_CLIENT_ID=…`.
class GoogleAuth {
  GoogleAuth._();

  static final GoogleAuth instance = GoogleAuth._();

  /// OAuth "Web application" client, the one configured in the Supabase
  /// Google provider. Android uses it as `serverClientId` so the ID token is
  /// issued for it.
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '582523176330-jji97pku1th0n6t01pv2lnse9ck3s2ve.apps.googleusercontent.com',
  );

  /// OAuth "iOS" client. Without it iOS cannot sign in natively.
  static const String iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Whether this platform has an in-app Google sign-in. Windows and Linux
  /// have no Google SDK, and Google refuses embedded web views.
  static bool get isSupported {
    if (kIsWeb) return webClientId.isNotEmpty;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => webClientId.isNotEmpty,
      TargetPlatform.iOS => iosClientId.isNotEmpty,
      _ => false,
    };
  }

  /// The web only accepts the button rendered by Google's own SDK.
  static bool get usesRenderedButton => kIsWeb;

  Future<void>? _init;
  String? _rawNonce;
  final _webIdTokens = StreamController<String>.broadcast();
  final _webErrors = StreamController<Object>.broadcast();

  /// Raw nonce whose SHA-256 is embedded in the ID token; Supabase checks it.
  String? get rawNonce => _rawNonce;

  /// Address of the last Google account picked, even if Supabase then
  /// refused it (banned account).
  String? lastEmail;

  /// ID tokens produced by the web button.
  Stream<String> get webIdTokens => _webIdTokens.stream;

  /// Failures reported by the web button (cancellations excluded).
  Stream<Object> get webErrors => _webErrors.stream;

  Future<void> ensureInitialized() => _init ??= _initialize();

  Future<void> _initialize() async {
    final raw = _randomNonce();
    _rawNonce = raw;
    final signIn = GoogleSignIn.instance;
    await signIn.initialize(
      clientId: kIsWeb
          ? webClientId
          : defaultTargetPlatform == TargetPlatform.iOS
              ? iosClientId
              : null,
      serverClientId: kIsWeb ? null : webClientId,
      nonce: sha256.convert(utf8.encode(raw)).toString(),
    );
    if (kIsWeb) {
      signIn.authenticationEvents.listen(
        (event) {
          if (event is! GoogleSignInAuthenticationEventSignIn) return;
          lastEmail = event.user.email;
          final token = event.user.authentication.idToken;
          if (token != null) _webIdTokens.add(token);
        },
        onError: (Object e) {
          if (!isCancellation(e)) _webErrors.add(e);
        },
      );
    }
  }

  /// Shows the native account picker and returns the ID token.
  Future<String> authenticate() async {
    await ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    lastEmail = account.email;
    final token = account.authentication.idToken;
    if (token == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Google did not return an ID token',
      );
    }
    return token;
  }

  /// Forgets the Google account so the next sign-in offers the picker again.
  Future<void> signOut() async {
    if (_init == null) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google sign-out: $e');
    }
  }

  static bool isCancellation(Object error) =>
      error is GoogleSignInException &&
      error.code == GoogleSignInExceptionCode.canceled;

  static String _randomNonce() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => random.nextInt(256)));
  }
}
