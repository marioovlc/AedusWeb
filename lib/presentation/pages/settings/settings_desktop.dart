import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';

class SettingsDesktop extends StatelessWidget {
  const SettingsDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final user = context.watch<AppProvider>().currentUser;
    final currentTheme = context.watch<AppProvider>().currentTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configuración', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Personaliza tu experiencia en la plataforma Aedus.', style: TextStyle(color: appColors.textLow, fontSize: 16)),
          const SizedBox(height: 48),
          _buildSection(context, 'Perfil de Usuario', children: [_buildProfileCard(context, user)]),
          const SizedBox(height: 40),
          _buildSection(context, 'Personalización Visual', children: [
            const Text('Selecciona el tema de la interfaz:'),
            const SizedBox(height: 16),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _ThemeCard(name: 'Blanco', color: const Color(0xFFF8FAFC), isActive: currentTheme == 'Blanco'),
              _ThemeCard(name: 'Original', color: const Color(0xFF060D1C), isActive: currentTheme == 'Original'),
              _ThemeCard(name: 'Daltónico', color: Colors.black, isActive: currentTheme == 'Daltónico'),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, {required List<Widget> children}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)), const SizedBox(height: 24), ...children]);
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    if (user == null) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.all(24.0), child: Row(children: [CircleAvatar(radius: 40, child: Text(user.nombre.substring(0, 2).toUpperCase())), const SizedBox(width: 24), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(user.email)])), ElevatedButton(onPressed: () {}, child: const Text('EDITAR PERFIL'))])));
  }
}

class _ThemeCard extends StatelessWidget {
  final String name;
  final Color color;
  final bool isActive;
  const _ThemeCard({required this.name, required this.color, required this.isActive});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: () => context.read<AppProvider>().setTheme(name), child: Container(width: 150, height: 100, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: isActive ? Colors.blue : Colors.grey)), child: Center(child: Text(name))));
  }
}
