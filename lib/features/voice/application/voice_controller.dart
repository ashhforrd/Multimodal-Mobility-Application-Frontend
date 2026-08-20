import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/text_to_speech_service.dart';
import '../../../data/services/voice_service.dart';
import '../../navigation/application/navigation_controller.dart';
import 'voice_state.dart';

final voiceServiceProvider = Provider((_) => VoiceService());
final geminiServiceProvider = Provider((_) => GeminiService());
final voiceProvider =
    StateNotifierProvider<VoiceController, VoiceState>((ref) => VoiceController(
          ref: ref,
          voiceService: ref.watch(voiceServiceProvider),
          geminiService: ref.watch(geminiServiceProvider),
          textToSpeechService: ref.watch(ttsProvider),
        ));

class VoiceController extends StateNotifier<VoiceState> {
  VoiceController({
    required Ref ref,
    required VoiceService voiceService,
    required GeminiService geminiService,
    required TextToSpeechService textToSpeechService,
  })  : _ref = ref,
        _voiceService = voiceService,
        _geminiService = geminiService,
        _textToSpeechService = textToSpeechService,
        super(const VoiceState());

  final Ref _ref;
  final VoiceService _voiceService;
  final GeminiService _geminiService;
  final TextToSpeechService _textToSpeechService;

  Future<void> toggleListening() async {
    if (state.isListening) {
      await _voiceService.stop();
      state = state.copyWith(isListening: false);
      return;
    }
    final available = await _voiceService.initialize();
    if (!available) {
      state = state.copyWith(
          errorMessage: 'Pengenalan suara tidak tersedia. Gunakan input teks.');
      return;
    }
    state = state.copyWith(isListening: true, errorMessage: null);
    try {
      await _voiceService
          .listen((text) => state = state.copyWith(transcript: text));
    } catch (_) {
      state = state.copyWith(
        isListening: false,
        errorMessage:
            'Mikrofon tidak dapat digunakan. Masukkan pertanyaan melalui teks.',
      );
    }
  }

  void setTranscript(String text) => state = state.copyWith(transcript: text);
  Future<void> submit() async {
    final nav = _ref.read(navigationProvider);
    if (state.transcript.trim().isEmpty || nav.activeStep == null) {
      state =
          state.copyWith(errorMessage: 'Masukkan pertanyaan terlebih dahulu.');
      return;
    }
    if (state.isListening) {
      await _voiceService.stop();
    }
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final result = await _geminiService.ask(
          question: state.transcript,
          active: nav.activeStep!,
          next: nav.nextStep,
          destination: nav.selectedDestination?.name ?? '',
          routeStatus: nav.routeStatus.name);
      state = state.copyWith(
        isProcessing: false,
        appResponse: result.text,
        suggestedInstruction: result.shouldUpdateInstruction
            ? result.suggestedInstruction ?? result.text
            : null,
        shouldOpenRecovery: result.shouldOpenRecovery,
      );
      state = state.copyWith(isListening: false, isSpeaking: true);
      await _textToSpeechService.speak(result.text);
      state = state.copyWith(isSpeaking: false);
    } on GeminiServiceException catch (error) {
      state = state.copyWith(
        isListening: false,
        isProcessing: false,
        errorMessage: error.message,
      );
    }
  }

  void applyResponse() {
    final suggestion = state.suggestedInstruction;
    if (suggestion != null) {
      _ref.read(navigationProvider.notifier).useInstruction(suggestion);
    }
  }

  void clear() => state = const VoiceState();
}
