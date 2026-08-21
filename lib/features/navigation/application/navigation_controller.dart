import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/destination.dart';
import '../../../data/models/geo_point.dart';
import '../../../data/models/route_step.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/map_service.dart';
import '../../../data/services/navigation_simulation_service.dart';
import '../../../data/services/route_service.dart';
import '../../../data/services/text_to_speech_service.dart';
import 'navigation_state.dart';

final routeServiceProvider = Provider<RouteService>((_) => RouteService());
final locationServiceProvider =
    Provider<LocationService>((_) => LocationService());
final mapServiceProvider = Provider<MapService>((_) => MapService());
final navigationSimulationProvider = Provider<NavigationSimulationService>(
    (_) => const NavigationSimulationService());
final ttsProvider = Provider<TextToSpeechService>((_) => TextToSpeechService());
final hapticProvider = Provider<HapticService>((_) => HapticService());

final navigationProvider =
    StateNotifierProvider<NavigationController, NavigationState>(
  (ref) => NavigationController(
    routeService: ref.watch(routeServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    mapService: ref.watch(mapServiceProvider),
    navigationSimulationService: ref.watch(navigationSimulationProvider),
    textToSpeechService: ref.watch(ttsProvider),
    hapticService: ref.watch(hapticProvider),
  ),
);

class NavigationController extends StateNotifier<NavigationState> {
  NavigationController({
    required RouteService routeService,
    required LocationService locationService,
    required MapService mapService,
    NavigationSimulationService navigationSimulationService =
        const NavigationSimulationService(),
    required TextToSpeechService textToSpeechService,
    required HapticService hapticService,
  })  : _routeService = routeService,
        _locationService = locationService,
        _mapService = mapService,
        _navigationSimulationService = navigationSimulationService,
        _textToSpeechService = textToSpeechService,
        _hapticService = hapticService,
        super(const NavigationState());

  final RouteService _routeService;
  final LocationService _locationService;
  final MapService _mapService;
  final NavigationSimulationService _navigationSimulationService;
  final TextToSpeechService _textToSpeechService;
  final HapticService _hapticService;
  final Set<int> _alertedSteps = {};
  StreamSubscription<GeoPoint>? _positionSubscription;
  Timer? _simulationTimer;
  var _simulationPositionIndex = 0;
  var _simulationTickInProgress = false;

  Future<void> loadCurrentLocation() async {
    state = state.copyWith(
      isLoadingLocation: true,
      clearLocationMessage: true,
    );
    final snapshot = await _locationService.getCurrentPosition();
    state = state.copyWith(
      currentPosition: snapshot.point,
      isLoadingLocation: false,
      locationMessage: snapshot.message,
    );
  }

  Future<bool> selectDestination(Destination destination) async {
    if (state.currentPosition == null) await loadCurrentLocation();
    final origin = state.currentPosition;
    if (origin == null) {
      state = state.copyWith(
        routeErrorMessage: state.locationMessage ??
            'Posisi saat ini diperlukan untuk membuat rute.',
      );
      return false;
    }
    state = state.copyWith(
      isLoadingRoute: true,
      clearRouteError: true,
    );
    try {
      final route = await _routeService.getRoute(destination, origin: origin);
      _alertedSteps.clear();
      state = state.copyWith(
        selectedDestination: destination,
        currentRoute: route,
        currentStepIndex: 0,
        routeStatus: RouteStatus.preview,
        distanceToNextActionPoint: route.steps.first.distanceMeters,
        remainingDistanceMeters: route.totalDistanceMeters,
        estimatedRemainingMinutes: route.estimatedTimeMinutes,
        isActionAlertVisible: false,
        isLoadingRoute: false,
        clearOverride: true,
        clearRouteError: true,
      );
      return true;
    } on RouteServiceException catch (error) {
      state = state.copyWith(
        isLoadingRoute: false,
        routeErrorMessage: error.message,
      );
      return false;
    }
  }

  Future<bool> selectMapDestination(GeoPoint point) => selectDestination(
        Destination(
          id: 'map-${point.latitude}-${point.longitude}',
          name: 'Titik pilihan pada peta',
          address:
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
          latitude: point.latitude,
          longitude: point.longitude,
          description: 'Lokasi yang dipilih langsung melalui peta.',
        ),
      );

  void clearDestinationSelection() {
    _alertedSteps.clear();
    state = NavigationState(
      currentPosition: state.currentPosition,
      locationMessage: state.locationMessage,
    );
  }

  Future<void> finishJourney() async {
    final positionSubscription = _positionSubscription;
    _positionSubscription = null;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _alertedSteps.clear();
    state = NavigationState(
      currentPosition: state.currentPosition,
      locationMessage: state.locationMessage,
    );
    await positionSubscription?.cancel();
    await _textToSpeechService.stop();
  }

  Future<void> start() async {
    final route = state.currentRoute;
    if (route == null) return;
    state = state.copyWith(
      routeStatus: RouteStatus.active,
      currentStepIndex: 0,
      distanceToNextActionPoint: route.steps.first.distanceMeters,
      remainingDistanceMeters: route.totalDistanceMeters,
      estimatedRemainingMinutes: route.estimatedTimeMinutes,
      clearOverride: true,
    );
    await _positionSubscription?.cancel();
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _positionSubscription = _locationService.watchPosition().listen(
          (position) => unawaited(updatePosition(position)),
          onError: (_) => state = state.copyWith(
            locationMessage:
                'Pembaruan posisi berhenti. Instruksi visual tetap dapat digunakan.',
          ),
        );
    unawaited(speakActiveInstruction());
  }

  Future<void> updatePosition(GeoPoint position) async {
    final route = state.currentRoute;
    final activeStep = state.activeStep;
    if (route == null || activeStep == null) return;

    state = state.copyWith(currentPosition: position);
    if (_mapService.isOffRoute(position, route)) {
      await markOffRoute();
      return;
    }
    if (state.routeStatus == RouteStatus.recovering ||
        state.routeStatus == RouteStatus.offRoute) {
      finishRecovery();
    }

    final target = GeoPoint(
      latitude: activeStep.latitude,
      longitude: activeStep.longitude,
    );
    final directDistance = _mapService.distanceMeters(position, target);
    final distance = (activeStep.actionType == RouteActionType.arrive
            ? directDistance
            : _mapService.distanceAlongRouteMeters(position, target, route))
        .round();
    final laterDistance = route.steps
        .skip(state.currentStepIndex + 1)
        .fold<int>(0, (total, step) => total + step.distanceMeters);
    final remaining = distance + laterDistance;
    final minutes = route.totalDistanceMeters == 0
        ? 0
        : (route.estimatedTimeMinutes * remaining / route.totalDistanceMeters)
            .ceil();
    state = state.copyWith(
      distanceToNextActionPoint: distance,
      remainingDistanceMeters: remaining,
      estimatedRemainingMinutes: minutes,
    );

    if (directDistance <= MapService.arrivalThresholdMeters &&
        activeStep.actionType == RouteActionType.arrive) {
      final positionSubscription = _positionSubscription;
      _positionSubscription = null;
      _simulationTimer?.cancel();
      _simulationTimer = null;
      state = state.copyWith(
        routeStatus: RouteStatus.completed,
        distanceToNextActionPoint: 0,
        remainingDistanceMeters: 0,
        estimatedRemainingMinutes: 0,
        isActionAlertVisible: false,
      );
      await positionSubscription?.cancel();
      await _hapticService.actionPoint();
      unawaited(_textToSpeechService.speak('Anda telah tiba di tujuan.'));
      return;
    }

    if (state.isActionAlertVisible) return;

    if (activeStep.shouldTriggerHaptic &&
        activeStep.actionType != RouteActionType.arrive &&
        distance <= MapService.actionPointThresholdMeters &&
        !_alertedSteps.contains(state.currentStepIndex)) {
      _alertedSteps.add(state.currentStepIndex);
      await showActionAlert();
      return;
    }

    if (activeStep.actionType != RouteActionType.arrive &&
        _mapService.hasReachedOrPassed(position, target, route)) {
      await nextStep();
    }
  }

  Future<void> nextStep() async {
    final route = state.currentRoute;
    if (route == null) return;
    final index = state.currentStepIndex + 1;
    if (index >= route.steps.length) return;
    final remaining = _mapService.remainingDistanceMeters(route, index);
    final minutes = route.totalDistanceMeters == 0
        ? 0
        : (route.estimatedTimeMinutes * remaining / route.totalDistanceMeters)
            .ceil();
    state = state.copyWith(
      currentStepIndex: index,
      routeStatus: RouteStatus.active,
      distanceToNextActionPoint: route.steps[index].distanceMeters,
      remainingDistanceMeters: remaining,
      estimatedRemainingMinutes: minutes,
      isActionAlertVisible: false,
      clearOverride: true,
    );
    unawaited(speakActiveInstruction());
  }

  Future<void> showActionAlert() async {
    await _hapticService.actionPoint();
    state = state.copyWith(
      routeStatus: RouteStatus.approachingActionPoint,
      isActionAlertVisible: true,
      distanceToNextActionPoint: state.distanceToNextActionPoint == 0
          ? MapService.actionPointThresholdMeters.round()
          : state.distanceToNextActionPoint,
    );
    unawaited(speakActiveInstruction());
  }

  void dismissAlert() => state = state.copyWith(
        routeStatus: RouteStatus.active,
        isActionAlertVisible: false,
      );

  Future<void> speakActiveInstruction() =>
      _textToSpeechService.speak(state.activeInstruction);

  void useInstruction(String text) =>
      state = state.copyWith(overrideInstruction: text);

  Future<void> markOffRoute() async {
    if (state.routeStatus == RouteStatus.offRoute ||
        state.routeStatus == RouteStatus.recovering) {
      return;
    }
    await _hapticService.warning();
    state = state.copyWith(
      routeStatus: RouteStatus.offRoute,
      isActionAlertVisible: false,
    );
  }

  void beginRecovery() =>
      state = state.copyWith(routeStatus: RouteStatus.recovering);

  void finishRecovery() =>
      state = state.copyWith(routeStatus: RouteStatus.active);

  Future<bool> recalculateActiveRoute() async {
    final destination = state.selectedDestination;
    var position = state.currentPosition;
    if (destination == null) return false;
    if (position == null) {
      final snapshot = await _locationService.getCurrentPosition();
      position = snapshot.point;
      if (position == null) {
        state = state.copyWith(
          locationMessage: snapshot.message,
          routeErrorMessage: snapshot.message,
        );
        return false;
      }
    }
    state = state.copyWith(isLoadingRoute: true, clearRouteError: true);
    try {
      final route = await _routeService.getRoute(destination, origin: position);
      _alertedSteps.clear();
      state = state.copyWith(
        currentPosition: position,
        currentRoute: route,
        currentStepIndex: 0,
        routeStatus: RouteStatus.active,
        distanceToNextActionPoint: route.steps.first.distanceMeters,
        remainingDistanceMeters: route.totalDistanceMeters,
        estimatedRemainingMinutes: route.estimatedTimeMinutes,
        isActionAlertVisible: false,
        isLoadingRoute: false,
        clearOverride: true,
        clearRouteError: true,
      );
      unawaited(speakActiveInstruction());
      return true;
    } on RouteServiceException catch (error) {
      state = state.copyWith(
        isLoadingRoute: false,
        routeErrorMessage: error.message,
      );
      return false;
    }
  }

  Future<void> startDeveloperSimulation() async {
    final scenario = _navigationSimulationService.createCampusScenario();
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _simulationTimer?.cancel();
    _alertedSteps.clear();
    _simulationPositionIndex = 0;
    state = NavigationState(
      selectedDestination: scenario.route.destination,
      currentRoute: scenario.route,
      currentPosition: scenario.route.origin,
      routeStatus: RouteStatus.active,
      distanceToNextActionPoint: scenario.route.steps.first.distanceMeters,
      remainingDistanceMeters: scenario.route.totalDistanceMeters,
      estimatedRemainingMinutes: scenario.route.estimatedTimeMinutes,
    );
    unawaited(speakActiveInstruction());
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 650),
      (_) {
        if (_simulationTickInProgress ||
            state.isActionAlertVisible ||
            state.routeStatus == RouteStatus.completed ||
            state.routeStatus == RouteStatus.offRoute ||
            state.routeStatus == RouteStatus.recovering) {
          return;
        }
        if (_simulationPositionIndex >= scenario.positions.length) {
          _simulationTimer?.cancel();
          _simulationTimer = null;
          return;
        }
        final position = scenario.positions[_simulationPositionIndex++];
        _simulationTickInProgress = true;
        updatePosition(position).whenComplete(
          () => _simulationTickInProgress = false,
        );
      },
    );
  }

  Future<void> reset() async {
    final route = state.currentRoute;
    if (route == null) return;
    _alertedSteps.clear();
    state = state.copyWith(
      currentStepIndex: 0,
      routeStatus: RouteStatus.active,
      distanceToNextActionPoint: route.steps.first.distanceMeters,
      remainingDistanceMeters: route.totalDistanceMeters,
      estimatedRemainingMinutes: route.estimatedTimeMinutes,
      isActionAlertVisible: false,
      clearOverride: true,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}
