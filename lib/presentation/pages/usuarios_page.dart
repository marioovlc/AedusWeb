import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../data/models/user_model.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<AppProvider>().usuariosAdmin;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: _buildUserTable(context, users),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Usuarios',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppTheme.textHighPriority),
            ),
            SizedBox(height: 8),
            Text(
              'Administra roles, permisos y estados de la plataforma.',
              style: TextStyle(color: AppTheme.textLowPriority, fontSize: 16),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('NUEVO USUARIO'),
        ),
      ],
    );
  }

  Widget _buildUserTable(BuildContext context, List<Usuario> users) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surface),
            columns: const [
              DataColumn(label: Text('USUARIO', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ROL', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('COINS', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: users.map((u) => _buildUserRow(context, u)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildUserRow(BuildContext context, Usuario user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Text(user.nombre.substring(0,1).toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue)),
              ),
              const SizedBox(width: 12),
              Text(user.nombre),
            ],
          ),
        ),
        DataCell(Text(user.email, style: const TextStyle(color: AppTheme.textLowPriority))),
        DataCell(_buildRoleBadge(user.rol)),
        DataCell(_buildStatusBadge(user.status)),
        DataCell(Text('🪙 ${user.aeduCoins}')),
        DataCell(
          user.status == 'INACTIVO' 
          ? Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 22), 
                  tooltip: 'Aprobar Solicitud',
                  onPressed: () => context.read<AppProvider>().approveUser(user.id)
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: AppTheme.danger, size: 22), 
                  tooltip: 'Rechazar',
                  onPressed: () => context.read<AppProvider>().rejectUser(user.id)
                ),
              ],
            )
          : Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18), 
                  tooltip: 'Modificar Estado',
                  onPressed: () => _showStatusEditDialog(context, user)
                ),
                IconButton(
                  icon: const Icon(Icons.shield, size: 18), 
                  tooltip: 'Asignar Rol',
                  onPressed: () => _showRoleEditDialog(context, user)
                ),
              ],
            ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String rol) {
    Color color = AppTheme.primaryBlue;
    if (rol == 'Administrador') color = Colors.purple;
    if (rol == 'Mantenimiento') color = AppTheme.secondaryIndigo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(rol, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    if (status == 'BANEADO') {
      color = AppTheme.danger;
      label = 'Baneado';
    } else if (status == 'INACTIVO') {
      color = Colors.orange;
      label = 'Pendiente';
    } else {
      color = AppTheme.success;
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
    String selectedRole = user.rol;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Modificar Rol: ${user.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['Administrador', 'Mantenimiento', 'USER'].map((r) {
                  return RadioListTile<String>(
                    title: Text(r),
                    value: r,
                    groupValue: selectedRole,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) {
                      setState(() { selectedRole = val!; });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text('Cancelar', style: TextStyle(color: AppTheme.textLowPriority))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                  onPressed: () {
                    context.read<AppProvider>().updateUserRole(user.id, selectedRole, user.nombre);
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
    bool isActive = user.status != 'INACTIVO';
    bool isBanned = user.status == 'BANEADO';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Modificar Estado: ${user.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Cuenta Aprobada (Activa)'),
                    subtitle: const Text('Permite al usuario acceder al sistema', style: TextStyle(fontSize: 12)),
                    value: isActive,
                    activeColor: AppTheme.success,
                    onChanged: (val) => setState(() => isActive = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Restringir Acceso (Baneado)'),
                    subtitle: const Text('Deniega permanentemente el acceso', style: TextStyle(fontSize: 12)),
                    value: isBanned,
                    activeColor: AppTheme.danger,
                    onChanged: (val) => setState(() => isBanned = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text('Cancelar', style: TextStyle(color: AppTheme.textLowPriority))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                  onPressed: () {
                    context.read<AppProvider>().updateUserStatus(user.id, isActive, isBanned, user.nombre);
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
