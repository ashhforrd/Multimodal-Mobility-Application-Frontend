import 'package:flutter/services.dart';

class HapticService {
  Future<void> actionPoint() => HapticFeedback.mediumImpact();
  Future<void> warning() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await HapticFeedback.heavyImpact();
  }
}
