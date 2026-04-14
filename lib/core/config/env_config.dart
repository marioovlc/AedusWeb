import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, kDebugMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get dbUrl => _get('DB_URL');
  static String get dbUser => _get('DB_USER');
  static String get dbPass => _get('DB_PASS');
  static String get internalApiKey => _get('INTERNAL_API_KEY');
  static String get aiApiKey => _get('AI_API_KEY');
  static String get aiModel => _get('AI_MODEL');
  static String get aiApiUrl => _get('AI_API_URL');
  static String get cloudinaryCloudName => _get('CLOUDINARY_CLOUD_NAME');
  static String get cloudinaryApiKey => _get('CLOUDINARY_API_KEY');
  static String get cloudinaryApiSecret => _get('CLOUDINARY_API_SECRET');
  static String get apiUrl => _get('API_URL');

  static String _get(String key) {
    String value = '';

    // 1. Try build-time constants (must use literals)
    switch (key) {
      case 'DB_URL': value = const String.fromEnvironment('DB_URL'); break;
      case 'DB_USER': value = const String.fromEnvironment('DB_USER'); break;
      case 'DB_PASS': value = const String.fromEnvironment('DB_PASS'); break;
      case 'INTERNAL_API_KEY': value = const String.fromEnvironment('INTERNAL_API_KEY'); break;
      case 'AI_API_KEY': value = const String.fromEnvironment('AI_API_KEY'); break;
      case 'AI_MODEL': value = const String.fromEnvironment('AI_MODEL'); break;
      case 'AI_API_URL': value = const String.fromEnvironment('AI_API_URL'); break;
      case 'CLOUDINARY_CLOUD_NAME': value = const String.fromEnvironment('CLOUDINARY_CLOUD_NAME'); break;
      case 'CLOUDINARY_API_KEY': value = const String.fromEnvironment('CLOUDINARY_API_KEY'); break;
      case 'CLOUDINARY_API_SECRET': value = const String.fromEnvironment('CLOUDINARY_API_SECRET'); break;
      case 'API_URL': value = const String.fromEnvironment('API_URL'); break;
    }

    if (value.isNotEmpty) {
      if (kDebugMode) debugPrint('EnvConfig: $key loaded from Environment');
      return value;
    }

    // 2. Try dotenv (local development)
    try {
      final fromDotEnv = dotenv.maybeGet(key);
      if (fromDotEnv != null && fromDotEnv.isNotEmpty) {
        if (kDebugMode) debugPrint('EnvConfig: $key loaded from DotEnv');
        return fromDotEnv;
      }
    } catch (_) {}

    // 3. Last resort fallbacks for essential Web services (safe public IDs)
    if (kDebugMode && key == 'INTERNAL_API_KEY') {
       debugPrint('EnvConfig: $key using Fallback');
    }
    switch (key) {
      case 'CLOUDINARY_CLOUD_NAME': return 'dbdpkml2m';
      case 'CLOUDINARY_API_KEY': return '242661642536897';
      case 'CLOUDINARY_API_SECRET': return 'aYOctG0R9k_Z9v_pguDlZ3wtrM8';
      case 'INTERNAL_API_KEY': return 'AedusSecureAuthKey2026!';
      case 'API_URL': 
        // If web, relative path works. If mobile, apuntamos directo a Vercel
        if (kIsWeb) return ''; 
        return 'https://aedus-web.vercel.app';
    }

    return '';
  }
}
