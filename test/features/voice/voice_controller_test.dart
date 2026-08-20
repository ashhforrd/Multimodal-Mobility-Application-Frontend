import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langkah_sahabat/data/models/assistant_response.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_controller.dart';
import 'package:langkah_sahabat/features/voice/application/voice_controller.dart';

import '../../helpers/fakes.dart';

void main() {
  test('jawaban suara dapat memperjelas instruksi aktif', () async {
    const response = AssistantResponse(
      text: 'Belok kanan setelah minimarket biru.',
      suggestedInstruction: 'Belok kanan setelah minimarket biru.',
      shouldUpdateInstruction: true,
    );
    final tts = FakeTextToSpeechService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        ttsProvider.overrideWithValue(tts),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(FakeRouteService()),
        geminiServiceProvider.overrideWithValue(FakeGeminiService(response)),
      ],
    );
    addTearDown(container.dispose);
    final navigation = container.read(navigationProvider.notifier);
    await navigation.selectDestination(testDestination);
    await navigation.start();

    final voice = container.read(voiceProvider.notifier);
    voice.setTranscript('Saya bingung harus belok di mana?');
    await voice.submit();
    voice.applyResponse();

    expect(container.read(voiceProvider).appResponse, response.text);
    expect(container.read(navigationProvider).activeInstruction, response.text);
    expect(tts.spokenTexts.last, response.text);
  });

  test('jawaban dapat meminta modul pemulihan rute', () async {
    const response = AssistantResponse(
      text: 'Mari kembali ke rute.',
      shouldOpenRecovery: true,
    );
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        ttsProvider.overrideWithValue(FakeTextToSpeechService()),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(FakeRouteService()),
        geminiServiceProvider.overrideWithValue(FakeGeminiService(response)),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(navigationProvider.notifier)
        .selectDestination(testDestination);

    final voice = container.read(voiceProvider.notifier);
    voice.setTranscript('Saya tersesat');
    await voice.submit();

    expect(container.read(voiceProvider).shouldOpenRecovery, isTrue);
  });
}
