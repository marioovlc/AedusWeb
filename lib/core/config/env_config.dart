import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de variables de entorno para el cliente Flutter.
///
/// ⚠️  REGLA DE SEGURIDAD: Este archivo NO debe contener secretos.
///     Los únicos valores permitidos aquí son:
///       - [internalApiKey]: la clave que protege el acceso a los proxies
///         del servidor. Su valor real solo existe en Vercel Environment
///         Variables; en desarrollo local se lee del `.env`.
///       - [apiUrl]: URL base de la API (vacía en web, dominio en móvil).
///
///     Credenciales de BD, IA y Cloudinary se leen ÚNICAMENTE en el servidor
///     (`api/query.js`, `api/ai.js`, `api/upload.js`).
class EnvConfig {
  /// Clave de autenticación cliente → proxies del servidor.
  static String get internalApiKey => _get('INTERNAL_API_KEY');

  /// URL base de la API.
  /// - Web: vacío (usa rutas relativas `/api/...`).
  /// - Móvil: URL absoluta del dominio de producción.
  static String get apiUrl => _get('API_URL');

  static String _get(String key) {
    // 1. Dotenv (desarrollo local)
    try {
      final fromDotEnv = dotenv.maybeGet(key);
      if (fromDotEnv != null && fromDotEnv.isNotEmpty) {
        if (kDebugMode) debugPrint('EnvConfig: $key loaded from DotEnv');
        return fromDotEnv;
      }
    } catch (_) {}

    // 2. Fallbacks seguros (sin secretos)
    switch (key) {
      case 'API_URL':
        // En web los proxies son rutas relativas, no se necesita URL base.
        if (kIsWeb) return '';
        return 'https://aedus-web.vercel.app';
    }

    if (kDebugMode) debugPrint('EnvConfig: $key not found');
    return '';
  }
}
