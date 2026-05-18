import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'connect_hub/connect_hub_desktop.dart';
import 'connect_hub/connect_hub_mobile.dart';

// =============================================
// ==== CLASE ConnectHubPage =====
// Descripción: Widget de tipo página que envuelve el centro de comunicación 'Connect Hub' y realiza la delegación adaptable para móviles y escritorio.
// =============================================
class ConnectHubPage extends StatelessWidget {
  const ConnectHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: ConnectHubMobile(),
      desktop: ConnectHubDesktop(),
    );
  }
}
