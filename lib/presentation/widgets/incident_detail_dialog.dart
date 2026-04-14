import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../data/models/incident_model.dart';
import '../../data/models/comentario_incidencia_model.dart';

class IncidentDetailDialog extends StatefulWidget {
  final Incidencia incidencia;
  final bool showAdminActions;
  
  const IncidentDetailDialog({
    super.key, 
    required this.incidencia, 
    this.showAdminActions = false,
  });

  @override
  State<IncidentDetailDialog> createState() => _IncidentDetailDialogState();
}

class _IncidentDetailDialogState extends State<IncidentDetailDialog> {
  String? aiSuggestion;
  bool loadingAI = false;
  List<ComentarioIncidencia>? _comentarios;
  final TextEditingController _commentController = TextEditingController();
  bool _isInternal = false;

  @override
  void initState() {
    super.initState();
    if (widget.showAdminActions) {
      _fetchAISuggestion();
    }
    _fetchComentarios();
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

  Future<void> _fetchComentarios() async {
    final comentarios = await context.read<AppProvider>().getComentariosIncidencia(widget.incidencia.id);
    if (mounted) {
      setState(() {
        _comentarios = comentarios;
      });
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _commentController.text.trim();
    if (texto.isEmpty) return;

    _commentController.clear();
    final nuevoComentario = await context.read<AppProvider>().addComentarioIncidencia(widget.incidencia.id, texto, isInternal: _isInternal);
    if (nuevoComentario != null && mounted) {
      setState(() {
        _comentarios?.add(nuevoComentario);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return Dialog(
      backgroundColor: appColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 700,
        height: 650,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Detalle de Incidencia #${widget.incidencia.id}', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                ),
                IconButton(onPressed: () { if (mounted) Navigator.pop(context); }, icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 32),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lado izquierdo: Info e imagen
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.incidencia.titulo, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                          const SizedBox(height: 8),
                          Text(widget.incidencia.descripcion, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          
                          if (widget.incidencia.imagenUrl != null && widget.incidencia.imagenUrl!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: widget.incidencia.imagenUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 200, 
                                  color: appColors.card,
                                  child: const Center(child: CircularProgressIndicator())
                                ),
                                errorWidget: (context, url, err) => Container(
                                  height: 200,
                                  color: appColors.card,
                                  child: Icon(Icons.broken_image, size: 50, color: appColors.textLow),
                                ),
                              ),
                            ),
                          ],

                          if (widget.showAdminActions) ...[
                            const SizedBox(height: 24),
                            _buildAISuggestionBox(context),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 32),
                  // Lado derecho: Comentarios y acciones
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Comentarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: appColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: appColors.border),
                            ),
                            child: _comentarios == null 
                              ? const Center(child: CircularProgressIndicator())
                              : _comentarios!.isEmpty
                                ? Center(child: Text('No hay comentarios aún.', style: TextStyle(color: appColors.textLow)))
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _comentarios!.length,
                                    separatorBuilder: (context, index) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final c = _comentarios![index];
                                      final isMe = c.usuarioId == context.read<AppProvider>().currentUser?.id;
                                      return _buildComentarioTile(context, c, isMe);
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (widget.showAdminActions)
                              IconButton(
                                icon: Icon(_isInternal ? Icons.lock : Icons.lock_open, color: _isInternal ? appColors.gold : appColors.textLow),
                                tooltip: _isInternal ? 'Nota Interna (Solo Staff)' : 'Comentario Público',
                                onPressed: () => setState(() => _isInternal = !_isInternal),
                              ),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: _isInternal ? 'Añadir nota interna...' : 'Añadir un comentario...',
                                  filled: _isInternal,
                                  fillColor: _isInternal ? appColors.gold.withValues(alpha: 0.1) : null,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onSubmitted: (_) => _enviarComentario(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: _isInternal ? appColors.gold : theme.colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                                onPressed: _enviarComentario,
                              ),
                            ),
                          ],
                        ),
                        
                        if (widget.showAdminActions) ...[
                          const SizedBox(height: 24),
                          const Text('Acciones del Administrador', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildActionButton(context, 'LEIDO', theme.colorScheme.primary, 1),
                              const SizedBox(width: 8),
                              _buildActionButton(context, 'EN REVISIÓN', appColors.gold, 2), 
                              const SizedBox(width: 8),
                              _buildActionButton(context, 'ACABADO', appColors.success, 4), 
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: appColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: appColors.border),
                            ),
                            child: Text(
                              'Estado: ${widget.incidencia.estadoNombre}', 
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComentarioTile(BuildContext context, ComentarioIncidencia c, bool isMe) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                c.usuarioNombre, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c.isInternal ? appColors.gold : (isMe ? theme.colorScheme.primary : theme.colorScheme.onSurface))
              ),
              const SizedBox(width: 4),
              if (c.usuarioRol == 'ADMIN' || c.usuarioRol == 'MANTENIMIENTO')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: appColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('STAFF', style: TextStyle(fontSize: 8, color: appColors.gold, fontWeight: FontWeight.bold)),
                ),
              if (c.isInternal)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.lock, size: 12, color: appColors.gold),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.isInternal ? appColors.gold.withValues(alpha: 0.2) : (isMe ? theme.colorScheme.primary.withValues(alpha: 0.1) : appColors.card),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.isInternal ? appColors.gold : (isMe ? theme.colorScheme.primary.withValues(alpha: 0.3) : appColors.border)),
            ),
            child: Text(c.texto, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 2),
          Text(
            '${c.fecha.hour.toString().padLeft(2, '0')}:${c.fecha.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 10, color: appColors.textLow),
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestionBox(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Sugerencia Técnica IA', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          if (loadingAI)
            const LinearProgressIndicator()
          else if (aiSuggestion != null)
            Text(aiSuggestion!, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic))
          else
            Text('No se pudo generar una sugerencia.', style: TextStyle(color: appColors.textLow)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Color color, int statusId) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          final navigator = Navigator.of(context);
          await context.read<AppProvider>().updateIncidenciaEstado(
            widget.incidencia.id, 
            statusId, 
            widget.incidencia.usuarioId
          );
          navigator.pop();
        },
        style: OutlinedButton.styleFrom(
           foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        child: Text(label),
      ),
    );
  }
}
