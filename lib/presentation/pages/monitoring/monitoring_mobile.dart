import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/log_model.dart';

class MonitoringMobile extends StatefulWidget {
  const MonitoringMobile({super.key});

  @override
  State<MonitoringMobile> createState() => _MonitoringMobileState();
}

class _MonitoringMobileState extends State<MonitoringMobile> {
  String _selectedLogCategory = 'TODOS';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Monitorización', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: appColors.textLow,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
                Tab(text: 'Logs'),
                Tab(text: 'Tickets'),
                Tab(text: 'Salud'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryTab(context),
            _buildIncidentsTab(context),
            _buildSystemStatusTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final logs = context.watch<AppProvider>().logs;
    final filteredLogs = _selectedLogCategory == 'TODOS' ? logs : logs.where((l) => l.categoria == _selectedLogCategory).toList();

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredLogs.length,
            itemBuilder: (ctx, i) => _buildLogTile(context, filteredLogs[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['TODOS', 'SISTEMA', 'ERROR', 'USUARIO'].map((cat) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(cat, style: const TextStyle(fontSize: 12)),
            selected: _selectedLogCategory == cat,
            onSelected: (v) => setState(() => _selectedLogCategory = cat),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildLogTile(BuildContext context, LogEntry log) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(log.accion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(log.detalles, style: const TextStyle(fontSize: 11)),
      trailing: Text('${log.fecha.hour}:${log.fecha.minute.toString().padLeft(2,"0")}', style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildIncidentsTab(BuildContext context) {
    final incidencias = context.watch<AppProvider>().incidencias;
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: incidencias.length,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(incidencias[i].titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(incidencias[i].estadoNombre, style: const TextStyle(fontSize: 12)),
          ),
        )
    );
  }

  Widget _buildSystemStatusTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusCard('Groq AI', true),
        _buildStatusCard('Neon DB', true),
        _buildStatusCard('Vercel API', true),
      ],
    );
  }

  Widget _buildStatusCard(String name, bool online) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.circle, color: online ? Colors.green : Colors.red, size: 12),
        title: Text(name),
        trailing: const Text('99.9%'),
      ),
    );
  }
}
