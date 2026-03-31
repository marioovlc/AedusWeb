import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(context, user.aeduCoins),
          const SizedBox(height: 48),
          
          _buildSectionTitle('Power-ups de Sistema'),
          const SizedBox(height: 24),
          _buildItemGrid(context, [
            _StoreItem(
              name: 'Prioridad Turbo',
              description: 'Tus tickets saltan al inicio de la cola de moderación.',
              price: 150,
              icon: Icons.rocket_launch,
              color: Colors.orange,
            ),
            _StoreItem(
              name: 'Análisis IA Extra',
              description: '10 sugerencias técnicas adicionales para tus incidencias.',
              price: 300,
              icon: Icons.auto_awesome,
              color: AppTheme.primaryBlue,
            ),
            _StoreItem(
              name: 'Soporte Directo',
              description: 'Acceso a un canal de chat prioritario con administradores.',
              price: 500,
              icon: Icons.support_agent,
              color: AppTheme.success,
            ),
          ]),

          const SizedBox(height: 48),
          _buildSectionTitle('Personalización Premium'),
          const SizedBox(height: 24),
          _buildItemGrid(context, [
            _StoreItem(
              name: 'Borde Dorado',
              description: 'Añade un destello premium a tu avatar en los chats.',
              price: 200,
              icon: Icons.stars,
              color: AppTheme.gold,
            ),
            _StoreItem(
              name: 'Tema Cyberpunk',
              description: 'Desbloquea el tema visual neón para toda la interfaz.',
              price: 450,
              icon: Icons.palette,
              color: Colors.purpleAccent,
            ),
            _StoreItem(
              name: 'Badge de Veterano',
              description: 'Muestra orgulloso tu estatus en la comunidad Aedus.',
              price: 1000,
              icon: Icons.verified,
              color: Colors.cyan,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, int coins) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.secondaryIndigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
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
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textHighPriority),
    );
  }

  Widget _buildItemGrid(BuildContext context, List<_StoreItem> items) {
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

  Widget _buildItemCard(BuildContext context, _StoreItem item) {
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
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(height: 20),
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                item.description,
                style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 13),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _confirmPurchase(context, item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
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

  void _confirmPurchase(BuildContext context, _StoreItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Compra'),
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
                    SnackBar(content: Text('¡Has adquirido "${item.name}"!'), backgroundColor: AppTheme.success),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No tienes suficientes AeduCoins.'), backgroundColor: AppTheme.danger),
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
}

class _StoreItem {
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;

  _StoreItem({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });
}
