import 'package:flutter_test/flutter_test.dart';
import 'package:moomoo/domain/translator/spelling_buffer.dart';

void main() {
  test('assembles letters, spaces and deletes into a phrase', () {
    final buf = SpellingBuffer(minHold: 1, cooldown: Duration.zero);
    expect(buf.update('H', 0.9), 'H');
    expect(buf.update('I', 0.9), 'I');
    expect(buf.update('space', 0.9), 'space');
    expect(buf.update('A', 0.9), 'A');
    expect(buf.text, 'HI A');
    expect(buf.update('del', 0.9), 'del');
    expect(buf.text, 'HI');
    expect(buf.update('nothing', 0.9), isNull);
    expect(buf.text, 'HI');
  });

  test('requires a stable hold before committing', () {
    final buf = SpellingBuffer(minHold: 2, cooldown: Duration.zero);
    expect(buf.update('A', 0.9), isNull);
    expect(buf.text, isEmpty);
    expect(buf.update('A', 0.9), 'A');
    expect(buf.text, 'A');
  });

  test('ignores low confidence predictions', () {
    final buf = SpellingBuffer(minHold: 1, cooldown: Duration.zero);
    expect(buf.update('A', 0.2), isNull);
    expect(buf.text, isEmpty);
  });
}
