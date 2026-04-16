import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../widgets/loading_shimmer.dart';

class DashboardDesktop extends StatefulWidget {
  const DashboardDesktop({super.key});

  @override
  State<DashboardDesktop> createState() => _DashboardDesktopState();
}

class _DashboardDesktopState extends State<DashboardDesktop> with TickerProviderStateMixin {
  late AnimationController _kpiController;
  bool _kpisAnimated = false;

  @override
  void initState() {
    super.initState();
    _kpiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _kpiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final provider = context.watch<AppProvider>();
    final kpis = provider.kpis;
    final isLoading = provider.isLoading;

    // Disparar animación KPI una sola vez cuando los datos cargan
    if (!isLoading && !_kpisAnimated) {
      _kpisAnimated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _kpiController.forward();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),

          // KPI Cards con animación stagger de entrada
          if (isLoading)
            const ShimmerKPIRow(isMobile: false)
          else
            _buildKPIRow(context, kpis, theme, appColors),

          const SizedBox(height: 32),

          // Charts Section
          if (isLoading)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: ShimmerChartCard(height: 370)),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: ShimmerChartCard(height: 370)),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildLineChartCard(context)),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildBarChartCard(context)),
              ],
            ),

          const SizedBox(height: 32),

          // Bottom Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildGamificationSection(context)),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: _buildAIAssistantCard(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPIRow(BuildContext context, Map<String, String> kpis, ThemeData theme, AppColors appColors) {
    final cards = [
      (title: 'Total Incidencias', value: kpis['Total Incidencias'] ?? '0', icon: FontAwesomeIcons.clipboardList, color: theme.colorScheme.primary),
      (title: 'Pendientes',        value: kpis['Pendientes'] ?? '0',        icon: FontAwesomeIcons.clock,         color: Colors.orange),
      (title: 'Resueltas',         value: kpis['Resueltas'] ?? '0',         icon: FontAwesomeIcons.circleCheck,   color: appColors.success),
      (title: 'Usuarios Activos',  value: kpis['Usuarios Activos'] ?? '0',  icon: FontAwesomeIcons.userGroup,     color: Colors.purple),
    ];

    return Row(
      children: cards.asMap().entries.expand((entry) {
        final i = entry.key;
        final d = entry.value;
        final start = i * 0.15;
        final end = (start + 0.55).clamp(0.0, 1.0);
        final tween = CurvedAnimation(
          parent: _kpiController,
          curve: Interval(start, end, curve: Curves.easeOut),
        );
        return <Widget>[
          Expanded(
            child: AnimatedBuilder(
              animation: _kpiController,
              builder: (context, child) => FadeTransition(
                opacity: tween,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(tween),
                  child: child,
                ),
              ),
              child: _HoverKPICard(
                title: d.title,
                value: d.value,
                icon: d.icon,
                color: d.color,
              ),
            ),
          ),
          if (i < cards.length - 1) const SizedBox(width: 20),
        ];
      }).toList(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final user = context.watch<AppProvider>().currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dashboard', style: theme.textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          'Bienvenido de nuevo, ${user?.nombre ?? "Usuario"}. Aquí tienes el resumen del sistema.',
          style: TextStyle(color: appColors.textLow, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLineChartCard(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final spots = context.read<AppProvider>().getWorkloadLast7Days().asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['creadas'] as double)))
        .toList();
    final hasData = spots.any((s) => s.y > 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolución de Incidencias (7 días)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: hasData
                  ? LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildEmptyChart(appColors, 'Sin actividad en los últimos 7 días'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final categories = context.read<AppProvider>().getIncidenciasPorCategoria();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categorías',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: categories.isEmpty
                  ? _buildEmptyChart(appColors, 'Sin incidencias categorizadas')
                  : BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                final keys = categories.keys.toList();
                                final i = value.toInt();
                                if (i < 0 || i >= keys.length) return const SizedBox.shrink();
                                final name = keys[i];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    name.length > 10 ? '${name.substring(0, 10)}…' : name,
                                    style: TextStyle(fontSize: 10, color: appColors.textLow, fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: categories.entries.toList().asMap().entries.map((e) {
                          final color = [theme.colorScheme.primary, theme.colorScheme.secondary, appColors.success, Colors.orange][e.key % 4];
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.value.toDouble(),
                                color: color,
                                width: 28,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(AppColors appColors, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 52, color: appColors.textLow.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: appColors.textLow, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildGamificationSection(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final achievements = provider.achievements;
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Logros y Misiones'),
        const SizedBox(height: 16),
        if (achievements.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('Completa acciones para desbloquear logros', style: TextStyle(color: appColors.textLow)),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.8,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, i) {
              final a = achievements[i];
              return _buildAchievementItem(
                context, a.title, a.description,
                a.unlocked ? FontAwesomeIcons.award : FontAwesomeIcons.lock,
                a.unlocked ? appColors.gold : appColors.textLow,
                a.unlocked,
              );
            },
          ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.onSurface),
    );
  }

  Widget _buildAchievementItem(BuildContext context, String title, String desc, FaIconData icon, Color color, [bool unlocked = true]) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Opacity(
      opacity: unlocked ? 1.0 : 0.45,
      child: Card(
        color: unlocked ? appColors.surface : appColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: unlocked ? color.withValues(alpha: 0.3) : appColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: FaIcon(icon, color: color, size: 24),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          subtitle: Text(desc, style: TextStyle(color: appColors.textLow, fontSize: 12)),
          trailing: unlocked ? FaIcon(FontAwesomeIcons.check, size: 12, color: appColors.success) : null,
        ),
      ),
    );
  }

  Widget _buildAIAssistantCard(BuildContext context) {
    final theme = Theme.of(context);
    final kpis = context.watch<AppProvider>().kpis;
    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.primary, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(FontAwesomeIcons.wandMagicSparkles, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 12),
                Text(
                  'Asistente AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Resumen del sistema:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              'Actualmente hay ${kpis['Pendientes']} incidencias pendientes. El tiempo promedio de resolución ha bajado un 5% respecto a la semana pasada.',
              style: TextStyle(color: theme.colorScheme.onSurface, height: 1.5, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI Card con efecto hover — se eleva y el fondo del icono se intensifica
// ---------------------------------------------------------------------------
class _HoverKPICard extends StatefulWidget {
  final String title;
  final String value;
  final FaIconData icon;
  final Color color;

  const _HoverKPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  State<_HoverKPICard> createState() => _HoverKPICardState();
}

class _HoverKPICardState extends State<_HoverKPICard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0.0, _hovered ? -6.0 : 0.0, 0.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.color.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))]
              : [],
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: _hovered ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(widget.icon, color: widget.color, size: 20),
                    ),
                    Icon(Icons.more_vert, color: appColors.textLow, size: 20),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  widget.value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  style: TextStyle(color: appColors.textLow, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
