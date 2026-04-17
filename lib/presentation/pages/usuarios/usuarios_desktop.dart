import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/loading_shimmer.dart';

class UsuariosDesktop extends StatefulWidget {
  const UsuariosDesktop({super.key});

  @override
  State<UsuariosDesktop> createState() => _UsuariosDesktopState();
}

class _UsuariosDesktopState extends State<UsuariosDesktop> {
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

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          Expanded(
            child: isLoading
                ? const SingleChildScrollView(child: ShimmerUserTable())
                : _buildUserTable(context, users),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Usuarios',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Administra roles, permisos y estados de la plataforma.',
              style: TextStyle(color: appColors.textLow, fontSize: 16),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('NUEVO USUARIO'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTable(BuildContext context, List<Usuario> users) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(appColors.surface),
              columns: [
                DataColumn(label: Text('USUARIO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('ROL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('COINS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('ACTIVIDAD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
              ],
              rows: users.map((u) => _buildUserRow(context, u)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime? lastSeen) {
    if (lastSeen == null) return 'Nunca';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }

  Color _onlineColor(DateTime? lastSeen, AppColors appColors) {
    if (lastSeen == null) return appColors.textLow;
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 5) return appColors.success;
    if (diff.inMinutes < 30) return Colors.orange;
    return appColors.textLow;
  }

  DataRow _buildUserRow(BuildContext context, Usuario user) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                    child: user.avatarUrl == null ? Text(user.nombre.substring(0,1).toUpperCase(), style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)) : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: _onlineColor(user.lastSeen, appColors),
                        shape: BoxShape.circle,
                        border: Border.all(color: appColors.card, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Text(user.nombre),
            ],
          ),
        ),
        DataCell(Text(user.email, style: TextStyle(color: appColors.textLow))),
        DataCell(_buildRoleBadge(context, user.rol)),
        DataCell(_buildStatusBadge(context, user.status)),
        DataCell(Text('🪙 ${user.aeduCoins}')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: _onlineColor(user.lastSeen, appColors),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _timeAgo(user.lastSeen),
                style: TextStyle(color: appColors.textLow, fontSize: 13),
              ),
            ],
          ),
        ),
        DataCell(
          user.status == 'INACTIVO' 
          ? Row(
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle_outline, color: appColors.success, size: 22), 
                  tooltip: 'Aprobar Solicitud',
                  onPressed: () => _confirmApprove(context, user)
                ),
                IconButton(
                  icon: Icon(Icons.cancel_outlined, color: appColors.danger, size: 22), 
                  tooltip: 'Rechazar',
                  onPressed: () => _confirmReject(context, user)
                ),
              ],
            )
          : Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: appColors.textLow), 
                  tooltip: 'Modificar Estado',
                  onPressed: () => _showStatusEditDialog(context, user)
                ),
                IconButton(
                  icon: Icon(Icons.shield, size: 18, color: appColors.textLow), 
                  tooltip: 'Asignar Rol',
                  onPressed: () => _showRoleEditDialog(context, user)
                ),
              ],
            ),
        ),
      ],
    );
  }

  Future<void> _confirmApprove(BuildContext context, Usuario user) async {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aprobar usuario', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Confirmas que deseas dar acceso al sistema a ${user.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCELAR', style: TextStyle(color: appColors.textLow))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appColors.success, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('APROBAR'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppProvider>().approveUser(user.id);
    }
  }

  Future<void> _confirmReject(BuildContext context, Usuario user) async {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rechazar solicitud', style: TextStyle(fontWeight: FontWeight.bold, color: appColors.danger)),
        content: Text('¿Estás seguro de que deseas rechazar y eliminar definitivamente la solicitud de ${user.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCELAR', style: TextStyle(color: appColors.textLow))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('RECHAZAR Y ELIMINAR'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppProvider>().rejectUser(user.id);
    }
  }

  Widget _buildRoleBadge(BuildContext context, String rol) {
    final theme = Theme.of(context);
    Color color = theme.colorScheme.primary;
    if (rol == 'Administrador' || rol.toUpperCase() == 'ADMIN') color = Colors.purple;
    if (rol == 'Mantenimiento') color = theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(rol, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    Color color;
    String label;
    
    if (status == 'BANEADO') {
      color = appColors.danger;
      label = 'Baneado';
    } else if (status == 'INACTIVO') {
      color = Colors.orange;
      label = 'Pendiente';
    } else {
      color = appColors.success;
      label = 'Activo';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
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
              title: Text('Modificar Rol: ${user.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              title: Text('Modificar Estado: ${user.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Cuenta Aprobada (Activa)'),
                    subtitle: Text('Permite al usuario acceder al sistema', style: TextStyle(fontSize: 12, color: appColors.textLow)),
                    value: isActive,
                    activeThumbColor: appColors.success,
                    onChanged: (val) => setState(() => isActive = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Restringir Acceso (Baneado)'),
                    subtitle: Text('Deniega permanentemente el acceso', style: TextStyle(fontSize: 12, color: appColors.textLow)),
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
}
