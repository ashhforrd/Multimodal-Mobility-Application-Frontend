enum RouteActionType {
  start,
  straight,
  slightLeft,
  slightRight,
  turnLeft,
  turnRight,
  sharpLeft,
  sharpRight,
  uTurn,
  cross,
  arrive,
  recover
}

class RouteStep {
  const RouteStep(
      {required this.id,
      required this.instruction,
      required this.landmarkName,
      required this.distanceMeters,
      required this.actionType,
      required this.latitude,
      required this.longitude,
      this.shouldTriggerHaptic = false});
  final String id, instruction, landmarkName;
  final int distanceMeters;
  final RouteActionType actionType;
  final double latitude, longitude;
  final bool shouldTriggerHaptic;
}
