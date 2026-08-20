import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  FlutterTts? _tts;

  FlutterTts get _engine => _tts ??= FlutterTts();

  Future<void> speak(String text) async {
    try {
      await _engine.setLanguage('id-ID');
      await _engine.setSpeechRate(0.48);
      await _engine.speak(text);
    } catch (_) {
      // Instruksi visual tetap tersedia ketika perangkat tidak mendukung TTS.
    }
  }

  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {
      // Tidak ada sesi audio yang perlu dihentikan.
    }
  }
}
