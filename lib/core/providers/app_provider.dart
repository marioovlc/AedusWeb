import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/models/user_model.dart';
import '../../data/models/incident_model.dart';
import '../../data/models/aula_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/log_model.dart';
import '../../data/models/comentario_incidencia_model.dart';
import '../../data/models/store_item_model.dart';
import '../../data/models/achievement_model.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../utils/file_helper.dart';

// =============================================
// ==== CLASE AppProvider =====
// Descripción: Controlador de estado global de la aplicación que gestiona la autenticación de usuarios, la carga y sincronización de incidencias, KPIs, contactos de chat, tienda gamificada, logs del sistema e integración directa con Aedus AI.
// =============================================
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
  List<StoreItem> _storeItems = [];
  List<Achievement> _achievements = [];
  String _currentTheme = 'Original';
  bool _isCompact = false;
  bool _isAccessibilityMode = false;
  bool _isLoading = false;
  final Map<String, bool> _systemHealth = {
    'AI': true,
    'DB': true,
    'API': true,
  };
  Timer? _refreshTimer;
  int _dbLatencyMs = 0;

  Usuario? get currentUser => _currentUser;
  List<Incidencia> get incidencias => _incidencias;
  List<Usuario> get contactos => _contactos;
  List<Aula> get aulas => _aulas;
  List<Usuario> get usuariosAdmin => _usuariosAdmin;
  List<Mensaje> get mensajes => _mensajes;
  List<LogEntry> get logs => _logs;
  List<StoreItem> get storeItems => _storeItems;
  List<Achievement> get achievements => _achievements;
  Map<String, String> get kpis => _kpis;
  String get currentTheme => _currentTheme;
  bool get isCompact => _isCompact;
  bool get isAccessibilityMode => _isAccessibilityMode;
  bool get isLoading => _isLoading;
  Map<String, bool> get systemHealth => _systemHealth;
  int get dbLatencyMs => _dbLatencyMs;
  int get unreadMessagesCount => _mensajes.where((m) => !m.isRead && m.receiverId == _currentUser?.id).length;

  void setCompact(bool compact) {
    _isCompact = compact;
    SharedPreferences.getInstance().then((p) => p.setBool('compact', compact));
    notifyListeners();
  }

  void setAccessibilityMode(bool mode) {
    _isAccessibilityMode = mode;
    SharedPreferences.getInstance().then((p) => p.setBool('accessibility', mode));
    notifyListeners();
  }

  int get pendingIncidentsCount => _incidencias.where((i) => i.estadoNombre == 'PENDIENTE' || i.estadoNombre == 'NO LEIDO').length;

  AppProvider() {
    _initDatabaseTable();
    _loadPreferences();
    refreshData();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = prefs.getString('theme') ?? 'Original';
    _isCompact = prefs.getBool('compact') ?? false;
    _isAccessibilityMode = prefs.getBool('accessibility') ?? false;
    notifyListeners();
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

  Future<void> _completeLogin(Map<String, dynamic> userMap) async {
    _currentUser = Usuario.fromMap(userMap);
    await updateLastSeen();
    _startAutoRefresh();
    await refreshData();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final results = await _db.query(
        "", // El SQL se ignora cuando la acción es 'login'
        substitutionValues: {'email': email, 'password': password},
        action: 'login',
      );

      if (results.isNotEmpty) {
        await _completeLogin(results.first);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en login: $e');
      return false;
    }
  }

  Future<bool> loginGuest() async {
    try {
      final results = await _db.query(
        "",
        action: 'login_guest',
      );
      if (results.isNotEmpty) {
        await _completeLogin(results.first);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en login invitado: $e');
      return false;
    }
  }

  Future<void> refreshData() async {
    if (_currentUser == null) return;
    // Solo mostrar shimmer en la primera carga (cuando no hay datos aún)
    final bool isFirstLoad = _incidencias.isEmpty;
    if (isFirstLoad) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      await Future.wait([
        updateLastSeen(),
        _fetchIncidencias(),
        _fetchKPIs(),
        _fetchContactos(),
        _fetchAulas(),
        _fetchStoreItems(),
        fetchLogs(),
        fetchAchievements(),
      ]);
    } catch (e) {
      debugPrint('Error en refreshData: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchIncidencias() async {
    final results = await _db.query("", action: "get_incidencias");
    final allIncidencias = results.map((m) => Incidencia.fromMap(m)).toList();
    
    // Filtrado: Solo los propietarios ven sus incidencias, a menos que sean personal o administrador
    final role = _currentUser?.rol.toUpperCase();
    if (role == 'ADMIN' || role == 'MANTENIMIENTO' || role == 'ADMINISTRADOR') {
      _incidencias = allIncidencias;
    } else {
      _incidencias = allIncidencias.where((i) => i.usuarioId == _currentUser?.id).toList();
    }
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
      'Usuarios Activos': (_contactos.length + 1).toString(), // Incluyéndose a sí mismo
    };
  }

  Future<void> _fetchContactos() async {
    final results = await _db.query("", action: "get_contactos", 
      substitutionValues: {'id': _currentUser!.id});
    _contactos = results.map((m) => Usuario.fromMap(m)).toList();
    
    // Contacto virtual de IA
    _contactos.insert(0, Usuario(
      id: 'aedus-ai-system',
      nombre: 'Aedus AI (Sugerencias)',
      email: 'ai@aedus.com',
      rol: 'Sistema',
      status: 'ACTIVO',
      aeduCoins: 9999,
    ));
    // No notifyListeners aquí — refreshData() ya notifica al terminar todo
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
      // Los mensajes de IA son transitorios y se guardan en memoria durante la sesión.
      // No los borramos si ya existen para mantener el historial de la sesión.
      if (_mensajes.isNotEmpty && (_mensajes.first.senderId == 'aedus-ai-system' || _mensajes.first.receiverId == 'aedus-ai-system')) {
        return; 
      }
      _mensajes = []; // Limpiar si estábamos viendo a otro contacto
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
    await createLog('CREAR INCIDENCIA', 'El usuario reportó la incidencia: $titulo', categoria: 'USUARIO');
    await grantAchievement('Primer Paso');
    await refreshData();
  }

  Future<void> updateIncidenciaEstado(int id, int estadoId, String uId) async {
    await _db.query(
      "",
      action: "update_incidencia_estado",
      substitutionValues: {
        'id': id,
        'eId': estadoId,
      },
    );

    // Gamificación: Otorgar 50 AeduCoins si finaliza (usualmente Estado 4 = ACABADO)
    if (estadoId == 4) {
      await _db.query("", action: "update_user_coins", substitutionValues: {'uId': uId, 'coins': 50, 'motivo': 'Recompensa por completar incidencia #$id'});
      await createLog('RECOMPENSA', 'Usuario $uId recibió 50 AeduCoins por completar incidencia $id', categoria: 'SISTEMA');
      // Comprobar logro 'Solucionador' (5 o más incidencias completadas)
      final finished = _incidencias.where((i) => i.usuarioId == uId && (i.estadoNombre == 'ACABADO' || i.estadoNombre == 'RESUELTO')).length;
      if (finished >= 4) { // 4 + la actual = 5
        await grantAchievement('Solucionador', userId: uId);
      }
    }

    await createLog('ACTUALIZAR INCIDENCIA', 'Estado de incidencia $id cambiado a $estadoId', categoria: 'SISTEMA');
    await refreshData();
  }

  Future<List<ComentarioIncidencia>> getComentariosIncidencia(int incidenciaId) async {
    final results = await _db.query(
      "",
      action: "get_comentarios_incidencia",
      substitutionValues: {
        'iId': incidenciaId,
        'rol': _currentUser?.rol ?? 'USER'
      },
    );
    return results.map((m) => ComentarioIncidencia.fromMap(m)).toList();
  }

  Future<ComentarioIncidencia?> addComentarioIncidencia(int incidenciaId, String texto, {bool isInternal = false}) async {
    if (_currentUser == null) return null;
    final results = await _db.query(
      "",
      action: "add_comentario_incidencia",
      substitutionValues: {
        'iId': incidenciaId,
        'uId': _currentUser!.id,
        'txt': texto,
        'internal': isInternal,
      },
    );
    if (results.isNotEmpty) {
      await createLog('NUEVO COMENTARIO', 'Usuario ${_currentUser!.nombre} comentó en incidencia #$incidenciaId (Interno: $isInternal)', categoria: 'USUARIO');
      return ComentarioIncidencia.fromMap({...results.first, 'usuario_nombre': _currentUser!.nombre, 'usuario_rol': _currentUser!.rol});
    }
    return null;
  }
  
  Future<void> _fetchStoreItems() async {
    try {
      final results = await _db.query("", action: "get_store_items");
      _storeItems = results.map((m) => StoreItem.fromMap(m)).toList();
    } catch(e) {
      debugPrint('Error fetching store items: $e');
    }
  }

  Future<void> fetchAchievements() async {
    if (_currentUser == null) return;
    try {
      final results = await _db.query("", action: "get_all_achievements", substitutionValues: {'uId': _currentUser!.id});
      _achievements = results.map((m) => Achievement.fromMap(m)).toList();
    } catch(e) {
      debugPrint('Error fetching achievements: $e');
    }
  }

  Future<void> grantAchievement(String title, {String? userId}) async {
    if (_currentUser == null) return;
    try {
      await _db.query("", action: "grant_achievement", substitutionValues: {
        'title': title,
        'uId': userId ?? _currentUser!.id,
      });
    } catch(e) {
      debugPrint('Error granting achievement: $e');
    }
  }

  Future<void> createStoreItem(String name, String desc, int price, String icon, String color) async {
    if (_currentUser == null) return;
    await _db.query("", action: "create_store_item", substitutionValues: {
      'nom': name, 'des': desc, 'pri': price, 'ico': icon, 'col': color
    });
    await _fetchStoreItems();
    notifyListeners();
  }

  Future<void> sendMessage(String receiverId, String text, {String? imageUrl, String? audioUrl, int? ticketLinkId}) async {
    if (_currentUser == null) return;

    final mensaje = Mensaje(
      id: 0,
      senderId: _currentUser!.id,
      receiverId: receiverId,
      contenido: text,
      imagenUrl: imageUrl,
      audioUrl: audioUrl,
      ticketLinkId: ticketLinkId,
      fecha: DateTime.now(),
      isRead: false,
    );

    if (receiverId == 'aedus-ai-system') {
      // Mensajes de IA: Actualización solo de sesión (sin Base de Datos)
      _mensajes.add(mensaje);
      notifyListeners();
      _triggerAIResponse(text);
      return;
    }

    try {
      // Mensajes estándar: Persistir en la Base de Datos
      await _db.query(
        "",
        action: "send_message",
        substitutionValues: {
          'me': _currentUser!.id,
          'other': receiverId,
          'txt': text,
          'img': imageUrl,
          'aud': audioUrl,
          'ticket_link_id': ticketLinkId,
        },
      );
      
      // Conceder logro 'Colaborador' en el primer mensaje
      await grantAchievement('Colaborador');
      
      // Actualizar la lista local desde la Base de Datos para obtener el ID y estado correctos
      await fetchMessages(receiverId);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _triggerAIResponse(String userText) async {
    final context = _getAIContext();
    final aiResponse = await _ai.getSummary(userText, context: context);
    
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

  Future<bool> requestUser(String nombre, String email, String password) async {
    // El backend en Vercel gestionará el hash de bcrypt de forma segura.
    await _db.query(
      "",
      action: "request_user",
      substitutionValues: {
        'nom': nombre,
        'em': email,
        'pass': password,
      },
    );
    return true;
  }

  Future<void> approveUser(String id) async {
    await _db.query(
      "",
      action: "approve_user",
      substitutionValues: {'id': id},
    );
    await createLog('ACTUALIZAR USUARIO', 'Se ha aprobado el acceso del usuario ID: $id', categoria: 'SISTEMA');
    await fetchAllUsers();
  }

  Future<void> rejectUser(String id) async {
    await _db.query(
      "",
      action: "reject_user",
      substitutionValues: {'id': id},
    );
    await createLog('ELIMINAR USUARIO', 'Se ha rechazado y eliminado al usuario ID: $id', categoria: 'SISTEMA');
    await fetchAllUsers();
  }

  Future<void> fetchLogs() async {
    final results = await _db.query("", action: "get_logs");
    _logs = results.map((m) => LogEntry.fromMap(m)).toList();
    // No notifyListeners aquí — refreshData() ya notifica al terminar todo
    // Si se llama de forma independiente, notificamos
    if (_isLoading == false) notifyListeners();
  }

  Future<void> createLog(String accion, String detalles, {String categoria = 'USUARIO'}) async {
    if (_currentUser == null) return;
    try {
      await _db.query(
        "",
        action: "create_log",
        substitutionValues: {
          'uId': _currentUser!.id,
          'acc': accion,
          'det': detalles,
          'cat': categoria,
        },
      );
    } catch (e) {
      debugPrint('Error logging action: $e');
    }
  }

  Future<void> updateUserRole(String userId, String role, String userName) async {
    await _db.query("", action: "update_user_role", substitutionValues: {'id': userId, 'rol': role});
    await createLog('MODIFICAR ROL', 'Se cambió el rol de $userName a $role', categoria: 'SISTEMA');
    await fetchAllUsers();
  }

  Future<void> updateUserStatus(String userId, bool active, bool banned, String userName) async {
    await _db.query("", action: "update_user_status", substitutionValues: {'id': userId, 'ban': banned, 'ev': active});
    await createLog('MODIFICAR ESTADO', 'Se cambió el estado de $userName. Activo: $active, Banned: $banned', categoria: 'SISTEMA');
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

  Map<String, int> getIncidenciasPorCategoria() {
    final Map<String, int> counts = {};
    for (final inc in _incidencias) {
      final cat = inc.categoriaNombre;
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> updateUserProfile({required String name, required String email, String? avatarUrl, String? telefono, String? bio}) async {
    if (_currentUser == null) return;
    
    final results = await _db.query(
      "", 
      action: "update_user_profile", 
      substitutionValues: {
        'id': _currentUser!.id,
        'nom': name,
        'em': email,
        'img': avatarUrl ?? _currentUser!.avatarUrl,
        'tel': telefono ?? _currentUser!.telefono,
        'bio': bio ?? _currentUser!.bio,
      }
    );

    if (results.isNotEmpty) {
      _currentUser = Usuario.fromMap(results.first);
      await createLog('ACTUALIZAR PERFIL', 'Información de perfil actualizada', categoria: 'USUARIO');
      notifyListeners();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentUser != null) {
        refreshData();
      } else {
        _stopAutoRefresh();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> updateLastSeen() async {
    if (_currentUser == null) return;
    try {
      await _db.query("", action: "update_last_seen", substitutionValues: {'id': _currentUser!.id});
    } catch (e) {
      debugPrint('Error updating last seen: $e');
    }
  }

  Future<String?> exportLogsToCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Usuario", "Email", "Acción", "Categoría", "Detalles", "Fecha"]);
    
    for (var log in _logs) {
      rows.add([
        log.id,
        log.usuarioNombre,
        log.usuarioEmail,
        log.accion,
        log.categoria,
        log.detalles,
        log.fecha.toIso8601String()
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      platformDownload(csv, "logs_${DateTime.now().millisecondsSinceEpoch}.csv");
      return "Descargado";
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/logs_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csv);
      await createLog('EXPORTAR', 'Se exportaron los logs a CSV: $path', categoria: 'SISTEMA');
      return path;
    } catch (e) {
      debugPrint("Error exporting logs: $e");
      return null;
    }
  }

  Future<String?> exportIncidenciasToCSV() async {
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Título", "Estado", "UsuarioID", "AulaID", "CategoríaID", "Fecha", "Descripción"]);
    
    for (var inc in _incidencias) {
      rows.add([
        inc.id,
        inc.titulo,
        inc.estadoNombre,
        inc.usuarioId,
        inc.aulaId,
        inc.categoriaId,
        inc.fecha.toIso8601String(),
        inc.descripcion
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      platformDownload(csv, "incidencias_${DateTime.now().millisecondsSinceEpoch}.csv");
      return "Descargado";
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/incidencias_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csv);
      await createLog('EXPORTAR', 'Se exportaron las incidencias a CSV: $path', categoria: 'SISTEMA');
      return path;
    } catch (e) {
      debugPrint("Error exporting incidencias: $e");
      return null;
    }
  }

  void setTheme(String themeName) {
    _currentTheme = themeName;
    SharedPreferences.getInstance().then((p) => p.setString('theme', themeName));
    notifyListeners();
  }

  Future<bool> purchaseItem(String itemName, int cost) async {
    if (_currentUser == null || _currentUser!.aeduCoins < cost) return false;
    
    try {
      await _db.query("", action: "update_user_coins", substitutionValues: {'uId': _currentUser!.id, 'coins': -cost, 'motivo': 'Compra: $itemName'});
      await createLog('COMPRA', 'Compra de item: $itemName por $cost coins', categoria: 'USUARIO');
      await refreshData();
      return true;
    } catch (e) {
      debugPrint('Error purchasing item: $e');
      return false;
    }
  }

  Future<void> checkSystemHealth() async {
    try {
      final startTime = DateTime.now();
      await _db.query("SELECT 1", action: "raw"); // Ping simple a la base de datos
      final dbPing = DateTime.now().difference(startTime).inMilliseconds;

      _dbLatencyMs = dbPing;
      _systemHealth['DB'] = dbPing < 500;
      _systemHealth['API'] = true;

      // Ping a la IA
      final aiRes = await _ai.getSummary("ping");
      _systemHealth['AI'] = !aiRes.contains("Error");

      notifyListeners();
    } catch (e) {
      debugPrint('Health check failed: $e');
      _systemHealth['DB'] = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _incidencias = [];
    _contactos = [];
    _mensajes = [];
    _stopAutoRefresh();
    notifyListeners();
  }

  String _getAIContext() {
    final sb = StringBuffer();
    sb.writeln("ESTADO ACTUAL DEL SISTEMA:");
    sb.writeln("Métricas principales: $_kpis");
    sb.writeln("Usuarios registrados: ${_contactos.length}");
    sb.writeln("Incidencias totales: ${_incidencias.length}");
    
    final pendientes = _incidencias.where((i) => i.estadoNombre == 'PENDIENTE' || i.estadoNombre == 'NO LEIDO' || i.estadoNombre == 'ABIERTA').length;
    sb.writeln("Incidencias pendientes: $pendientes");
    
    sb.writeln("\nLISTA DE USUARIOS (Resumen):");
    // Omitir el índice 0 (la propia IA)
    final userLimit = _contactos.length > 16 ? 16 : _contactos.length;
    for (int i = 1; i < userLimit; i++) {
      final u = _contactos[i];
      sb.writeln("- ${u.nombre} (Rol: ${u.rol})");
    }
    if (_contactos.length > 16) sb.writeln("- ... y otros más.");

    sb.writeln("\nÚLTIMAS INCIDENCIAS ACTIVAS:");
    final activas = _incidencias.where((i) => i.estadoNombre != 'ACABADO' && i.estadoNombre != 'RESUELTO' && i.estadoNombre != 'CERRADA').take(15);
    for (final i in activas) {
      sb.writeln("- #${i.id}: ${i.titulo} [${i.estadoNombre}]");
    }
    
    return sb.toString();
  }
}
