import 'package:langkah_sahabat/data/models/assistant_response.dart';
import 'package:langkah_sahabat/data/models/destination.dart';
import 'package:langkah_sahabat/data/models/geo_point.dart';
import 'package:langkah_sahabat/data/models/navigation_route.dart';
import 'package:langkah_sahabat/data/models/recovery_plan.dart';
import 'package:langkah_sahabat/data/models/route_step.dart';
import 'package:langkah_sahabat/data/services/gemini_service.dart';
import 'package:langkah_sahabat/data/services/haptic_service.dart';
import 'package:langkah_sahabat/data/services/location_service.dart';
import 'package:langkah_sahabat/data/services/map_service.dart';
import 'package:langkah_sahabat/data/services/route_service.dart';
import 'package:langkah_sahabat/data/services/text_to_speech_service.dart';
import 'package:langkah_sahabat/data/services/voice_service.dart';

const testDestination = Destination(
  id: 'library',
  name: 'Perpustakaan Pusat',
  address: 'Jalan Akademik 1',
  latitude: -6.8920,
  longitude: 107.6107,
  description: 'Tujuan pengujian',
);

const testOrigin = GeoPoint(
  latitude: -6.8900,
  longitude: 107.6090,
);

NavigationRoute buildTestRoute({
  Destination destination = testDestination,
  GeoPoint origin = testOrigin,
}) =>
    NavigationRoute(
      id: 'test-route-${destination.id}',
      origin: origin,
      destination: destination,
      estimatedTimeMinutes: 12,
      totalDistanceMeters: 850,
      steps: [
        RouteStep(
          id: '1',
          instruction: 'Mulai berjalan ke arah gerbang utama.',
          landmarkName: 'Pos keamanan',
          distanceMeters: 120,
          actionType: RouteActionType.start,
          latitude: origin.latitude,
          longitude: origin.longitude,
        ),
        const RouteStep(
          id: '2',
          instruction: 'Berjalan lurus menuju gerbang utama.',
          landmarkName: 'Gerbang utama',
          distanceMeters: 180,
          actionType: RouteActionType.straight,
          latitude: -6.8905,
          longitude: 107.6095,
        ),
        const RouteStep(
          id: '3',
          instruction: 'Belok kanan setelah minimarket.',
          landmarkName: 'Minimarket kampus',
          distanceMeters: 90,
          actionType: RouteActionType.turnRight,
          latitude: -6.8910,
          longitude: 107.6100,
          shouldTriggerHaptic: true,
        ),
        const RouteStep(
          id: '4',
          instruction: 'Lanjutkan melewati gedung perpustakaan.',
          landmarkName: 'Perpustakaan Pusat',
          distanceMeters: 220,
          actionType: RouteActionType.straight,
          latitude: -6.8920,
          longitude: 107.6107,
        ),
        const RouteStep(
          id: '5',
          instruction: 'Menyeberang di jalur pejalan kaki.',
          landmarkName: 'Jalur penyeberangan',
          distanceMeters: 80,
          actionType: RouteActionType.cross,
          latitude: -6.8925,
          longitude: 107.6110,
          shouldTriggerHaptic: true,
        ),
        RouteStep(
          id: '6',
          instruction: 'Anda telah tiba di ${destination.name}.',
          landmarkName: destination.name,
          distanceMeters: 0,
          actionType: RouteActionType.arrive,
          latitude: destination.latitude,
          longitude: destination.longitude,
          shouldTriggerHaptic: true,
        ),
      ],
      geometry: [
        origin,
        const GeoPoint(latitude: -6.8905, longitude: 107.6095),
        const GeoPoint(latitude: -6.8910, longitude: 107.6100),
        const GeoPoint(latitude: -6.8920, longitude: 107.6107),
        GeoPoint(
          latitude: destination.latitude,
          longitude: destination.longitude,
        ),
      ],
    );

class FakeLocationService extends LocationService {
  FakeLocationService({this.position = testOrigin});

  final GeoPoint position;

  @override
  Future<LocationSnapshot> getCurrentPosition() async => LocationSnapshot(
        point: position,
        message: 'Posisi pengujian digunakan.',
      );

  @override
  Stream<GeoPoint> watchPosition() => const Stream.empty();
}

class FakeUnavailableLocationService extends LocationService {
  @override
  Future<LocationSnapshot> getCurrentPosition() async => const LocationSnapshot(
        point: null,
        message: 'GPS tidak tersedia dalam pengujian.',
      );

  @override
  Stream<GeoPoint> watchPosition() => const Stream.empty();
}

class FakeRouteService extends RouteService {
  @override
  Future<NavigationRoute> getRoute(
    Destination destination, {
    required GeoPoint origin,
  }) async =>
      buildTestRoute(destination: destination, origin: origin);

  @override
  Future<RecoveryPlan> getRecoveryPlan({
    required GeoPoint currentPosition,
    required NavigationRoute route,
    required int currentStepIndex,
    int recalculationCount = 0,
  }) async {
    final rejoin = GeoPoint(
      latitude: route
          .steps[(currentStepIndex + 1).clamp(0, route.steps.length - 1)]
          .latitude,
      longitude: route
          .steps[(currentStepIndex + 1).clamp(0, route.steps.length - 1)]
          .longitude,
    );
    return RecoveryPlan(
      instruction: recalculationCount.isEven
          ? 'Berjalan kembali ke rute utama.'
          : 'Putar balik menuju rute utama.',
      points: [currentPosition, rejoin],
      rejoinPoint: rejoin,
    );
  }
}

class FakeMapService extends MapService {
  FakeMapService({this.results = const [testDestination]});

  final List<Destination> results;

  @override
  Future<List<Destination>> searchDestinations(
    String query, {
    GeoPoint? nearby,
  }) async =>
      results;
}

class FakeTextToSpeechService extends TextToSpeechService {
  final List<String> spokenTexts = [];

  @override
  Future<void> speak(String text) async => spokenTexts.add(text);

  @override
  Future<void> stop() async {}
}

class FakeHapticService extends HapticService {
  int actionPointCount = 0;
  int warningCount = 0;

  @override
  Future<void> actionPoint() async => actionPointCount++;

  @override
  Future<void> warning() async => warningCount++;
}

class FakeGeminiService extends GeminiService {
  FakeGeminiService(this.response);

  final AssistantResponse response;
  int askCount = 0;
  final List<String> questions = [];

  @override
  Future<AssistantResponse> ask({
    required String question,
    required RouteStep active,
    RouteStep? next,
    required String destination,
    required String routeStatus,
  }) async {
    askCount++;
    questions.add(question);
    return response;
  }
}

class FakeVoiceService extends VoiceService {
  FakeVoiceService({this.available = true});

  final bool available;
  int listenCount = 0;
  int stopCount = 0;
  int cancelCount = 0;
  void Function(String)? _onText;
  void Function()? _onCompleted;

  @override
  Future<bool> initialize() async => available;

  @override
  Future<void> listen({
    required void Function(String) onText,
    required void Function() onCompleted,
  }) async {
    listenCount++;
    _onText = onText;
    _onCompleted = onCompleted;
  }

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> cancel() async => cancelCount++;

  void emitText(String text) => _onText?.call(text);

  void complete() => _onCompleted?.call();
}
