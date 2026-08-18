class Destination {
  const Destination(
      {required this.id,
      required this.name,
      required this.address,
      required this.latitude,
      required this.longitude,
      required this.description});
  final String id, name, address, description;
  final double latitude, longitude;
}
