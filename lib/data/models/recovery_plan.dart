import 'geo_point.dart';

class RecoveryPlan {
  const RecoveryPlan({
    required this.instruction,
    required this.points,
    required this.rejoinPoint,
  });

  final String instruction;
  final List<GeoPoint> points;
  final GeoPoint rejoinPoint;
}
