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
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_nombreController.text.isEmpty || _emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await context.read<AppProvider>().requestUser(
            _nombreController.text,
            _emailController.text,
            _passController.text,
          );

      if (!mounted) return;

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Solicitud Enviada'),
            content: const Text('Tu solicitud de registro ha sido enviada. Un administrador deberá validarla antes de que puedas entrar.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('ENTENDIDO'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la solicitud. El email podría estar en uso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
      body: Row(
        children: [
          // Left Side: Branding / Aedus Aesthetic
          Expanded(
            flex: 3,
            child: Container(
              child: Stack(
                children: [
                   // Tech Grid Pattern
                   Positioned.fill(
                    child: Opacity(
                      opacity: 0.05,
                      child: CustomPaint(
                        painter: _PatternPainter(Colors.white),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: const Icon(Icons.security, size: 100, color: Colors.white),
                        ),
                        const SizedBox(height: 48),
                        const Text(
                          'ÚNETE A AEDUS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SOLICITUD DE ACCESO AL SISTEMA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Side: Integrated Registration Form
          Expanded(
            flex: 2,
            child: Container(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Crear Solicitud',
                        style: theme.textTheme.displayLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Completa el formulario para la revisión administrativa.',
                        style: TextStyle(color: appColors.textLow, fontSize: 16),
                      ),
                      const SizedBox(height: 48),
                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: appColors.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: appColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildTextField(context, 'Nombre Completo', 'Ej: Mario Valtierra', _nombreController, false),
                            const SizedBox(height: 20),
                            _buildTextField(context, 'Email Corporativo', 'usuario@dominio.com', _emailController, false),
                            const SizedBox(height: 20),
                            _buildTextField(context, 'Contraseña', 'Crea una contraseña segura', _passController, true),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: _isLoading 
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                                    : const Text('ENVIAR SOLICITUD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: RichText(
                            text: TextSpan(
                              text: '¿Ya tienes una cuenta? ',
                              style: TextStyle(color: appColors.textLow),
                              children: [
                                TextSpan(
                                  text: 'Inicia sesión',
                                  style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, String hint, TextEditingController controller, bool isPassword) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5)),
            filled: true,
            fillColor: appColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
            prefixIcon: Icon(
              isPassword ? Icons.lock_reset : (label.contains('Nombre') ? Icons.person_outline : Icons.alternate_email),
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  _PatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
