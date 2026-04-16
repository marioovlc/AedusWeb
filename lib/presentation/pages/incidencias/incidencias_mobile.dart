import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/incident_model.dart';
import '../../../data/models/aula_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/services/storage_service.dart';
import '../../widgets/incident_detail_dialog.dart';
import '../../widgets/loading_shimmer.dart';

class IncidenciasMobile extends StatefulWidget {
  const IncidenciasMobile({super.key});

  @override
  State<IncidenciasMobile> createState() => _IncidenciasMobileState();
}

class _IncidenciasMobileState extends State<IncidenciasMobile> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  Aula? _selectedAula;
  String _selectedCategory = 'Hardware';
  bool _isCreating = false;
  String? _aiSuggestion;
  bool _isLoadingAI = false;
  String? _submitError;
  String _statusFilter = 'TODOS';
  Uint8List? _imageBytes;
  String? _imageName;
  final _picker = ImagePicker();
  final List<String> _statusOptions = ['TODOS', 'PENDIENTE', 'LEIDO', 'REVISIÓN', 'ACABADO'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tituloController.dispose();
    _descController.dispose();
    super.dispose();
  }

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

  Future<void> _getAIHelp() async {
    if (_tituloController.text.isEmpty) return;
    setState(() { _isLoadingAI = true; _aiSuggestion = null; });
    final suggestion = await context.read<AppProvider>().getAISuggestion(
      _tituloController.text,
      _descController.text,
    );
    if (mounted) setState(() { _aiSuggestion = suggestion; _isLoadingAI = false; });
  }

  Future<void> _submitIncident() async {
    final title = _tituloController.text.trim();
    if (title.isEmpty) {
      setState(() => _submitError = 'El título es obligatorio.');
      return;
    }
    setState(() { _isCreating = true; _submitError = null; });

    String? uploadedUrl;
    if (_imageBytes != null) {
      uploadedUrl = await StorageService().uploadFile(_imageBytes!, _imageName ?? 'incident_img.png');
    }

    final aulaId = _selectedAula?.id ?? 1;
    final Map<String, int> categoryIds = {'Hardware': 1, 'Software': 2, 'Red': 3, 'Otros': 4};
    final catId = categoryIds[_selectedCategory] ?? 4;

    if (!mounted) return;

    await context.read<AppProvider>().createIncidencia(
      title,
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

    _tabController.animateTo(1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reportado con éxito.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Text('Incidencias', style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: appColors.textLow,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'REPORTAR'),
                Tab(text: 'MIS TICKETS'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFormTab(context),
                  _buildListTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField('Título', '¿Qué sucede?', _tituloController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildAulaDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildCategoryDropdown()),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField('Descripción', 'Detalles...', _descController, maxLines: 4),
          const SizedBox(height: 16),
          if (_imageBytes != null) ...[
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_imageBytes!, height: 120, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          if (_submitError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).extension<AppColors>()!.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).extension<AppColors>()!.danger.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Theme.of(context).extension<AppColors>()!.danger, size: 16),
                  const SizedBox(width: 8),
                  Text(_submitError!, style: TextStyle(color: Theme.of(context).extension<AppColors>()!.danger, fontSize: 13)),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(onPressed: _pickImage, icon: const Icon(Icons.add_a_photo)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _isLoadingAI ? null : _getAIHelp,
                icon: _isLoadingAI
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 14),
                label: Text(_isLoadingAI ? 'Analizando...' : '✨ Sugerencia IA'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isCreating ? null : _submitIncident,
                child: _isCreating ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('ENVIAR'),
              ),
            ],
          ),
          if (_aiSuggestion != null) ...[
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)), child: Text(_aiSuggestion!, style: const TextStyle(fontSize: 12))),
          ],
        ],
      ),
    );
  }

  Widget _buildListTab(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allIncidencias = provider.incidencias;
    final incidencias = _statusFilter == 'TODOS'
        ? allIncidencias
        : allIncidencias.where((i) =>
            i.estadoNombre.toUpperCase() == _statusFilter).toList();
    if (provider.isLoading) return const ShimmerTicketList();

    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statusOptions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final opt = _statusOptions[i];
              final selected = _statusFilter == opt;
              return FilterChip(
                label: Text(opt, style: const TextStyle(fontSize: 11)),
                selected: selected,
                onSelected: (_) => setState(() => _statusFilter = opt),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: incidencias.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).extension<AppColors>()!.textLow),
                      const SizedBox(height: 12),
                      Text(
                        _statusFilter == 'TODOS'
                            ? 'No tienes tickets registrados'
                            : 'No hay tickets con estado "$_statusFilter"',
                        style: TextStyle(color: Theme.of(context).extension<AppColors>()!.textLow),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.refreshData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: incidencias.length,
                    itemBuilder: (ctx, i) => _buildTicketCard(context, incidencias[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(BuildContext context, Incidencia incident) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => showDialog(context: context, builder: (context) => IncidentDetailDialog(incidencia: incident, showAdminActions: false)),
        title: Text(incident.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(incident.estadoNombre),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(labelText: label, hintText: hint));
  }

  Widget _buildAulaDropdown() {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();
    return DropdownButton<Aula>(
      isExpanded: true, 
      underline: Container(height: 1, color: theme.dividerColor),
      value: _selectedAula ?? (provider.aulas.isNotEmpty ? provider.aulas.first : null), 
      items: provider.aulas.map((e) => DropdownMenuItem(
        value: e, 
        child: Text(e.nombre, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14))
      )).toList(), 
      onChanged: (v) => setState(() => _selectedAula = v)
    );
  }

  Widget _buildCategoryDropdown() {
    final theme = Theme.of(context);
    return DropdownButton<String>(
      isExpanded: true, 
      underline: Container(height: 1, color: theme.dividerColor),
      value: _selectedCategory, 
      items: ['Hardware', 'Software', 'Red', 'Otros'].map((e) => DropdownMenuItem(
        value: e, 
        child: Text(e, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14))
      )).toList(), 
      onChanged: (v) => setState(() => _selectedCategory = v!)
    );
  }
}
