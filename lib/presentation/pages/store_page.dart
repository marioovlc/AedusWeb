import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../data/models/store_item_model.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());
    final items = provider.storeItems;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: (user.rol == 'ADMIN' || user.rol == 'Administrador' || user.rol == 'MANTENIMIENTO') 
        ? FloatingActionButton.extended(
            onPressed: () => _showCreateItemDialog(context),
            label: const Text('Nuevo Objeto'),
            icon: const Icon(Icons.add),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ) 
        : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, user.aeduCoins),
            const SizedBox(height: 48),
            
            _buildSectionTitle(context, 'Artículos Disponibles'),
            const SizedBox(height: 24),
            
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('La tienda está vacía. Vuelve más tarde.')),
              )
            else
              _buildItemGrid(context, items),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, int coins) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenido a AeduShop',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Canjea tus AeduCoins por ventajas exclusivas.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  coins.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
    );
  }

  Widget _buildItemGrid(BuildContext context, List<StoreItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(context, item);
      },
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _parseIcon(String name) {
    switch(name) {
      case 'rocket': return Icons.rocket_launch;
      case 'star': return Icons.stars;
      case 'support': return Icons.support_agent;
      case 'palette': return Icons.palette;
      case 'verified': return Icons.verified;
      case 'shield': return Icons.shield;
      default: return Icons.auto_awesome;
    }
  }

  Widget _buildItemCard(BuildContext context, StoreItem item) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final color = _parseColor(item.colorHex);
    final icon = _parseIcon(item.iconStr);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 20),
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                item.description,
                style: TextStyle(color: appColors.textLow, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      item.price.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: appColors.gold),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _confirmPurchase(context, item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Comprar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPurchase(BuildContext context, StoreItem item) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Compra'),
        backgroundColor: appColors.surface,
        content: Text('¿Deseas canjear ${item.price} AeduCoins por "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<AppProvider>().purchaseItem(item.name, item.price);
              if (ctx.mounted) Navigator.pop(ctx);
              
              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('¡Has adquirido "${item.name}"!'), backgroundColor: appColors.success),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('No tienes suficientes AeduCoins.'), backgroundColor: appColors.danger),
                  );
                }
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showCreateItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String selectedIcon = 'star';
    String selectedColor = '#F2C94C';

    final iconsMap = {
      'rocket': Icons.rocket_launch,
      'star': Icons.stars,
      'support': Icons.support_agent,
      'palette': Icons.palette,
      'verified': Icons.verified,
      'shield': Icons.shield,
    };

    final colorsMap = {
      '#F2C94C': Colors.orange,
      '#4F8EF7': Colors.blue,
      '#2ECC71': Colors.green,
      '#9B59B6': Colors.purple,
    };

    final appColors = Theme.of(context).extension<AppColors>()!;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: appColors.surface,
              title: const Text('Nuevo Artículo de Tienda'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                    const SizedBox(height: 16),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceCtrl, 
                      decoration: const InputDecoration(labelText: 'Precio (AeduCoins)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    const Text('Icono', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: iconsMap.keys.map((k) {
                        return ChoiceChip(
                          label: Icon(iconsMap[k], size: 18),
                          selected: selectedIcon == k,
                          onSelected: (val) => setState(() => selectedIcon = k),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: colorsMap.keys.map((k) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = k),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: colorsMap[k],
                              shape: BoxShape.circle,
                              border: Border.all(color: selectedColor == k ? Colors.white : Colors.transparent, width: 3),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                    await context.read<AppProvider>().createStoreItem(
                      nameCtrl.text,
                      descCtrl.text,
                      int.tryParse(priceCtrl.text) ?? 100,
                      selectedIcon,
                      selectedColor,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Crear Objeto'),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
