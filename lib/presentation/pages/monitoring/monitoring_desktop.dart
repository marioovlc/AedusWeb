import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/log_model.dart';
import '../../../data/models/incident_model.dart';

class MonitoringDesktop extends StatefulWidget {
  const MonitoringDesktop({super.key});

  @override
  State<MonitoringDesktop> createState() => _MonitoringDesktopState();
}

class _MonitoringDesktopState extends State<MonitoringDesktop> {
  String _selectedLogCategory = 'TODOS';
  final List<String> _categories = ['TODOS', 'SISTEMA', 'ERROR', 'USUARIO'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeader(context),
                TabBar(
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: appColors.textLow,
                  tabs: const [
                    Tab(text: 'Historial', icon: Icon(Icons.history)),
                    Tab(text: 'Incidencias', icon: Icon(Icons.dashboard_customize)),
                    Tab(text: 'Estado del Sistema', icon: Icon(Icons.health_and_safety)),
                  ],
                ),
              ],
            ),
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Monitorización', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        Text('Panel administrativo de Aedus', style: TextStyle(color: appColors.textLow, fontSize: 14)),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final logs = context.watch<AppProvider>().logs;
    final filteredLogs = _selectedLogCategory == 'TODOS' ? logs : logs.where((l) => l.categoria == _selectedLogCategory).toList();
    Map<String, List<LogEntry>> groupedLogs = {};
    for (var log in filteredLogs) {
      String dateKey = _formatDateKey(log.fecha);
      if (!groupedLogs.containsKey(dateKey)) groupedLogs[dateKey] = [];
      groupedLogs[dateKey]!.add(log);
    }
    final dateKeys = groupedLogs.keys.toList();

    return Column(
      children: [
        _buildFilters(context),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: dateKeys.length,
            itemBuilder: (context, index) {
              final date = dateKeys[index];
              return StickyHeader(header: Container(height: 50, color: Theme.of(context).scaffoldBackgroundColor, alignment: Alignment.centerLeft, child: Text(date, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))), content: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: groupedLogs[date]!.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (ctx, i) => _buildLogTile(context, groupedLogs[date]![i])));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), child: Row(children: _categories.map((cat) => Padding(padding: const EdgeInsets.only(right: 8.0), child: FilterChip(selected: _selectedLogCategory == cat, label: Text(cat), onSelected: (v) => setState(() => _selectedLogCategory = cat)))).toList()));
  }

  String _formatDateKey(DateTime date) => '${date.day}/${date.month}';

  Widget _buildLogTile(BuildContext context, LogEntry log) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return ListTile(title: Text(log.accion, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(log.detalles), trailing: Text('${log.fecha.hour}:${log.fecha.minute.toString().padLeft(2,"0")}', style: TextStyle(color: appColors.textLow)));
  }

  Widget _buildIncidentsTab(BuildContext context) {
    final incidencias = context.watch<AppProvider>().incidencias;
    return GridView.builder(padding: const EdgeInsets.all(32), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5), itemCount: incidencias.length, itemBuilder: (ctx, i) => _buildIncidentCard(context, incidencias[i]));
  }

  Widget _buildIncidentCard(BuildContext context, Incidencia inc) {
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(inc.titulo, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(inc.descripcion, maxLines: 2)])));
  }

  Widget _buildSystemStatusTab(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(32), children: [const Text('Estado del Sistema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 24), GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16, children: [Card(child: const Center(child: Text('Groq AI: OK'))), Card(child: const Center(child: Text('Neon DB: OK')))])]);
  }
}
