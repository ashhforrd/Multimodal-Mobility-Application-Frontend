import 'destination.dart';
import 'route_step.dart';

class NavigationRoute {
  const NavigationRoute(
      {required this.id,
      required this.destination,
      required this.estimatedTimeMinutes,
      required this.totalDistanceMeters,
      required this.steps});
  final String id;
  final Destination destination;
  final int estimatedTimeMinutes, totalDistanceMeters;
  final List<RouteStep> steps;
}
