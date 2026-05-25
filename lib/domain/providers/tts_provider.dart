import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

part 'tts_provider.g.dart';

@riverpod
class TtsController extends _$TtsController {
  final FlutterTts _tts = FlutterTts();
  
  @override
  bool build() {
    _initTts();
    return false; // Not speaking by default
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      state = true;
    });

    _tts.setCompletionHandler(() {
      state = false;
    });

    _tts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      state = false;
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = false;
  }
}
