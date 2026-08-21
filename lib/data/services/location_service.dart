import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

import '../models/geo_point.dart';

class LocationService {
  Future<LocationSnapshot> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationSnapshot(
          point: null,
          message:
              'Aktifkan layanan lokasi untuk membuat rute dari posisi Anda.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationSnapshot(
          point: null,
          message: 'Izin lokasi diperlukan untuk navigasi secara langsung.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationSnapshot(
        point: GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          courseDegrees: position.speed >= .5 ? position.heading : null,
        ),
      );
    } catch (_) {
      return const LocationSnapshot(
        point: null,
        message: 'Posisi tidak dapat dibaca. Periksa GPS dan coba kembali.',
      );
    }
  }

  Stream<GeoPoint> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: _liveNavigationSettings(),
    ).map(
      (position) => GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        courseDegrees: position.speed >= .5 ? position.heading : null,
      ),
    );
  }

  LocationSettings _liveNavigationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }
}
