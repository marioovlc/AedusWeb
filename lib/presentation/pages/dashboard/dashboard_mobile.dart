import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../widgets/loading_shimmer.dart';

class DashboardMobile extends StatelessWidget {
  const DashboardMobile({super.key});

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
          else Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildKPICard(context, 'Total', kpis['Total Incidencias'] ?? '0', FontAwesomeIcons.clipboardList, theme.colorScheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKPICard(context, 'Pend.', kpis['Pendientes'] ?? '0', FontAwesomeIcons.clock, Colors.orange)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildKPICard(context, 'Resuel.', kpis['Resueltas'] ?? '0', FontAwesomeIcons.circleCheck, appColors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKPICard(context, 'Activos', kpis['Usuarios Activos'] ?? '0', FontAwesomeIcons.userGroup, Colors.purple)),
                ],
              ),
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
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: context.read<AppProvider>().getWorkloadLast7Days().asMap().entries.map((e) {
                         return FlSpot(e.key.toDouble(), e.value['creadas']);
                      }).toList(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(BuildContext context) {
    final theme = Theme.of(context);
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
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: context.read<AppProvider>().getIncidenciasPorCategoria().entries.toList().asMap().entries.map((e) {
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

  Widget _buildGamificationSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Logros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        _buildAchievementItem(context, 'Primer Reporte', FontAwesomeIcons.award, theme.extension<AppColors>()!.gold),
        const SizedBox(height: 8),
        _buildAchievementItem(context, 'Soporte Rápido', FontAwesomeIcons.bolt, Colors.cyan),
      ],
    );
  }

  Widget _buildAchievementItem(BuildContext context, String title, FaIconData icon, Color color) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Card(
      color: appColors.surface,
      child: ListTile(
        leading: FaIcon(icon, color: color, size: 20),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        dense: true,
      ),
    );
  }
}
