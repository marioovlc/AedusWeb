import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

/// Servicio de almacenamiento que delega las subidas a Cloudinary
/// al proxy serverless `/api/upload`.
///
/// El CLOUDINARY_API_SECRET **nunca se envía al cliente**; solo existe
/// en las variables de entorno del servidor (Vercel).
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// URL del proxy en el servidor. En web usa ruta relativa;
  /// en móvil apunta al dominio de producción.
  String get _proxyUrl {
    final base = EnvConfig.apiUrl;
    return kIsWeb ? '/api/upload' : '$base/api/upload';
  }

  /// Sube [fileBytes] a Cloudinary a través del proxy serverless y devuelve
  /// la URL pública del archivo, o `null` si falla.
  Future<String?> uploadFile(
    Uint8List fileBytes,
    String fileName, {
    bool isAudio = false,
  }) async {
    try {
      // Convertir bytes a base64 para enviar al proxy mediante JSON
      final fileBase64 = base64Encode(fileBytes);

      final response = await http
          .post(
            Uri.parse(_proxyUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-API-KEY': EnvConfig.internalApiKey,
            },
            body: jsonEncode({
              'fileBase64': fileBase64,
              'fileName': fileName,
              'isAudio': isAudio,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url = data['url'] as String?;
        if (url != null && url.isNotEmpty) return url;
        debugPrint('StorageService: respuesta OK pero sin URL: ${response.body}');
        return null;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint(
          'StorageService: upload failed ${response.statusCode} — ${errorData['error']}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('StorageService error: $e');
      return null;
    }
  }
}
