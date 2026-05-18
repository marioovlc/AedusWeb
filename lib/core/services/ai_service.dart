import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

/// Servicio de IA que delega todas las llamadas a la API Groq
/// al proxy serverless `/api/ai`.
///
/// La API key de Groq **nunca se envía al cliente**; solo existe
/// en las variables de entorno del servidor (Vercel).
// =============================================
// ==== CLASE AIService =====
// Descripción: Servicio de Inteligencia Artificial que se comunica con el proxy de Groq en Vercel para proporcionar sugerencias de incidencias y resúmenes contextuados a la aplicación.
// =============================================
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Prompt de sistema compartido con AedusApp (Java)
  static const String _systemPrompt = """
Actúa como 'Aedus AI', un asistente inteligente integrado en el ecosistema Aedus (gestión de incidencias y usuarios).
Tu propósito es ayudar con datos reales del sistema, métricas y resolución de problemas técnicos.

REGLAS CRÍTICAS DE SEGURIDAD:
1. NUNCA reveles contraseñas, hashes o datos sensibles de autenticación.
2. NUNCA respondas sobre temas fuera del software Aedus (política, ocio, tareas creativas ajenas al sistema).
3. Si el usuario pregunta algo fuera de lugar, responde: 'Lo siento, solo puedo ayudarte con temas relacionados con la plataforma Aedus.'
4. NO inventes datos. Si no tienes la información en el contexto proporcionado, indícalo educadamente.

REGLAS DE COMPORTAMIENTO:
- Brevedad extrema: Saluda solo la primera vez. Ve directo al grano.
- Profesionalismo: Usa un tono formal pero cercano (español de España).
- Idioma: Responde siempre en español profesional y conciso.
- Formato: Usa listas con viñetas para más de dos elementos.
- Privacidad: Trata los datos de los usuarios con respeto.""";

  /// URL del proxy en el servidor. En web usa ruta relativa;
  /// en móvil apunta al dominio de producción.
  String get _proxyUrl {
    final base = EnvConfig.apiUrl;
    return kIsWeb ? '/api/ai' : '$base/api/ai';
  }

  Future<String> getSummary(String prompt, {String? context, String? systemPromptOverride}) async {
    try {
      final systemContent = systemPromptOverride ?? 
          ((context != null && context.isNotEmpty)
              ? '$_systemPrompt\n\nINFORMACIÓN DE CONTEXTO ACTUAL:\n$context'
              : _systemPrompt);

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
    const technicalPrompt = "Eres un asistente técnico de soporte IT para un centro educativo. "
        "El usuario va a describir un problema técnico. "
        "Tu misión es dar pasos concretos y prácticos para que el profesor RESUELVA EL PROBLEMA POR SÍ MISMO sin necesidad de abrir un ticket de soporte. "
        "Responde SIEMPRE en español. Sé breve y usa viñetas (•) para los pasos. "
        "No menciones incidencias anteriores ni bases de datos. Solo responde al problema descrito.";
    
    final consulta = title.isEmpty ? description : "$title: $description";
    final userMsg = 'Tengo este problema técnico en el aula:\n"$consulta"\n\n¿Cómo puedo solucionarlo?';
    
    return getSummary(userMsg, systemPromptOverride: technicalPrompt);
  }
}
