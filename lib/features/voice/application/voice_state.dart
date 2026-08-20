class VoiceState {
  const VoiceState(
      {this.isListening = false,
      this.transcript = '',
      this.appResponse = '',
      this.isProcessing = false,
      this.isSpeaking = false,
      this.suggestedInstruction,
      this.shouldOpenRecovery = false,
      this.errorMessage});
  final bool isListening, isProcessing, isSpeaking;
  final String transcript, appResponse;
  final String? suggestedInstruction;
  final bool shouldOpenRecovery;
  final String? errorMessage;
  VoiceState copyWith(
          {bool? isListening,
          String? transcript,
          String? appResponse,
          bool? isProcessing,
          bool? isSpeaking,
          String? suggestedInstruction,
          bool? shouldOpenRecovery,
          String? errorMessage}) =>
      VoiceState(
          isListening: isListening ?? this.isListening,
          transcript: transcript ?? this.transcript,
          appResponse: appResponse ?? this.appResponse,
          isProcessing: isProcessing ?? this.isProcessing,
          isSpeaking: isSpeaking ?? this.isSpeaking,
          suggestedInstruction:
              suggestedInstruction ?? this.suggestedInstruction,
          shouldOpenRecovery: shouldOpenRecovery ?? this.shouldOpenRecovery,
          errorMessage: errorMessage);
}
