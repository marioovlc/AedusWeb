import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
              'Administra roles, permisos y estados de la plataforma (Desktop).',
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
                DataColumn(label: Text('VISTO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
              ],
              rows: users.map((u) => _buildUserRow(context, u)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildUserRow(BuildContext context, Usuario user) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(user.nombre.substring(0,1).toUpperCase(), style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
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
        DataCell(Text(user.lastSeen != null 
          ? '${user.lastSeen!.day}/${user.lastSeen!.month} ${user.lastSeen!.hour}:${user.lastSeen!.minute.toString().padLeft(2, '0')}' 
          : 'Nunca', style: TextStyle(color: appColors.textLow, fontSize: 13))),
        DataCell(
          user.status == 'INACTIVO' 
          ? Row(
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle_outline, color: appColors.success, size: 22), 
                  tooltip: 'Aprobar Solicitud',
                  onPressed: () => context.read<AppProvider>().approveUser(user.id)
                ),
                IconButton(
                  icon: Icon(Icons.cancel_outlined, color: appColors.danger, size: 22), 
                  tooltip: 'Rechazar',
                  onPressed: () => context.read<AppProvider>().rejectUser(user.id)
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
