import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/destination.dart';
import '../models/geo_point.dart';
import '../models/navigation_route.dart';
import '../models/recovery_plan.dart';
import '../models/route_step.dart';

class RouteServiceException implements Exception {
  const RouteServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Service S02 backed by an OSRM instance prepared with the foot profile.
class RouteService {
  RouteService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ??
                _environmentValue('ROUTING_BASE_URL') ??
                'https://routing.openstreetmap.de/routed-foot')
            .replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  Future<NavigationRoute> getRoute(
    Destination destination, {
    required GeoPoint origin,
  }) async {
    final coordinates = '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final uri = Uri.parse('$_baseUrl/route/v1/foot/$coordinates').replace(
      queryParameters: const {
        'steps': 'true',
        'geometries': 'geojson',
        'overview': 'full',
        'alternatives': 'false',
      },
    );

    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw const RouteServiceException(
          'Layanan rute sedang tidak tersedia. Coba kembali beberapa saat lagi.',
        );
      }
      return _parseRoute(response.body, origin, destination);
    } on RouteServiceException {
      rethrow;
    } catch (_) {
      throw const RouteServiceException(
        'Rute pejalan kaki tidak dapat dimuat. Periksa koneksi internet Anda.',
      );
    }
  }

  Future<RecoveryPlan> getRecoveryPlan({
    required GeoPoint currentPosition,
    required NavigationRoute route,
    required int currentStepIndex,
    int recalculationCount = 0,
  }) async {
    final rejoinIndex = (currentStepIndex + 1).clamp(0, route.steps.length - 1);
    final rejoinStep = route.steps[rejoinIndex];
    final rejoinPoint = GeoPoint(
      latitude: rejoinStep.latitude,
      longitude: rejoinStep.longitude,
    );
    final recoveryRoute = await getRoute(
      Destination(
        id: 'rejoin-${route.id}-$rejoinIndex-$recalculationCount',
        name: 'Titik bergabung rute',
        address: rejoinStep.landmarkName,
        latitude: rejoinPoint.latitude,
        longitude: rejoinPoint.longitude,
        description: 'Titik untuk kembali ke rute utama.',
      ),
      origin: currentPosition,
    );
    final firstInstruction = recoveryRoute.steps.first.instruction;
    return RecoveryPlan(
      instruction:
          '$firstInstruction Kembali ke rute utama di ${rejoinStep.landmarkName}.',
      points: recoveryRoute.geometry,
      rejoinPoint: rejoinPoint,
    );
  }

  NavigationRoute _parseRoute(
    String body,
    GeoPoint origin,
    Destination destination,
  ) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (data['code'] != 'Ok') {
      throw const RouteServiceException(
        'Tidak ditemukan rute pejalan kaki menuju tujuan tersebut.',
      );
    }
    final routes = data['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw const RouteServiceException(
        'Tidak ditemukan rute pejalan kaki menuju tujuan tersebut.',
      );
    }
    final routeData = routes.first as Map<String, dynamic>;
    final geometryData = routeData['geometry'] as Map<String, dynamic>;
    final geometry = _parseCoordinates(geometryData['coordinates']);
    final legs = routeData['legs'] as List<dynamic>? ?? const [];
    final rawSteps = legs
        .expand(
          (leg) => ((leg as Map<String, dynamic>)['steps'] as List<dynamic>? ??
              const []),
        )
        .cast<Map<String, dynamic>>()
        .toList();
    if (geometry.length < 2 || rawSteps.length < 2) {
      throw const RouteServiceException(
        'Data rute yang diterima tidak lengkap. Pilih tujuan lain.',
      );
    }
    final steps = <RouteStep>[
      for (var index = 0; index < rawSteps.length - 1; index++)
        _parseStep(
          segmentData: rawSteps[index],
          actionData: rawSteps[index + 1],
          index: index,
          destination: destination,
        ),
    ];
    final distance = (routeData['distance'] as num).round();
    final durationSeconds = (routeData['duration'] as num).toDouble();
    return NavigationRoute(
      id: 'osrm-${origin.latitude}-${origin.longitude}-${destination.id}',
      origin: origin,
      destination: destination,
      estimatedTimeMinutes: (durationSeconds / 60).ceil().clamp(1, 9999),
      totalDistanceMeters: distance,
      steps: steps,
      geometry: geometry,
    );
  }

  RouteStep _parseStep({
    required Map<String, dynamic> segmentData,
    required Map<String, dynamic> actionData,
    required int index,
    required Destination destination,
  }) {
    final maneuver =
        actionData['maneuver'] as Map<String, dynamic>? ?? const {};
    final type = maneuver['type'] as String? ?? 'continue';
    final modifier = maneuver['modifier'] as String?;
    final name = (actionData['name'] as String? ?? '').trim();
    final actionGeometry = actionData['geometry'] as Map<String, dynamic>?;
    final actionPoints = _parseCoordinates(actionGeometry?['coordinates']);
    final segmentGeometry = segmentData['geometry'] as Map<String, dynamic>?;
    final segmentPoints = _parseCoordinates(segmentGeometry?['coordinates']);
    final maneuverPoint = _parsePoint(maneuver['location']);
    final target = maneuverPoint ??
        (actionPoints.isNotEmpty
            ? actionPoints.first
            : segmentPoints.isNotEmpty
                ? segmentPoints.last
                : null);
    if (target == null) {
      throw const RouteServiceException(
          'Koordinat instruksi rute tidak valid.');
    }
    final action = _actionType(type, modifier, name);
    return RouteStep(
      id: 'osrm-step-$index',
      instruction: _instruction(type, modifier, name, destination),
      landmarkName: name.isNotEmpty
          ? name
          : type == 'arrive'
              ? destination.name
              : 'Jalur di depan',
      distanceMeters: (segmentData['distance'] as num? ?? 0).round(),
      actionType: action,
      latitude: target.latitude,
      longitude: target.longitude,
      shouldTriggerHaptic: _isActionPoint(action),
    );
  }

  RouteActionType _actionType(String type, String? modifier, String name) {
    if (type == 'depart') return RouteActionType.start;
    if (type == 'arrive') return RouteActionType.arrive;
    final lowerName = name.toLowerCase();
    if (lowerName.contains('penyeberangan') || lowerName.contains('crossing')) {
      return RouteActionType.cross;
    }
    switch (modifier) {
      case 'slight left':
        return RouteActionType.slightLeft;
      case 'slight right':
        return RouteActionType.slightRight;
      case 'sharp left':
        return RouteActionType.sharpLeft;
      case 'sharp right':
        return RouteActionType.sharpRight;
      case 'uturn':
        return RouteActionType.uTurn;
      case 'left':
        return RouteActionType.turnLeft;
      case 'right':
        return RouteActionType.turnRight;
    }
    return RouteActionType.straight;
  }

  bool _isActionPoint(RouteActionType action) => switch (action) {
        RouteActionType.slightLeft ||
        RouteActionType.slightRight ||
        RouteActionType.turnLeft ||
        RouteActionType.turnRight ||
        RouteActionType.sharpLeft ||
        RouteActionType.sharpRight ||
        RouteActionType.uTurn ||
        RouteActionType.cross ||
        RouteActionType.arrive =>
          true,
        _ => false,
      };

  String _instruction(
    String type,
    String? modifier,
    String name,
    Destination destination,
  ) {
    final reference = name.isEmpty ? 'jalur di depan' : name;
    final direction = switch (modifier) {
      'uturn' => 'putar balik',
      'sharp right' => 'belok tajam ke kanan',
      'right' => 'belok kanan',
      'slight right' => 'serong sedikit ke kanan',
      'sharp left' => 'belok tajam ke kiri',
      'left' => 'belok kiri',
      'slight left' => 'serong sedikit ke kiri',
      _ => 'lanjutkan lurus',
    };
    return switch (type) {
      'depart' => 'Mulai berjalan melalui $reference.',
      'arrive' => 'Anda telah tiba di ${destination.name}.',
      'turn' => '${_capitalize(direction)} ke $reference.',
      'end of road' => 'Di ujung jalan, $direction menuju $reference.',
      'fork' => '${_capitalize(direction)} pada percabangan menuju $reference.',
      'roundabout' ||
      'rotary' =>
        'Masuki bundaran dan lanjutkan menuju $reference.',
      'exit roundabout' ||
      'exit rotary' =>
        'Keluar dari bundaran menuju $reference.',
      'new name' || 'continue' => 'Lanjutkan melalui $reference.',
      _ => '${_capitalize(direction)} melalui $reference.',
    };
  }

  List<GeoPoint> _parseCoordinates(Object? rawCoordinates) {
    if (rawCoordinates is! List) return const [];
    return rawCoordinates
        .whereType<List<dynamic>>()
        .where((coordinate) => coordinate.length >= 2)
        .map(
          (coordinate) => GeoPoint(
            latitude: (coordinate[1] as num).toDouble(),
            longitude: (coordinate[0] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  GeoPoint? _parsePoint(Object? rawPoint) {
    if (rawPoint is! List || rawPoint.length < 2) return null;
    return GeoPoint(
      latitude: (rawPoint[1] as num).toDouble(),
      longitude: (rawPoint[0] as num).toDouble(),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (!kIsWeb)
          'User-Agent': 'LangkahSahabat/1.0 (thesis navigation prototype)',
      };
}

String? _environmentValue(String key) =>
    dotenv.isInitialized ? dotenv.env[key] : null;
