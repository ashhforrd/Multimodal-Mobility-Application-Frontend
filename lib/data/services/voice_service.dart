import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  SpeechToText? _speech;

  SpeechToText get _engine => _speech ??= SpeechToText();

  Future<bool> initialize() async {
    try {
      return await _engine.initialize();
    } catch (_) {
      return false;
    }
  }

  Future<void> listen(void Function(String) onText) => _engine.listen(
        onResult: (result) => onText(result.recognizedWords),
        listenOptions: SpeechListenOptions(localeId: 'id_ID'),
      );
  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {
      // Input teks tetap tersedia ketika sesi mikrofon gagal dihentikan.
    }
  }
}
