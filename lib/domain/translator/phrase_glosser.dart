import 'dart:math' as math;

import '../learning/practice.dart' show normalizeSignWord;
import '../../data/local/lsfb_dictionary_asset.dart';
import '../../data/models/sign.dart';

/// One segment of a phrase after glossification.
class GlossSegment {
  const GlossSegment({
    required this.surface,
    required this.gloss,
    this.sign,
  });

  /// Text as typed / matched (e.g. "à côté").
  final String surface;

  /// Dictionary gloss (e.g. "A-COTE"), or the surface uppercased if unknown.
  final String gloss;

  /// Resolved dictionary sign when the segment exists in the lexicon.
  final Sign? sign;

  bool get found => sign != null;
}

/// Result of turning a free-text phrase into an ordered gloss sequence.
class GlossedPhrase {
  const GlossedPhrase({
    required this.segments,
    required this.rawText,
  });

  final List<GlossSegment> segments;
  final String rawText;

  List<GlossSegment> get found => [for (final s in segments) if (s.found) s];
  List<GlossSegment> get missing => [for (final s in segments) if (!s.found) s];

  String get glossLine => segments.map((s) => s.gloss).join(' ');
}

/// Folds text for dictionary matching: lower-case, strip accents, keep spaces.
String foldLookup(String input) {
  final parts = input
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map(normalizeSignWord)
      .where((p) => p.isNotEmpty);
  return parts.join(' ');
}

String? glossOf(Sign sign) {
  if (LsfbDictionaryAsset.isLocalId(sign.id)) {
    return sign.id.substring(LsfbDictionaryAsset.idPrefix.length);
  }
  final tags = sign.tags ?? const <String>[];
  for (final t in tags) {
    if (t.startsWith('source:')) continue;
    if (t.trim().isNotEmpty) return t.trim();
  }
  return sign.word.toUpperCase();
}

/// Builds a longest-match lexicon from dictionary signs (word + synonyms + gloss).
Map<String, Sign> buildLexicon(Iterable<Sign> signs) {
  final map = <String, Sign>{};
  void put(String key, Sign sign) {
    final k = foldLookup(key);
    if (k.isEmpty) return;
    final existing = map[k];
    // Prefer the entry whose surface is longer / already exact; keep first otherwise.
    if (existing == null) {
      map[k] = sign;
      return;
    }
    if (foldLookup(sign.word).length > foldLookup(existing.word).length) {
      map[k] = sign;
    }
  }

  for (final sign in signs) {
    put(sign.word, sign);
    put(glossOf(sign) ?? '', sign);
    for (final tag in sign.tags ?? const <String>[]) {
      if (tag.startsWith('source:')) continue;
      put(tag, sign);
    }
  }
  return map;
}

/// Turns [text] into glosses using longest-match over [lexicon] (compound-aware).
///
/// Example: `"je suis à côté"` → segments for compounds like `"à côté"` before
/// single tokens, so dictionary multi-word entries are kept intact.
GlossedPhrase glossifyPhrase(String text, Map<String, Sign> lexicon) {
  final raw = text.trim();
  if (raw.isEmpty) {
    return const GlossedPhrase(segments: [], rawText: '');
  }

  final keys = lexicon.keys.toList()
    ..sort((a, b) {
      final byLen = b.length.compareTo(a.length);
      if (byLen != 0) return byLen;
      return a.compareTo(b);
    });

  final folded = foldLookup(raw);
  final segments = <GlossSegment>[];
  var i = 0;
  while (i < folded.length) {
    while (i < folded.length && folded[i] == ' ') {
      i++;
    }
    if (i >= folded.length) break;

    final rest = folded.substring(i);
    String? hit;
    for (final key in keys) {
      if (rest == key ||
          rest.startsWith('$key ') ||
          (rest.startsWith(key) &&
              (rest.length == key.length ||
                  !_isLookupChar(rest.codeUnitAt(key.length))))) {
        hit = key;
        break;
      }
    }

    if (hit != null) {
      final sign = lexicon[hit]!;
      segments.add(GlossSegment(
        surface: sign.word,
        gloss: glossOf(sign) ?? hit.toUpperCase(),
        sign: sign,
      ));
      i += hit.length;
      continue;
    }

    // Unknown token: consume until next space.
    final nextSpace = rest.indexOf(' ');
    final token = nextSpace < 0 ? rest : rest.substring(0, nextSpace);
    segments.add(GlossSegment(
      surface: token,
      gloss: token.toUpperCase(),
      sign: null,
    ));
    i += token.length;
  }

  return GlossedPhrase(segments: segments, rawText: raw);
}

bool _isLookupChar(int unit) {
  final c = String.fromCharCode(unit);
  return RegExp(r'[a-z0-9]').hasMatch(c);
}

/// Dictionary search ranking: exact hits first, then prefix (query length ≥ 3).
/// Never returns mid-word contains matches ("je" ↛ "déjeuner" / "jeu").
List<Sign> filterDictionaryMatches(List<Sign> signs, String query, {int limit = 20}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return signs.take(limit).toList(growable: false);

  final qFold = foldLookup(q);
  final exact = <Sign>[];
  final prefix = <Sign>[];

  for (final sign in signs) {
    final word = sign.word.toLowerCase();
    final wordFold = foldLookup(sign.word);
    if (word == q || wordFold == qFold) {
      exact.add(sign);
      continue;
    }
    var synonymExact = false;
    for (final tag in sign.tags ?? const <String>[]) {
      if (tag.startsWith('source:')) continue;
      if (tag.toLowerCase() == q || foldLookup(tag) == qFold) {
        synonymExact = true;
        break;
      }
    }
    if (synonymExact) {
      exact.add(sign);
      continue;
    }
    // Prefix only for longer queries — avoids "je" → "jeu".
    if (qFold.length >= 3 &&
        (wordFold.startsWith(qFold) || word.startsWith(q))) {
      prefix.add(sign);
    }
  }

  return [...exact, ...prefix].take(limit).toList(growable: false);
}

/// Max compound span considered when building the lexicon (words).
int maxCompoundTokens(Iterable<Sign> signs) {
  var max = 1;
  for (final s in signs) {
    max = math.max(max, s.word.trim().split(RegExp(r'\s+')).length);
  }
  return max;
}
