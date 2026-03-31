import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    super.key, 
    required this.child, 
    required this.currentRoute,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      drawer: isMobile ? _buildSidebar(context) : null,
      appBar: isMobile ? AppBar(
        title: Image.asset('lib/assets/aedus.png', height: 45),
        backgroundColor: AppTheme.background,
      ) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context),
          Expanded(
            child: Container(
              color: AppTheme.background,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      height: double.infinity,
      color: AppTheme.surface,
      child: Column(
        children: [
          // Logo Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(color: AppTheme.borders.withValues(alpha: 0.5)),
              ),
            ),
            child: Image.asset(
              'lib/assets/aedus.png',
              fit: BoxFit.contain,
              height: 100,
            ),
          ),
          const SizedBox(height: 10),

          // Main Navigation
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('PRINCIPAL'),
                  _buildNavItem(context, 'Dashboard', FontAwesomeIcons.gaugeHigh, '/dashboard'),
                  _buildNavItem(
                    context, 
                    'Incidencias', 
                    FontAwesomeIcons.triangleExclamation, 
                    '/incidencias', 
                    badgeCount: context.watch<AppProvider>().pendingIncidentsCount > 0 
                        ? context.watch<AppProvider>().pendingIncidentsCount 
                        : null,
                  ),
                  _buildNavItem(context, 'Connect Hub', FontAwesomeIcons.comments, '/connect'),
                  
                  if (context.watch<AppProvider>().currentUser?.rol == 'Administrador' || context.watch<AppProvider>().currentUser?.rol.toUpperCase() == 'ADMIN') ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('ADMINISTRACIÓN'),
                    _buildNavItem(context, 'Usuarios', FontAwesomeIcons.users, '/users'),
                    _buildNavItem(context, 'Monitorización', FontAwesomeIcons.chartLine, '/monitoring'),
                    _buildNavItem(context, 'Logs de Sistema', FontAwesomeIcons.clockRotateLeft, '/logs'),
                    _buildNavItem(context, 'Tienda', FontAwesomeIcons.shop, '/shop'),
                  ],
                ],
              ),
            ),
          ),

          // User Card
          _buildUserCard(context),

          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildNavItem(context, 'Configuración', FontAwesomeIcons.gear, '/settings'),
                _buildNavItem(context, 'Cerrar Sesión', FontAwesomeIcons.rightFromBracket, '/login', 
                  hoverColor: Colors.red.withValues(alpha: 0.1),
                  iconColor: AppTheme.textLowPriority,
                  onTap: () {
                    context.read<AppProvider>().logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textLowPriority,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, 
    String title, 
    FaIconData icon, 
    String route, {
    int? badgeCount,
    Color? hoverColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    bool isActive = widget.currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap ?? () {
          if (isActive) return;
          Navigator.pushReplacementNamed(context, route);
        },
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: hoverColor ?? AppTheme.primaryBlue.withValues(alpha: 0.05),
        leading: FaIcon(
          icon, 
          size: 18, 
          color: isActive ? AppTheme.primaryBlue : (iconColor ?? AppTheme.textLowPriority),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.textHighPriority : AppTheme.textLowPriority,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: badgeCount != null 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cards,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borders),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.secondaryIndigo],
              ),
            ),
            child: Center(
              child: Text(
                user.nombre.substring(0, 2).toUpperCase(), 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nombre,
                  style: const TextStyle(color: AppTheme.textHighPriority, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.rol,
                  style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              Text(
                user.aeduCoins.toString(),
                style: TextStyle(color: AppTheme.gold.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
