class Landmark {
  const Landmark(
      {required this.id,
      required this.name,
      required this.type,
      required this.description,
      required this.latitude,
      required this.longitude});
  final String id, name, type, description;
  final double latitude, longitude;
}
