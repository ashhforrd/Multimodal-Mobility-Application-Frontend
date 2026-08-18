import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/assistant_service.dart';
import '../../../data/services/voice_service.dart';
import '../../navigation/application/navigation_controller.dart';
import 'voice_state.dart';

final voiceServiceProvider = Provider((_) => VoiceService());
final assistantServiceProvider = Provider((_) => AssistantService());
final voiceProvider = StateNotifierProvider<VoiceController, VoiceState>(
    (ref) => VoiceController(ref));

class VoiceController extends StateNotifier<VoiceState> {
  VoiceController(this.ref) : super(const VoiceState());
  final Ref ref;
  Future<void> toggleListening() async {
    if (state.isListening) {
      await ref.read(voiceServiceProvider).stop();
      state = state.copyWith(isListening: false);
      return;
    }
    final available = await ref.read(voiceServiceProvider).initialize();
    if (!available) {
      state = state.copyWith(
          errorMessage: 'Pengenalan suara tidak tersedia. Gunakan input teks.');
      return;
    }
    state = state.copyWith(isListening: true, errorMessage: null);
    await ref
        .read(voiceServiceProvider)
        .listen((text) => state = state.copyWith(transcript: text));
  }

  void setTranscript(String text) => state = state.copyWith(transcript: text);
  Future<void> submit() async {
    final nav = ref.read(navigationProvider);
    if (state.transcript.trim().isEmpty || nav.activeStep == null) {
      state =
          state.copyWith(errorMessage: 'Masukkan pertanyaan terlebih dahulu.');
      return;
    }
    state = state.copyWith(isProcessing: true, errorMessage: null);
    final result = await ref.read(assistantServiceProvider).ask(
        question: state.transcript,
        active: nav.activeStep!,
        next: nav.nextStep,
        destination: nav.selectedDestination?.name ?? '',
        routeStatus: nav.routeStatus.name);
    state = state.copyWith(isProcessing: false, appResponse: result.text);
    await ref.read(ttsProvider).speak(result.text);
  }

  void clear() => state = const VoiceState();
}
