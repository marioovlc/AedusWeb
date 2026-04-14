import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final String _apiUrl = EnvConfig.aiApiUrl;
  final String _apiKey = EnvConfig.aiApiKey;
  final String _model = EnvConfig.aiModel;

  // Sincronizado con AedusApp (Java)
  static const String _systemPrompt = """
Actúa como una extensión de inteligencia artificial integrada en un software de gestión (Dashboard). Tu nombre es 'Aedus AI'.
Tus reglas de comportamiento son:
- Brevedad extrema: Se educado y saluda al inicio unicamente. Ve directo a la respuesta.
- Contexto técnico: Responde únicamente dudas sobre métricas, datos, tendencias o funciones del software.
- Idioma: Responde siempre en español profesional y conciso.
- Limitación: Si el usuario te pide tareas creativas, chistes o temas personales, responde: 'Solo estoy autorizado para realizar análisis de datos'.
- Formato: Usa viñetas (puntos) si tienes que enumerar más de dos elementos.
""";

  Future<String> getSummary(String prompt, {String? context}) async {
    try {
      final finalSystemPrompt = context != null && context.isNotEmpty
          ? "$_systemPrompt\n\nINFORMACIÓN DE CONTEXTO ACTUAL:\n$context"
          : _systemPrompt;

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': finalSystemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3, // Lower temperature for more consistent/factual responses
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
