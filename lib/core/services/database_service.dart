import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import '../config/env_config.dart';

// =============================================
// ==== CLASE DatabaseService =====
// Descripción: Servicio de base de datos unificado que realiza consultas y mutaciones a PostgreSQL delegándolas de forma segura a través del proxy API de Vercel.
// =============================================
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Connection? _connection;

  Future<void> connect() async {
    // La conexión a PostgreSQL directa ha sido deprecada (unificada con API web).
    debugPrint('DatabaseService: Modo API en todas las plataformas.');
  }

  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? substitutionValues, String? action}) async {
    // Unificar todas las plataformas para usar la API
    return _queryAPI(sql, substitutionValues, action: action);
  }

  Future<List<Map<String, dynamic>>> _queryAPI(String sql, Map<String, dynamic>? parameters, {String? action}) async {
    try {
      final baseUrl = EnvConfig.apiUrl;
      final uri = kIsWeb ? Uri.parse('/api/query') : Uri.parse('$baseUrl/api/query');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': EnvConfig.internalApiKey,
        },
        body: jsonEncode({
          'parameters': parameters,
          'action': action,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 403) {
        final body = jsonDecode(response.body);
        final msg = body['error'] ?? 'Forbidden';
        debugPrint('Authentication Error: $msg. Check INTERNAL_API_KEY in env_config.dart and Vercel dashboard.');
        throw Exception(msg);
      } else {
        final body = jsonDecode(response.body);
        final msg = body['error'] ?? 'Error desconocido (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('API Query Error: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (kIsWeb) return;
    await _connection?.close();
    _connection = null;
  }
}
