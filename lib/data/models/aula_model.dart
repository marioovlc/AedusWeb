class Aula {
  final int id;
  final String nombre;
  final int capacidad;
  final String tipo;

  Aula({
    required this.id,
    required this.nombre,
    required this.capacidad,
    required this.tipo,
  });

  factory Aula.fromMap(Map<String, dynamic> map) {
    return Aula(
      id: map['id'] as int? ?? 0,
      nombre: map['nombre'] as String? ?? 'Desconocida',
      capacidad: map['capacidad'] as int? ?? 0,
      tipo: map['tipo'] as String? ?? 'GENERAL',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'capacidad': capacidad,
      'tipo': tipo,
    };
  }
}
