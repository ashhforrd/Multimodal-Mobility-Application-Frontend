import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/destination.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/route_service.dart';
import '../../../data/services/text_to_speech_service.dart';
import 'navigation_state.dart';

final routeServiceProvider = Provider((_) => RouteService());
final ttsProvider = Provider((_) => TextToSpeechService());
final hapticProvider = Provider((_) => HapticService());
final navigationProvider =
    StateNotifierProvider<NavigationController, NavigationState>(
        (ref) => NavigationController(ref));

class NavigationController extends StateNotifier<NavigationState> {
  NavigationController(this.ref) : super(const NavigationState());
  final Ref ref;

  Future<void> selectDestination(Destination destination) async {
    final route = await ref.read(routeServiceProvider).getRoute(destination);
    state = NavigationState(
        selectedDestination: destination,
        currentRoute: route,
        routeStatus: RouteStatus.preview,
        distanceToNextActionPoint: route.steps.first.distanceMeters);
  }

  void start() => state = state.copyWith(
      routeStatus: RouteStatus.active,
      currentStepIndex: 0,
      clearOverride: true);
  void nextStep() {
    final route = state.currentRoute;
    if (route == null) return;
    final index = state.currentStepIndex + 1;
    if (index >= route.steps.length) return;
    state = state.copyWith(
        currentStepIndex: index,
        routeStatus: index == route.steps.length - 1
            ? RouteStatus.completed
            : RouteStatus.active,
        distanceToNextActionPoint: route.steps[index].distanceMeters,
        isActionAlertVisible: false,
        clearOverride: true);
  }

  Future<void> showActionAlert() async {
    await ref.read(hapticProvider).actionPoint();
    state = state.copyWith(
        routeStatus: RouteStatus.approachingActionPoint,
        isActionAlertVisible: true,
        distanceToNextActionPoint: 20);
  }

  void dismissAlert() => state = state.copyWith(
      routeStatus: RouteStatus.active, isActionAlertVisible: false);
  Future<void> speakActive() =>
      ref.read(ttsProvider).speak(state.activeInstruction);
  void useInstruction(String text) =>
      state = state.copyWith(overrideInstruction: text);
  Future<void> offRoute() async {
    await ref.read(hapticProvider).warning();
    state = state.copyWith(
        routeStatus: RouteStatus.offRoute, isActionAlertVisible: false);
  }

  void recover() => state = state.copyWith(routeStatus: RouteStatus.active);
  void reset() => state = state.copyWith(
      currentStepIndex: 0,
      routeStatus: RouteStatus.active,
      isActionAlertVisible: false,
      clearOverride: true);
}
