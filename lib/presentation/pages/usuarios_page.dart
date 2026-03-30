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
            child: _buildUserTable(users),
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

  Widget _buildUserTable(List<Usuario> users) {
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
            rows: users.map((u) => _buildUserRow(u)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildUserRow(Usuario user) {
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
          Row(
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}),
              IconButton(icon: const Icon(Icons.shield, size: 18), onPressed: () {}),
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
    final isBanned = status == 'BANEADO';
    final color = isBanned ? AppTheme.danger : AppTheme.success;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(isBanned ? 'Baneado' : 'Activo', style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}
