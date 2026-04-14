import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'auth/registration_desktop.dart';
import 'auth/registration_mobile.dart';

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
