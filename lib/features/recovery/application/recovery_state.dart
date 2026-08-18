class RecoveryState {
  const RecoveryState(
      {this.isRecovering = false,
      this.recoveryInstruction =
          'Putar balik perlahan dan kembali menuju minimarket kampus.',
      this.hasPlayedInitialAudio = false,
      this.recalculationCount = 0});
  final bool isRecovering, hasPlayedInitialAudio;
  final String recoveryInstruction;
  final int recalculationCount;
  RecoveryState copyWith(
          {bool? isRecovering,
          String? recoveryInstruction,
          bool? hasPlayedInitialAudio,
          int? recalculationCount}) =>
      RecoveryState(
          isRecovering: isRecovering ?? this.isRecovering,
          recoveryInstruction: recoveryInstruction ?? this.recoveryInstruction,
          hasPlayedInitialAudio:
              hasPlayedInitialAudio ?? this.hasPlayedInitialAudio,
          recalculationCount: recalculationCount ?? this.recalculationCount);
}
