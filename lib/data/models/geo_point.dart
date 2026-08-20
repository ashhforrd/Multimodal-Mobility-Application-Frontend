class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

class LocationSnapshot {
  const LocationSnapshot({
    required this.point,
    this.message,
  });

  final GeoPoint? point;
  final String? message;
}
