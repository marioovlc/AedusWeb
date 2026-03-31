import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sticky_headers/sticky_headers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../data/models/log_model.dart';
import '../../data/models/incident_model.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  String _selectedLogCategory = 'TODOS';
  final List<String> _categories = ['TODOS', 'SISTEMA', 'ERROR', 'USUARIO'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeader(),
                const TabBar(
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  indicatorColor: AppTheme.primaryBlue,
                  labelColor: AppTheme.primaryBlue,
                  unselectedLabelColor: AppTheme.textLowPriority,
                  tabs: [
                    Tab(text: 'Historial de Actividad', icon: Icon(Icons.history)),
                    Tab(text: 'Control de Incidencias', icon: Icon(Icons.dashboard_customize)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Monitorización',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textHighPriority),
        ),
        Text(
          'Panel administrativo de Aedus',
          style: TextStyle(color: AppTheme.textLowPriority, fontSize: 14),
        ),
      ],
    );
  }

  // --- HISTORY TAB ---

  Widget _buildHistoryTab(BuildContext context) {
    final logs = context.watch<AppProvider>().logs;
    final filteredLogs = _selectedLogCategory == 'TODOS' 
        ? logs 
        : logs.where((l) => l.categoria == _selectedLogCategory).toList();

    // Group logs by date
    Map<String, List<LogEntry>> groupedLogs = {};
    for (var log in filteredLogs) {
      String dateKey = _formatDateKey(log.fecha);
      if (!groupedLogs.containsKey(dateKey)) {
        groupedLogs[dateKey] = [];
      }
      groupedLogs[dateKey]!.add(log);
    }

    final dateKeys = groupedLogs.keys.toList();

    return Column(
      children: [
        _buildHistoryFilters(),
        Expanded(
          child: dateKeys.isEmpty 
            ? _buildEmptyState('No hay logs para esta categoría.')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                itemCount: dateKeys.length,
                itemBuilder: (context, index) {
                  final date = dateKeys[index];
                  final logsForDate = groupedLogs[date]!;
                  
                  return StickyHeader(
                    header: Container(
                      height: 50.0,
                      color: AppTheme.background,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        date,
                        style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    content: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logsForDate.length,
                      separatorBuilder: (context, i) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final log = logsForDate[i];
                        return _buildLogTile(log);
                      },
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildHistoryFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: _categories.map((cat) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                selected: _selectedLogCategory == cat,
                label: Text(cat),
                onSelected: (val) => setState(() => _selectedLogCategory = cat),
              ),
            )).toList(),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final path = await context.read<AppProvider>().exportLogsToCSV();
              if (path != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logs exportados a: $path'), backgroundColor: AppTheme.success),
                );
              }
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Exportar CSV'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
          ),
        ],
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) return 'Hoy';
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) return 'Ayer';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildLogTile(LogEntry log) {
    Color catColor = AppTheme.primaryBlue;
    if (log.categoria == 'ERROR') catColor = AppTheme.danger;
    if (log.categoria == 'SISTEMA') catColor = AppTheme.gold;

    return ListTile(
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: catColor.withOpacity(0.1),
        child: Icon(Icons.circle, color: catColor, size: 8),
      ),
      title: Text(log.accion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text('${log.usuarioNombre}: ${log.detalles}', style: const TextStyle(fontSize: 13)),
      trailing: Text(
        '${log.fecha.hour.toString().padLeft(2, '0')}:${log.fecha.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 12),
      ),
    );
  }

  // --- INCIDENTS TAB ---

  Widget _buildIncidentsTab(BuildContext context) {
    final incidencias = context.watch<AppProvider>().incidencias;
    
    return Column(
      children: [
        _buildIncidentsHeader(context),
        Expanded(
          child: incidencias.isEmpty
            ? _buildEmptyState('No hay incidencias registradas.')
            : GridView.builder(
              padding: const EdgeInsets.all(32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: incidencias.length,
              itemBuilder: (context, index) {
                final inc = incidencias[index];
                return _buildIncidentCard(context, inc);
              },
            ),
        ),
      ],
    );
  }

  Widget _buildIncidentsHeader(BuildContext context) {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Todas las Incidencias del Sistema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ElevatedButton.icon(
            onPressed: () async {
              final path = await context.read<AppProvider>().exportIncidenciasToCSV();
              if (path != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Incidencias exportadas a: $path'), backgroundColor: AppTheme.success),
                );
              }
            },
            icon: const Icon(Icons.file_download, size: 18),
            label: const Text('Reporte Completo'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(BuildContext context, Incidencia inc) {
    Color statusColor = AppTheme.textLowPriority;
    IconData statusIcon = Icons.info_outline;

    switch (inc.estadoNombre.toUpperCase()) {
      case 'NO LEIDO': statusColor = AppTheme.danger; statusIcon = Icons.error_outline; break;
      case 'LEIDO': statusColor = AppTheme.primaryBlue; statusIcon = Icons.visibility; break;
      case 'EN REVISIÓN': statusColor = AppTheme.gold; statusIcon = Icons.pending_actions; break;
      case 'ACABADO': statusColor = AppTheme.success; statusIcon = Icons.check_circle_outline; break;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showIncidentDetail(context, inc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(inc.estadoNombre, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Text('#${inc.id}', style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Text(inc.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Expanded(
                child: Text(inc.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 13)),
              ),
              const Divider(),
              Text(_formatDateKey(inc.fecha), style: const TextStyle(fontSize: 11, color: AppTheme.textLowPriority)),
            ],
          ),
        ),
      ),
    );
  }

  void _showIncidentDetail(BuildContext context, Incidencia inc) {
    showDialog(
      context: context,
      builder: (context) {
        return _IncidentDetailDialog(incidencia: inc);
      }
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: AppTheme.textLowPriority),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppTheme.textLowPriority)),
        ],
      ),
    );
  }
}

