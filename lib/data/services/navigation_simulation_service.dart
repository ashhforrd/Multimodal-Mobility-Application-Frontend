import 'dart:math' as math;

import '../models/destination.dart';
import '../models/geo_point.dart';
import '../models/navigation_route.dart';
import '../models/route_step.dart';

class DeveloperNavigationScenario {
  const DeveloperNavigationScenario({
    required this.route,
    required this.positions,
  });

  final NavigationRoute route;
  final List<GeoPoint> positions;
}

/// Deterministic input for developer testing. It never calls GPS or a network.
class NavigationSimulationService {
  const NavigationSimulationService();

  DeveloperNavigationScenario createCampusScenario() {
    const origin = GeoPoint(latitude: -6.89150, longitude: 107.61050);
    const slightRight = GeoPoint(latitude: -6.89090, longitude: 107.61050);
    const slightLeft = GeoPoint(latitude: -6.89040, longitude: 107.61100);
    const turnLeft = GeoPoint(latitude: -6.88980, longitude: 107.61100);
    const turnRight = GeoPoint(latitude: -6.88980, longitude: 107.61030);
    const destinationPoint = GeoPoint(latitude: -6.88920, longitude: 107.61030);
    const destination = Destination(
      id: 'developer-simulation-destination',
      name: 'Tujuan simulasi kampus',
      address: 'Area kampus, Bandung',
      latitude: -6.88920,
      longitude: 107.61030,
      description: 'Tujuan khusus pengujian developer.',
    );
    const geometry = [
      origin,
      slightRight,
      slightLeft,
      turnLeft,
      turnRight,
      destinationPoint,
    ];
    final segmentDistances = <int>[
      for (var index = 0; index < geometry.length - 1; index++)
        _distanceMeters(geometry[index], geometry[index + 1]).round(),
    ];
    final totalDistance =
        segmentDistances.fold<int>(0, (total, distance) => total + distance);
    final route = NavigationRoute(
      id: 'developer-simulation-route',
      origin: origin,
      destination: destination,
      estimatedTimeMinutes: (totalDistance / 75).ceil(),
      totalDistanceMeters: totalDistance,
      steps: [
        RouteStep(
          id: 'simulation-slight-right',
          instruction: 'Serong sedikit ke kanan di persimpangan depan.',
          landmarkName: 'Persimpangan pertama',
          distanceMeters: segmentDistances[0],
          actionType: RouteActionType.slightRight,
          latitude: slightRight.latitude,
          longitude: slightRight.longitude,
          shouldTriggerHaptic: true,
        ),
        RouteStep(
          id: 'simulation-slight-left',
          instruction: 'Serong sedikit ke kiri mengikuti jalur pejalan kaki.',
          landmarkName: 'Jalur pejalan kaki',
          distanceMeters: segmentDistances[1],
          actionType: RouteActionType.slightLeft,
          latitude: slightLeft.latitude,
          longitude: slightLeft.longitude,
          shouldTriggerHaptic: true,
        ),
        RouteStep(
          id: 'simulation-turn-left',
          instruction: 'Belok kiri setelah taman.',
          landmarkName: 'Taman kampus',
          distanceMeters: segmentDistances[2],
          actionType: RouteActionType.turnLeft,
          latitude: turnLeft.latitude,
          longitude: turnLeft.longitude,
          shouldTriggerHaptic: true,
        ),
        RouteStep(
          id: 'simulation-turn-right',
          instruction: 'Belok kanan di ujung jalan.',
          landmarkName: 'Ujung jalan',
          distanceMeters: segmentDistances[3],
          actionType: RouteActionType.turnRight,
          latitude: turnRight.latitude,
          longitude: turnRight.longitude,
          shouldTriggerHaptic: true,
        ),
        RouteStep(
          id: 'simulation-arrive',
          instruction: 'Anda telah tiba di tujuan simulasi kampus.',
          landmarkName: destination.name,
          distanceMeters: segmentDistances[4],
          actionType: RouteActionType.arrive,
          latitude: destinationPoint.latitude,
          longitude: destinationPoint.longitude,
          shouldTriggerHaptic: true,
        ),
      ],
      geometry: geometry,
    );
    return DeveloperNavigationScenario(
      route: route,
      positions: _interpolatePath(geometry),
    );
  }

  List<GeoPoint> _interpolatePath(List<GeoPoint> points) {
    final positions = <GeoPoint>[];
    for (var index = 0; index < points.length - 1; index++) {
      final start = points[index];
      final end = points[index + 1];
      final distance = _distanceMeters(start, end);
      final samples = math.max(1, (distance / 5).ceil());
      final course = _bearingDegrees(start, end);
      for (var sample = index == 0 ? 0 : 1; sample <= samples; sample++) {
        final fraction = sample / samples;
        positions.add(
          GeoPoint(
            latitude:
                start.latitude + (end.latitude - start.latitude) * fraction,
            longitude:
                start.longitude + (end.longitude - start.longitude) * fraction,
            courseDegrees: course,
          ),
        );
      }
    }
    return positions;
  }

  double _distanceMeters(GeoPoint first, GeoPoint second) {
    const earthRadius = 6371000.0;
    final lat1 = _radians(first.latitude);
    final lat2 = _radians(second.latitude);
    final deltaLat = _radians(second.latitude - first.latitude);
    final deltaLon = _radians(second.longitude - first.longitude);
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _bearingDegrees(GeoPoint start, GeoPoint end) {
    final startLatitude = _radians(start.latitude);
    final endLatitude = _radians(end.latitude);
    final deltaLongitude = _radians(end.longitude - start.longitude);
    final y = math.sin(deltaLongitude) * math.cos(endLatitude);
    final x = math.cos(startLatitude) * math.sin(endLatitude) -
        math.sin(startLatitude) *
            math.cos(endLatitude) *
            math.cos(deltaLongitude);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
