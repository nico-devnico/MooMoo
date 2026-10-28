import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/data/models/sign.dart';
import 'package:moomoo/domain/translator/phrase_glosser.dart';

Sign _sign(String id, String word, {List<String>? tags}) => Sign(
      id: id,
      word: word,
      difficultyLevel: 1,
      tags: tags,
      isValidated: true,
      viewCount: 0,
    );

void main() {
  test('whole phrase is preferred when it exists in the lexicon', () {
    final lexicon = buildLexicon([
      _sign('1', 'à côté', tags: ['A-COTE']),
      _sign('2', 'à'),
      _sign('3', 'côté'),
      _sign('4', 'bonjour'),
    ]);

    final whole = lexicon[foldLookup('à côté')];
    expect(whole, isNotNull);
    expect(whole!.word, 'à côté');

    final glossed = glossifyPhrase('à côté', lexicon);
    expect(glossed.segments, hasLength(1));
    expect(glossed.segments.single.found, isTrue);
    expect(glossed.missing, isEmpty);
  });

  test('unknown words are reported while known words stay found', () {
    final lexicon = buildLexicon([
      _sign('1', 'bonjour'),
      _sign('2', 'merci'),
    ]);
    final glossed = glossifyPhrase('bonjour xyzzy merci', lexicon);
    expect(glossed.found.map((s) => s.surface), ['bonjour', 'merci']);
    expect(glossed.missing.map((s) => s.surface), ['xyzzy']);
  });
}
