class VoiceState {
  const VoiceState(
      {this.isListening = false,
      this.isConversationActive = false,
      this.transcript = '',
      this.lastQuestion = '',
      this.appResponse = '',
      this.isProcessing = false,
      this.isSpeaking = false,
      this.suggestedInstruction,
      this.shouldOpenRecovery = false,
      this.errorMessage});
  final bool isListening, isConversationActive, isProcessing, isSpeaking;
  final String transcript, lastQuestion, appResponse;
  final String? suggestedInstruction;
  final bool shouldOpenRecovery;
  final String? errorMessage;
  VoiceState copyWith(
          {bool? isListening,
          bool? isConversationActive,
          String? transcript,
          String? lastQuestion,
          String? appResponse,
          bool? isProcessing,
          bool? isSpeaking,
          String? suggestedInstruction,
          bool? shouldOpenRecovery,
          String? errorMessage}) =>
      VoiceState(
          isListening: isListening ?? this.isListening,
          isConversationActive:
              isConversationActive ?? this.isConversationActive,
          transcript: transcript ?? this.transcript,
          lastQuestion: lastQuestion ?? this.lastQuestion,
          appResponse: appResponse ?? this.appResponse,
          isProcessing: isProcessing ?? this.isProcessing,
          isSpeaking: isSpeaking ?? this.isSpeaking,
          suggestedInstruction:
              suggestedInstruction ?? this.suggestedInstruction,
          shouldOpenRecovery: shouldOpenRecovery ?? this.shouldOpenRecovery,
          errorMessage: errorMessage);
}
