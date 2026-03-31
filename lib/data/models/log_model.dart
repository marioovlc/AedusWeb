class LogEntry {
  final int id;
  final String usuarioId;
  final String usuarioNombre;
  final String usuarioEmail;
  final String accion;
  final String detalles;
  final DateTime fecha;

  LogEntry({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.usuarioEmail,
    required this.accion,
    required this.detalles,
    required this.fecha,
  });

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      id: map['id'] as int,
      usuarioId: map['usuario_id'].toString(),
      usuarioNombre: map['usuario_nombre']?.toString() ?? 'Sistema',
      usuarioEmail: map['usuario_email']?.toString() ?? '',
      accion: map['accion']?.toString() ?? 'Desconocida',
      detalles: map['detalles']?.toString() ?? '',
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'usuario_email': usuarioEmail,
      'accion': accion,
      'detalles': detalles,
      'fecha': fecha.toIso8601String(),
    };
  }
}
