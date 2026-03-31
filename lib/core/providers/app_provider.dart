import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/incident_model.dart';
import '../../data/models/aula_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/log_model.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';

class AppProvider with ChangeNotifier {
  Usuario? _currentUser;
  List<Incidencia> _incidencias = [];
  List<Usuario> _contactos = [];
  List<Mensaje> _mensajes = [];
  List<LogEntry> _logs = [];
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
  List<LogEntry> get logs => _logs;
  Map<String, String> get kpis => _kpis;

  int get pendingIncidentsCount => _incidencias.where((i) => i.estadoNombre == 'PENDIENTE' || i.estadoNombre == 'NO LEIDO').length;

  AppProvider() {
    _initDatabaseTable();
    refreshData();
  }

  Future<void> _initDatabaseTable() async {
    try {
      await _db.query("", action: "init_db");
    } catch (e) {
      debugPrint('Error initializing solicitudes_usuario table: $e');
    }
  }

  Future<void> fetchAllUsers() async {
    final results = await _db.query("", action: "get_users");
    _usuariosAdmin = results.map((m) => Usuario.fromMap(m)).toList();
    notifyListeners();
  }

  final DatabaseService _db = DatabaseService();
  final AIService _ai = AIService();

  Future<bool> login(String email, String password) async {
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
    return false;
  }

  Future<void> refreshData() async {
    if (_currentUser == null) return;
    await Future.wait([
      _fetchIncidencias(),
      _fetchKPIs(),
      _fetchContactos(),
      _fetchAulas(),
      fetchLogs(),
    ]);
    notifyListeners();
  }

  Future<void> _fetchIncidencias() async {
    final results = await _db.query("", action: "get_incidencias");
    _incidencias = results.map((m) => Incidencia.fromMap(m)).toList();
  }

  Future<void> _fetchKPIs() async {
    final results = await _db.query("", action: "get_kpis");
    
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
    final results = await _db.query("", action: "get_contactos", 
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
      final results = await _db.query("", action: "get_aulas");
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
      "",
      action: "get_mensajes",
      substitutionValues: {'me': _currentUser!.id, 'other': receiverId},
    );
    _mensajes = results.map((m) => Mensaje.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> createIncidencia(String titulo, String descripcion, int aulaId, int categoriaId, {String? imagenUrl}) async {
    if (_currentUser == null) return;
    await _db.query(
      "",
      action: "create_incidencia",
      substitutionValues: {
        'titulo': titulo,
        'descripcion': descripcion,
        'uId': _currentUser!.id,
        'aId': aulaId,
        'cId': categoriaId,
        'img': imagenUrl,
      },
    );
    await createLog('CREAR INCIDENCIA', 'El usuario reportó la incidencia: $titulo');
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
        "",
        action: "send_message",
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

  Future<void> requestUser(String nombre, String email, String password, String motivo) async {
    // Vercel backend will handle the bcrypt hashing securely.
    await _db.query(
      "",
      action: "request_user",
      substitutionValues: {
        'nom': nombre,
        'em': email,
        'pass': password,
      },
    );
  }

  Future<void> approveUser(String id) async {
    await _db.query(
      "",
      action: "approve_user",
      substitutionValues: {'id': id},
    );
    await createLog('ACTUALIZAR USUARIO', 'Se ha aprobado el acceso del usuario ID: $id');
    await fetchAllUsers();
  }

  Future<void> rejectUser(String id) async {
    await _db.query(
      "",
      action: "reject_user",
      substitutionValues: {'id': id},
    );
    await createLog('ELIMINAR USUARIO', 'Se ha rechazado y eliminado al usuario ID: $id');
    await fetchAllUsers();
  }

  Future<void> fetchLogs() async {
    final results = await _db.query("", action: "get_logs");
    _logs = results.map((m) => LogEntry.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> createLog(String accion, String detalles) async {
    if (_currentUser == null) return;
    try {
      await _db.query(
        "",
        action: "create_log",
        substitutionValues: {
          'uId': _currentUser!.id,
          'acc': accion,
          'det': detalles,
        },
      );
    } catch (e) {
      debugPrint('Error logging action: $e');
    }
  }

  Future<void> updateUserRole(String userId, String role, String userName) async {
    await _db.query("", action: "update_user_role", substitutionValues: {'id': userId, 'rol': role});
    await createLog('MODIFICAR ROL', 'Se cambió el rol de $userName a $role');
    await fetchAllUsers();
  }

  Future<void> updateUserStatus(String userId, bool active, bool banned, String userName) async {
    await _db.query("", action: "update_user_status", substitutionValues: {'id': userId, 'ban': banned, 'ev': active});
    await createLog('MODIFICAR ESTADO', 'Se cambió el estado de $userName. Activo: $active, Banned: $banned');
    await fetchAllUsers();
  }

  List<Map<String, dynamic>> getWorkloadLast7Days() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> workload = [];
    
    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      int creadas = 0;
      int resueltas = 0;
      
      for (final inc in _incidencias) {
        if (inc.fecha.year == targetDate.year && inc.fecha.month == targetDate.month && inc.fecha.day == targetDate.day) {
          creadas++;
          if (inc.estadoNombre == 'RESUELTO' || inc.estadoNombre == 'ACABADO') {
            resueltas++;
          }
        }
      }
      
      workload.add({
        'dayLabel': "${targetDate.day}/${targetDate.month}",
        'creadas': creadas.toDouble(),
        'resueltas': resueltas.toDouble()
      });
    }
    return workload;
  }

  void logout() {
    _currentUser = null;
    _incidencias = [];
    _contactos = [];
    _mensajes = [];
    notifyListeners();
  }
}
