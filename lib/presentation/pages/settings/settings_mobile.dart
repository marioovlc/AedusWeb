import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/services/storage_service.dart';

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
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickAndUploadAvatar(context),
              child: Stack(
                children: [
                   CircleAvatar(
                     radius: 40, 
                     backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl) : null,
                     child: user.avatarUrl == null ? Text(user.nombre.substring(0,2).toUpperCase()) : null,
                   ),
                   Positioned(
                     bottom: 0, right: 0,
                     child: Container(
                       padding: const EdgeInsets.all(4),
                       decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                       child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showEditProfileDialog(context, user), 
              child: const Text('EDITAR PERFIL')
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final url = await StorageService().uploadFile(bytes, image.name);
      if (url != null && context.mounted) {
        await context.read<AppProvider>().updateUserProfile(
          name: context.read<AppProvider>().currentUser!.nombre,
          email: context.read<AppProvider>().currentUser!.email,
          avatarUrl: url,
        );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    final nameController = TextEditingController(text: user.nombre);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 16),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              await context.read<AppProvider>().updateUserProfile(
                name: nameController.text,
                email: emailController.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('GUARDAR'),
          ),
        ],
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
    return RadioGroup<String>(
      groupValue: currentTheme,
      onChanged: (v) => context.read<AppProvider>().setTheme(v!),
      child: Column(
        children: ['Blanco', 'Original', 'Daltónico'].map((t) => RadioListTile<String>(
          title: Text(t),
          value: t,
        )).toList(),
      ),
    );
  }
}
