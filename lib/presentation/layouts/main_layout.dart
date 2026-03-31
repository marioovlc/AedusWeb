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
    final provider = context.watch<AppProvider>();
    bool isCompact = provider.isCompact;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isCompact ? 84 : 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.borders.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          // Logo Area
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? 30.0 : 40.0, 
              horizontal: isCompact ? 12.0 : 20.0
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(color: AppTheme.borders.withValues(alpha: 0.5)),
              ),
            ),
            child: isCompact 
              ? const Center(child: FaIcon(FontAwesomeIcons.solidStar, color: AppTheme.primaryBlue, size: 28))
              : Image.asset(
                  'lib/assets/aedus.png',
                  fit: BoxFit.contain,
                  height: 80,
                ),
          ),
          const SizedBox(height: 10),

          // Main Navigation
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  if (!isCompact) _buildSectionTitle('PRINCIPAL'),
                  _buildNavItem(context, 'Dashboard', FontAwesomeIcons.gaugeHigh, '/dashboard', isCompact: isCompact),
                  _buildNavItem(
                    context, 
                    'Incidencias', 
                    FontAwesomeIcons.triangleExclamation, 
                    '/incidencias', 
                    isCompact: isCompact,
                    badgeCount: provider.pendingIncidentsCount > 0 
                        ? provider.pendingIncidentsCount 
                        : null,
                  ),
                  _buildNavItem(context, 'Connect Hub', FontAwesomeIcons.comments, '/connect', isCompact: isCompact),
                  _buildNavItem(context, 'Tienda', FontAwesomeIcons.shop, '/shop', isCompact: isCompact),
                  
                  if (provider.currentUser?.rol == 'Administrador' || provider.currentUser?.rol.toUpperCase() == 'ADMIN') ...[
                    const SizedBox(height: 24),
                    if (!isCompact) _buildSectionTitle('ADMINISTRACIÓN'),
                    _buildNavItem(context, 'Usuarios', FontAwesomeIcons.users, '/users', isCompact: isCompact),
                    _buildNavItem(context, 'Monitorización', FontAwesomeIcons.chartLine, '/monitoring', isCompact: isCompact),
                  ],
                ],
              ),
            ),
          ),

          // User Card
          _buildUserCard(context, isCompact),

          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                _buildNavItem(context, 'Configuración', FontAwesomeIcons.gear, '/settings', isCompact: isCompact),
                _buildNavItem(context, 'Cerrar Sesión', FontAwesomeIcons.rightFromBracket, '/login', 
                  isCompact: isCompact,
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
    bool isCompact = false,
    int? badgeCount,
    Color? hoverColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    bool isActive = widget.currentRoute == route;

    Widget navContent;
    if (isCompact) {
      navContent = Center(
        child: FaIcon(
          icon, 
          size: 20, 
          color: isActive ? AppTheme.primaryBlue : (iconColor ?? AppTheme.textLowPriority),
        ),
      );
    } else {
      navContent = Row(
        children: [
          FaIcon(
            icon, 
            size: 18, 
            color: isActive ? AppTheme.primaryBlue : (iconColor ?? AppTheme.textLowPriority),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? AppTheme.textHighPriority : AppTheme.textLowPriority,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badgeCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      );
    }

    Widget navItem = InkWell(
      onTap: onTap ?? () {
        if (isActive) return;
        Navigator.pushReplacementNamed(context, route);
      },
      borderRadius: BorderRadius.circular(12),
      hoverColor: hoverColor ?? AppTheme.primaryBlue.withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 16 : 12, 
          horizontal: isCompact ? 0 : 16
        ),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: navContent,
      ),
    );

    if (isCompact) {
      return Tooltip(
        message: title,
        preferBelow: false,
        child: navItem,
      );
    }
    return navItem;
  }

  Widget _buildUserCard(BuildContext context, bool isCompact) {
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Tooltip(
          message: '${user.nombre} (${user.rol})\n🪙 ${user.aeduCoins}',
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              user.nombre.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

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
