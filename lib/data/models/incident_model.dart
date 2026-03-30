class Incidencia {
  final int id;
  final String titulo;
  final String descripcion;
  final String usuarioId;
  final int aulaId;
  final int categoriaId;
  final int estadoId;
  final String estadoNombre;
  final String? imagenUrl;
  final DateTime fecha;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.usuarioId,
    required this.aulaId,
    required this.categoriaId,
    required this.estadoId,
    required this.estadoNombre,
    this.imagenUrl,
    required this.fecha,
  });

  factory Incidencia.fromMap(Map<String, dynamic> map) {
    return Incidencia(
      id: map['id'] as int,
      titulo: map['titulo'] as String? ?? 'Sin Título',
      descripcion: map['descripcion'] as String? ?? '',
      usuarioId: map['usuario_id'].toString(),
      aulaId: map['aula_id'] as int? ?? 0,
      categoriaId: map['categoria_id'] as int? ?? 0,
      estadoId: map['estado_id'] as int? ?? 5,
      estadoNombre: map['estado_nombre'] as String? ?? (map['estado_id'] == 1 ? 'LEIDO' : 'NO LEIDO'),
      imagenUrl: map['imagen_url'] as String?,
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'usuario_id': usuarioId,
      'aula_id': aulaId,
      'categoria_id': categoriaId,
      'estado_id': estadoId,
      'imagen_url': imagenUrl,
      'fecha': fecha.toIso8601String(),
    };
  }
}
