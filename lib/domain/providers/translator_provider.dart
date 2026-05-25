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

enum TranslationMode { signToText, textToSign }

@riverpod
class TranslationModeState extends _$TranslationModeState {
  @override
  TranslationMode build() => TranslationMode.signToText;

  void setMode(TranslationMode mode) => state = mode;
  void toggleMode() {
    state = state == TranslationMode.signToText 
        ? TranslationMode.textToSign 
        : TranslationMode.signToText;
  }
}
