class Incidencia {
  final int id;
  final String titulo;
  final String descripcion;
  final int usuarioId;
  final int aulaId;
  final int categoriaId;
  final String estado;
  final String? imagenRuta;
  final DateTime fecha;

  Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.usuarioId,
    required this.aulaId,
    required this.categoriaId,
    required this.estado,
    this.imagenRuta,
    required this.fecha,
  });

  factory Incidencia.fromMap(Map<String, dynamic> map) {
    return Incidencia(
      id: map['id'] as int,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      usuarioId: map['usuario_id'] as int,
      aulaId: map['aula_id'] as int,
      categoriaId: map['categoria_id'] as int,
      estado: map['estado'] as String? ?? 'NO LEIDO',
      imagenRuta: map['imagen_ruta'] as String?,
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
      'estado': estado,
      'imagen_ruta': imagenRuta,
      'fecha': fecha.toIso8601String(),
    };
  }
}
