import 'package:flutter_test/flutter_test.dart';
import 'package:langkah_sahabat/data/models/geo_point.dart';
import 'package:langkah_sahabat/data/services/map_service.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_controller.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_state.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeTextToSpeechService tts;
  late FakeHapticService haptic;
  late NavigationController controller;

  setUp(() {
    tts = FakeTextToSpeechService();
    haptic = FakeHapticService();
    controller = NavigationController(
      routeService: FakeRouteService(),
      locationService: FakeLocationService(),
      mapService: MapService(),
      textToSpeechService: tts,
      hapticService: haptic,
    );
  });

  tearDown(() => controller.dispose());

  group('NavigationController', () {
    test('memisahkan pemilihan tujuan, pratinjau, dan mulai navigasi',
        () async {
      await controller.selectDestination(testDestination);

      expect(controller.state.routeStatus, RouteStatus.preview);
      expect(controller.state.currentRoute, isNotNull);
      expect(controller.state.currentPosition, testOrigin);

      await controller.start();

      expect(controller.state.routeStatus, RouteStatus.active);
      expect(tts.spokenTexts.last, controller.state.activeInstruction);
    });

    test('memicu haptik dan dialog pada titik aksi', () async {
      await controller.selectDestination(testDestination);
      await controller.start();
      await controller.nextStep();
      await controller.nextStep();
      final action = controller.state.activeStep!;

      await controller.updatePosition(
        GeoPoint(latitude: action.latitude, longitude: action.longitude),
      );

      expect(haptic.actionPointCount, 1);
      expect(controller.state.isActionAlertVisible, isTrue);
      expect(controller.state.routeStatus, RouteStatus.approachingActionPoint);
      expect(tts.spokenTexts.last, controller.state.activeInstruction);
    });

    test('mendeteksi keluar rute dan memicu peringatan haptik', () async {
      await controller.selectDestination(testDestination);
      await controller.start();

      await controller.updatePosition(
        const GeoPoint(latitude: -6.8800, longitude: 107.6200),
      );

      expect(controller.state.routeStatus, RouteStatus.offRoute);
      expect(haptic.warningCount, 1);
    });

    test('mengakhiri pemulihan otomatis setelah posisi kembali ke rute',
        () async {
      await controller.selectDestination(testDestination);
      await controller.start();
      await controller.markOffRoute();
      controller.beginRecovery();

      await controller.updatePosition(testOrigin);

      expect(controller.state.routeStatus, RouteStatus.active);
    });

    test('tidak membuat rute palsu ketika GPS tidak tersedia', () async {
      final safeController = NavigationController(
        routeService: FakeRouteService(),
        locationService: FakeUnavailableLocationService(),
        mapService: MapService(),
        textToSpeechService: tts,
        hapticService: haptic,
      );
      addTearDown(safeController.dispose);

      final success = await safeController.selectDestination(testDestination);

      expect(success, isFalse);
      expect(safeController.state.currentRoute, isNull);
      expect(safeController.state.routeErrorMessage, contains('GPS'));
    });

    test('selesai perjalanan menghentikan audio dan membersihkan rute',
        () async {
      await controller.selectDestination(testDestination);
      await controller.start();

      await controller.finishJourney();

      expect(controller.state.routeStatus, RouteStatus.idle);
      expect(controller.state.currentRoute, isNull);
      expect(controller.state.selectedDestination, isNull);
      expect(controller.state.currentPosition, testOrigin);
      expect(tts.stopCount, 1);
    });
  });
}
