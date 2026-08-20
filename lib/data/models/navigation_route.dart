import 'destination.dart';
import 'geo_point.dart';
import 'route_step.dart';

class NavigationRoute {
  const NavigationRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.estimatedTimeMinutes,
    required this.totalDistanceMeters,
    required this.steps,
    required this.geometry,
  });

  final String id;
  final GeoPoint origin;
  final Destination destination;
  final int estimatedTimeMinutes, totalDistanceMeters;
  final List<RouteStep> steps;
  final List<GeoPoint> geometry;
}
