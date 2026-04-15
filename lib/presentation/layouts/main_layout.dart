import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../core/utils/responsive_utils.dart';

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
  int _getSelectedIndex(String route) {
    if (route.startsWith('/dashboard')) return 0;
    if (route.startsWith('/incidencias')) return 1;
    if (route.startsWith('/connect')) return 2;
    if (route.startsWith('/shop')) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    String route = '/dashboard';
    switch (index) {
      case 0: route = '/dashboard'; break;
      case 1: route = '/incidencias'; break;
      case 2: route = '/connect'; break;
      case 3: route = '/shop'; break;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final user = context.watch<AppProvider>().currentUser;
    bool isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      drawer: isMobile ? _buildSidebar(context) : null,
      appBar: isMobile ? AppBar(
        title: Image.asset('lib/assets/aedus.png', height: 52),
        centerTitle: true,
        backgroundColor: appColors.surface,
        elevation: 0,
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                      child: user.avatarUrl == null ? Text(user.nombre.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 10)) : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(
                          color: appColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: appColors.surface, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ) : null,
      bottomNavigationBar: isMobile ? BottomNavigationBar(
        currentIndex: _getSelectedIndex(widget.currentRoute),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: appColors.surface,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: appColors.textLow,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.gaugeHigh, size: 20), label: 'Dash'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.triangleExclamation, size: 20), label: 'Tickets'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.comments, size: 20), label: 'Hub'),
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.shop, size: 20), label: 'Tienda'),
        ],
      ) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    bool isCompact = provider.isCompact;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isCompact ? 84 : 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: appColors.surface,
        border: Border(right: BorderSide(color: appColors.border.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          // Logo Area
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? 24.0 : 36.0, 
              horizontal: isCompact ? 12.0 : 20.0
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(color: appColors.border.withValues(alpha: 0.5)),
              ),
            ),
            child: isCompact 
              ? Center(child: FaIcon(FontAwesomeIcons.solidStar, color: theme.colorScheme.primary, size: 28))
              : Column(
                  children: [
                    Image.asset(
                      'lib/assets/aedus.png',
                      fit: BoxFit.contain,
                      height: 80,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'AEDUS',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
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
                  if (!isCompact) _buildSectionTitle(context, 'PRINCIPAL'),
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
                    if (!isCompact) _buildSectionTitle(context, 'ADMINISTRACIÓN'),
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
                  iconColor: appColors.textLow,
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 12),
      child: Text(
        title,
        style: TextStyle(
          color: appColors.textLow,
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
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    bool isActive = widget.currentRoute == route;

    Widget navContent;
    if (isCompact) {
      navContent = Center(
        child: FaIcon(
          icon, 
          size: 20, 
          color: isActive ? theme.colorScheme.primary : (iconColor ?? appColors.textLow),
        ),
      );
    } else {
      navContent = Row(
        children: [
          FaIcon(
            icon, 
            size: 18, 
            color: isActive ? theme.colorScheme.primary : (iconColor ?? appColors.textLow),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? theme.colorScheme.onSurface : appColors.textLow,
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
                color: appColors.danger,
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
      hoverColor: hoverColor ?? theme.colorScheme.primary.withValues(alpha: 0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: isCompact ? 16 : 12, 
          horizontal: isCompact ? 0 : 16
        ),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
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
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final user = context.watch<AppProvider>().currentUser;
    if (user == null) return const SizedBox.shrink();

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Tooltip(
          message: '${user.nombre} (${user.rol})\n🪙 ${user.aeduCoins}',
          child: Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                child: user.avatarUrl == null ? Text(
                  user.nombre.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ) : null,
              ),
              Positioned(
                bottom: 1, right: 1,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: appColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: appColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appColors.border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: user.avatarUrl == null ? LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  ) : null,
                  image: user.avatarUrl != null ? DecorationImage(
                    image: CachedNetworkImageProvider(user.avatarUrl!),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: user.avatarUrl == null ? Center(
                  child: Text(
                    user.nombre.substring(0, 2).toUpperCase(), 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                  ),
                ) : null,
              ),
              Positioned(
                bottom: 1, right: 1,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: appColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: appColors.card, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nombre,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.rol,
                  style: TextStyle(color: appColors.textLow, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              Text(
                user.aeduCoins.toString(),
                style: TextStyle(color: appColors.gold.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