class _IncidentDetailDialog extends StatefulWidget {
  final Incidencia incidencia;
  const _IncidentDetailDialog({required this.incidencia});

  @override
  State<_IncidentDetailDialog> createState() => _IncidentDetailDialogState();
}

class _IncidentDetailDialogState extends State<_IncidentDetailDialog> {
  String? aiSuggestion;
  bool loadingAI = false;

  @override
  void initState() {
    super.initState();
    _fetchAISuggestion();
  }

  Future<void> _fetchAISuggestion() async {
    setState(() => loadingAI = true);
    final suggestion = await context.read<AppProvider>().getAISuggestion(
      widget.incidencia.titulo, 
      widget.incidencia.descripcion
    );
    if (mounted) {
      setState(() {
        aiSuggestion = suggestion;
        loadingAI = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detalle de Incidencia', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 32),
            
            Text(widget.incidencia.titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            const SizedBox(height: 8),
            Text(widget.incidencia.descripcion, style: const TextStyle(fontSize: 16)),
            
            const SizedBox(height: 24),
            _buildAISuggestionBox(),
            
            const SizedBox(height: 32),
            const Text('Acciones del Administrador', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionButton('LEIDO', AppTheme.primaryBlue, 1),
                const SizedBox(width: 8),
                _buildActionButton('EN REVISIÓN', AppTheme.gold, 2), // Assuming IDs mapping
                const SizedBox(width: 8),
                _buildActionButton('ACABADO', AppTheme.success, 4), // Assuming ID 4 is finished
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAISuggestionBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              const Text('Sugerencia Técnica IA', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 12),
          if (loadingAI)
            const LinearProgressIndicator()
          else if (aiSuggestion != null)
            Text(aiSuggestion!, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic))
          else
            const Text('No se pudo generar una sugerencia.', style: TextStyle(color: AppTheme.textLowPriority)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, int statusId) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          await context.read<AppProvider>().updateIncidenciaEstado(
            widget.incidencia.id, 
            statusId, 
            widget.incidencia.usuarioId
          );
          if (mounted) Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label),
      ),
    );
  }
}
