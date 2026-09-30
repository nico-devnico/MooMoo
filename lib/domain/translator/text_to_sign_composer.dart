import '../../data/local/lsfb_dictionary_asset.dart';
import '../../data/models/landmark_compose.dart';
import '../../data/models/sign.dart';
import '../../data/models/sign_landmarks.dart';
import '../../data/repositories/dictionary_repository.dart';
import '../../data/repositories/ml_model_repository.dart';

/// Splits a typed phrase into lookup tokens (order preserved, punctuation stripped).
List<String> tokenizePhrase(String text) {
  return text
      .trim()
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll(RegExp(r'''^[^\wÀ-ÿ]+|[^\wÀ-ÿ]+$'''), ''))
      .where((w) => w.isNotEmpty)
      .toList(growable: false);
}

Sign? pickBestSign(List<Sign> signs, String lookup) {
  if (signs.isEmpty) return null;
  final target = lookup.toLowerCase();
  for (final sign in signs) {
    if (sign.word.toLowerCase() == target) return sign;
  }
  for (final sign in signs) {
    final w = sign.word.toLowerCase();
    if (w.startsWith(target) || target.startsWith(w)) return sign;
  }
  return signs.first;
}

/// Resolves each word in [text] against the dictionary, asks the ML service to
/// download the medias temporarily, extract Holistic landmarks and concatenate
/// them into one sequence playable by [LandmarkViewer].
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
    final words = tokenizePhrase(text);
    if (words.isEmpty) {
      return LandmarkComposeResult.unavailable('Aucun mot à traduire.');
    }

    final resolved = <_ResolvedWord>[];
    final unresolved = <LandmarkMissing>[];

    for (final word in words) {
      var matches = await _dictionary.searchSigns(
        query: word,
        languageId: languageId,
        limit: 8,
      );
      var sign = pickBestSign(matches, word);
      // Catalogue LSFB embarqué : repli si la langue préférée n'a rien (ou pas de média).
      if (sign == null || (sign.videoUrl ?? '').trim().isEmpty) {
        final lsfb = await _dictionary.searchSigns(
          query: word,
          languageId: LsfbDictionaryAsset.lsfbLanguageId,
          limit: 8,
        );
        final lsfbSign = pickBestSign(lsfb, word);
        if (lsfbSign != null &&
            ((lsfbSign.videoUrl ?? '').trim().isNotEmpty || sign == null)) {
          sign = lsfbSign;
        }
      }
      if (sign == null) {
        unresolved.add(LandmarkMissing(word: word, reason: 'introuvable'));
        continue;
      }
      final detail = await _dictionary.getSignById(sign.id) ?? sign;
      resolved.add(_ResolvedWord(query: word, sign: detail));
    }

    final clips = <TextToSignClip>[
      for (final r in resolved)
        if ((r.sign.videoUrl ?? '').trim().isNotEmpty)
          TextToSignClip(
            word: r.query,
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
              word: r.query,
              signId: r.sign.id,
              reason: 'pas de vidéo',
            ),
      ];
      return LandmarkComposeResult(
        ok: result.ok,
        landmarks: result.landmarks,
        segments: result.segments,
        missing: [...unresolved, ...missingUrls, ...result.missing],
        errorCode: result.errorCode,
        errorMessage: result.errorMessage,
      );
    }

    // No media URLs: stitch landmark_data already stored on the signs.
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
      errorCode: 'no_media',
      errorMessage: 'Aucun média trouvé dans le dictionnaire pour cette phrase.',
    );
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
    const gap = 4;

    for (var i = 0; i < resolved.length; i++) {
      final r = resolved[i];
      final lm = SignLandmarks.parse(r.sign.landmarkData);
      if (lm.isEmpty) {
        missing.add(LandmarkMissing(
          word: r.query,
          signId: r.sign.id,
          reason: 'pas de landmarks',
        ));
        continue;
      }
      final start = frames.length;
      frames.addAll(lm.frames);
      segments.add(LandmarkSegment(
        word: r.sign.word,
        signId: r.sign.id,
        startFrame: start,
        frames: lm.frames.length,
      ));
      if (i < resolved.length - 1 && lm.frames.isNotEmpty) {
        final hold = lm.frames.last;
        for (var g = 0; g < gap; g++) {
          frames.add(hold);
        }
      }
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
  const _ResolvedWord({required this.query, required this.sign});

  final String query;
  final Sign sign;
}
