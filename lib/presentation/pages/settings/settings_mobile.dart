import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_provider.dart';

class SettingsMobile extends StatelessWidget {
  const SettingsMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AppProvider>().currentUser;
    final currentTheme = context.watch<AppProvider>().currentTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configuración', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 24),
          _buildProfileCard(context, user),
          const SizedBox(height: 32),
          Text('Personalización', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          const Text('Tema del sistema:'),
          const SizedBox(height: 12),
          _ThemeSettingsList(currentTheme: currentTheme),
          const SizedBox(height: 32),
          Text('Preferencias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          _buildToggles(context),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    if (user == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(radius: 40, child: Text(user.nombre.substring(0,2).toUpperCase())),
            const SizedBox(height: 16),
            Text(user.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: const Text('EDITAR PERFIL')),
          ],
        ),
      ),
    );
  }

  Widget _buildToggles(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Column(
      children: [
        SwitchListTile(title: const Text('Modo Compacto'), value: provider.isCompact, onChanged: (v) => provider.setCompact(v)),
        SwitchListTile(title: const Text('Accesibilidad'), value: provider.isAccessibilityMode, onChanged: (v) => provider.setAccessibilityMode(v)),
      ],
    );
  }
}

class _ThemeSettingsList extends StatelessWidget {
  final String currentTheme;
  const _ThemeSettingsList({required this.currentTheme});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: ['Blanco', 'Original', 'Daltónico'].map((t) => RadioListTile(
        title: Text(t),
        value: t,
        groupValue: currentTheme,
        onChanged: (v) => context.read<AppProvider>().setTheme(v!),
      )).toList(),
    );
  }
}
