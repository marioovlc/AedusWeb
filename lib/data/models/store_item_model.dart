// =============================================
// ==== CLASE StoreItem =====
// Descripción: Modelo de datos que representa un artículo disponible para compra virtual en la tienda de la plataforma Aedus, registrando su identificador, nombre, descripción, costo en AeduCoins, icono y color.
// =============================================
class StoreItem {
  final int id;
  final String name;
  final String description;
  final int price;
  final String iconStr;
  final String colorHex;

  StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.iconStr,
    required this.colorHex,
  });

  factory StoreItem.fromMap(Map<String, dynamic> map) {
    return StoreItem(
      id: map['id'] as int,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] as int? ?? 0,
      iconStr: map['icon'] ?? 'settings',
      colorHex: map['color'] ?? '#4F8EF7',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'icon': iconStr,
      'color': colorHex,
    };
  }
}
