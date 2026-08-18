import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  Future<void> speak(String text) async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.48);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
