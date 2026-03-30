import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

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
          _buildWorkloadChart(),
          
          const SizedBox(height: 48),
          
          _buildSection('Logs de Rendimiento'),
          const SizedBox(height: 16),
          _buildPerformanceLogs(),
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

  Widget _buildWorkloadChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tickets atendidos vs Resueltos (7d)', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _buildLegendItem('Atendidos', AppTheme.primaryBlue),
                    const SizedBox(width: 16),
                    _buildLegendItem('Resueltas', AppTheme.secondaryIndigo),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  barGroups: [
                    _buildBarGroup(0, 15, 12),
                    _buildBarGroup(1, 20, 18),
                    _buildBarGroup(2, 10, 10),
                    _buildBarGroup(3, 25, 20),
                    _buildBarGroup(4, 18, 15),
                    _buildBarGroup(5, 12, 11),
                    _buildBarGroup(6, 30, 25),
                  ],
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

  Widget _buildPerformanceLogs() {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final logs = [
            'Database Query Optimized: incidence_fetch took 12ms',
            'Cloudinary: 5 images compressed successfully',
            'Groq AI: Rate limit within 20% of quota',
            'Backup: nightly_dump.sql generated (45MB)',
            'Identity: 30 new user sessions active',
          ];
          return ListTile(
            leading: const Icon(Icons.code, color: AppTheme.primaryBlue, size: 20),
            title: Text(logs[index], style: const TextStyle(fontSize: 13)),
            trailing: const Text('hace 5m', style: TextStyle(color: AppTheme.textLowPriority, fontSize: 11)),
          );
        },
      ),
    );
  }
}
