import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/store_item_model.dart';
import '../../widgets/loading_shimmer.dart';

class StoreMobile extends StatelessWidget {
  const StoreMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());
    final items = provider.storeItems;
    final isLoading = provider.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: user.isAdmin
        ? FloatingActionButton(
            onPressed: () => _showCreateItemDialog(context),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          )
        : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context, user.aeduCoins),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Tienda de Beneficios', style: theme.textTheme.displayLarge?.copyWith(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const ShimmerStoreGrid(crossAxisCount: 1)
                else if (items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: theme.extension<AppColors>()!.textLow.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No hay artículos disponibles', style: TextStyle(color: theme.extension<AppColors>()!.textLow)),
                        ],
                      ),
                    ),
                  )
                else
                  _buildItemList(context, items),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, int coins) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🪙 Mi Saldo Actual', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(coins.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('CANJEA TUS AEDUCOINS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const Text('Por ventajas exclusivas en el sistema', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context, List<StoreItem> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(context, items[index]),
    );
  }

  Widget _buildItemCard(BuildContext context, StoreItem item) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.stars, color: theme.colorScheme.primary),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('🪙 ${item.price} AeduCoins', style: TextStyle(color: appColors.gold, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        trailing: ElevatedButton(
          onPressed: () => _confirmPurchase(context, item),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            elevation: 0,
          ),
          child: const Text('CANJEAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _confirmPurchase(BuildContext context, StoreItem item) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
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
      'coffee': Icons.local_cafe,
      'food': Icons.restaurant,
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
              title: const Text('Nuevo Artículo'),
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
                  child: const Text('Crear'),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
