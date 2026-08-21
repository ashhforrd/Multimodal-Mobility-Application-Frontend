import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langkah_sahabat/data/models/geo_point.dart';
import 'package:langkah_sahabat/data/models/route_step.dart';
import 'package:langkah_sahabat/data/services/route_service.dart';

import '../../helpers/fakes.dart';

void main() {
  const origin = GeoPoint(latitude: -6.8900, longitude: 107.6090);

  group('RouteService', () {
    test('memetakan respons OSRM menjadi rute pejalan kaki', () async {
      final service = RouteService(
        baseUrl: 'https://router.example/foot',
        client: MockClient(
          (request) async => http.Response(_osrmResponse(request.url), 200),
        ),
      );

      final route = await service.getRoute(testDestination, origin: origin);

      expect(route.origin, origin);
      expect(route.destination, testDestination);
      expect(route.geometry, hasLength(3));
      expect(route.steps, hasLength(2));
      expect(route.steps.first.instruction, contains('Belok kanan'));
      expect(route.steps.first.actionType, RouteActionType.turnRight);
      expect(route.steps.first.latitude, middleLatitude(origin));
      expect(route.steps.first.longitude, middleLongitude(origin));
      expect(route.steps.last.actionType, RouteActionType.arrive);
      expect(route.totalDistanceMeters, 120);
      expect(route.estimatedTimeMinutes, 2);
    });

    test('membentuk rute pemulihan nyata menuju titik bergabung', () async {
      final service = RouteService(
        baseUrl: 'https://router.example/foot',
        client: MockClient(
          (request) async => http.Response(_osrmResponse(request.url), 200),
        ),
      );
      final route = await service.getRoute(testDestination, origin: origin);
      const current = GeoPoint(latitude: -6.8895, longitude: 107.6085);

      final plan = await service.getRecoveryPlan(
        currentPosition: current,
        route: route,
        currentStepIndex: 0,
      );

      expect(plan.points.first, current);
      expect(plan.points.last, plan.rejoinPoint);
      expect(plan.instruction, contains(route.steps[1].landmarkName));
    });

    test('membedakan manuver serong dari belokan biasa', () async {
      final service = RouteService(
        baseUrl: 'https://router.example/foot',
        client: MockClient(
          (request) async => http.Response(
            _osrmResponse(request.url, modifier: 'slight left'),
            200,
          ),
        ),
      );

      final route = await service.getRoute(testDestination, origin: origin);

      expect(route.steps.first.actionType, RouteActionType.slightLeft);
      expect(route.steps.first.instruction, contains('Serong sedikit ke kiri'));
    });

    test('memberikan error ramah ketika OSRM tidak menemukan rute', () async {
      final service = RouteService(
        baseUrl: 'https://router.example/foot',
        client: MockClient(
          (_) async => http.Response('{"code":"NoRoute","routes":[]}', 200),
        ),
      );

      expect(
        () => service.getRoute(testDestination, origin: origin),
        throwsA(
          isA<RouteServiceException>().having(
            (error) => error.message,
            'message',
            contains('Tidak ditemukan'),
          ),
        ),
      );
    });
  });
}

double middleLatitude(GeoPoint origin) =>
    (origin.latitude + testDestination.latitude) / 2;

double middleLongitude(GeoPoint origin) =>
    (origin.longitude + testDestination.longitude) / 2;

String _osrmResponse(Uri uri, {String modifier = 'right'}) {
  final coordinateSegment = uri.pathSegments.last;
  final pairs = coordinateSegment.split(';');
  final start = pairs.first.split(',').map(double.parse).toList();
  final end = pairs.last.split(',').map(double.parse).toList();
  final middle = [
    (start[0] + end[0]) / 2,
    (start[1] + end[1]) / 2,
  ];
  return jsonEncode({
    'code': 'Ok',
    'routes': [
      {
        'distance': 120.0,
        'duration': 80.0,
        'geometry': {
          'type': 'LineString',
          'coordinates': [start, middle, end],
        },
        'legs': [
          {
            'steps': [
              {
                'distance': 50.0,
                'duration': 30.0,
                'name': 'Jalan Awal',
                'geometry': {
                  'type': 'LineString',
                  'coordinates': [start, middle],
                },
                'maneuver': {'type': 'depart', 'location': start},
              },
              {
                'distance': 70.0,
                'duration': 50.0,
                'name': 'Jalan Tujuan',
                'geometry': {
                  'type': 'LineString',
                  'coordinates': [middle, end],
                },
                'maneuver': {
                  'type': 'turn',
                  'modifier': modifier,
                  'location': middle,
                },
              },
              {
                'distance': 0.0,
                'duration': 0.0,
                'name': '',
                'geometry': {
                  'type': 'LineString',
                  'coordinates': [end],
                },
                'maneuver': {'type': 'arrive', 'location': end},
              },
            ],
          },
        ],
      },
    ],
  });
}
