import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../data/models/incident_model.dart';

class IncidenciasPage extends StatefulWidget {
  const IncidenciasPage({super.key});

  @override
  State<IncidenciasPage> createState() => _IncidenciasPageState();
}

class _IncidenciasPageState extends State<IncidenciasPage> {
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedAula = 'Aula 101';
  String _selectedCategory = 'Hardware';
  bool _isCreating = false;
  String? _aiSuggestion;

  Future<void> _submitIncident() async {
    if (_tituloController.text.isEmpty) return;
    setState(() => _isCreating = true);
    
    // Simplification: mapping names to IDs for this demo
    final aulaId = int.parse(_selectedAula.split(' ').last);
    final catId = _selectedCategory == 'Hardware' ? 1 : 2;

    await context.read<AppProvider>().createIncidencia(
      _tituloController.text,
      _descController.text,
      aulaId,
      catId,
    );
    
    _tituloController.clear();
    _descController.clear();
    setState(() {
      _isCreating = false;
      _aiSuggestion = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia reportada con éxito.')),
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
    final incidencias = context.watch<AppProvider>().incidencias;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Form
                Expanded(flex: 2, child: _buildCreationForm(context)),
                const SizedBox(width: 32),
                // Right Panel: My Tickets
                Expanded(flex: 3, child: _buildTicketList(incidencias)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de Incidencias',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppTheme.textHighPriority),
        ),
        SizedBox(height: 8),
        Text(
          'Reporta problemas técnicos y realiza el seguimiento en tiempo real.',
          style: TextStyle(color: AppTheme.textLowPriority, fontSize: 16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nueva Incidencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildTextField('Título de la incidencia', 'Ej: Proyector no enciende', _tituloController),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDropdown('Aula', ['Aula 101', 'Aula 102', 'Laboratorio 1'], _selectedAula, (v) => setState(() => _selectedAula = v!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown('Categoría', ['Hardware', 'Software', 'Red', 'Otros'], _selectedCategory, (v) => setState(() => _selectedCategory = v!))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Descripción detallada', 'Escribe aquí los pasos para reproducir el error...', _descController, maxLines: 5),
                const SizedBox(height: 24),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file),
                      label: const Text('ADJUNTAR IMAGEN'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.secondaryIndigo]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _getAIHelp,
                        icon: const FaIcon(FontAwesomeIcons.magic, size: 14),
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
                if (_aiSuggestion != null) ...[
                  const SizedBox(height: 24),
                  _buildAIHintCard(_aiSuggestion!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _submitIncident,
                    child: _isCreating 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
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

  Widget _buildFormCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cards,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borders),
      ),
      child: child,
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _buildDropdown(String label, List<String> options, String selected, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borders),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selected,
              dropdownColor: AppTheme.surface,
              style: const TextStyle(color: AppTheme.textHighPriority),
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIHintCard(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.lightbulb, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textHighPriority, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(List<Incidencia> incidencias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tickets Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
              onPressed: () => context.read<AppProvider>().refreshData(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: incidencias.length,
            itemBuilder: (context, index) {
              return _buildTicketCard(incidencias[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(Incidencia incident) {
    Color statusColor;
    switch (incident.estado) {
      case 'RESUELTO': statusColor = AppTheme.success; break;
      case 'PENDIENTE': statusColor = Colors.orange; break;
      default: statusColor = AppTheme.primaryBlue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, color: AppTheme.textLowPriority),
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
                      _buildStatusBadge(incident.estado, statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    incident.descripcion,
                    style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppTheme.textLowPriority),
                      const SizedBox(width: 6),
                      Text(
                        '${incident.fecha.day}/${incident.fecha.month} ${incident.fecha.hour}:${incident.fecha.minute}', 
                        style: const TextStyle(fontSize: 12, color: AppTheme.textLowPriority),
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
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
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
