import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          
          _buildSection('Estado de los Servicios'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildServiceStatus('API Vercel', true, '99.9% uptime')),
              const SizedBox(width: 16),
              Expanded(child: _buildServiceStatus('Neon DB', true, '24ms latency')),
              const SizedBox(width: 16),
              Expanded(child: _buildServiceStatus('Cloudinary', true, 'Ready')),
              const SizedBox(width: 16),
              Expanded(child: _buildServiceStatus('Groq AI', true, 'Active')),
            ],
          ),
          
          const SizedBox(height: 48),
          
          _buildSection('Carga de Trabajo de Mantenimiento'),
          const SizedBox(height: 16),
          _buildWorkloadChart(context),
          
          const SizedBox(height: 48),
          
          _buildSection('Logs de Actividad del Sistema'),
          const SizedBox(height: 16),
          _buildPerformanceLogs(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monitorización del Sistema',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppTheme.textHighPriority),
        ),
        SizedBox(height: 8),
        Text(
          'Métricas en tiempo real sobre el rendimiento y disponibilidad de Aedus.',
          style: TextStyle(color: AppTheme.textLowPriority, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textHighPriority),
    );
  }

  Widget _buildServiceStatus(String name, bool online, String secondary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Icon(Icons.circle, color: online ? AppTheme.success : AppTheme.danger, size: 10),
              ],
            ),
            const SizedBox(height: 12),
            Text(secondary, style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkloadChart(BuildContext context) {
    final workloadStats = context.watch<AppProvider>().getWorkloadLast7Days();
    final List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < workloadStats.length; i++) {
        final double creadas = workloadStats[i]['creadas'];
        final double resueltas = workloadStats[i]['resueltas'];
        if (creadas > maxY) maxY = creadas;
        if (resueltas > maxY) maxY = resueltas;
        barGroups.add(_buildBarGroup(i, creadas, resueltas));
    }

    if (maxY == 0) maxY = 10;
    else maxY = maxY * 1.5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tickets Nuevos vs Resueltos (7d)', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _buildLegendItem('Nuevos', AppTheme.primaryBlue),
                    const SizedBox(width: 16),
                    _buildLegendItem('Resueltos', AppTheme.secondaryIndigo),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < workloadStats.length) {
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(workloadStats[value.toInt()]['dayLabel'] as String, style: const TextStyle(fontSize: 10, color: AppTheme.textLowPriority)),
                             );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  barGroups: barGroups.isEmpty ? [_buildBarGroup(0, 0, 0)] : barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: AppTheme.primaryBlue, width: 12),
        BarChartRodData(toY: y2, color: AppTheme.secondaryIndigo, width: 12),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 12)),
      ],
    );
  }

  Widget _buildPerformanceLogs(BuildContext context) {
    final logs = context.watch<AppProvider>().logs;

    if (logs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No hay logs disponibles.', style: TextStyle(color: AppTheme.textLowPriority))),
        )
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = logs[index];
          
          final Duration d = DateTime.now().difference(log.fecha);
          String timeStr = 'ahora';
          if (d.inDays > 0) timeStr = 'hace ${d.inDays}d';
          else if (d.inHours > 0) timeStr = 'hace ${d.inHours}h';
          else if (d.inMinutes > 0) timeStr = 'hace ${d.inMinutes}m';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: CircleAvatar(
               radius: 18,
               backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
               child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 18),
            ),
            title: Text('${log.usuarioNombre}: ${log.accion}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(log.detalles, style: const TextStyle(fontSize: 13, color: AppTheme.textLowPriority)),
            trailing: Text(timeStr, style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 12)),
          );
        },
      ),
    );
  }
}
