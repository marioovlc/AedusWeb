class Usuario {
  final String id;
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
      id: map['id'].toString(),
      nombre: map['name'] as String? ?? 'Desconocido',
      email: map['email'] as String? ?? '',
      rol: map['role'] as String? ?? 'USER',
      status: map['status']?.toString() ?? ((map['banned'] == true) ? 'BANEADO' : 'ACTIVO'),
      aeduCoins: map['aeducoins'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': nombre,
      'email': email,
      'role': rol,
      'status': status,
      'aeducoins': aeduCoins,
    };
  }
}
