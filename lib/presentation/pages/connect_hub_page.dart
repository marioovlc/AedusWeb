import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/incident_model.dart';
import '../../data/models/comentario_incidencia_model.dart';
import '../../core/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/incident_detail_dialog.dart';

class ConnectHubPage extends StatefulWidget {
  const ConnectHubPage({super.key});

  @override
  State<ConnectHubPage> createState() => _ConnectHubPageState();
}

class _ConnectHubPageState extends State<ConnectHubPage> {
  bool _isTicketMode = false;

  Usuario? _activeContact;
  Incidencia? _activeTicket;
  
  List<ComentarioIncidencia> _ticketComments = [];

  final _messageController = TextEditingController();
  final _ticketMessageController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _imagePicker = ImagePicker();
  
  bool _isRecording = false;
  bool _isSupportMode = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      if (!_isTicketMode && _activeContact != null) {
        context.read<AppProvider>().fetchMessages(_activeContact!.id);
      } else if (_isTicketMode && _activeTicket != null) {
        _refreshTicketComments();
      }
    });
  }

  Future<void> _refreshTicketComments() async {
     if (_activeTicket == null) return;
     final comments = await context.read<AppProvider>().getComentariosIncidencia(_activeTicket!.id);
     if (mounted) {
       setState(() => _ticketComments = comments);
     }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _messageController.dispose();
    _ticketMessageController.dispose();
    super.dispose();
  }

  void _selectContact(Usuario contact) {
    setState(() {
      _activeContact = contact;
    });
    context.read<AppProvider>().fetchMessages(contact.id);
  }

  void _selectTicket(Incidencia ticket) {
    setState(() {
      _activeTicket = ticket;
      _ticketComments = [];
    });
    _refreshTicketComments();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(const RecordConfig(), path: ''); 
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final uri = Uri.parse(path);
        final response = await http.get(uri);
        final bytes = response.bodyBytes;
        
        final url = await StorageService().uploadFile(bytes, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a', isAudio: true);
        if (url != null) {
          _sendMessage(audioUrl: url);
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final url = await StorageService().uploadFile(bytes, image.name);
      if (url != null) {
        _sendMessage(imageUrl: url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<AppProvider>();

    return Row(
      children: [
        Expanded(flex: 2, child: _buildContactsPanel(context, provider)),
        VerticalDivider(width: 1, color: appColors.border),
        Expanded(flex: 4, child: _isTicketMode ? _buildTicketChatPanel(context) : _buildChatPanel(context, provider.mensajes)),
        VerticalDivider(width: 1, color: appColors.border),
        Expanded(flex: 2, child: _isTicketMode ? _buildTicketDetailsPanel(context) : _buildDetailsPanel(context)),
      ],
    );
  }

  Widget _buildContactsPanel(BuildContext context, AppProvider provider) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final contactos = provider.contactos;
    final incidencias = provider.incidencias;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: TextField(
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search, size: 20, color: appColors.textLow),
              fillColor: appColors.surface,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isTicketMode = false),
                child: _TabItem(title: 'Personas', isActive: !_isTicketMode, context: context),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _isTicketMode = true),
                child: _TabItem(title: 'Tickets', isActive: _isTicketMode, context: context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isTicketMode 
            ? ListView.builder(
                itemCount: incidencias.length,
                itemBuilder: (context, index) => _buildTicketItem(context, incidencias[index], _activeTicket?.id == incidencias[index].id)
              )
            : ListView.builder(
                itemCount: contactos.length,
                itemBuilder: (context, index) => _buildContactItem(context, contactos[index], _activeContact?.id == contactos[index].id),
              ),
        ),
      ],
    );
  }

  Widget _buildContactItem(BuildContext context, Usuario contact, bool isActive) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    bool isAI = contact.id == 'aedus-ai-system';
    
    return ListTile(
      onTap: () => _selectContact(contact),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.05),
      leading: CircleAvatar(
        backgroundColor: isAI ? theme.colorScheme.primary.withValues(alpha: 0.1) : appColors.card,
        child: isAI 
          ? FaIcon(FontAwesomeIcons.robot, size: 14, color: theme.colorScheme.primary)
          : Text(contact.nombre.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
      ),
      title: Text(contact.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
      subtitle: Text(contact.rol, style: TextStyle(color: appColors.textLow, fontSize: 12)),
      trailing: isActive ? CircleAvatar(radius: 4, backgroundColor: theme.colorScheme.primary) : null,
    );
  }

  Widget _buildTicketItem(BuildContext context, Incidencia ticket, bool isActive) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return ListTile(
      onTap: () => _selectTicket(ticket),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.05),
      leading: CircleAvatar(
        backgroundColor: appColors.card,
        child: Text('#${ticket.id}', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      title: Text(ticket.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
      subtitle: Text(ticket.estadoNombre, style: TextStyle(color: appColors.textLow, fontSize: 12)),
      trailing: isActive ? CircleAvatar(radius: 4, backgroundColor: theme.colorScheme.primary) : null,
    );
  }

  Widget _buildChatPanel(BuildContext context, List<Mensaje> mensajes) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    if (_activeContact == null) {
      return Center(child: Text('Selecciona un contacto para chatear', style: TextStyle(color: appColors.textLow)));
    }

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
          child: Row(
            children: [
              Text(_activeContact!.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
              const Spacer(),
              Icon(Icons.videocam_outlined, color: appColors.textLow),
              const SizedBox(width: 16),
              Icon(Icons.phone_outlined, color: appColors.textLow),
              const SizedBox(width: 16),
              Icon(Icons.more_vert, color: appColors.textLow),
            ],
          ),
        ),
        Divider(height: 1, color: appColors.border),
        // Chat Messages
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: ListView.builder(
              itemCount: mensajes.length,
              itemBuilder: (context, index) {
                final msg = mensajes[index];
                final isMe = msg.senderId == context.read<AppProvider>().currentUser?.id;
                
                if (_activeContact?.id == 'aedus-ai-system' && index == 0) {
                  return _buildAIResponse(context, "¡Hola! Soy tu asistente Aedus. ¿En qué puedo ayudarte hoy con el sistema?");
                }

                if (msg.contenido.startsWith('[TICKET_LINK]:')) {
                   return _buildSharedTicket(context, msg, isMe);
                }

                return _buildMessage(context, msg, isMe);
              },
            ),
          ),
        ),
        // Chat Input
        _buildChatInput(context),
      ],
    );
  }

  Widget _buildTicketChatPanel(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    if (_activeTicket == null) {
      return Center(child: Text('Selecciona un ticket para ver sus comentarios', style: TextStyle(color: appColors.textLow)));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
          child: Row(
            children: [
              Text('Ticket #${_activeTicket!.id} - ${_activeTicket!.titulo}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
              const Spacer(),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: theme.colorScheme.primary.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(_activeTicket!.estadoNombre, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: appColors.border),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _ticketComments.isEmpty 
              ? Center(child: Text('No hay comentarios.', style: TextStyle(color: appColors.textLow)))
              : ListView.builder(
                  itemCount: _ticketComments.length,
                  itemBuilder: (context, index) {
                    final msg = _ticketComments[index];
                    final isMe = msg.usuarioId == context.read<AppProvider>().currentUser?.id;
                    return _buildTicketComment(context, msg, isMe);
                  },
              )
          ),
        ),
        _buildTicketChatInput(context),
      ],
    );
  }

  Widget _buildTicketComment(BuildContext context, ComentarioIncidencia c, bool isMe) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: c.isInternal ? appColors.gold.withValues(alpha: 0.2) : (isMe ? theme.colorScheme.primary.withValues(alpha: 0.2) : appColors.card),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: Border.all(
             color: c.isInternal ? appColors.gold : (isMe ? theme.colorScheme.primary.withValues(alpha: 0.4) : appColors.border),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.usuarioNombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c.isInternal ? appColors.gold : (isMe ? theme.colorScheme.primary : theme.colorScheme.onSurface))),
                const SizedBox(width: 8),
                if (c.usuarioRol == 'ADMIN' || c.usuarioRol == 'MANTENIMIENTO')
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                     decoration: BoxDecoration(color: appColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                     child: Text('STAFF', style: TextStyle(fontSize: 8, color: appColors.gold, fontWeight: FontWeight.bold)),
                   ),
                if (c.isInternal)
                   Container(
                     margin: const EdgeInsets.only(left: 8),
                     child: Icon(Icons.lock, size: 12, color: appColors.gold),
                   )
              ],
            ),
            const SizedBox(height: 8),
            Text(c.texto, style: TextStyle(color: theme.colorScheme.onSurface, height: 1.4)),
            const SizedBox(height: 8),
            Text(
              '${c.fecha.hour.toString().padLeft(2, '0')}:${c.fecha.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, color: appColors.textLow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketChatInput(BuildContext context) {
    if (_activeTicket == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final rol = context.watch<AppProvider>().currentUser?.rol ?? '';
    final isStaff = rol == 'ADMIN' || rol == 'MANTENIMIENTO' || rol == 'Administrador';

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (isStaff)
            IconButton(
              icon: Icon(_isSupportMode ? Icons.lock : Icons.lock_open, color: _isSupportMode ? appColors.gold : appColors.textLow),
              tooltip: _isSupportMode ? 'Modo Soporte: Activado' : 'Modo Normal: Público',
              onPressed: () => setState(() => _isSupportMode = !_isSupportMode),
            ),
          Expanded(
            child: TextField(
              controller: _ticketMessageController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: _isSupportMode ? 'Escribiendo en modo soporte...' : 'Escribe un mensaje para el ticket...',
                hintStyle: TextStyle(color: _isSupportMode ? appColors.gold.withValues(alpha: 0.8) : appColors.textLow.withValues(alpha: 0.5)),
                fillColor: _isSupportMode ? appColors.gold.withValues(alpha: 0.1) : appColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendTicketComment(),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _isSupportMode ? appColors.gold : theme.colorScheme.primary, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendTicketComment,
            ),
          ),
        ],
      ),
    );
  }

  void _sendTicketComment() async {
     final text = _ticketMessageController.text.trim();
     if (text.isEmpty || _activeTicket == null) return;
     _ticketMessageController.clear();
     await context.read<AppProvider>().addComentarioIncidencia(_activeTicket!.id, text, isInternal: _isSupportMode);
     _refreshTicketComments();
  }

  Widget _buildSharedTicket(BuildContext context, Mensaje msg, bool isMe) {
    final theme = Theme.of(context);
    final ticketIdStr = msg.contenido.split(':')[1].replaceAll(']', '').trim();
    final ticketId = int.tryParse(ticketIdStr) ?? 0;
    
    // Fallback if ticket is not found locally
    final allIncids = context.watch<AppProvider>().incidencias;
    final Incidencia? ticket = allIncids.where((i) => i.id == ticketId).firstOrNull;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
           if (ticket != null) {
              showDialog(
                context: context,
                builder: (ctx) => IncidentDetailDialog(incidencia: ticket, showAdminActions: false),
              );
           }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.confirmation_number, color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ticket Compartido', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(ticket != null ? ticket.titulo : 'Ticket #$ticketIdStr', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIResponse(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Sugerencia IA', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(color: theme.colorScheme.onSurface, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, Mensaje msg, bool isMe) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : appColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.imagenUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: msg.imagenUrl!,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                ),
              ),
              if (msg.contenido.isNotEmpty) const SizedBox(height: 8),
            ],
            if (msg.audioUrl != null) ...[
              AudioPlayerWidget(url: msg.audioUrl!),
              if (msg.contenido.isNotEmpty) const SizedBox(height: 8),
            ],
            if (msg.contenido.isNotEmpty)
              Text(msg.contenido, style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          PopupMenuButton(
            icon: Icon(Icons.add, color: appColors.textLow),
            color: appColors.surface,
            itemBuilder: (context) => [
               PopupMenuItem(
                  value: 'img',
                  onTap: _pickImage,
                  child: const Text('Adjuntar Imagen'),
               ),
               PopupMenuItem(
                  value: 'ticket',
                  onTap: () {
                     Future.delayed(const Duration(milliseconds: 100), () {
                       if (!mounted) return;
                       _showShareTicketDialog(context);
                     });
                  },
                  child: const Text('Compartir Ticket'),
               )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: _isRecording ? 'Grabando audio...' : 'Escribe un mensaje...',
                hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5)),
                fillColor: appColors.card,
                suffixIcon: GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: _stopRecording,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: FaIcon(
                      FontAwesomeIcons.microphone, 
                      size: 16, 
                      color: _isRecording ? appColors.danger : appColors.textLow
                    ),
                  ),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showShareTicketDialog(BuildContext context) {
    final incidencias = context.read<AppProvider>().incidencias;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).extension<AppColors>()!.surface,
      builder: (ctx) {
        return ListView.builder(
           padding: const EdgeInsets.all(24),
           itemCount: incidencias.length,
           itemBuilder: (c, idx) {
              final inc = incidencias[idx];
              return ListTile(
                 title: Text(inc.titulo),
                 subtitle: Text(inc.estadoNombre),
                 onTap: () {
                    _sendMessage(textOverride: '[TICKET_LINK]:${inc.id}');
                    Navigator.pop(ctx);
                 },
              );
           }
        );
      }
    );
  }

  void _sendMessage({String? imageUrl, String? audioUrl, String? textOverride}) {
    if (_activeContact == null) return;
    final text = textOverride ?? _messageController.text.trim();
    if (text.isEmpty && imageUrl == null && audioUrl == null) return;
    
    context.read<AppProvider>().sendMessage(
      _activeContact!.id, 
      text,
      imagenUrl: imageUrl,
      audioUrl: audioUrl,
    );
    _messageController.clear();
  }

  Widget _buildDetailsPanel(BuildContext context) {
    if (_activeContact == null) return const SizedBox.shrink();
    return _UserDetailsWidget(contact: _activeContact!);
  }

  Widget _buildTicketDetailsPanel(BuildContext context) {
    if (_activeTicket == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final ticket = _activeTicket!;

    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
         Text('Información', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
         const SizedBox(height: 32),
         if (ticket.imagenUrl != null) ...[
            ClipRRect(
               borderRadius: BorderRadius.circular(16),
               child: CachedNetworkImage(
                  imageUrl: ticket.imagenUrl!,
                  height: 150,
                  fit: BoxFit.cover,
                  placeholder: (c,u) => const CircularProgressIndicator(),
                  errorWidget: (c,u,e) => const Icon(Icons.broken_image),
               ),
            ),
            const SizedBox(height: 24),
         ],
         _buildInfoRow(context, 'Autor ID', ticket.usuarioId),
         _buildInfoRow(context, 'F. Creación', '${ticket.fecha.day}/${ticket.fecha.month}'),
         _buildInfoRow(context, 'Descripción', ticket.descripcion),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: appColors.textLow, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}

class _UserDetailsWidget extends StatelessWidget {
  final Usuario contact;
  const _UserDetailsWidget({required this.contact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Detalles del Usuario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(contact.nombre.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ),
          const SizedBox(height: 24),
          Text(contact.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: theme.colorScheme.onSurface)),
          Text(contact.rol, style: TextStyle(color: appColors.textLow)),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          _buildInfoCol(context, 'Email', contact.email),
          _buildInfoCol(context, 'Estado', contact.status),
          _buildInfoCol(context, 'Coins', contact.aeduCoins.toString()),
        ],
      ),
    );
  }

  Widget _buildInfoCol(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: appColors.textLow, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  const AudioPlayerWidget({super.key, required this.url});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 20, color: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.play(UrlSource(widget.url));
              }
            },
          ),
          Text(
            '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / ${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final BuildContext context;
  const _TabItem({required this.title, required this.isActive, required this.context});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(this.context);
    final appColors = theme.extension<AppColors>()!;
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: isActive ? theme.colorScheme.primary : appColors.textLow,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 20,
            height: 2,
            color: theme.colorScheme.primary,
          ),
      ],
    );
  }
}
