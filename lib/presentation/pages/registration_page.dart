import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _motivoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (_nombreController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena los campos obligatorios.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AppProvider>().requestUser(
        _nombreController.text,
        _emailController.text,
        _passwordController.text,
        _motivoController.text,
      );
      
      if (mounted) {
        final theme = Theme.of(context);
        final appColors = theme.extension<AppColors>()!;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: appColors.surface,
            title: Text('Solicitud Enviada', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
            content: Text(
              'Tu solicitud de usuario ha sido registrada correctamente. Un administrador la revisará pronto.',
              style: TextStyle(color: appColors.textLow),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('VOLVER AL LOGIN'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la solicitud: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: appColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: appColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Solicitud de Usuario',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Completa el formulario para solicitar acceso al sistema.',
                  style: TextStyle(color: appColors.textLow, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildTextField(context, 'Nombre Completo', _nombreController, false),
                const SizedBox(height: 20),
                _buildTextField(context, 'Email', _emailController, false),
                const SizedBox(height: 20),
                _buildTextField(context, 'Contraseña Deseada', _passwordController, true),
                const SizedBox(height: 20),
                _buildTextField(context, 'Motivo de la solicitud (Opcional)', _motivoController, false, maxLines: 3),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('ENVIAR SOLICITUD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text('YA TENGO CUENTA - VOLVER', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller, bool isPassword, {int maxLines = 1}) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: appColors.textLow, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          maxLines: maxLines,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Introduce tu $label',
            hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5)),
            fillColor: appColors.card,
          ),
        ),
      ],
    );
  }
}
