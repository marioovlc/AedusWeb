import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
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
import 'presentation/pages/store_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/widgets/sustainability_wrapper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Usar URLs limpias (/dashboard) en lugar de URLs con hash (/#/dashboard)
  usePathUrlStrategy();

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

// Rutas que requieren que el usuario esté autenticado
const _protectedRoutes = {
  '/dashboard',
  '/incidencias',
  '/connect',
  '/users',
  '/monitoring',
  '/shop',
  '/settings',
};

// Rutas que requieren el rol de administrador o mantenimiento
const _adminRoutes = {
  '/users',
  '/monitoring',
};

// =============================================
// ==== CLASE AedusApp =====
// Descripción: Widget raíz de la aplicación que configura el tema global, la envoltura de sustentabilidad y la navegación protegida con guards de seguridad basados en autenticación y roles de usuario.
// =============================================
class AedusApp extends StatelessWidget {
  const AedusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Selector en lugar de Consumer: MaterialApp solo se reconstruye cuando
    // cambian el tema, accesibilidad, estado de sesión, o rol de admin.
    // Los refreshes de datos (incidencias, KPIs, logs...) NO vuelven a construir
    // el MaterialApp completo.
    return Selector<AppProvider, (String, bool, bool, bool)>(
      selector: (_, p) => (
        p.currentTheme,
        p.isAccessibilityMode,
        p.currentUser != null,
        p.currentUser?.isAdmin ?? false,
      ),
      builder: (context, _, child) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        return MaterialApp(
          builder: (context, child) => SustainabilityWrapper(child: child!),
          title: 'Aedus App',

          debugShowCheckedModeBanner: false,
          themeMode: provider.currentTheme == 'Blanco' ? ThemeMode.light : ThemeMode.dark,
          theme: AppTheme.getTheme('Blanco', isAccessibilityMode: provider.isAccessibilityMode),
          darkTheme: AppTheme.getTheme(provider.currentTheme, isAccessibilityMode: provider.isAccessibilityMode),
          initialRoute: '/login',
          onGenerateRoute: (settings) {
            final routeName = settings.name ?? '/login';
            // Leer el estado actual al navegar (no depende del ciclo de build)
            final p = Provider.of<AppProvider>(context, listen: false);

            // Guard de autenticación: redirigir a login si no está autenticado
            if (_protectedRoutes.contains(routeName) && p.currentUser == null) {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/login'),
                builder: (context) => const LoginPage(),
              );
            }

            // Guard de rol: redirigir a los no administradores fuera de las rutas administrativas
            if (_adminRoutes.contains(routeName) && p.currentUser?.isAdmin != true) {
              return PageRouteBuilder(
                settings: const RouteSettings(name: '/dashboard'),
                pageBuilder: (context, animation, secondaryAnimation) => MainLayout(
                  currentRoute: '/dashboard',
                  child: const DashboardPage(),
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
              );
            }

            Widget page;
            switch (routeName) {
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
              case '/shop':
                page = const StorePage();
                break;
              case '/settings':
                page = const SettingsPage();
                break;
              default:
                page = p.currentUser == null ? const LoginPage() : const DashboardPage();
            }

            if (routeName == '/login' || routeName == '/register') {
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => page,
              );
            }

            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) => MainLayout(
                currentRoute: routeName,
                child: page,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
        );
      },
    );
  }
}

