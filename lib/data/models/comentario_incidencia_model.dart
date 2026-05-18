// =============================================
// ==== CLASE ComentarioIncidencia =====
// Descripción: Modelo de datos que representa un comentario o nota asociada a una incidencia técnica, dando soporte a marcas de comentarios internos para el equipo técnico.
// =============================================
class ComentarioIncidencia {
  final int id;
  final int incidenciaId;
  final String usuarioId;
  final String usuarioNombre;
  final String usuarioRol;
  final String texto;
  final DateTime fecha;
  final bool isInternal;

  ComentarioIncidencia({
    required this.id,
    required this.incidenciaId,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.usuarioRol,
    required this.texto,
    required this.fecha,
    this.isInternal = false,
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
      isInternal: map['is_internal'] == true || map['is_internal'] == 'true',
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
      'is_internal': isInternal,
    };
  }
}
