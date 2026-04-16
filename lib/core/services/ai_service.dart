import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

/// Servicio de IA que delega todas las llamadas a la API Groq
/// al proxy serverless `/api/ai`.
///
/// La API key de Groq **nunca se envía al cliente**; solo existe
/// en las variables de entorno del servidor (Vercel).
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Prompt de sistema compartido con AedusApp (Java)
  static const String _systemPrompt = """
Actúa como una extensión de inteligencia artificial integrada en un software de gestión (Dashboard). Tu nombre es 'Aedus AI'.
Tus reglas de comportamiento son:
- Brevedad extrema: Se educado y saluda al inicio unicamente. Ve directo a la respuesta.
- Contexto técnico: Responde únicamente dudas sobre métricas, datos, tendencias o funciones del software.
- Idioma: Responde siempre en español profesional y conciso.
- Limitación: Si el usuario te pide tareas creativas, chistes o temas personales, responde: 'Solo estoy autorizado para realizar análisis de datos'.
- Formato: Usa viñetas (puntos) si tienes que enumerar más de dos elementos.
""";

  /// URL del proxy en el servidor. En web usa ruta relativa;
  /// en móvil apunta al dominio de producción.
  String get _proxyUrl {
    final base = EnvConfig.apiUrl;
    return kIsWeb ? '/api/ai' : '$base/api/ai';
  }

  Future<String> getSummary(String prompt, {String? context}) async {
    try {
      final systemContent = (context != null && context.isNotEmpty)
          ? '$_systemPrompt\n\nINFORMACIÓN DE CONTEXTO ACTUAL:\n$context'
          : _systemPrompt;

      final response = await http
          .post(
            Uri.parse(_proxyUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-API-KEY': EnvConfig.internalApiKey,
            },
            body: jsonEncode({
              'messages': [
                {'role': 'system', 'content': systemContent},
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.3,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Desconocido';
        return 'Error de la IA (${response.statusCode}): $errorMessage';
      }
    } catch (e) {
      debugPrint('AIService error: $e');
      return 'Error conectando con la IA: $e';
    }
  }

  Future<String> getTicketSuggestion(String title, String description) async {
    final prompt =
        'Analiza esta incidencia y sugiere una solución rápida: Título: $title, Descripción: $description';
    return getSummary(prompt);
  }
}
