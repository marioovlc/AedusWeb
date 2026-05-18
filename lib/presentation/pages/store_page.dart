import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'store/store_desktop.dart';
import 'store/store_mobile.dart';

// =============================================
// ==== CLASE StorePage =====
// Descripción: Widget delegador para la pantalla de la Tienda de Recompensas de la Plataforma (Store), adaptando el diseño para dispositivos móviles o escritorio.
// =============================================
class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: StoreMobile(),
      desktop: StoreDesktop(),
    );
  }
}
