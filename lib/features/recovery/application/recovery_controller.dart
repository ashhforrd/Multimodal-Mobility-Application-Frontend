import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/route_service.dart';
import '../../../data/services/text_to_speech_service.dart';
import '../../navigation/application/navigation_controller.dart';
import 'recovery_state.dart';

final recoveryProvider =
    StateNotifierProvider<RecoveryController, RecoveryState>(
  (ref) => RecoveryController(
    ref: ref,
    routeService: ref.watch(routeServiceProvider),
    textToSpeechService: ref.watch(ttsProvider),
  ),
);

class RecoveryController extends StateNotifier<RecoveryState> {
  RecoveryController({
    required Ref ref,
    required RouteService routeService,
    required TextToSpeechService textToSpeechService,
  })  : _ref = ref,
        _routeService = routeService,
        _textToSpeechService = textToSpeechService,
        super(const RecoveryState());

  final Ref _ref;
  final RouteService _routeService;
  final TextToSpeechService _textToSpeechService;

  Future<void> enter() async {
    final navigation = _ref.read(navigationProvider);
    final route = navigation.currentRoute;
    final position = navigation.currentPosition;
    if (route == null || position == null) {
      state = state.copyWith(
        errorMessage: 'Data posisi atau rute belum tersedia.',
      );
      return;
    }
    _ref.read(navigationProvider.notifier).beginRecovery();
    state = const RecoveryState(isRecalculating: true);
    try {
      final plan = await _routeService.getRecoveryPlan(
        currentPosition: position,
        route: route,
        currentStepIndex: navigation.currentStepIndex,
      );
      state = state.copyWith(
        isRecovering: true,
        recoveryInstruction: plan.instruction,
        recoveryPoints: plan.points,
        rejoinPoint: plan.rejoinPoint,
        hasPlayedInitialAudio: true,
        isRecalculating: false,
        errorMessage: null,
      );
      await speak();
    } on RouteServiceException catch (error) {
      state = state.copyWith(
        isRecalculating: false,
        errorMessage: error.message,
      );
    }
  }

  Future<void> speak() => _textToSpeechService.speak(state.recoveryInstruction);

  Future<void> recalculate() async {
    if (state.isRecalculating) return;
    state = state.copyWith(isRecalculating: true, errorMessage: null);
    await _ref.read(navigationProvider.notifier).loadCurrentLocation();
    final navigation = _ref.read(navigationProvider);
    final route = navigation.currentRoute;
    final position = navigation.currentPosition;
    if (route == null || position == null) {
      state = state.copyWith(
        isRecalculating: false,
        errorMessage:
            'Posisi terbaru belum tersedia. Periksa GPS lalu coba kembali.',
      );
      return;
    }
    final count = state.recalculationCount + 1;
    try {
      final plan = await _routeService.getRecoveryPlan(
        currentPosition: position,
        route: route,
        currentStepIndex: navigation.currentStepIndex,
        recalculationCount: count,
      );
      state = state.copyWith(
        recalculationCount: count,
        recoveryInstruction: plan.instruction,
        recoveryPoints: plan.points,
        rejoinPoint: plan.rejoinPoint,
        isRecalculating: false,
      );
      await speak();
    } on RouteServiceException catch (error) {
      state = state.copyWith(
        isRecalculating: false,
        errorMessage: error.message,
      );
    }
  }

  void finish() {
    _ref.read(navigationProvider.notifier).finishRecovery();
    state = state.copyWith(isRecovering: false);
  }
}
