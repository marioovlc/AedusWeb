import 'package:postgres/postgres.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Connection? _connection;

  Future<void> connect() async {
    final String user = dotenv.get('DB_USER');
    final String pass = dotenv.get('DB_PASS');

    // Simple extraction of host/port from JDBC URL or just hardcode for Neon if needed.
    // Neon typically uses: ep-mute-frog-agiqzzew-pooler.c-2.eu-central-1.aws.neon.tech
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
      print('Connected to PostgreSQL (Neon)');
    } catch (e) {
      print('Error connecting to DB: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? substitutionValues}) async {
    if (_connection == null) await connect();
    final result = await _connection?.execute(sql, parameters: substitutionValues);
    
    // Convert Result to List<Map>
    List<Map<String, dynamic>> list = [];
    if (result != null) {
      for (final row in result) {
        list.add(row.toColumnMap());
      }
    }
    return list;
  }

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
