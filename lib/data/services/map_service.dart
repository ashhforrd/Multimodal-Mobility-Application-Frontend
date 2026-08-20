import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/destination.dart';
import '../models/geo_point.dart';
import '../models/navigation_route.dart';

class MapServiceException implements Exception {
  const MapServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MapService {
  MapService({http.Client? client, String? searchBaseUrl})
      : _client = client ?? http.Client(),
        _searchBaseUrl = (searchBaseUrl ??
                _environmentValue('GEOCODING_BASE_URL') ??
                'https://nominatim.openstreetmap.org')
            .replaceFirst(RegExp(r'/$'), '');

  static const double actionPointThresholdMeters = 35;
  static const double stepCompletionThresholdMeters = 12;
  static const double offRouteThresholdMeters = 60;

  final http.Client _client;
  final String _searchBaseUrl;
  final Map<String, List<Destination>> _searchCache = {};
  DateTime? _lastSearchAt;

  /// User-triggered destination search for module M01 through service S03.
  /// Requests are cached and limited to one per second for Nominatim policy.
  Future<List<Destination>> searchDestinations(
    String query, {
    GeoPoint? nearby,
  }) async {
    final normalized = query.trim();
    if (normalized.length < 3) {
      throw const MapServiceException(
        'Masukkan setidaknya tiga karakter untuk mencari tujuan.',
      );
    }
    final cacheKey = nearby == null
        ? normalized.toLowerCase()
        : '${normalized.toLowerCase()}|'
            '${nearby.latitude.toStringAsFixed(3)},'
            '${nearby.longitude.toStringAsFixed(3)}';
    final cached = _searchCache[cacheKey];
    if (cached != null) return cached;

    final previousRequest = _lastSearchAt;
    if (previousRequest != null) {
      final wait = const Duration(seconds: 1) -
          DateTime.now().difference(previousRequest);
      if (!wait.isNegative) await Future<void>.delayed(wait);
    }
    _lastSearchAt = DateTime.now();

    final parameters = <String, String>{
      'q': normalized,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '5',
      'accept-language': 'id',
      if (_environmentValue('NOMINATIM_EMAIL')?.trim().isNotEmpty == true)
        'email': _environmentValue('NOMINATIM_EMAIL')!.trim(),
      if (nearby != null)
        'viewbox': '${nearby.longitude - .25},${nearby.latitude + .25},'
            '${nearby.longitude + .25},${nearby.latitude - .25}',
    };
    final uri = Uri.parse('$_searchBaseUrl/search').replace(
      queryParameters: parameters,
    );

    try {
      final response = await _client
          .get(uri, headers: _searchHeaders)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw const MapServiceException(
          'Pencarian lokasi sedang tidak tersedia. Coba kembali nanti.',
        );
      }
      final rawResults = jsonDecode(response.body) as List<dynamic>;
      final results = rawResults
          .whereType<Map<String, dynamic>>()
          .map(_parseDestination)
          .toList(growable: false);
      _searchCache[cacheKey] = results;
      return results;
    } on MapServiceException {
      rethrow;
    } catch (_) {
      throw const MapServiceException(
        'Lokasi tidak dapat dicari. Periksa koneksi internet Anda.',
      );
    }
  }

  List<GeoPoint> routePoints(NavigationRoute route) => route.geometry.isNotEmpty
      ? route.geometry
      : [
          route.origin,
          ...route.steps.map(
            (step) => GeoPoint(
              latitude: step.latitude,
              longitude: step.longitude,
            ),
          ),
        ];

  double distanceMeters(GeoPoint first, GeoPoint second) {
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

  double nearestDistanceToRoute(GeoPoint point, NavigationRoute route) {
    final points = routePoints(route);
    if (points.length == 1) return distanceMeters(point, points.first);
    return Iterable<int>.generate(points.length - 1)
        .map(
          (index) => _distanceToSegment(
            point,
            points[index],
            points[index + 1],
          ),
        )
        .reduce(math.min);
  }

  bool isOffRoute(GeoPoint point, NavigationRoute route) =>
      nearestDistanceToRoute(point, route) > offRouteThresholdMeters;

  int remainingDistanceMeters(NavigationRoute route, int currentStepIndex) =>
      route.steps
          .skip(currentStepIndex)
          .fold(0, (total, step) => total + step.distanceMeters);

  double _radians(double degrees) => degrees * math.pi / 180;

  Destination _parseDestination(Map<String, dynamic> data) {
    final displayName = data['display_name'] as String? ?? 'Lokasi tanpa nama';
    final name = (data['name'] as String?)?.trim();
    final osmType = data['osm_type']?.toString() ?? 'place';
    final osmId = data['osm_id']?.toString() ?? data['place_id'].toString();
    return Destination(
      id: '$osmType-$osmId',
      name: name?.isNotEmpty == true ? name! : displayName.split(',').first,
      address: displayName,
      latitude: double.parse(data['lat'].toString()),
      longitude: double.parse(data['lon'].toString()),
      description:
          '${data['category'] ?? 'lokasi'} • ${data['type'] ?? 'tempat'}',
    );
  }

  Map<String, String> get _searchHeaders => {
        'Accept': 'application/json',
        'Accept-Language': 'id',
        if (!kIsWeb)
          'User-Agent': 'LangkahSahabat/1.0 (thesis navigation prototype)',
      };

  double _distanceToSegment(
    GeoPoint point,
    GeoPoint start,
    GeoPoint end,
  ) {
    // Proyeksi lokal ini akurat untuk segmen pendek pada rute pejalan kaki.
    const earthRadius = 6371000.0;
    final referenceLatitude =
        _radians((start.latitude + end.latitude + point.latitude) / 3);
    final pointX =
        _radians(point.longitude) * math.cos(referenceLatitude) * earthRadius;
    final pointY = _radians(point.latitude) * earthRadius;
    final startX =
        _radians(start.longitude) * math.cos(referenceLatitude) * earthRadius;
    final startY = _radians(start.latitude) * earthRadius;
    final endX =
        _radians(end.longitude) * math.cos(referenceLatitude) * earthRadius;
    final endY = _radians(end.latitude) * earthRadius;
    final deltaX = endX - startX;
    final deltaY = endY - startY;
    final lengthSquared = deltaX * deltaX + deltaY * deltaY;
    if (lengthSquared == 0) return distanceMeters(point, start);
    final projection =
        (((pointX - startX) * deltaX + (pointY - startY) * deltaY) /
                lengthSquared)
            .clamp(0.0, 1.0);
    final nearestX = startX + projection * deltaX;
    final nearestY = startY + projection * deltaY;
    return math.sqrt(
      math.pow(pointX - nearestX, 2) + math.pow(pointY - nearestY, 2),
    );
  }
}

String? _environmentValue(String key) =>
    dotenv.isInitialized ? dotenv.env[key] : null;
