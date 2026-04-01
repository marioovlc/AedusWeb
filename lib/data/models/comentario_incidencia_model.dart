class ComentarioIncidencia {
  final int id;
  final int incidenciaId;
  final String usuarioId;
  final String usuarioNombre;
  final String usuarioRol;
  final String texto;
  final DateTime fecha;

  ComentarioIncidencia({
    required this.id,
    required this.incidenciaId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.usuarioRol,
    required this.texto,
    required this.fecha,
  });

  factory ComentarioIncidencia.fromMap(Map<String, dynamic> map) {
    return ComentarioIncidencia(
      id: map['id'] as int,
      incidenciaId: map['incidencia_id'] as int,
      usuarioId: map['usuario_id'].toString(),
      usuarioNombre: map['usuario_nombre'] as String? ?? 'Desconocido',
      usuarioRol: map['usuario_rol'] as String? ?? 'USER',
      texto: map['texto'] as String? ?? '',
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'incidencia_id': incidenciaId,
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'usuario_rol': usuarioRol,
      'texto': texto,
      'fecha': fecha.toIso8601String(),
    };
  }
}
