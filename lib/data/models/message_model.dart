class Mensaje {
  final int id;
  final String senderId;
  final String receiverId;
  final String contenido;
  final String? imagenUrl;
  final String? audioUrl;
  final DateTime fecha;
  final bool isRead;

  Mensaje({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.contenido,
    this.imagenUrl,
    this.audioUrl,
    required this.fecha,
    this.isRead = false,
  });

  factory Mensaje.fromMap(Map<String, dynamic> map) {
    return Mensaje(
      id: map['id'] as int,
      senderId: map['usuario_id'].toString(),
      receiverId: map['receptor_id']?.toString() ?? '',
      contenido: map['texto'] as String? ?? '',
      imagenUrl: map['imagen_url'] as String?,
      audioUrl: map['audio_url'] as String?,
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha'].toString()) : DateTime.now(),
      isRead: map['leido'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuario_id': senderId,
      'receptor_id': receiverId,
      'texto': contenido,
      'imagen_url': imagenUrl,
      'audio_url': audioUrl,
      'fecha': fecha.toIso8601String(),
      'leido': isRead,
    };
  }
}
