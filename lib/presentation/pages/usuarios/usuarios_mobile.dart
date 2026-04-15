import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();
    final users = provider.usuariosAdmin;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.fetchAllUsers(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text('Usuarios', style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isLoading 
                    ? const ShimmerUserTable() 
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (ctx, i) => _buildUserCard(context, users[i]),
                      ),
                ),
              ],
            ),
          ),
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
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                      child: user.avatarUrl == null ? Text(user.nombre.substring(0,1).toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)) : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: _onlineColor(user.lastSeen, appColors),
                          shape: BoxShape.circle,
                          border: Border.all(color: appColors.card, width: 1.5),
                        ),
                      ),
                    ),
                  ],
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_timeAgo(user.lastSeen), style: TextStyle(color: _onlineColor(user.lastSeen, appColors), fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('visto', style: TextStyle(color: appColors.textLow, fontSize: 10)),
                  ],
                ),
                if (user.status == 'INACTIVO') 
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle_outline, color: appColors.success, size: 24), 
                        onPressed: () => context.read<AppProvider>().approveUser(user.id)
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel_outlined, color: appColors.danger, size: 24), 
                        onPressed: () => context.read<AppProvider>().rejectUser(user.id)
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20), 
                        onPressed: () => _showStatusEditDialog(context, user)
                      ),
                      IconButton(
                        icon: const Icon(Icons.shield_outlined, size: 20), 
                        onPressed: () => _showRoleEditDialog(context, user)
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleEditDialog(BuildContext context, Usuario user) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    String selectedRole = user.rol;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: appColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Modificar Rol: ${user.nombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: RadioGroup<String>(
                groupValue: selectedRole,
                onChanged: (val) {
                  setState(() { selectedRole = val!; });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Administrador', 'Mantenimiento', 'USER'].map((r) {
                    return RadioListTile<String>(
                      title: Text(r),
                      value: r,
                      activeColor: theme.colorScheme.primary,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: Text('Cancelar', style: TextStyle(color: appColors.textLow))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
                  onPressed: () {
                    ctx.read<AppProvider>().updateUserRole(user.id, selectedRole, user.nombre);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showStatusEditDialog(BuildContext context, Usuario user) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    bool isActive = user.status != 'INACTIVO';
    bool isBanned = user.status == 'BANEADO';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: appColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Modificar Estado: ${user.nombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Cuenta Aprobada'),
                    subtitle: Text('Permite el acceso al sistema', style: TextStyle(fontSize: 11, color: appColors.textLow)),
                    value: isActive,
                    activeThumbColor: appColors.success,
                    onChanged: (val) => setState(() => isActive = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Restringir Acceso (Baneado)'),
                    subtitle: Text('Deniega permanentemente el acceso', style: TextStyle(fontSize: 11, color: appColors.textLow)),
                    value: isBanned,
                    activeThumbColor: appColors.danger,
                    onChanged: (val) => setState(() => isBanned = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: Text('Cancelar', style: TextStyle(color: appColors.textLow))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
                  onPressed: () {
                    ctx.read<AppProvider>().updateUserStatus(user.id, isActive, isBanned, user.nombre);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
        );
      }
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

  Color _onlineColor(DateTime? lastSeen, AppColors appColors) {
    if (lastSeen == null) return appColors.textLow;
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 5) return appColors.success;
    if (diff.inMinutes < 30) return Colors.orange;
    return appColors.textLow;
  }

  String _timeAgo(DateTime? lastSeen) {
    if (lastSeen == null) return 'Nunca';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}
