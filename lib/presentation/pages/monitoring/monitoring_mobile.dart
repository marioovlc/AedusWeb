import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/log_model.dart';
import '../../widgets/incident_detail_dialog.dart';
import '../../widgets/loading_shimmer.dart';

class MonitoringMobile extends StatefulWidget {
  const MonitoringMobile({super.key});

  @override
  State<MonitoringMobile> createState() => _MonitoringMobileState();
}

class _MonitoringMobileState extends State<MonitoringMobile> {
  String _selectedLogCategory = 'TODOS';
  // Incident filters
  String _incidentStatusFilter = 'TODOS';
  String _incidentSearchQuery = '';
  final List<String> _incidentStatuses = ['TODOS', 'PENDIENTE', 'LEIDO', 'REVISIÓN', 'ACABADO'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: appColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Monitorización', 
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: appColors.border.withValues(alpha: 0.5))),
              ),
              child: TabBar(
                isScrollable: false,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: appColors.textLow,
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                tabs: const [
                  Tab(text: 'LOGS'),
                  Tab(text: 'INCIDENCIAS'),
                  Tab(text: 'SISTEMA'),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildHistoryTab(context),
              _buildIncidentsTab(context),
              _buildSystemStatusTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final logs = provider.logs;
    final filteredLogs = _selectedLogCategory == 'TODOS' 
        ? logs 
        : logs.where((l) => l.categoria == _selectedLogCategory).toList();

    if (provider.isLoading && logs.isEmpty) {
      return ShimmerTicketList();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredLogs.length,
              itemBuilder: (ctx, i) => _buildLogCard(context, filteredLogs[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: ['TODOS', 'SISTEMA', 'ERROR', 'USUARIO'].map((cat) => Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(cat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            selected: _selectedLogCategory == cat,
            onSelected: (v) => setState(() => _selectedLogCategory = cat),
            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            checkmarkColor: theme.colorScheme.primary,
            side: BorderSide(
              color: _selectedLogCategory == cat 
                  ? theme.colorScheme.primary 
                  : appColors.border.withValues(alpha: 0.5)
            ),
            labelStyle: TextStyle(
              color: _selectedLogCategory == cat 
                  ? theme.colorScheme.primary 
                  : appColors.textLow,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, LogEntry log) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    Color catColor = log.categoria == 'ERROR' 
        ? appColors.danger 
        : (log.categoria == 'SISTEMA' ? theme.colorScheme.primary : appColors.textLow);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: appColors.border.withValues(alpha: 0.5))
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () {
          showDialog(
            context: context,
            useRootNavigator: true,
            builder: (context) => AlertDialog(
              backgroundColor: appColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(log.accion, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: catColor.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       log.categoria, 
                       style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 11)
                     ),
                   ),
                   const SizedBox(height: 16),
                   Text(log.detalles, style: const TextStyle(fontSize: 14, height: 1.5)),
                   const SizedBox(height: 24),
                   Row(
                     children: [
                       Icon(Icons.access_time, size: 14, color: appColors.textLow),
                       const SizedBox(width: 4),
                       Text(
                         '${log.fecha.day}/${log.fecha.month}/${log.fecha.year} ${log.fecha.hour}:${log.fecha.minute.toString().padLeft(2,"0")}', 
                         style: TextStyle(fontSize: 12, color: appColors.textLow)
                       ),
                     ],
                   ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('CERRAR', style: TextStyle(fontWeight: FontWeight.bold))
                ),
              ],
            ),
          );
        },
        leading: Container(
          width: 8, height: 32,
          decoration: BoxDecoration(
            color: catColor, 
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: catColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
            ]
          ),
        ),
        title: Text(log.accion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          log.detalles, 
          style: TextStyle(fontSize: 12, color: appColors.textLow), 
          maxLines: 1, 
          overflow: TextOverflow.ellipsis
        ),
        trailing: Text(
          '${log.fecha.hour}:${log.fecha.minute.toString().padLeft(2,"0")}', 
          style: TextStyle(fontSize: 11, color: appColors.textLow, fontWeight: FontWeight.w500)
        ),
      ),
    );
  }

  Widget _buildIncidentsTab(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allIncidencias = provider.incidencias;

    // Apply filters
    var incidencias = allIncidencias;
    if (_incidentStatusFilter != 'TODOS') {
      incidencias = incidencias.where((i) {
        final st = i.estadoNombre.toUpperCase();
        if (_incidentStatusFilter == 'ACABADO') return st == 'ACABADO' || st == 'RESUELTO';
        if (_incidentStatusFilter == 'PENDIENTE') return st == 'PENDIENTE' || st == 'NO LEIDO' || st == 'NO LEÍDO';
        if (_incidentStatusFilter == 'REVISIÓN') return st == 'REVISIÓN' || st == 'EN REVISIÓN' || st == 'REVISION' || st == 'EN REVISION';
        if (_incidentStatusFilter == 'LEIDO') return st == 'LEIDO' || st == 'LEÍDO';
        return st == _incidentStatusFilter;
      }).toList();
    }
    if (_incidentSearchQuery.isNotEmpty) {
      final q = _incidentSearchQuery.toLowerCase();
      incidencias = incidencias
          .where((i) =>
              i.titulo.toLowerCase().contains(q) ||
              i.descripcion.toLowerCase().contains(q))
          .toList();
    }

    if (provider.isLoading && allIncidencias.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ShimmerTicketList(),
      );
    }

    final appColors = Theme.of(context).extension<AppColors>()!;

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: Column(
        children: [
          // Search & Filters
          _buildIncidentFilters(context),
          // List
          Expanded(
            child: incidencias.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: appColors.textLow.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          _incidentSearchQuery.isNotEmpty
                              ? 'Sin resultados para "$_incidentSearchQuery"'
                              : 'No hay incidencias con estado "$_incidentStatusFilter"',
                          style: TextStyle(color: appColors.textLow, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: incidencias.length,
                    itemBuilder: (ctx, i) {
                      final inc = incidencias[i];
                      final colors = Theme.of(context).extension<AppColors>()!;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          onTap: () {
                            showDialog(
                              context: context,
                              useRootNavigator: true,
                              builder: (context) => IncidentDetailDialog(
                                incidencia: inc,
                                showAdminActions: true,
                              ),
                            );
                          },
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.confirmation_number_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            inc.titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: _getStatusColor(inc.estadoNombre, colors)),
                                const SizedBox(width: 6),
                                Text(
                                  inc.estadoNombre,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(inc.estadoNombre, colors),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Icon(Icons.chevron_right, color: colors.textLow.withValues(alpha: 0.5)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentFilters(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            onChanged: (v) => setState(() => _incidentSearchQuery = v),
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar incidencia...',
              hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5), fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 18, color: appColors.textLow),
              suffixIcon: _incidentSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 16, color: appColors.textLow),
                      onPressed: () => setState(() => _incidentSearchQuery = ''),
                    )
                  : null,
              fillColor: appColors.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _incidentStatuses.map((opt) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(opt, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _incidentStatusFilter == opt,
                  onSelected: (v) => setState(() => _incidentStatusFilter = opt),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: _incidentStatusFilter == opt
                        ? theme.colorScheme.primary
                        : appColors.border.withValues(alpha: 0.5),
                  ),
                  labelStyle: TextStyle(
                    color: _incidentStatusFilter == opt
                        ? theme.colorScheme.primary
                        : appColors.textLow,
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getStatusColor(String name, AppColors colors) {
    switch (name.toUpperCase()) {
      case 'PENDIENTE': return colors.danger;
      case 'LEIDO': return colors.gold;
      case 'REVISIÓN': return colors.gold;
      case 'ACABADO': return colors.success;
      default: return colors.textLow;
    }
  }

  Widget _buildSystemStatusTab(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final provider = context.watch<AppProvider>();
    final health = provider.systemHealth;
    final latencyMs = provider.dbLatencyMs;
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INFRAESTRUCTURA', 
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: appColors.textLow, 
                letterSpacing: 1.5
              )
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary, size: 20),
              tooltip: 'Actualizar estado',
              onPressed: () => context.read<AppProvider>().checkSystemHealth(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatusCard('Groq AI Engine', 
          (health['AI'] ?? true) ? 'Operativo' : 'Error', 
          health['AI'] ?? true, Icons.auto_awesome),
        _buildStatusCard('Neon Database', 
          (health['DB'] ?? true) 
            ? (latencyMs > 0 ? 'Latencia: ${latencyMs}ms' : 'En línea') 
            : 'Sin conexión', 
          health['DB'] ?? true, Icons.storage),
        _buildStatusCard('Vercel Edge', 
          (health['API'] ?? true) ? 'Conectado' : 'Sin conexión', 
          health['API'] ?? true, Icons.cloud_done),
        const SizedBox(height: 32),
        Text(
          'MÉTRICAS DE RED', 
          style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.bold, 
            color: appColors.textLow, 
            letterSpacing: 1.5
          )
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: appColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              _buildInfoTile('Latencia de DB', 
                latencyMs > 0 ? '${latencyMs}ms' : 'Calculando...', Icons.speed),
              const Divider(height: 32),
              _buildInfoTile('Tiempo de Actividad', '99.98%', Icons.history),
              const Divider(height: 32),
              _buildInfoTile('Versión del Sistema', 'BETA', Icons.info_outline),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String name, String status, bool online, IconData icon) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: appColors.border.withValues(alpha: 0.5))
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (online ? appColors.success : appColors.danger).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: online ? appColors.success : appColors.danger, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(status, style: TextStyle(fontSize: 12, color: appColors.textLow)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (online ? appColors.success : appColors.danger).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                online ? 'ONLINE' : 'OFFLINE', 
                style: TextStyle(
                  color: online ? appColors.success : appColors.danger, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Icon(icon, size: 18, color: appColors.textLow),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: appColors.textLow, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
