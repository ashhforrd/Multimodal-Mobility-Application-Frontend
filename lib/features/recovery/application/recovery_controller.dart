import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../navigation/application/navigation_controller.dart';
import 'recovery_state.dart';

final recoveryProvider =
    StateNotifierProvider<RecoveryController, RecoveryState>(
        (ref) => RecoveryController(ref));

class RecoveryController extends StateNotifier<RecoveryState> {
  RecoveryController(this.ref) : super(const RecoveryState());
  final Ref ref;
  Future<void> enter() async {
    state = state.copyWith(isRecovering: true, hasPlayedInitialAudio: true);
    await speak();
  }

  Future<void> speak() =>
      ref.read(ttsProvider).speak(state.recoveryInstruction);
  Future<void> recalculate() async {
    final count = state.recalculationCount + 1;
    final text =
        await ref.read(routeServiceProvider).recalculateRecovery(count);
    state =
        state.copyWith(recalculationCount: count, recoveryInstruction: text);
    await speak();
  }

  void finish() {
    ref.read(navigationProvider.notifier).recover();
    state = state.copyWith(isRecovering: false);
  }
}
