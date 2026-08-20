import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langkah_sahabat/data/services/gemini_service.dart';

import '../../helpers/fakes.dart';

void main() {
  group('GeminiService', () {
    test('mengirim konteks navigasi ke Gemini dan memetakan jawaban', () async {
      late http.Request capturedRequest;
      final service = GeminiService(
        apiKey: 'test-api-key',
        model: 'gemini-test',
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Belok kanan setelah gerbang.'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final response = await service.ask(
        question: 'Saya harus ke mana?',
        active: buildTestRoute().steps[1],
        next: buildTestRoute().steps[2],
        destination: testDestination.name,
        routeStatus: 'active',
      );

      expect(response.text, 'Belok kanan setelah gerbang.');
      expect(capturedRequest.url.path, contains('gemini-test:generateContent'));
      expect(capturedRequest.headers['x-goog-api-key'], 'test-api-key');
      expect(capturedRequest.body, contains(testDestination.name));
    });

    test('tidak membuat jawaban simulasi ketika API key kosong', () async {
      final service = GeminiService(apiKey: '');

      expect(
        () => service.ask(
          question: 'Saya harus ke mana?',
          active: buildTestRoute().steps[1],
          destination: testDestination.name,
          routeStatus: 'active',
        ),
        throwsA(
          isA<GeminiServiceException>().having(
            (error) => error.message,
            'message',
            contains('GEMINI_API_KEY'),
          ),
        ),
      );
    });
  });
}
