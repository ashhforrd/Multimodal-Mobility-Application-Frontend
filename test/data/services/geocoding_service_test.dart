import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langkah_sahabat/data/models/geo_point.dart';
import 'package:langkah_sahabat/data/services/map_service.dart';

void main() {
  test('mencari tujuan Nominatim dan menyimpan hasil dalam cache', () async {
    var requestCount = 0;
    final service = MapService(
      searchBaseUrl: 'https://geocoder.example',
      client: MockClient((request) async {
        requestCount++;
        expect(request.url.path, '/search');
        expect(request.url.queryParameters['q'], 'Perpustakaan ITB');
        expect(request.url.queryParameters['limit'], '5');
        return http.Response(
          '''[
            {
              "osm_type":"node",
              "osm_id":123,
              "name":"Perpustakaan ITB",
              "display_name":"Perpustakaan ITB, Bandung, Indonesia",
              "lat":"-6.89148",
              "lon":"107.61066",
              "category":"amenity",
              "type":"library"
            }
          ]''',
          200,
        );
      }),
    );

    final first = await service.searchDestinations('Perpustakaan ITB');
    final cached = await service.searchDestinations('Perpustakaan ITB');

    expect(first.single.name, 'Perpustakaan ITB');
    expect(first.single.latitude, -6.89148);
    expect(cached, first);
    expect(requestCount, 1);
  });

  test('menolak pencarian yang terlalu pendek tanpa request jaringan', () {
    final service = MapService(
      client: MockClient((_) async => http.Response('[]', 200)),
    );

    expect(
      () => service.searchDestinations('IT'),
      throwsA(isA<MapServiceException>()),
    );
  });

  test('mendapatkan nama lokasi dari koordinat peta dan menyimpan cache',
      () async {
    var requestCount = 0;
    final service = MapService(
      searchBaseUrl: 'https://geocoder.example',
      client: MockClient((request) async {
        requestCount++;
        expect(request.url.path, '/reverse');
        expect(request.url.queryParameters['lat'], '-6.89148');
        expect(request.url.queryParameters['lon'], '107.61066');
        return http.Response(
          '''{
            "osm_type":"way",
            "osm_id":456,
            "name":"Perpustakaan ITB",
            "display_name":"Perpustakaan ITB, Jalan Ganesha, Bandung",
            "lat":"-6.89148",
            "lon":"107.61066",
            "category":"amenity",
            "type":"library"
          }''',
          200,
        );
      }),
    );
    const point = GeoPoint(latitude: -6.89148, longitude: 107.61066);

    final first = await service.reverseGeocode(point);
    final cached = await service.reverseGeocode(point);

    expect(first.name, 'Perpustakaan ITB');
    expect(first.address, contains('Jalan Ganesha'));
    expect(cached, same(first));
    expect(requestCount, 1);
  });
}
