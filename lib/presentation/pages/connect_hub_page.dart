import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'connect_hub/connect_hub_desktop.dart';
import 'connect_hub/connect_hub_mobile.dart';

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
