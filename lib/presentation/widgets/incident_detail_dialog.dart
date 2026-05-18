import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../data/models/incident_model.dart';
import '../../data/models/comentario_incidencia_model.dart';

// =============================================
// ==== CLASE IncidentDetailDialog =====
// Descripción: Diálogo interactivo que muestra los detalles de una incidencia, permitiendo a los administradores y técnicos actualizar su estado, añadir notas internas y asignar la tarea a otros técnicos con sugerencias de Aedus AI.
// =============================================
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
    // Listener para actualizar el contador de caracteres
    _commentController.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

  String? _getAssignedUser() {
    if (_comentarios == null) return null;
    for (var c in _comentarios!.reversed) {
      if (c.isInternal && c.texto.startsWith('Ticket asignado a: ')) {
        return c.texto.substring('Ticket asignado a: '.length).trim();
      }
    }
    return null;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Dialog(
      backgroundColor: appColors.surface,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: appColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
        ),
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 900,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.confirmation_number_outlined, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incidencia #${widget.incidencia.id}', 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: appColors.textLow, letterSpacing: 1.2)
                      ),
                      Text(
                        'Detalles del Ticket', 
                        style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
                if (widget.showAdminActions) ...[
                  _buildAssignButton(context, theme, appColors),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: () { if (mounted) Navigator.pop(context); }, 
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(backgroundColor: appColors.card),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            Flexible(
              child: SingleChildScrollView(
                child: isMobile 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(context, theme, appColors, isMobile),
                        const SizedBox(height: 32),
                        _buildCommentsSection(context, theme, appColors, isMobile),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildInfoSection(context, theme, appColors, isMobile)),
                        const SizedBox(width: 40),
                        Container(width: 1, height: 500, color: appColors.border.withValues(alpha: 0.5)),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildCommentsSection(context, theme, appColors, isMobile)),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, ThemeData theme, AppColors appColors, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.incidencia.categoriaNombre, 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)
              ),
            ),
            if (_getAssignedUser() != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: appColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: appColors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.engineering, size: 12, color: appColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      _getAssignedUser()!, 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: appColors.gold)
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text(widget.incidencia.titulo, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 12),
        Text(
          widget.incidencia.descripcion, 
          style: TextStyle(fontSize: 15, height: 1.6, color: appColors.textHigh.withValues(alpha: 0.8))
        ),
        const SizedBox(height: 24),
        
        if (widget.incidencia.imagenUrl != null && widget.incidencia.imagenUrl!.isNotEmpty) ...[
          Text('ADJUNTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: appColors.textLow, letterSpacing: 1)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: widget.incidencia.imagenUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => Container(
                height: 200, 
                decoration: BoxDecoration(color: appColors.card, borderRadius: BorderRadius.circular(20)),
                child: const Center(child: CircularProgressIndicator())
              ),
              errorWidget: (context, url, err) => Container(
                height: 200,
                decoration: BoxDecoration(color: appColors.card, borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.broken_image, size: 50, color: appColors.textLow),
              ),
            ),
          ),
        ],

        if (widget.showAdminActions) ...[
          const SizedBox(height: 32),
          _buildAISuggestionBox(context),
        ],
      ],
    );
  }

  Widget _buildCommentsSection(BuildContext context, ThemeData theme, AppColors appColors, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('COMENTARIOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: appColors.textLow, letterSpacing: 1)),
            if (_comentarios != null)
              Text('${_comentarios!.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: isMobile ? 350 : 450,
          decoration: BoxDecoration(
            color: appColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: appColors.border.withValues(alpha: 0.3)),
          ),
          child: _comentarios == null 
            ? const Center(child: CircularProgressIndicator())
            : _comentarios!.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, color: appColors.textLow, size: 40),
                    const SizedBox(height: 12),
                    Text('Sin actividad aún.', style: TextStyle(color: appColors.textLow, fontSize: 14)),
                  ],
                ))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comentarios!.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final c = _comentarios![index];
                    final isMe = c.usuarioId == context.read<AppProvider>().currentUser?.id;
                    return _buildComentarioTile(context, c, isMe);
                  },
                ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: appColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: appColors.border),
          ),
          child: Row(
            children: [
              if (widget.showAdminActions)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(_isInternal ? Icons.lock : Icons.lock_open, color: _isInternal ? appColors.gold : appColors.textLow, size: 20),
                  tooltip: _isInternal ? 'Nota Interna' : 'Comentario Público',
                  onPressed: () => setState(() => _isInternal = !_isInternal),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(fontSize: 14),
                  maxLength: 500,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: InputDecoration(
                    hintText: _isInternal ? 'Nota interna...' : 'Escribe algo...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _enviarComentario(),
                ),
              ),
              if (_commentController.text.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '${_commentController.text.length}/500',
                  style: TextStyle(
                    fontSize: 11,
                    color: _commentController.text.length > 450 ? appColors.danger : appColors.textLow,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.send_rounded, color: _isInternal ? appColors.gold : theme.colorScheme.primary, size: 20),
                onPressed: _enviarComentario,
                style: IconButton.styleFrom(
                  backgroundColor: (_isInternal ? appColors.gold : theme.colorScheme.primary).withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
        
        if (widget.showAdminActions) ...[
          const SizedBox(height: 32),
          Text('ACTUALIZAR ESTADO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: appColors.textLow, letterSpacing: 1)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionButton(context, 'LEIDO', appColors.gold, 1),
                const SizedBox(width: 8),
                _buildActionButton(context, 'REVISIÓN', Colors.orange, 2), 
                const SizedBox(width: 8),
                _buildActionButton(context, 'ACABADO', appColors.success, 4), 
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildComentarioTile(BuildContext context, ComentarioIncidencia c, bool isMe) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              c.usuarioNombre, 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isMe ? theme.primaryColor : appColors.textLow)
            ),
            if (c.isInternal) ...[
              const SizedBox(width: 6),
              Icon(Icons.lock, size: 10, color: appColors.gold),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.isInternal 
                ? appColors.gold.withValues(alpha: 0.1) 
                : (isMe ? theme.primaryColor.withValues(alpha: 0.1) : appColors.card),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            border: Border.all(
              color: c.isInternal 
                  ? appColors.gold.withValues(alpha: 0.3) 
                  : (isMe ? theme.primaryColor.withValues(alpha: 0.3) : appColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Text(c.texto, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildAISuggestionBox(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
           BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Text('Aedus AI (Análisis)', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          if (loadingAI)
            const LinearProgressIndicator()
          else if (aiSuggestion != null)
            Text(aiSuggestion!, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.5))
          else
            const Text('No hay análisis disponible.'),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Color color, int statusId) {
    return OutlinedButton(
      onPressed: () async {
        final appColors = Theme.of(context).extension<AppColors>()!;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: appColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Confirmar cambio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${widget.incidencia.id} — ${widget.incidencia.titulo}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: appColors.textHigh),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text('¿Cambiar el estado a "$label"?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(label),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          final provider = context.read<AppProvider>();
          final incidenciaId = widget.incidencia.id;
          final usuarioId = widget.incidencia.usuarioId;
          Navigator.of(context).pop();
          
          await provider.updateIncidenciaEstado(
            incidenciaId,
            statusId,
            usuarioId,
          );
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }

  Widget _buildAssignButton(BuildContext context, ThemeData theme, AppColors appColors) {
    return OutlinedButton(
      onPressed: () async {
        final provider = context.read<AppProvider>();
        // Comprobar si los usuarios están cargados
        if (provider.usuariosAdmin.isEmpty) {
          showDialog(
            context: context, 
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator())
          );
          await provider.fetchAllUsers();
          if (context.mounted) Navigator.pop(context); // ocultar el indicador de carga
        }
        
        final techUsers = provider.usuariosAdmin.where((u) => 
            u.rol.toUpperCase() == 'ADMIN' || 
            u.rol.toUpperCase() == 'MANTENIMIENTO' || 
            u.rol.toUpperCase() == 'ADMINISTRADOR').toList();

        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: appColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Asignar Técnico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            content: SizedBox(
              width: 350,
              child: techUsers.isEmpty 
                ? const Text('No hay técnicos disponibles.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: techUsers.length,
                    itemBuilder: (context, i) {
                      final u = techUsers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(u.nombre[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(u.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(u.rol, style: TextStyle(fontSize: 11, color: appColors.textLow)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final incidenciaId = widget.incidencia.id;
                          final titulo = widget.incidencia.titulo;
                          
                          try {
                            // 1. Añadir comentario interno
                            await provider.addComentarioIncidencia(
                              incidenciaId, 
                              'Ticket asignado a: ${u.nombre}', 
                              isInternal: true
                            );
                          } catch (e) {
                            debugPrint('Error inserting comment: $e');
                          }

                          try {
                            // 2. Enviar mensaje para notificar al técnico
                            await provider.sendMessage(
                              u.id, 
                              'Has sido asignado a la incidencia: #$incidenciaId - $titulo', 
                              ticketLinkId: incidenciaId
                            );
                          } catch (e) {
                            debugPrint('Error sending tech message: $e');
                          }
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ticket asignado a ${u.nombre} correctamente')),
                            );
                            _fetchComentarios(); // Refrescar comentarios para que aparezca la asignación
                          }
                        },
                      );
                    },
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold))
              ),
            ],
          )
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      child: const Text('ASIGNAR', style: TextStyle(letterSpacing: 0.5)),
    );
  }
}
