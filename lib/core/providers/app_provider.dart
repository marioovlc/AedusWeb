import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/incident_model.dart';
import '../../data/models/aula_model.dart';
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
  List<Aula> _aulas = [];

  Usuario? get currentUser => _currentUser;
  List<Incidencia> get incidencias => _incidencias;
  List<Usuario> get contactos => _contactos;
  List<Aula> get aulas => _aulas;
  List<Usuario> get usuariosAdmin => _usuariosAdmin;
  List<Mensaje> get mensajes => _mensajes;
  Map<String, String> get kpis => _kpis;

  int get pendingIncidentsCount => _incidencias.where((i) => i.estadoNombre == 'PENDIENTE' || i.estadoNombre == 'NO LEIDO').length;

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
      debugPrint('Login error: $e');
    }
    return false;
  }

  Future<void> refreshData() async {
    if (_currentUser == null) return;
    await Future.wait([
      _fetchIncidencias(),
      _fetchKPIs(),
      _fetchContactos(),
      _fetchAulas(),
    ]);
    notifyListeners();
  }

  Future<void> _fetchIncidencias() async {
    final results = await _db.query(
      "SELECT i.*, e.nombre as estado_nombre FROM gestion_incidencias.incidencias i JOIN gestion_incidencias.estados e ON i.estado_id = e.id ORDER BY i.fecha DESC"
    );
    _incidencias = results.map((m) => Incidencia.fromMap(m)).toList();
  }

  Future<void> _fetchKPIs() async {
    final results = await _db.query(
      "SELECT e.nombre as estado, count(*) FROM gestion_incidencias.incidencias i JOIN gestion_incidencias.estados e ON i.estado_id = e.id GROUP BY e.nombre"
    );
    
    int total = 0;
    int pendientes = 0;
    int resueltas = 0;

    for (final row in results) {
      final estado = row['estado'].toString().toUpperCase();
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
    
    // Virtual AI Contact
    _contactos.insert(0, Usuario(
      id: 'aedus-ai-system',
      nombre: 'Aedus AI (Sugerencias)',
      email: 'ai@aedus.com',
      rol: 'Sistema',
      status: 'ACTIVO',
      aeduCoins: 9999,
    ));
    notifyListeners();
  }

  Future<void> _fetchAulas() async {
    try {
      final results = await _db.query("SELECT * FROM gestion_incidencias.aulas ORDER BY nombre ASC");
      _aulas = results.map((m) => Aula.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching incidencias: $e');
    }
  }

  Future<void> fetchMessages(String receiverId) async {
    if (_currentUser == null) return;
    
    if (receiverId == 'aedus-ai-system') {
      // AI messages are transient and held in memory during the session.
      // We don't clear them if they already exist to maintain session history.
      if (_mensajes.isNotEmpty && (_mensajes.first.senderId == 'aedus-ai-system' || _mensajes.first.receiverId == 'aedus-ai-system')) {
        return; 
      }
      _mensajes = []; // Clear if we were looking at another contact
      notifyListeners();
      return;
    }

    final results = await _db.query(
      "SELECT * FROM gestion_incidencias.mensajes WHERE (usuario_id = @me AND receptor_id = @other) OR (usuario_id = @other AND receptor_id = @me) ORDER BY fecha ASC",
      substitutionValues: {'me': _currentUser!.id, 'other': receiverId},
    );
    _mensajes = results.map((m) => Mensaje.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> createIncidencia(String titulo, String descripcion, int aulaId, int categoriaId, {String? imagenUrl}) async {
    if (_currentUser == null) return;
    await _db.query(
      "INSERT INTO gestion_incidencias.incidencias (titulo, descripcion, usuario_id, aula_id, categoria_id, estado_id, fecha, imagen_url) VALUES (@titulo, @descripcion, @uId, @aId, @cId, 5, NOW(), @img)",
      substitutionValues: {
        'titulo': titulo,
        'descripcion': descripcion,
        'uId': _currentUser!.id,
        'aId': aulaId,
        'cId': categoriaId,
        'img': imagenUrl,
      },
    );
    await refreshData();
  }

  Future<void> sendMessage(String receiverId, String text, {String? imagenUrl, String? audioUrl}) async {
    if (_currentUser == null) return;

    final mensaje = Mensaje(
      id: 0,
      senderId: _currentUser!.id,
      receiverId: receiverId,
      contenido: text,
      imagenUrl: imagenUrl,
      audioUrl: audioUrl,
      fecha: DateTime.now(),
      isRead: false,
    );

    if (receiverId == 'aedus-ai-system') {
      // AI messages: Session-only update (No DB)
      _mensajes.add(mensaje);
      notifyListeners();
      _triggerAIResponse(text);
      return;
    }

    try {
      // Standard messages: Persist in DB
      await _db.query(
        "INSERT INTO gestion_incidencias.mensajes (usuario_id, receptor_id, texto, imagen_url, audio_url, fecha, leido) VALUES (@me, @other, @txt, @img, @aud, NOW(), false)",
        substitutionValues: {
          'me': _currentUser!.id,
          'other': receiverId,
          'txt': text,
          'img': imagenUrl,
          'aud': audioUrl,
        },
      );
      
      // Update local list from DB to get the correct ID/state
      await fetchMessages(receiverId);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _triggerAIResponse(String userText) async {
    final aiResponse = await _ai.getSummary(userText);
    
    final responseMsg = Mensaje(
      id: 0,
      senderId: 'aedus-ai-system',
      receiverId: _currentUser!.id,
      contenido: aiResponse,
      fecha: DateTime.now(),
      isRead: true,
    );

    _mensajes.add(responseMsg);
    notifyListeners();
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
