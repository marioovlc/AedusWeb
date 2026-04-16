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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use clean URLs (/dashboard) instead of hash URLs (/#/dashboard)
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

// Routes that require the user to be authenticated
const _protectedRoutes = {
  '/dashboard',
  '/incidencias',
  '/connect',
  '/users',
  '/monitoring',
  '/shop',
  '/settings',
};

// Routes that require admin or mantenimiento role
const _adminRoutes = {
  '/users',
  '/monitoring',
};

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

            // Auth guard: redirect to login if not authenticated
            if (_protectedRoutes.contains(routeName) && p.currentUser == null) {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/login'),
                builder: (context) => const LoginPage(),
              );
            }

            // Role guard: redirect non-admins away from admin routes
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

