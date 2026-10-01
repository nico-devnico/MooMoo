import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/translator/phrase_glosser.dart';
import '../models/sign.dart';
import '../models/sign_language.dart';

/// Catalogue LSFB embarqué (`assets/dictionnaire/dataset_gifs_links.json`).
class LsfbDictionaryAsset {
  LsfbDictionaryAsset._();

  static const assetPath = 'assets/dictionnaire/dataset_gifs_links.json';
  static const languageCode = 'LSFB';
  static const idPrefix = 'lsfb:';

  /// Langue locale de secours si Supabase n'a pas encore LSFB.
  static const fallbackLanguage = SignLanguage(
    id: lsfbLanguageId,
    code: languageCode,
    name: 'Langue des signes de Belgique francophone',
    country: 'BE',
    flagEmoji: '🇧🇪',
    isActive: true,
  );

  /// ID réservé aux signes locaux quand aucune langue LSFB n'existe en base.
  static const lsfbLanguageId = 9001;

  static List<Sign>? _cache;

  static bool isLocalId(String id) => id.startsWith(idPrefix);

  static Future<List<Sign>> load({int? languageId}) async {
    if (_cache != null) {
      return _withLanguage(_cache!, languageId);
    }
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _cache = const [];
      return const [];
    }
    final signs = <Sign>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final gloss = (map['glose'] as String?)?.trim();
      final word = (map['nom_signe'] as String?)?.trim();
      if (gloss == null || gloss.isEmpty || word == null || word.isEmpty) {
        continue;
      }
      final gif = (map['gif_url'] as String?)?.trim();
      final dico = (map['dico_url'] as String?)?.trim();
      final translations = <String>[
        for (final t in (map['translations'] as List? ?? const []))
          if (t is String && t.trim().isNotEmpty) t.trim(),
      ];
      final synonyms = [
        for (final t in translations)
          if (t.toLowerCase() != word.toLowerCase()) t,
      ];
      final descriptionParts = <String>[
        'Glosse : $gloss',
        if (synonyms.isNotEmpty) 'Aussi : ${synonyms.join(', ')}',
      ];
      signs.add(
        Sign(
          id: '$idPrefix$gloss',
          signLanguageId: languageId ?? fallbackLanguage.id,
          word: word,
          description: descriptionParts.join('\n'),
          difficultyLevel: 1,
          videoUrl: gif,
          thumbnailUrl: gif,
          tags: [
            gloss,
            ...synonyms,
            if (dico != null && dico.isNotEmpty) 'source:$dico',
          ],
          isValidated: true,
          viewCount: 0,
        ),
      );
    }
    signs.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    _cache = signs;
    return _withLanguage(signs, languageId);
  }

  static List<Sign> _withLanguage(List<Sign> signs, int? languageId) {
    if (languageId == null) return signs;
    return [
      for (final s in signs) s.copyWith(signLanguageId: languageId),
    ];
  }

  static Future<Sign?> byId(String id, {int? languageId}) async {
    if (!isLocalId(id)) return null;
    final all = await load(languageId: languageId);
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  static Future<List<Sign>> search({
    String? query,
    int? languageId,
    int limit = 20,
    int offset = 0,
  }) async {
    final all = await load(languageId: languageId);
    final q = query?.trim() ?? '';
    if (q.isEmpty) {
      return all.skip(offset).take(limit).toList(growable: false);
    }
    // Exact / synonym / prefix — never mid-word contains ("je" ↛ "déjeuner").
    final ranked = filterDictionaryMatches(all, q, limit: offset + limit);
    return ranked.skip(offset).take(limit).toList(growable: false);
  }
}
