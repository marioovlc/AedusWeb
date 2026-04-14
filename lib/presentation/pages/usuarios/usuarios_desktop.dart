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
            Text('Gestión de Usuarios', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('Administra roles, permisos y estados de la plataforma.', style: TextStyle(color: appColors.textLow, fontSize: 16)),
          ],
        ),
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('NUEVO USUARIO')),
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
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(appColors.surface),
            columns: [
              DataColumn(label: Text('USUARIO', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
              DataColumn(label: Text('ROL', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
              DataColumn(label: Text('ESTADO', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
              DataColumn(label: Text('COINS', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
              DataColumn(label: Text('VISTO', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
              DataColumn(label: Text('ACCIONES', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
            ],
            rows: users.map((u) => _buildUserRow(context, u)).toList(),
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
        DataCell(Text(user.nombre, style: TextStyle(color: theme.colorScheme.onSurface))),
        DataCell(_buildRoleBadge(context, user.rol)),
        DataCell(_buildStatusBadge(context, user.status)),
        DataCell(Text('🪙 ${user.aeduCoins}')),
        DataCell(Text(user.lastSeen != null ? '${user.lastSeen!.day}/${user.lastSeen!.month} ${user.lastSeen!.hour}:${user.lastSeen!.minute.toString().padLeft(2, "0")}' : 'Nunca', style: TextStyle(fontSize: 12, color: appColors.textLow))),
        DataCell(Row(children: [IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () {}), IconButton(icon: const Icon(Icons.shield, size: 18), onPressed: () {})])),
      ],
    );
  }

  Widget _buildRoleBadge(BuildContext context, String rol) {
    Color color = Colors.blue;
    if (rol == 'Administrador' || rol == 'ADMIN') color = Colors.purple;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(rol, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    Color color = status == 'ACTIVO' ? appColors.success : (status == 'BANEADO' ? appColors.danger : Colors.orange);
    return Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(status, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold))]);
  }
}
