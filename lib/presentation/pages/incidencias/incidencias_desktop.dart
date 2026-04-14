import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final Map<String, int> categoryIds = {'Hardware': 1, 'Software': 2, 'Red': 3, 'Otros': 4};
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incidencia reportada con éxito.')));
    }
  }

  Future<void> _getAIHelp() async {
    if (_tituloController.text.isEmpty) return;
    setState(() => _aiSuggestion = 'Analizando incidencia...');
    final suggestion = await context.read<AppProvider>().getAISuggestion(_tituloController.text, _descController.text);
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
                Expanded(flex: 2, child: _buildCreationForm(context)),
                const SizedBox(width: 32),
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
        Text('Gestión de Incidencias', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('Reporta problemas técnicos y realiza el seguimiento en tiempo real.', style: TextStyle(color: appColors.textLow, fontSize: 16)),
      ],
    );
  }

  Widget _buildCreationForm(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: _buildFormCard(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nueva Incidencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 24),
            _buildTextField(context, 'Título', 'Ej: Proyector no enciende', _tituloController),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAulaDropdown(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildCategoryDropdown(context)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(context, 'Descripción', 'Escribe aquí los pasos...', _descController, maxLines: 5),
            const SizedBox(height: 24),
            Row(
              children: [
                OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.attach_file), label: Text(_imageBytes == null ? 'ADJUNTAR' : 'CAMBIAR')),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _getAIHelp,
                  icon: const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 14),
                  label: const Text('✨ ASISTENTE AI'),
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
            if (_imageBytes != null) ...[const SizedBox(height: 16), ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_imageBytes!, height: 150, width: double.infinity, fit: BoxFit.cover))],
            if (_aiSuggestion != null) ...[const SizedBox(height: 24), _buildAIHintCard(context, _aiSuggestion!)],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isCreating ? null : _submitIncident, child: _isCreating ? const CircularProgressIndicator() : const Text('ENVIAR INCIDENCIA'))),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, {required Widget child}) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: appColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: appColors.border)), child: child);
  }

  Widget _buildTextField(BuildContext context, String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: appColors.textLow, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 8), TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(hintText: hint))]);
  }

  Widget _buildAulaDropdown(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Aula', style: TextStyle(color: appColors.textLow, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 8), DropdownButton<Aula>(isExpanded: true, value: _selectedAula ?? (provider.aulas.isNotEmpty ? provider.aulas.first : null), items: provider.aulas.map((e) => DropdownMenuItem(value: e, child: Text(e.nombre))).toList(), onChanged: (v) => setState(() => _selectedAula = v))]);
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Categoría', style: TextStyle(color: appColors.textLow, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 8), DropdownButton<String>(isExpanded: true, value: _selectedCategory, items: ['Hardware', 'Software', 'Red', 'Otros'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _selectedCategory = v!))]);
  }

  Widget _buildAIHintCard(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5))), child: Row(children: [FaIcon(FontAwesomeIcons.lightbulb, color: theme.colorScheme.primary), const SizedBox(width: 16), Expanded(child: Text(text, style: const TextStyle(fontSize: 13)))]));
  }

  Widget _buildTicketList(BuildContext context, List<Incidencia> incidencias) {
    final isLoading = context.watch<AppProvider>().isLoading;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tickets Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<AppProvider>().refreshData())]), const SizedBox(height: 24), Expanded(child: isLoading ? const ShimmerTicketList() : ListView.separated(itemCount: incidencias.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (ctx, i) => _buildTicketCard(context, incidencias[i])) )]);
  }

  Widget _buildTicketCard(BuildContext context, Incidencia incident) {
    final theme = Theme.of(context);
    return Card(child: ListTile(onTap: () => showDialog(context: context, builder: (context) => IncidentDetailDialog(incidencia: incident, showAdminActions: false)), leading: Icon(Icons.description, color: theme.colorScheme.primary), title: Text(incident.titulo, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(incident.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(incident.estadoNombre, style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)))));
  }
}
