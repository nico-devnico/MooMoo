import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_client.dart';
import '../services/google_auth.dart';

abstract class AuthRepository {
  Stream<AuthState> watchAuthState();
  User? get currentUser;
  Session? get currentSession;

  Future<AuthResponse> signInWithEmailPassword(String email, String password);
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String displayName, {
    bool isDeaf = false,
  });
  Future<void> signInWithGoogle();

  /// Exchanges an ID token from the in-app Google sign-in for a session.
  Future<AuthResponse> signInWithGoogleIdToken(String idToken);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);
}

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;
  final ApiClient _api;

  AuthRepositoryImpl(this._supabase, {ApiClient? api})
      : _api = api ?? ApiClient();

  @override
  Stream<AuthState> watchAuthState() => _supabase.auth.onAuthStateChange;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Session? get currentSession => _supabase.auth.currentSession;

  @override
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    // Prefer Node API (ensure-profile + clearer errors), fall back to direct Auth
    try {
      final res = await _api.postJson('/api/auth/login', body: {
        'email': email,
        'password': password,
      });
      final sessionJson = res['session'];
      if (sessionJson is Map && sessionJson['access_token'] != null) {
        final restored = await _supabase.auth.setSession(
          sessionJson['refresh_token'] as String? ?? '',
        );
        if (restored.session != null) return restored;
        // setSession may need access+refresh — use signIn as fallback
      }
    } on ApiUnreachableException {
      // Backend not running: Supabase Auth below handles it on its own.
    } on ApiException catch (e) {
      // Re-throw API validation / auth errors so UI shows the real message
      if (e.status == 400 || e.status == 401) {
        throw AuthException(e.message, statusCode: e.status.toString());
      }
      debugPrint('API login fallback: $e');
    } catch (e) {
      debugPrint('API login fallback: $e');
    }

    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String displayName, {
    bool isDeaf = false,
  }) async {
    try {
      final res = await _api.postJson('/api/auth/signup', body: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'isDeaf': isDeaf,
      });
      final sessionJson = res['session'];
      final refresh = sessionJson is Map ? sessionJson['refresh_token'] as String? : null;
      if (refresh != null && refresh.isNotEmpty) {
        final restored = await _supabase.auth.setSession(refresh);
        if (restored.session != null) return restored;
      }
      // If email confirmation required, session may be null — still OK
      if (res['ok'] == true) {
        // Establish local session via direct sign-in when possible
        try {
          return await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } catch (_) {
          return AuthResponse(
            user: null,
            session: null,
          );
        }
      }
    } on ApiUnreachableException {
      // Backend not running: sign up straight through Supabase Auth below.
    } on ApiException catch (e) {
      if (e.status == 400 || e.status == 401 || e.status == 422) {
        throw AuthException(e.message, statusCode: e.status.toString());
      }
      debugPrint('API signup fallback: $e');
    } catch (e) {
      debugPrint('API signup fallback: $e');
    }

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      // Read by the on_auth_user_created trigger when there is no session yet.
      data: {'display_name': displayName, 'is_deaf': isDeaf},
    );

    final user = response.user;
    final session = response.session;
    if (user != null) {
      try {
        if (session != null) {
          await _api.postJson(
            '/api/auth/ensure-profile',
            accessToken: session.accessToken,
            body: {
              'displayName': displayName,
              'isDeaf': isDeaf,
              'email': email,
            },
          );
        } else {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'email': email,
            'display_name': displayName,
            'is_deaf': isDeaf,
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      } on ApiUnreachableException {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'display_name': displayName,
          'is_deaf': isDeaf,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('ensure profile after signup: $e');
      }
    }
    return response;
  }

  @override
  Future<void> signInWithGoogle() async {
    if (GoogleAuth.isSupported && !GoogleAuth.usesRenderedButton) {
      final idToken = await GoogleAuth.instance.authenticate();
      await signInWithGoogleIdToken(idToken);
      return;
    }
    // Desktop (Windows, Linux, macOS): no Google SDK and Google refuses
    // embedded web views, so the system browser is the only option left.
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : 'moomoo://login-callback',
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  @override
  Future<AuthResponse> signInWithGoogleIdToken(String idToken) {
    return _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      nonce: GoogleAuth.instance.rawNonce,
    );
  }

  @override
  Future<void> signOut() async {
    await GoogleAuth.instance.signOut();
    await _supabase.auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
