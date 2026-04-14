import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'usuarios/usuarios_desktop.dart';
import 'usuarios/usuarios_mobile.dart';

class UsuariosPage extends StatelessWidget {
  const UsuariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: UsuariosMobile(),
      desktop: UsuariosDesktop(),
    );
  }
}
