import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'dashboard/dashboard_desktop.dart';
import 'dashboard/dashboard_mobile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: DashboardMobile(),
      desktop: DashboardDesktop(),
    );
  }
}
