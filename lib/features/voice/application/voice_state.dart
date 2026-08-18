class VoiceState {
  const VoiceState(
      {this.isListening = false,
      this.transcript = '',
      this.appResponse = '',
      this.isProcessing = false,
      this.isSpeaking = false,
      this.errorMessage});
  final bool isListening, isProcessing, isSpeaking;
  final String transcript, appResponse;
  final String? errorMessage;
  VoiceState copyWith(
          {bool? isListening,
          String? transcript,
          String? appResponse,
          bool? isProcessing,
          bool? isSpeaking,
          String? errorMessage}) =>
      VoiceState(
          isListening: isListening ?? this.isListening,
          transcript: transcript ?? this.transcript,
          appResponse: appResponse ?? this.appResponse,
          isProcessing: isProcessing ?? this.isProcessing,
          isSpeaking: isSpeaking ?? this.isSpeaking,
          errorMessage: errorMessage);
}
