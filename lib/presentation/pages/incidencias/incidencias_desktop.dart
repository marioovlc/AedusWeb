import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/incident_model.dart';
import '../../../data/models/aula_model.dart';
import '../../../core/services/storage_service.dart';
import '../../widgets/incident_detail_dialog.dart';
import '../../widgets/loading_shimmer.dart';

class IncidenciasDesktop extends StatefulWidget {
  const IncidenciasDesktop({super.key});

  @override
  State<IncidenciasDesktop> createState() => _IncidenciasDesktopState();
}

class _IncidenciasDesktopState extends State<IncidenciasDesktop> {
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  Aula? _selectedAula;
  String _selectedCategory = 'Hardware';
  bool _isCreating = false;
  String? _aiSuggestion;
  Uint8List? _imageBytes;
  String? _imageName;
  final _picker = ImagePicker();
  String _searchQuery = '';
  String _statusFilter = 'TODOS';
  final List<String> _statusOptions = ['TODOS', 'PENDIENTE', 'LEIDO', 'REVISIÓN', 'ACABADO'];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });
    }
  }

  Future<void> _submitIncident() async {
    if (_tituloController.text.isEmpty) return;
    setState(() => _isCreating = true);
    
    String? uploadedUrl;
    if (_imageBytes != null) {
      uploadedUrl = await StorageService().uploadFile(_imageBytes!, _imageName ?? 'incident_img.png');
    }

    final aulaId = _selectedAula?.id ?? 1;
    
    final Map<String, int> categoryIds = {
      'Hardware': 1,
      'Software': 2,
      'Red': 3,
      'Otros': 4,
    };
    final catId = categoryIds[_selectedCategory] ?? 4;

    if (!mounted) return;

    await context.read<AppProvider>().createIncidencia(
      _tituloController.text,
      _descController.text,
      aulaId,
      catId,
      imagenUrl: uploadedUrl,
    );
    
    _tituloController.clear();
    _descController.clear();
    setState(() {
      _isCreating = false;
      _aiSuggestion = null;
      _imageBytes = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencias reportada con éxito.')),
      );
    }
  }

  Future<void> _getAIHelp() async {
    if (_tituloController.text.isEmpty) return;
    setState(() => _aiSuggestion = 'Analizando incidencia...');
    final suggestion = await context.read<AppProvider>().getAISuggestion(
      _tituloController.text,
      _descController.text,
    );
    setState(() => _aiSuggestion = suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final incidencias = provider.incidencias;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Form
                Expanded(flex: 2, child: _buildCreationForm(context)),
                const SizedBox(width: 32),
                // Right Panel: My Tickets
                Expanded(flex: 3, child: _buildTicketList(context, incidencias)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de Incidencias',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'Reporta problemas técnicos y realiza el seguimiento en tiempo real (Desktop).',
          style: TextStyle(color: appColors.textLow, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildCreationForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nueva Incidencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildTextField(context, 'Título de la incidencia', 'Ej: Proyector no enciende', _tituloController),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAulaDropdown(
                        context,
                        context.watch<AppProvider>().aulas, 
                        _selectedAula, 
                        (v) => setState(() => _selectedAula = v)
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryDropdown(context, ['Hardware', 'Software', 'Red', 'Otros'], _selectedCategory, (v) => setState(() => _selectedCategory = v!))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(context, 'Descripción detallada', 'Escribe aquí los pasos para reproducir el error...', _descController, maxLines: 5),
                const SizedBox(height: 24),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_imageBytes == null ? 'ADJUNTAR IMAGEN' : 'CAMBIAR IMAGEN'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _getAIHelp,
                        icon: const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 14),
                        label: const Text('✨ SUGERENCIA IA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_imageBytes != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_imageBytes!, height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],
                if (_aiSuggestion != null) ...[
                  const SizedBox(height: 24),
                  _buildAIHintCard(context, _aiSuggestion!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _submitIncident,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: _isCreating 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('ENVIAR INCIDENCIA'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, {required Widget child}) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.border),
      ),
      child: child,
    );
  }

  Widget _buildTextField(BuildContext context, String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: appColors.textLow, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }

  Widget _buildAulaDropdown(BuildContext context, List<Aula> options, Aula? selected, ValueChanged<Aula?> onChanged) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    
    if (selected != null && !options.any((a) => a.id == selected!.id)) {
      selected = null;
    }
    if (selected == null && options.isNotEmpty) {
      selected = options.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aula', style: TextStyle(color: appColors.textLow, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Aula>(
              isExpanded: true,
              value: selected,
              dropdownColor: appColors.surface,
              hint: const Text('Seleccionar Aula'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e.nombre))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, List<String> options, String selected, ValueChanged<String?> onChanged) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categoría', style: TextStyle(color: appColors.textLow, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: appColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selected,
              dropdownColor: appColors.surface,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIHintCard(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.lightbulb, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(BuildContext context, List<Incidencia> allIncidencias) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final isLoading = context.watch<AppProvider>().isLoading;

    // Apply filters
    var incidencias = allIncidencias;
    if (_statusFilter != 'TODOS') {
      incidencias = incidencias.where((i) {
        final st = i.estadoNombre.toUpperCase();
        if (_statusFilter == 'ACABADO') return st == 'ACABADO' || st == 'RESUELTO';
        if (_statusFilter == 'PENDIENTE') return st == 'PENDIENTE' || st == 'NO LEIDO' || st == 'NO LEÍDO';
        if (_statusFilter == 'REVISIÓN') return st == 'REVISIÓN' || st == 'EN REVISIÓN' || st == 'REVISION' || st == 'EN REVISION';
        if (_statusFilter == 'LEIDO') return st == 'LEIDO' || st == 'LEÍDO';
        return st == _statusFilter;
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      incidencias = incidencias
          .where((i) =>
              i.titulo.toLowerCase().contains(q) ||
              i.descripcion.toLowerCase().contains(q))
          .toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tickets Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              onPressed: () => context.read<AppProvider>().refreshData(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Search field
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Buscar por título o descripción...',
            hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5)),
            prefixIcon: Icon(Icons.search, size: 20, color: appColors.textLow),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 18, color: appColors.textLow),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statusOptions.map((opt) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(opt, style: const TextStyle(fontSize: 11)),
                selected: _statusFilter == opt,
                onSelected: (_) => setState(() => _statusFilter = opt),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: isLoading
              ? const ShimmerTicketList()
              : incidencias.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: appColors.textLow),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Sin resultados para "$_searchQuery"'
                                : 'No hay tickets con estado "$_statusFilter"',
                            style: TextStyle(color: appColors.textLow),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: incidencias.length,
                      itemBuilder: (context, index) =>
                          _buildTicketCard(context, incidencias[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(BuildContext context, Incidencia incident) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    Color statusColor;
    switch (incident.estadoNombre.toUpperCase()) {
      case 'ACABADO':
      case 'RESUELTO': statusColor = appColors.success; break;
      case 'PENDIENTE':
      case 'EN REVISION': statusColor = Colors.orange; break;
      default: statusColor = theme.colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => IncidentDetailDialog(incidencia: incident, showAdminActions: false),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: appColors.surface,
                ),
                child: incident.imagenUrl != null 
                    ? CachedNetworkImage(
                        imageUrl: incident.imagenUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (context, url, error) => Icon(Icons.broken_image, color: appColors.textLow),
                      )
                    : Icon(Icons.image, color: appColors.textLow),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        incident.titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      _buildStatusBadge(context, incident.estadoNombre, statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incident.descripcion,
                    style: TextStyle(color: appColors.textLow, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: appColors.textLow),
                      const SizedBox(width: 6),
                      Text(
                        '${incident.fecha.day}/${incident.fecha.month} ${incident.fecha.hour}:${incident.fecha.minute}', 
                        style: TextStyle(fontSize: 12, color: appColors.textLow),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.category, size: 12, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        incident.categoriaId == 1 ? 'Hardware' : 'Software', 
                        style: TextStyle(fontSize: 12, color: statusColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
