import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/loading_shimmer.dart';

class UsuariosMobile extends StatefulWidget {
  const UsuariosMobile({super.key});

  @override
  State<UsuariosMobile> createState() => _UsuariosMobileState();
}

class _UsuariosMobileState extends State<UsuariosMobile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final users = provider.usuariosAdmin;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.person_add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuarios', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading 
                ? const ShimmerUserTable() // Or a mobile shimmer
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (ctx, i) => _buildUserCard(context, users[i]),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Usuario user) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(user.nombre.substring(0,1).toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(user.rol, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                    ],
                  ),
                ),
                _buildStatusCircle(context, user.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AeduCoins', style: TextStyle(color: appColors.textLow, fontSize: 11)),
                    Text('🪙 ${user.aeduCoins}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.shield_outlined, size: 20), onPressed: () {}),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCircle(BuildContext context, String status) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    Color color = status == 'ACTIVO' ? appColors.success : (status == 'BANEADO' ? appColors.danger : Colors.orange);
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
