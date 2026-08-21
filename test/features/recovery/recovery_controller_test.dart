import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langkah_sahabat/data/models/geo_point.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_controller.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_state.dart';
import 'package:langkah_sahabat/features/recovery/application/recovery_controller.dart';

import '../../helpers/fakes.dart';

void main() {
  test('masuk pemulihan, memutar arahan, lalu menghitung ulang rute', () async {
    final tts = FakeTextToSpeechService();
    final location = FakeLocationService();
    final routeService = FakeRouteService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        ttsProvider.overrideWithValue(tts),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(routeService),
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

    const updatedPosition = GeoPoint(
      latitude: -6.8891,
      longitude: 107.6082,
    );
    location.position = updatedPosition;
    await recovery.recalculate();

    expect(container.read(recoveryProvider).recalculationCount, 1);
    expect(routeService.routeOrigins.last, updatedPosition);
    expect(container.read(navigationProvider).currentPosition, updatedPosition);
    expect(
      container.read(navigationProvider).currentRoute!.origin,
      updatedPosition,
    );
    expect(
      tts.spokenTexts.last,
      container.read(navigationProvider).activeInstruction,
    );

    recovery.finish();
    expect(container.read(navigationProvider).routeStatus, RouteStatus.active);
  });
}
