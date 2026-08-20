import 'package:flutter_test/flutter_test.dart';
import 'package:langkah_sahabat/data/models/geo_point.dart';
import 'package:langkah_sahabat/data/services/map_service.dart';

import '../../helpers/fakes.dart';

void main() {
  const origin = GeoPoint(latitude: -6.8900, longitude: 107.6090);
  final route = buildTestRoute(origin: origin);
  final service = MapService();

  group('MapService', () {
    test('menghitung jarak geografis dalam meter', () {
      const point = GeoPoint(latitude: -6.8890, longitude: 107.6090);

      expect(service.distanceMeters(origin, point), closeTo(111, 2));
    });

    test('mengukur jarak terhadap segmen, bukan hanya titik rute', () {
      const midpoint = GeoPoint(latitude: -6.89025, longitude: 107.60925);

      expect(service.nearestDistanceToRoute(midpoint, route), lessThan(2));
      expect(service.isOffRoute(midpoint, route), isFalse);
    });

    test('mendeteksi posisi yang keluar dari rute', () {
      const farPoint = GeoPoint(latitude: -6.8800, longitude: 107.6200);

      expect(service.isOffRoute(farPoint, route), isTrue);
    });

    test('menghitung jarak tersisa dari langkah aktif', () {
      expect(service.remainingDistanceMeters(route, 2), 390);
    });
  });
}
