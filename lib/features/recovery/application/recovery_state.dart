import '../../../data/models/geo_point.dart';

class RecoveryState {
  const RecoveryState(
      {this.isRecovering = false,
      this.recoveryInstruction =
          'Rute pemulihan sedang disiapkan dari posisi Anda.',
      this.recoveryPoints = const [],
      this.rejoinPoint,
      this.hasPlayedInitialAudio = false,
      this.recalculationCount = 0,
      this.isRecalculating = false,
      this.errorMessage});
  final bool isRecovering, hasPlayedInitialAudio;
  final String recoveryInstruction;
  final List<GeoPoint> recoveryPoints;
  final GeoPoint? rejoinPoint;
  final int recalculationCount;
  final bool isRecalculating;
  final String? errorMessage;
  RecoveryState copyWith(
          {bool? isRecovering,
          String? recoveryInstruction,
          List<GeoPoint>? recoveryPoints,
          GeoPoint? rejoinPoint,
          bool? hasPlayedInitialAudio,
          int? recalculationCount,
          bool? isRecalculating,
          String? errorMessage}) =>
      RecoveryState(
          isRecovering: isRecovering ?? this.isRecovering,
          recoveryInstruction: recoveryInstruction ?? this.recoveryInstruction,
          recoveryPoints: recoveryPoints ?? this.recoveryPoints,
          rejoinPoint: rejoinPoint ?? this.rejoinPoint,
          hasPlayedInitialAudio:
              hasPlayedInitialAudio ?? this.hasPlayedInitialAudio,
          recalculationCount: recalculationCount ?? this.recalculationCount,
          isRecalculating: isRecalculating ?? this.isRecalculating,
          errorMessage: errorMessage);
}
