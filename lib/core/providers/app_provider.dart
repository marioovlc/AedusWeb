import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/incident_model.dart';
import '../../data/models/message_model.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

class AppProvider with ChangeNotifier {
  Usuario? _currentUser;
  List<Incidencia> _incidencias = [];
  List<Usuario> _contactos = [];
  List<Mensaje> _mensajes = [];
  Map<String, String> _kpis = {
    'Total Incidencias': '0',
    'Pendientes': '0',
    'Resueltas': '0',
    'Usuarios Activos': '0',
  };
  List<Usuario> _usuariosAdmin = [];

  Usuario? get currentUser => _currentUser;
  List<Incidencia> get incidencias => _incidencias;
  List<Usuario> get contactos => _contactos;
  List<Usuario> get usuariosAdmin => _usuariosAdmin;
  List<Mensaje> get mensajes => _mensajes;
  Map<String, String> get kpis => _kpis;

  int get pendingIncidentsCount => _incidencias.where((i) => i.estado == 'PENDIENTE').length;

  Future<void> fetchAllUsers() async {
    final results = await _db.query("SELECT * FROM neon_auth.user ORDER BY name ASC");
    _usuariosAdmin = results.map((m) => Usuario.fromMap(m)).toList();
    notifyListeners();
  }

  final DatabaseService _db = DatabaseService();
  final AIService _ai = AIService();

  Future<bool> login(String email, String password) async {
    try {
      final results = await _db.query(
        "", // SQL is ignored when action is 'login'
        substitutionValues: {'email': email, 'password': password},
        action: 'login',
      );

      if (results.isNotEmpty) {
        _currentUser = Usuario.fromMap(results.first);
        await refreshData();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  Future<void> refreshData() async {
    if (_currentUser == null) return;
    await Future.wait([
      _fetchIncidencias(),
      _fetchKPIs(),
      _fetchContactos(),
    ]);
    notifyListeners();
  }

  Future<void> _fetchIncidencias() async {
    final results = await _db.query("SELECT * FROM gestion_incidencias.incidencias ORDER BY fecha DESC");
    _incidencias = results.map((m) => Incidencia.fromMap(m)).toList();
  }

  Future<void> _fetchKPIs() async {
    final results = await _db.query(
      "SELECT estado, count(*) FROM gestion_incidencias.incidencias GROUP BY estado"
    );
    
    int total = 0;
    int pendientes = 0;
    int resueltas = 0;

    for (final row in results) {
      final estado = row['estado'] as String;
      final count = int.parse(row['count'].toString());
      total += count;
      if (estado == 'PENDIENTE' || estado == 'NO LEIDO') pendientes += count;
      if (estado == 'RESUELTO' || estado == 'ACABADO') resueltas += count;
    }

    _kpis = {
      'Total Incidencias': total.toString(),
      'Pendientes': pendientes.toString(),
      'Resueltas': resueltas.toString(),
      'Usuarios Activos': '8', // Mock for now or count from session
    };
  }

  Future<void> _fetchContactos() async {
    final results = await _db.query("SELECT * FROM neon_auth.user WHERE id != @id", 
      substitutionValues: {'id': _currentUser!.id});
    _contactos = results.map((m) => Usuario.fromMap(m)).toList();
  }

  Future<void> fetchMessages(String receiverId) async {
    if (_currentUser == null) return;
    final results = await _db.query(
      "SELECT * FROM gestion_incidencias.mensajes WHERE (usuario_id = @me AND receptor_id = @other) OR (usuario_id = @other AND receptor_id = @me) ORDER BY fecha ASC",
      substitutionValues: {'me': _currentUser!.id, 'other': receiverId},
    );
    _mensajes = results.map((m) => Mensaje.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> createIncidencia(String titulo, String descripcion, int aulaId, int categoriaId) async {
    if (_currentUser == null) return;
    await _db.query(
      "INSERT INTO gestion_incidencias.incidencias (titulo, descripcion, usuario_id, aula_id, categoria_id, estado, fecha) VALUES (@titulo, @descripcion, @uId, @aId, @cId, 'PENDIENTE', NOW())",
      substitutionValues: {
        'titulo': titulo,
        'descripcion': descripcion,
        'uId': _currentUser!.id,
        'aId': aulaId,
        'cId': categoriaId,
      },
    );
    await refreshData();
  }

  Future<String> getAISuggestion(String title, String description) async {
    return await _ai.getTicketSuggestion(title, description);
  }

  void logout() {
    _currentUser = null;
    _incidencias = [];
    _contactos = [];
    _mensajes = [];
    notifyListeners();
  }
}
