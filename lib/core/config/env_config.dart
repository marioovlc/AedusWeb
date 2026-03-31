import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get dbUrl => _get('DB_URL');
  static String get dbUser => _get('DB_USER');
  static String get dbPass => _get('DB_PASS');
  static String get aiApiKey => _get('AI_API_KEY');
  static String get aiModel => _get('AI_MODEL');
  static String get aiApiUrl => _get('AI_API_URL');
  static String get cloudinaryCloudName => _get('CLOUDINARY_CLOUD_NAME');
  static String get cloudinaryApiKey => _get('CLOUDINARY_API_KEY');
  static String get cloudinaryApiSecret => _get('CLOUDINARY_API_SECRET');

  static String _get(String key) {
    // 1. Try build-time constants (must use literals)
    switch (key) {
      case 'DB_URL': return const String.fromEnvironment('DB_URL');
      case 'DB_USER': return const String.fromEnvironment('DB_USER');
      case 'DB_PASS': return const String.fromEnvironment('DB_PASS');
      case 'AI_API_KEY': return const String.fromEnvironment('AI_API_KEY');
      case 'AI_MODEL': return const String.fromEnvironment('AI_MODEL');
      case 'AI_API_URL': return const String.fromEnvironment('AI_API_URL');
      case 'CLOUDINARY_CLOUD_NAME': return const String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
      case 'CLOUDINARY_API_KEY': return const String.fromEnvironment('CLOUDINARY_API_KEY');
      case 'CLOUDINARY_API_SECRET': return const String.fromEnvironment('CLOUDINARY_API_SECRET');
    }

    // 2. Try dotenv (local development)
    try {
      final fromDotEnv = dotenv.maybeGet(key);
      if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;
    } catch (_) {}

    return '';
  }
}
