import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final kpis = context.watch<AppProvider>().kpis;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          
          // KPI Cards from Provider
          Row(
            children: [
              Expanded(child: _buildKPICard('Total Incidencias', kpis['Total Incidencias'] ?? '0', FontAwesomeIcons.clipboardList, AppTheme.primaryBlue)),
              const SizedBox(width: 20),
              Expanded(child: _buildKPICard('Pendientes', kpis['Pendientes'] ?? '0', FontAwesomeIcons.clock, Colors.orange)),
              const SizedBox(width: 20),
              Expanded(child: _buildKPICard('Resueltas', kpis['Resueltas'] ?? '0', FontAwesomeIcons.circleCheck, AppTheme.success)),
              const SizedBox(width: 20),
              Expanded(child: _buildKPICard('Usuarios Activos', kpis['Usuarios Activos'] ?? '0', FontAwesomeIcons.userGroup, Colors.purple)),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Charts Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildLineChartCard()),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: _buildBarChartCard()),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Bottom Grid: Gamification & AI Assistant
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildGamificationSection()),
              const SizedBox(width: 20),
              Expanded(flex: 1, child: _buildAIAssistantCard(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenido de nuevo, ${user?.nombre ?? "Usuario"}. Aquí tienes el resumen del sistema.',
          style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, FaIconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(icon, color: color, size: 20),
                ),
                const Icon(Icons.more_vert, color: AppTheme.textLowPriority, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textHighPriority,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textLowPriority,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartCard() {
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
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3),
                        const FlSpot(1, 1),
                        const FlSpot(2, 4),
                        const FlSpot(3, 2),
                        const FlSpot(4, 5),
                        const FlSpot(5, 3),
                        const FlSpot(6, 4),
                      ],
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      ),
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

  Widget _buildBarChartCard() {
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
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: AppTheme.primaryBlue)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: AppTheme.secondaryIndigo)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: AppTheme.success)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 6, color: Colors.orange)]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Logros y Misiones'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAchievementItem('Primer Reporte', 'Has creado tu primera incidencia.', FontAwesomeIcons.award, AppTheme.gold)),
            const SizedBox(width: 16),
            Expanded(child: _buildAchievementItem('Soporte Rápido', 'Resuelto en menos de 1 hora.', FontAwesomeIcons.bolt, Colors.cyan)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textHighPriority),
    );
  }

  Widget _buildAchievementItem(String title, String desc, FaIconData icon, Color color) {
    return Card(
      color: AppTheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: FaIcon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textHighPriority)),
        subtitle: Text(desc, style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 12)),
      ),
    );
  }

  Widget _buildAIAssistantCard(BuildContext context) {
    final kpis = context.watch<AppProvider>().kpis;
    return Card(
      color: AppTheme.primaryBlue.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.primaryBlue, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                FaIcon(FontAwesomeIcons.wandMagicSparkles, color: AppTheme.primaryBlue, size: 18),
                SizedBox(width: 12),
                Text(
                  'Asistente AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Resumen del sistema:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHighPriority),
            ),
            const SizedBox(height: 12),
            Text(
              'Actualmente hay ${kpis['Pendientes']} incidencias pendientes. El tiempo promedio de resolución ha bajado un 5% respecto a la semana pasada.',
              style: const TextStyle(color: AppTheme.textHighPriority, height: 1.5, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
