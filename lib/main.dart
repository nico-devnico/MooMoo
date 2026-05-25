import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'app.dart';
import 'core/constants/supabase_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
    );
    
    // Handle deep links for OAuth
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep link reçoit: $uri');
      if (uri.scheme == 'moomoo' && uri.host == 'login-callback') {
        Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
    
  } catch (e) {
    debugPrint('Initialisation de Supabase: $e');
  }

  runApp(
    const ProviderScope(
      child: MooMooApp(),
    ),
  );
}
