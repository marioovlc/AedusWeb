import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
          Text(
            'Configuración',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Personaliza tu experiencia en la plataforma Aedus.',
            style: TextStyle(color: appColors.textLow, fontSize: 16),
          ),
          const SizedBox(height: 48),

          _buildSection(context, 'Perfil de Usuario', children: [
            _buildProfileCard(context, user),
          ]),

          const SizedBox(height: 40),
          _buildSection(context, 'Personalización Visual', children: [
            const Text('Selecciona el tema de la interfaz:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ThemeCard(name: 'Blanco', color: const Color(0xFFF8FAFC), isActive: currentTheme == 'Blanco'),
                _ThemeCard(name: 'Original', color: const Color(0xFF060D1C), isActive: currentTheme == 'Original'),
                _ThemeCard(name: 'Daltónico', color: Colors.black, isActive: currentTheme == 'Daltónico'),
                _ThemeCard(name: 'Accesibilidad', color: Colors.black87, isActive: currentTheme == 'Accesibilidad'),
              ],
            ),
          ]),

          const SizedBox(height: 40),
          _buildSection(context, 'Preferencias del Sistema', children: [
            _buildSettingToggle(context, 'Notificaciones Desktop', true, (v) {}),
            _buildSettingToggle(context, 'Sonidos de Notificación', true, (v) {}),
            _buildSettingToggle(context, 'Modo Compacto', context.watch<AppProvider>().isCompact, (v) {
              context.read<AppProvider>().setCompact(v);
            }),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, {required List<Widget> children}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                user.nombre.substring(0, 2).toUpperCase(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user.email, style: TextStyle(color: appColors.textLow)),
                  const SizedBox(height: 12),
                  _buildBadge(context, user.rol),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('EDITAR PERFIL'),
              style: ElevatedButton.styleFrom(backgroundColor: appColors.surface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String rol) {
    final theme = Theme.of(context);
    Color color = theme.colorScheme.primary;
    if (rol == 'Administrador') color = Colors.purple;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        rol.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingToggle(BuildContext context, String title, bool val, Function(bool) onChanged) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: theme.colorScheme.onSurface)),
      value: val,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: theme.colorScheme.primary,
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String name;
  final Color color;
  final bool isActive;

  const _ThemeCard({required this.name, required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    return InkWell(
      onTap: () => context.read<AppProvider>().setTheme(name),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : appColors.border,
            width: isActive ? 3 : 1,
          ),
          boxShadow: isActive ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.2), blurRadius: 10)] : null,
        ),
        child: Stack(
          children: [
            if (isActive)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
              ),
            Center(
              child: Text(
                name,
                style: TextStyle(
                  color: name == 'Blanco' ? Colors.black : Colors.white,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
