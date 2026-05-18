// =============================================
// ==== CLASE Achievement =====
// Descripción: Modelo de datos que representa un logro o medalla del sistema gamificado, almacenando su recompensa en monedas y su estado de desbloqueo.
// =============================================
class Achievement {
  final String id;
  final String title;
  final String description;
  final int reward;
  final String? iconPath;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    this.iconPath,
    this.unlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'].toString(),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      reward: map['reward'] as int? ?? 0,
      iconPath: map['icon_path'] as String?,
      unlocked: map['unlocked'] == true || map['unlocked'] == 't',
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'].toString())
          : null,
    );
  }
}
