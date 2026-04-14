import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';

class RegistrationDesktop extends StatefulWidget {
  const RegistrationDesktop({super.key});

  @override
  State<RegistrationDesktop> createState() => _RegistrationDesktopState();
}

class _RegistrationDesktopState extends State<RegistrationDesktop> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AppProvider>().requestUser(
        _nombreController.text,
        _emailController.text,
        _passwordController.text,
        'Registro desde web responsive',
      );
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro solicitado. Espera aprobación.')));
         Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(color: appColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: appColors.border)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Crear Cuenta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre Completo')),
              const SizedBox(height: 16),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _register, child: _isLoading ? const CircularProgressIndicator() : const Text('REGISTRARSE'))),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver al Login')),
            ],
          ),
        ),
      ),
    );
  }
}
