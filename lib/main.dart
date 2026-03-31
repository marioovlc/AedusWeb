import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_provider.dart';
import 'presentation/layouts/main_layout.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/incidencias_page.dart';
import 'presentation/pages/connect_hub_page.dart';
import 'presentation/pages/usuarios_page.dart';
import 'presentation/pages/monitoring_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/registration_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Info: No .env file found. Falling back to build-time vars.");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const AedusApp(),
    ),
  );
}

class AedusApp extends StatelessWidget {
  const AedusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aedus App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      initialRoute: '/login', // Start with Login
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/login':
            page = const LoginPage();
            break;
          case '/register':
            page = const RegistrationPage();
            break;
          case '/dashboard':
            page = const DashboardPage();
            break;
          case '/incidencias':
            page = const IncidenciasPage();
            break;
          case '/connect':
            page = const ConnectHubPage();
            break;
          case '/users':
            page = const UsuariosPage();
            break;
          case '/monitoring':
            page = const MonitoringPage();
            break;
          default:
            page = const LoginPage();
        }

        // Only wrap with MainLayout if it's not the login or register page
        if (settings.name == '/login' || settings.name == '/register') {
          return MaterialPageRoute(builder: (context) => page);
        }

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => MainLayout(
            currentRoute: settings.name ?? '',
            child: page,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    );
  }
}
