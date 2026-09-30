import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sign.dart';
import 'lsfb_dictionary_asset.dart';

/// Favoris locaux pour les signes hors Supabase (`lsfb:…`).
///
/// Les IDs locaux ne peuvent pas aller dans `public.favorites` (FK UUID).
class LocalFavoritesStore {
  LocalFavoritesStore._();

  static const _prefsKey = 'moomoo_local_favorite_sign_ids';

  static Future<Set<String>> ids() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
    return {
      for (final id in raw)
        if (id.startsWith(LsfbDictionaryAsset.idPrefix)) id,
    };
  }

  static Future<bool> isFavorite(String signId) async {
    if (!LsfbDictionaryAsset.isLocalId(signId)) return false;
    return (await ids()).contains(signId);
  }

  static Future<void> add(String signId) async {
    if (!LsfbDictionaryAsset.isLocalId(signId)) return;
    final prefs = await SharedPreferences.getInstance();
    final next = {...await ids(), signId}.toList()..sort();
    await prefs.setStringList(_prefsKey, next);
  }

  static Future<void> remove(String signId) async {
    if (!LsfbDictionaryAsset.isLocalId(signId)) return;
    final prefs = await SharedPreferences.getInstance();
    final next = (await ids())..remove(signId);
    await prefs.setStringList(_prefsKey, next.toList()..sort());
  }

  static Future<void> toggle(String signId, {required bool currentlyFavorite}) async {
    if (currentlyFavorite) {
      await remove(signId);
    } else {
      await add(signId);
    }
  }

  /// Signes LSFB favoris, pour fusion avec les favoris Supabase.
  static Future<List<Sign>> loadSigns({int? languageId}) async {
    final favIds = await ids();
    if (favIds.isEmpty) return const [];
    final all = await LsfbDictionaryAsset.load(languageId: languageId);
    return [
      for (final sign in all)
        if (favIds.contains(sign.id)) sign,
    ];
  }

  /// Debug / migration éventuelle.
  static Future<String> exportJson() async {
    final list = (await ids()).toList()..sort();
    return jsonEncode(list);
  }
}
