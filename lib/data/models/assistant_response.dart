class AssistantResponse {
  const AssistantResponse(
      {required this.text,
      this.suggestedInstruction,
      this.shouldUpdateInstruction = false,
      this.shouldOpenRecovery = false});
  final String text;
  final String? suggestedInstruction;
  final bool shouldUpdateInstruction, shouldOpenRecovery;
}
