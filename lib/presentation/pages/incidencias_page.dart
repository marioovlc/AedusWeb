import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'incidencias/incidencias_desktop.dart';
import 'incidencias/incidencias_mobile.dart';

// =============================================
// ==== CLASE IncidenciasPage =====
// Descripción: Widget delegador que gestiona la pantalla del listado e historial de incidencias (Tickets), adaptando la visualización a móvil o escritorio.
// =============================================
class IncidenciasPage extends StatelessWidget {
  const IncidenciasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: IncidenciasMobile(),
      desktop: IncidenciasDesktop(),
    );
  }
}
