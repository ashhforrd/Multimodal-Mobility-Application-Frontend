import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/assistant_response.dart';
import '../models/route_step.dart';

class AssistantService {
  Future<AssistantResponse> ask(
      {required String question,
      required RouteStep active,
      RouteStep? next,
      required String destination,
      required String routeStatus}) async {
    final useMock = dotenv.env['USE_MOCK_ASSISTANT']?.toLowerCase() != 'false';
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (useMock || key.isEmpty) return _mock(question, active);
    try {
      final prompt =
          'Jawab singkat dalam bahasa Indonesia. Jangan mengarang lokasi. Tujuan: $destination. Status: $routeStatus. Instruksi aktif: ${active.instruction}. Landmark: ${active.landmarkName}. Instruksi berikutnya: ${next?.instruction ?? '-'} Pertanyaan: $question';
      final response = await http.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$key'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ]
          }));
      if (response.statusCode != 200) throw Exception('Gemini gagal');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      return AssistantResponse(text: text);
    } catch (_) {
      return _mock(question, active);
    }
  }

  AssistantResponse _mock(String question, RouteStep active) {
    final lower = question.toLowerCase();
    if (lower.contains('kembali') || lower.contains('tersesat')) {
      return const AssistantResponse(
          text: 'Mari gunakan mode pemulihan untuk kembali ke rute.',
          shouldOpenRecovery: true);
    }
    final text =
        'Tetap tenang. ${active.instruction} Gunakan ${active.landmarkName} sebagai acuan.';
    return AssistantResponse(
        text: text,
        suggestedInstruction: text,
        shouldUpdateInstruction: lower.contains('bingung'));
  }
}
