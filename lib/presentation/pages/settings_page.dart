import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'settings/settings_desktop.dart';
import 'settings/settings_mobile.dart';

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
