import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static const String _dbUrl = 'DB_URL';
  static const String _dbUser = 'DB_USER';
  static const String _dbPass = 'DB_PASS';
  static const String _aiApiKey = 'AI_API_KEY';
  static const String _aiModel = 'AI_MODEL';
  static const String _aiApiUrl = 'AI_API_URL';

  static String get dbUrl => _get(_dbUrl);
  static String get dbUser => _get(_dbUser);
  static String get dbPass => _get(_get(_dbPass));
  static String get aiApiKey => _get(_get(_aiApiKey));
  static String get aiModel => _get(_aiModel);
  static String get aiApiUrl => _get(_aiApiUrl);

  static String _get(String key) {
    // 1. Try to get from build-time environment (--dart-define)
    final fromEnv = String.fromEnvironment(key);
    if (fromEnv.isNotEmpty) return fromEnv;

    // 2. Try to get from dotenv (local development)
    try {
      final fromDotEnv = dotenv.maybeGet(key);
      if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;
    } catch (_) {}

    return '';
  }
}
