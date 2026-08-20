import 'dart:async';

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
  bool _submitInProgress = false;
  bool _continuousConversation = false;
  bool _voiceReady = false;
  int _listeningGeneration = 0;

  Future<void> startContinuousConversation() async {
    if (_continuousConversation) return;
    _continuousConversation = true;
    state = state.copyWith(
      isConversationActive: true,
      errorMessage: null,
    );
    await _textToSpeechService.stop();
    await _startListening();
  }

  Future<void> stopContinuousConversation({bool updateState = true}) async {
    _continuousConversation = false;
    _listeningGeneration++;
    if (updateState) {
      state = state.copyWith(
        isConversationActive: false,
        isListening: false,
        isSpeaking: false,
      );
    }
    await Future.wait([
      _voiceService.cancel(),
      _textToSpeechService.stop(),
    ]);
  }

  Future<void> toggleListening() async {
    if (state.isListening) {
      await _stopAndSubmit();
      return;
    }
    if (state.isProcessing || state.isSpeaking) return;
    await _startListening(clearConversation: true);
  }

  Future<void> _startListening({bool clearConversation = false}) async {
    if (state.isListening || state.isProcessing || state.isSpeaking) return;
    final available = _voiceReady || await _voiceService.initialize();
    if (!available) {
      state = state.copyWith(
        isConversationActive: false,
        errorMessage:
            'Pengenalan suara tidak tersedia. Periksa izin mikrofon lalu buka kembali panel ini.',
      );
      _continuousConversation = false;
      return;
    }
    _voiceReady = true;
    final generation = ++_listeningGeneration;
    state = state.copyWith(
      isListening: true,
      transcript: '',
      lastQuestion: clearConversation ? '' : state.lastQuestion,
      appResponse: clearConversation ? '' : state.appResponse,
      errorMessage: null,
    );
    try {
      await _voiceService.listen(
        onText: (text) {
          if (generation != _listeningGeneration) return;
          state = state.copyWith(transcript: text, errorMessage: null);
        },
        onCompleted: () => unawaited(_completeSpeech(generation)),
      );
    } catch (_) {
      if (generation != _listeningGeneration) return;
      state = state.copyWith(
        isListening: false,
        errorMessage: 'Mikrofon tidak dapat digunakan. Periksa izin mikrofon.',
      );
      await _resumeContinuousConversation();
    }
  }

  void setTranscript(String text) => state = state.copyWith(transcript: text);

  Future<void> _stopAndSubmit() async {
    _listeningGeneration++;
    state = state.copyWith(isListening: false);
    await _voiceService.stop();
    await submit();
  }

  Future<void> _completeSpeech(int generation) async {
    if (generation != _listeningGeneration || !state.isListening) return;
    _listeningGeneration++;
    state = state.copyWith(isListening: false);
    await _voiceService.stop();
    if (state.transcript.trim().isEmpty) {
      await _resumeContinuousConversation();
      return;
    }
    await submit(fromContinuousConversation: true);
  }

  Future<void> submit({bool fromContinuousConversation = false}) async {
    if (_submitInProgress || state.isProcessing) return;
    final nav = _ref.read(navigationProvider);
    final question = state.transcript.trim();
    if (question.isEmpty || nav.activeStep == null) {
      state =
          state.copyWith(errorMessage: 'Masukkan pertanyaan terlebih dahulu.');
      return;
    }
    if (state.isListening) {
      _listeningGeneration++;
      state = state.copyWith(isListening: false);
      await _voiceService.stop();
    }
    _submitInProgress = true;
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final result = await _geminiService.ask(
          question: question,
          active: nav.activeStep!,
          next: nav.nextStep,
          destination: nav.selectedDestination?.name ?? '',
          routeStatus: nav.routeStatus.name);
      state = state.copyWith(
        transcript: '',
        lastQuestion: question,
        isProcessing: false,
        appResponse: result.text,
        suggestedInstruction: result.shouldUpdateInstruction
            ? result.suggestedInstruction ?? result.text
            : null,
        shouldOpenRecovery: result.shouldOpenRecovery,
      );
      if (!fromContinuousConversation || _continuousConversation) {
        state = state.copyWith(isListening: false, isSpeaking: true);
        await _textToSpeechService.speak(result.text);
        state = state.copyWith(isSpeaking: false);
      }
    } on GeminiServiceException catch (error) {
      state = state.copyWith(
        isListening: false,
        isProcessing: false,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        isListening: false,
        isProcessing: false,
        errorMessage: 'Pertanyaan tidak dapat diproses. Coba kembali.',
      );
    } finally {
      _submitInProgress = false;
    }
    if (fromContinuousConversation) {
      await _resumeContinuousConversation();
    }
  }

  Future<void> _resumeContinuousConversation() async {
    if (!_continuousConversation) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!_continuousConversation) return;
    await _startListening();
  }

  void applyResponse() {
    final suggestion = state.suggestedInstruction;
    if (suggestion != null) {
      _ref.read(navigationProvider.notifier).useInstruction(suggestion);
    }
  }

  Future<void> cancelListening({bool updateState = true}) async {
    _listeningGeneration++;
    if (updateState) {
      state = state.copyWith(isListening: false);
    }
    await _voiceService.cancel();
  }

  Future<void> clear() async {
    _continuousConversation = false;
    await cancelListening();
    await _textToSpeechService.stop();
    state = const VoiceState();
  }
}
