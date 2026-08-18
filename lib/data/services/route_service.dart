import '../mock/mock_routes.dart';
import '../models/destination.dart';
import '../models/navigation_route.dart';

class RouteService {
  Future<NavigationRoute> getRoute(Destination destination) async =>
      buildMockRoute(destination);
  Future<String> recalculateRecovery(int count) async => count.isEven
      ? 'Putar balik perlahan, lalu berjalan menuju minimarket kampus.'
      : 'Berjalan 60 meter ke arah gerbang utama, lalu ambil jalur di sisi kanan.';
}
