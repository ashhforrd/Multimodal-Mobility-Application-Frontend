import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_controller.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_state.dart';
import 'package:langkah_sahabat/features/recovery/application/recovery_controller.dart';

import '../../helpers/fakes.dart';

void main() {
  test('masuk pemulihan, memutar arahan, lalu menghitung ulang rute', () async {
    final tts = FakeTextToSpeechService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        ttsProvider.overrideWithValue(tts),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(FakeRouteService()),
      ],
    );
    addTearDown(container.dispose);
    final navigation = container.read(navigationProvider.notifier);
    await navigation.selectDestination(testDestination);
    await navigation.start();
    await navigation.markOffRoute();

    final recovery = container.read(recoveryProvider.notifier);
    await recovery.enter();

    expect(
        container.read(navigationProvider).routeStatus, RouteStatus.recovering);
    expect(container.read(recoveryProvider).recoveryPoints, hasLength(2));
    expect(tts.spokenTexts.last, contains('kembali'));

    await recovery.recalculate();

    expect(container.read(recoveryProvider).recalculationCount, 1);
    expect(tts.spokenTexts.last, contains('Putar balik'));

    recovery.finish();
    expect(container.read(navigationProvider).routeStatus, RouteStatus.active);
  });
}
