import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'auth/registration_desktop.dart';
import 'auth/registration_mobile.dart';

// =============================================
// ==== CLASE RegistrationPage =====
// Descripción: Widget delegador para la pantalla de registro de usuarios que selecciona dinámicamente el diseño móvil o de escritorio según la resolución del dispositivo.
// =============================================
class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: RegistrationMobile(),
      desktop: RegistrationDesktop(),
    );
  }
}
