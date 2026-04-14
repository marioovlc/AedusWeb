import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'auth/login_desktop.dart';
import 'auth/login_mobile.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: LoginMobile(),
      desktop: LoginDesktop(),
    );
  }
}
