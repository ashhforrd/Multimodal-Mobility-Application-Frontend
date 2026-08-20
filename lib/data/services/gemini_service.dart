import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/assistant_response.dart';
import '../models/route_step.dart';

class GeminiServiceException implements Exception {
  const GeminiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Implementasi service S07 pada laporan.
class GeminiService {
  GeminiService({
    http.Client? client,
    String? apiKey,
    String? model,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? _environmentValue('GEMINI_API_KEY') ?? '',
        _model =
            model ?? _environmentValue('GEMINI_MODEL') ?? 'gemini-3.5-flash';

  final http.Client _client;
  final String _apiKey;
  final String _model;

  Future<AssistantResponse> ask({
    required String question,
    required RouteStep active,
    RouteStep? next,
    required String destination,
    required String routeStatus,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw const GeminiServiceException(
        'Bantuan AI belum dikonfigurasi. Tambahkan GEMINI_API_KEY pada .env.',
      );
    }
    try {
      final prompt =
          'Jawab singkat dalam bahasa Indonesia. Jangan mengarang lokasi. '
          'Tujuan: $destination. Status: $routeStatus. '
          'Instruksi aktif: ${active.instruction}. '
          'Landmark: ${active.landmarkName}. '
          'Instruksi berikutnya: ${next?.instruction ?? '-'} '
          'Pertanyaan: $question';
      final response = await _client
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/'
              '$_model:generateContent',
            ),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const GeminiServiceException(
          'Kunci Gemini tidak valid atau tidak memiliki akses.',
        );
      }
      if (response.statusCode != 200) {
        throw const GeminiServiceException(
          'Bantuan AI sedang tidak tersedia. Coba kembali nanti.',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>;
      final candidate = candidates.first as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      final firstPart = parts.first as Map<String, dynamic>;
      return AssistantResponse(text: firstPart['text'] as String);
    } on GeminiServiceException {
      rethrow;
    } catch (_) {
      throw const GeminiServiceException(
        'Bantuan AI tidak dapat dihubungi. Periksa koneksi internet Anda.',
      );
    }
  }
}

String? _environmentValue(String key) =>
    dotenv.isInitialized ? dotenv.env[key] : null;
