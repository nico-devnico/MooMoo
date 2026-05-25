import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'translator_provider.g.dart';

@riverpod
class TranslatorState extends _$TranslatorState {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void start() => state = true;
  void stop() => state = false;
}
