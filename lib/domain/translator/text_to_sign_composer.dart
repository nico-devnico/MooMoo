import '../../data/local/lsfb_dictionary_asset.dart';
import '../../data/models/landmark_compose.dart';
import '../../data/models/sign.dart';
import '../../data/models/sign_landmarks.dart';
import '../../data/repositories/dictionary_repository.dart';
import '../../data/repositories/ml_model_repository.dart';
import 'phrase_glosser.dart';

/// Legacy helper kept for UI word chips (single tokens).
List<String> tokenizePhrase(String text) {
  return text
      .trim()
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll(RegExp(r'''^[^\wÀ-ÿ]+|[^\wÀ-ÿ]+$'''), ''))
      .where((w) => w.isNotEmpty)
      .toList(growable: false);
}

Sign? pickBestSign(List<Sign> signs, String lookup) {
  final ranked = filterDictionaryMatches(signs, lookup, limit: signs.length);
  return ranked.isEmpty ? null : ranked.first;
}

/// Resolves a phrase into glosses (compound-aware), verifies each gloss exists
/// in the dictionary, then asks the ML service to compose landmark video.
class TextToSignComposer {
  TextToSignComposer({
    required DictionaryRepository dictionary,
    required MlModelRepository ml,
  })  : _dictionary = dictionary,
        _ml = ml;

  final DictionaryRepository _dictionary;
  final MlModelRepository _ml;

  Future<LandmarkComposeResult> compose(
    String text, {
    int? languageId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return LandmarkComposeResult.unavailable('Aucun mot à traduire.');
    }

    final lexiconSigns = await _loadLexicon(languageId);
    final lexicon = buildLexicon(lexiconSigns);
    final glossed = glossifyPhrase(trimmed, lexicon);

    if (glossed.segments.isEmpty) {
      return LandmarkComposeResult.unavailable('Aucun mot à traduire.');
    }

    final resolved = <_ResolvedWord>[];
    final unresolved = <LandmarkMissing>[
      for (final s in glossed.missing)
        LandmarkMissing(word: s.surface, reason: 'introuvable (${s.gloss})'),
    ];

    for (final segment in glossed.found) {
      final sign = segment.sign!;
      final detail = await _dictionary.getSignById(sign.id) ?? sign;
      resolved.add(_ResolvedWord(
        query: segment.surface,
        gloss: segment.gloss,
        sign: detail,
      ));
    }

    final clips = <TextToSignClip>[
      for (final r in resolved)
        if ((r.sign.videoUrl ?? '').trim().isNotEmpty)
          TextToSignClip(
            word: r.gloss,
            url: r.sign.videoUrl!.trim(),
            signId: r.sign.id,
            matchedWord: r.sign.word,
          ),
    ];

    if (clips.isNotEmpty) {
      final result = await _ml.composeLandmarks(clips);
      final missingUrls = [
        for (final r in resolved)
          if ((r.sign.videoUrl ?? '').trim().isEmpty)
            LandmarkMissing(
              word: '${r.query} (${r.gloss})',
              signId: r.sign.id,
              reason: 'pas de vidéo',
            ),
      ];
      return LandmarkComposeResult(
        ok: result.ok,
        landmarks: result.landmarks,
        segments: [
          for (final s in result.segments)
            LandmarkSegment(
              word: s.word,
              startFrame: s.startFrame,
              frames: s.frames,
              signId: s.signId,
            ),
        ],
        missing: [...unresolved, ...missingUrls, ...result.missing],
        errorCode: result.errorCode,
        errorMessage: result.errorMessage,
      );
    }

    final local = _composeFromStored(resolved);
    if (local != null) {
      return LandmarkComposeResult(
        ok: true,
        landmarks: local.landmarks,
        segments: local.segments,
        missing: [...unresolved, ...local.missing],
      );
    }

    return LandmarkComposeResult(
      ok: false,
      landmarks: SignLandmarks.empty,
      missing: unresolved,
      errorCode: unresolved.isNotEmpty ? 'unknown_glosses' : 'no_media',
      errorMessage: unresolved.isNotEmpty
          ? 'Glosses introuvables : ${unresolved.map((m) => m.word).join(', ')}'
          : 'Aucun média trouvé dans le dictionnaire pour cette phrase.',
    );
  }

  Future<List<Sign>> _loadLexicon(int? languageId) async {
    // Prefer LSFB catalogue (has compounds + glosses); merge preferred language.
    final lsfb = await _dictionary.searchSigns(
      languageId: LsfbDictionaryAsset.lsfbLanguageId,
      limit: 5000,
    );
    if (languageId == null ||
        languageId == LsfbDictionaryAsset.lsfbLanguageId) {
      return lsfb;
    }
    final preferred = await _dictionary.searchSigns(
      languageId: languageId,
      limit: 2000,
    );
    final byId = <String, Sign>{
      for (final s in lsfb) s.id: s,
      for (final s in preferred) s.id: s,
    };
    return byId.values.toList(growable: false);
  }

  ({
    SignLandmarks landmarks,
    List<LandmarkSegment> segments,
    List<LandmarkMissing> missing,
  })? _composeFromStored(List<_ResolvedWord> resolved) {
    final frames = <LandmarkFrame>[];
    final segments = <LandmarkSegment>[];
    final missing = <LandmarkMissing>[];
    const fps = 15.0;
    const blend = 6;

    LandmarkFrame? previousLast;
    for (var i = 0; i < resolved.length; i++) {
      final r = resolved[i];
      final lm = SignLandmarks.parse(r.sign.landmarkData);
      if (lm.isEmpty) {
        missing.add(LandmarkMissing(
          word: '${r.query} (${r.gloss})',
          signId: r.sign.id,
          reason: 'pas de landmarks',
        ));
        continue;
      }
      if (previousLast != null && lm.frames.isNotEmpty) {
        for (var g = 1; g <= blend; g++) {
          final t = g / (blend + 1);
          final s = t * t * (3 - 2 * t);
          frames.add(LandmarkFrame.lerp(previousLast, lm.frames.first, s));
        }
      }
      final start = frames.length;
      frames.addAll(lm.frames);
      segments.add(LandmarkSegment(
        word: r.gloss,
        signId: r.sign.id,
        startFrame: start,
        frames: lm.frames.length,
      ));
      previousLast = lm.frames.isNotEmpty ? lm.frames.last : previousLast;
    }
    if (frames.isEmpty) return null;
    return (
      landmarks: SignLandmarks(frames: frames, fps: fps),
      segments: segments,
      missing: missing,
    );
  }
}

class _ResolvedWord {
  const _ResolvedWord({
    required this.query,
    required this.gloss,
    required this.sign,
  });

  final String query;
  final String gloss;
  final Sign sign;
}
