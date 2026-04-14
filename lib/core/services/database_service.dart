import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import '../config/env_config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Connection? _connection;

  Future<void> connect() async {
    if (kIsWeb) return; // No direct connection on web

    final String user = EnvConfig.dbUser;
    final String pass = EnvConfig.dbPass;
    final host = 'ep-mute-frog-agiqzzew-pooler.c-2.eu-central-1.aws.neon.tech';
    const database = 'neondb';

    try {
      _connection = await Connection.open(
        Endpoint(
          host: host,
          database: database,
          username: user,
          password: pass,
        ),
        settings: const ConnectionSettings(sslMode: SslMode.require),
      );
      debugPrint('Connected to PostgreSQL (Neon)');
    } catch (e) {
      debugPrint('Error connecting to DB: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? substitutionValues, String? action}) async {
    // Unify all platforms to use the API
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
