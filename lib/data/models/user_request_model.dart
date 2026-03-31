class UserRequest {
  final int id;
  final String nombre;
  final String email;
  final String passwordHash;
  final String? motivo;
  final DateTime fechaSolicitud;
  final String estado;

  UserRequest({
    required this.id,
    required this.nombre,
    required this.email,
    required this.passwordHash,
    this.motivo,
    required this.fechaSolicitud,
    required this.estado,
  });

  factory UserRequest.fromMap(Map<String, dynamic> map) {
    return UserRequest(
      id: map['id'],
      nombre: map['nombre'],
      email: map['email'],
      passwordHash: map['password_hash'],
      motivo: map['motivo'],
      fechaSolicitud: DateTime.parse(map['fecha_solicitud'].toString()),
      estado: map['estado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'password_hash': passwordHash,
      'motivo': motivo,
      'fecha_solicitud': fechaSolicitud.toIso8601String(),
      'estado': estado,
    };
  }
}
