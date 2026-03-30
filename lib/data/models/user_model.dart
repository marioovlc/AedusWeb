class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String status;
  final int aeduCoins;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.status,
    required this.aeduCoins,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      email: map['email'] as String,
      rol: map['rol'] as String,
      status: map['status'] as String,
      aeduCoins: map['aeducoins'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'status': status,
      'aeducoins': aeduCoins,
    };
  }
}
