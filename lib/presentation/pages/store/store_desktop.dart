import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/store_item_model.dart';
import '../../widgets/loading_shimmer.dart';

class StoreDesktop extends StatelessWidget {
  const StoreDesktop({super.key});

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
      floatingActionButton: (user.rol == 'ADMIN' || user.rol == 'Administrador' || user.rol == 'MANTENIMIENTO') 
        ? FloatingActionButton.extended(
            onPressed: () => _showCreateItemDialog(context),
            label: const Text('Nuevo Objeto'),
            icon: const Icon(Icons.add),
          ) 
        : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, user.aeduCoins),
            const SizedBox(height: 48),
            Text('Artículos Disponibles', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 24),
            if (isLoading)
              const ShimmerStoreGrid(crossAxisCount: 3)
            else if (items.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('La tienda está vacía.')))
            else
              _buildItemGrid(context, items, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, int coins) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bienvenido a AeduShop', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Canjea tus AeduCoins por ventajas exclusivas.', style: TextStyle(color: Colors.white70, fontSize: 18)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(24)),
            child: Row(children: [const Text('🪙', style: TextStyle(fontSize: 32)), const SizedBox(width: 16), Text(coins.toString(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(BuildContext context, List<StoreItem> items, int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 24, mainAxisSpacing: 24, childAspectRatio: 1.2),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(context, items[index]),
    );
  }

  Widget _buildItemCard(BuildContext context, StoreItem item) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.stars, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 16),
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🪙 ${item.price}', style: TextStyle(fontWeight: FontWeight.bold, color: appColors.gold)),
                ElevatedButton(onPressed: () {}, child: const Text('Comprar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateItemDialog(BuildContext context) {
    // Logic for creating item (can be moved here or to a mixin)
  }
}
