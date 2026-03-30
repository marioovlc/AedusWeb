class Mensaje {
  final int id;
  final int senderId;
  final int receiverId;
  final String contenido;
  final DateTime fecha;
  final bool isRead;

  Mensaje({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.contenido,
    required this.fecha,
    this.isRead = false,
  });

  factory Mensaje.fromMap(Map<String, dynamic> map) {
    return Mensaje(
      id: map['id'] as int,
      senderId: map['sender_id'] as int,
      receiverId: map['receiver_id'] as int,
      contenido: map['contenido'] as String,
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha'].toString()) : DateTime.now(),
      isRead: map['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'contenido': contenido,
      'fecha': fecha.toIso8601String(),
      'is_read': isRead,
    };
  }
}
