import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'monitoring/monitoring_desktop.dart';
import 'monitoring/monitoring_mobile.dart';

// =============================================
// ==== CLASE MonitoringPage =====
// Descripción: Widget delegador para la pantalla de Monitorización de Servidores y Sistemas (Monitoring), adaptando el diseño según si el cliente está en móvil o escritorio.
// =============================================
class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: MonitoringMobile(),
      desktop: MonitoringDesktop(),
    );
  }
}
