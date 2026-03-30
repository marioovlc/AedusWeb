import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final String _apiUrl = dotenv.get('AI_API_URL');
  final String _apiKey = dotenv.get('AI_API_KEY');
  final String _model = dotenv.get('AI_MODEL');

  Future<String> getSummary(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': 'Eres un asistente experto de la plataforma Aedus.'},
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Error de la IA: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error conectando con la IA: $e';
    }
  }

  Future<String> getTicketSuggestion(String title, String description) async {
    final prompt = 'Analiza esta incidencia y sugiere una solución rápida: Título: $title, Descripción: $description';
    return getSummary(prompt);
  }
}
