import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  Future<bool> initialize() => _speech.initialize();
  Future<void> listen(void Function(String) onText) => _speech.listen(
        onResult: (result) => onText(result.recognizedWords),
        listenOptions: SpeechListenOptions(localeId: 'id_ID'),
      );
  Future<void> stop() => _speech.stop();
}
