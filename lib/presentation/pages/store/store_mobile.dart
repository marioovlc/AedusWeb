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
      floatingActionButton: (user.rol == 'ADMIN' || user.rol == 'Administrador' || user.rol == 'MANTENIMIENTO') 
        ? FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ) 
        : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(context, user.aeduCoins),
            const SizedBox(height: 32),
            Text('Tienda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            if (isLoading)
              const ShimmerStoreGrid(crossAxisCount: 1)
            else if (items.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Sin artículos.')))
            else
              _buildItemList(context, items),
          ],
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
        gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🪙 Mis AeduCoins', style: TextStyle(color: Colors.white, fontSize: 14)),
              Text(coins.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Canjea beneficios', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(Icons.stars, color: theme.colorScheme.primary),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('🪙 ${item.price}', style: TextStyle(color: appColors.gold, fontWeight: FontWeight.bold)),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(minimumSize: const Size(60, 32), padding: EdgeInsets.zero),
          child: const Text('Comprar', style: TextStyle(fontSize: 10)),
        ),
      ),
    );
  }
}
