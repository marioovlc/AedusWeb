class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String status;
  final int aeduCoins;
  final String? avatarUrl;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.status,
    required this.aeduCoins,
    this.avatarUrl,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'].toString(),
      nombre: map['name'] as String? ?? 'Desconocido',
      email: map['email'] as String? ?? '',
      rol: map['role'] as String? ?? map['rol'] as String? ?? 'USER',
      status: map['status']?.toString() ?? ((map['banned'] == true) ? 'BANEADO' : (map['emailVerified'] == false ? 'INACTIVO' : 'ACTIVO')),
      aeduCoins: map['aeducoins'] as int? ?? map['aedu_coins'] as int? ?? 0,
      avatarUrl: map['avatar_url'] as String?,
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
      'avatar_url': avatarUrl,
    };
  }
}
