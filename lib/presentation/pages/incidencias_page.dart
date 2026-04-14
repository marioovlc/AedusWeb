import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'incidencias/incidencias_desktop.dart';
import 'incidencias/incidencias_mobile.dart';

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
