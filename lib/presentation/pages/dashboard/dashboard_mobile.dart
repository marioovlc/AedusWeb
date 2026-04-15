import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../widgets/loading_shimmer.dart';

class DashboardMobile extends StatefulWidget {
  const DashboardMobile({super.key});

  @override
  State<DashboardMobile> createState() => _DashboardMobileState();
}

class _DashboardMobileState extends State<DashboardMobile> with TickerProviderStateMixin {
  late AnimationController _achievementController;
  bool _achievementsAnimated = false;

  @override
  void initState() {
    super.initState();
    _achievementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _achievementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final provider = context.watch<AppProvider>();
    final kpis = provider.kpis;
    final isLoading = provider.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          
          // KPI Grid (2x2)
          if (isLoading)
            const ShimmerKPIRow(isMobile: true)
          else GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            children: [
              _buildKPICard(context, 'Total', kpis['Total Incidencias'] ?? '0', FontAwesomeIcons.clipboardList, theme.colorScheme.primary),
              _buildKPICard(context, 'Pend.', kpis['Pendientes'] ?? '0', FontAwesomeIcons.clock, Colors.orange),
              _buildKPICard(context, 'Resuel.', kpis['Resueltas'] ?? '0', FontAwesomeIcons.circleCheck, appColors.success),
              _buildKPICard(context, 'Activos', kpis['Usuarios Activos'] ?? '0', FontAwesomeIcons.userGroup, Colors.purple),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // AI Assistant (Prominent on Mobile)
          _buildAIAssistantCard(context),
          
          const SizedBox(height: 32),
          
          // Charts (Stacked)
          if (isLoading)
            Column(
              children: [
                ShimmerChartCard(height: 300),
                const SizedBox(height: 16),
                ShimmerChartCard(height: 300),
              ],
            )
          else Column(
            children: [
              _buildLineChartCard(context),
              const SizedBox(height: 16),
              _buildBarChartCard(context),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Gamification
          _buildGamificationSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AppProvider>().currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          'Hola, ${user?.nombre ?? "Usuario"}',
          style: TextStyle(color: theme.extension<AppColors>()!.textLow, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildKPICard(BuildContext context, String title, String value, FaIconData icon, Color color) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(icon, color: color, size: 18),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: appColors.textLow, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssistantCard(BuildContext context) {
    final theme = Theme.of(context);
    final kpis = context.watch<AppProvider>().kpis;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary.withValues(alpha: 0.1), theme.colorScheme.primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.wandMagicSparkles, color: theme.colorScheme.primary, size: 16),
              const SizedBox(width: 8),
              Text('Asistente AI', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tienes ${kpis['Pendientes']} incidencias por resolver hoy. ¡Buen trabajo!',
            style: TextStyle(fontSize: 13, height: 1.4, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evolución (7d)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
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
                            barWidth: 3,
                            belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: categories.isEmpty
                  ? _buildEmptyChart(appColors, 'Sin incidencias categorizadas')
                  : BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: categories.entries.toList().asMap().entries.map((e) {
                          return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.value.toDouble(), color: theme.colorScheme.primary)]);
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
          Icon(Icons.bar_chart_outlined, size: 40, color: appColors.textLow.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: appColors.textLow, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildGamificationSection(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();
    final achievements = provider.achievements;
    final appColors = theme.extension<AppColors>()!;

    // Trigger animation once when achievements load
    if (achievements.isNotEmpty && !_achievementsAnimated) {
      _achievementsAnimated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _achievementController.forward();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(FontAwesomeIcons.trophy, size: 16, color: appColors.gold),
            const SizedBox(width: 8),
            Text('Logros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
            const Spacer(),
            if (achievements.isNotEmpty)
              Text(
                '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
                style: TextStyle(color: appColors.textLow, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (achievements.isEmpty)
          Card(
            color: appColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    FaIcon(FontAwesomeIcons.lock, size: 28, color: appColors.textLow),
                    const SizedBox(height: 8),
                    Text('Completa acciones para desbloquear logros', style: TextStyle(color: appColors.textLow, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          )
        else
          ...achievements.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            return AnimatedBuilder(
              animation: _achievementController,
              builder: (context, child) {
                final delay = (i * 0.12).clamp(0.0, 0.88);
                final start = delay;
                final end = (delay + 0.4).clamp(0.0, 1.0);
                final curve = CurvedAnimation(
                  parent: _achievementController,
                  curve: Interval(start, end, curve: Curves.easeOut),
                );
                return FadeTransition(
                  opacity: curve,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(curve),
                    child: child,
                  ),
                );
              },
              child: _buildAchievementItem(
                context,
                a.title,
                a.description,
                a.unlocked ? FontAwesomeIcons.award : FontAwesomeIcons.lock,
                a.unlocked ? appColors.gold : appColors.textLow,
                a.unlocked,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAchievementItem(BuildContext context, String title, String description, FaIconData icon, Color color, [bool unlocked = true]) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Opacity(
      opacity: unlocked ? 1.0 : 0.5,
      child: Card(
        color: unlocked ? appColors.surface : appColors.card,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: unlocked ? color.withValues(alpha: 0.35) : appColors.border),
        ),
        child: Container(
          decoration: unlocked
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                )
              : null,
          child: ListTile(
            dense: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, color: color, size: 18),
            ),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
            subtitle: description.isNotEmpty
                ? Text(description, style: TextStyle(color: appColors.textLow, fontSize: 11))
                : null,
            trailing: unlocked
                ? Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: appColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(FontAwesomeIcons.check, size: 10, color: appColors.success),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
