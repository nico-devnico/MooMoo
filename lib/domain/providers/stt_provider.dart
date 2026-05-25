import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

part 'stt_provider.g.dart';

@riverpod
class SpeechController extends _$SpeechController {
  final SpeechToText _speech = SpeechToText();
  
  @override
  bool build() {
    return false; // Not listening by default
  }

  Future<bool> initialize() async {
    try {
      return await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            state = false;
          }
        },
        onError: (error) {
          debugPrint('STT Error: $error');
          state = false;
        },
      );
    } catch (e) {
      debugPrint('STT Init Exception: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    final available = await initialize();
    if (available) {
      state = true;
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          // Also update a global provider for the result
          ref.read(sttResultProvider.notifier).state = result.recognizedWords;
        },
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.confirmation,
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    state = false;
  }
}

@riverpod
class SttResult extends _$SttResult {
  @override
  String build() => '';

  set state(String value) => super.state = value;
}
