import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  SpeechToText? _speech;
  void Function()? _onCompleted;
  bool _completionSent = false;

  SpeechToText get _engine => _speech ??= SpeechToText();

  Future<bool> initialize() async {
    try {
      return await _engine.initialize(
        onStatus: _handleStatus,
        onError: (_) => _notifyCompleted(),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> listen({
    required void Function(String) onText,
    required void Function() onCompleted,
  }) {
    _onCompleted = onCompleted;
    _completionSent = false;
    return _engine.listen(
      onResult: (result) {
        onText(result.recognizedWords);
        if (result.finalResult) _notifyCompleted();
      },
      listenOptions: SpeechListenOptions(
        localeId: 'id_ID',
        listenMode: ListenMode.dictation,
        partialResults: true,
        autoPunctuation: true,
        pauseFor: const Duration(seconds: 2),
        listenFor: const Duration(seconds: 45),
      ),
    );
  }

  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {
      // Input teks tetap tersedia ketika sesi mikrofon gagal dihentikan.
    }
  }

  Future<void> cancel() async {
    _completionSent = true;
    _onCompleted = null;
    try {
      await _engine.cancel();
    } catch (_) {
      // Tidak ada sesi aktif yang perlu dibatalkan.
    }
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus) {
      _notifyCompleted();
    }
  }

  void _notifyCompleted() {
    if (_completionSent) return;
    _completionSent = true;
    _onCompleted?.call();
  }
}
