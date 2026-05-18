import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'settings/settings_desktop.dart';
import 'settings/settings_mobile.dart';

// =============================================
// ==== CLASE SettingsPage =====
// Descripción: Widget delegador para la pantalla de Configuración de la Aplicación y Perfil (Settings), derivando su presentación según el tipo de pantalla del dispositivo.
// =============================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: SettingsMobile(),
      desktop: SettingsDesktop(),
    );
  }
}
