import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/incident_model.dart';
import '../../../core/services/storage_service.dart';
import '../../widgets/incident_detail_dialog.dart';

// =============================================
// ==== CLASE ConnectHubDesktop =====
// Descripción: Widget estructurado que representa la interfaz de Connect Hub optimizada para escritorio, ofreciendo chat en tiempo real con soporte de imágenes, notas de voz, reproductor de audio integrado y un asistente inteligente de IA.
// =============================================
class ConnectHubDesktop extends StatefulWidget {
  const ConnectHubDesktop({super.key});

  @override
  State<ConnectHubDesktop> createState() => _ConnectHubDesktopState();
}

class _ConnectHubDesktopState extends State<ConnectHubDesktop> {
  Usuario? _activeContact;

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _imagePicker = ImagePicker();
  bool _isRecording = false;
  bool _isAITyping = false;
  String _searchQuery = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      if (_activeContact != null) {
        context.read<AppProvider>().fetchMessages(_activeContact!.id);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectContact(Usuario contact) {
    setState(() {
      _activeContact = contact;
    });
    context.read<AppProvider>().fetchMessages(contact.id);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        if (!mounted) return;
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
      if (!mounted) return;
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
        SizedBox(width: 300, child: _buildContactsPanel(context, provider)),
        VerticalDivider(width: 1, color: appColors.border),
        Expanded(child: _buildChatPanel(context, provider.mensajes)),
        if (_activeContact != null) ...[
          VerticalDivider(width: 1, color: appColors.border),
          SizedBox(width: 260, child: _buildDetailsPanel(context)),
        ],
      ],
    );
  }

  // ─── CONTACTS PANEL ────────────────────────────────────────────────────────
  Widget _buildContactsPanel(BuildContext context, AppProvider provider) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final allContactos = provider.contactos;
    final contactos = _searchQuery.isEmpty
        ? allContactos
        : allContactos.where((c) =>
            c.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.rol.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        // Cabecera
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            color: appColors.surface,
            border: Border(bottom: BorderSide(color: appColors.border.withValues(alpha: 0.5))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const FaIcon(FontAwesomeIcons.comments, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Connect Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                      Text('${allContactos.length} contactos', style: TextStyle(fontSize: 11, color: appColors.textLow)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Buscar contacto...',
                  hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5), fontSize: 13),
                  prefixIcon: Icon(Icons.search, size: 18, color: appColors.textLow),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 16, color: appColors.textLow),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  fillColor: appColors.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ],
          ),
        ),
        // Lista de contactos
        Expanded(
          child: contactos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 40, color: appColors.textLow.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text('Sin resultados', style: TextStyle(color: appColors.textLow, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: contactos.length,
                  itemBuilder: (context, index) => _buildContactItem(
                      context, contactos[index], _activeContact?.id == contactos[index].id),
                ),
        ),
      ],
    );
  }

  Widget _buildContactItem(BuildContext context, Usuario contact, bool isActive) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final bool isAI = contact.id == 'aedus-ai-system';

    // Color de estado de conexión
    Color onlineColor = appColors.textLow.withValues(alpha: 0.4);
    if (contact.lastSeen != null) {
      final diff = DateTime.now().difference(contact.lastSeen!);
      if (diff.inMinutes < 5) { onlineColor = appColors.success; }
      else if (diff.inMinutes < 30) { onlineColor = Colors.orange; }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        border: isActive
            ? Border(left: BorderSide(color: theme.colorScheme.primary, width: 3))
            : const Border(left: BorderSide(color: Colors.transparent, width: 3)),
      ),
      child: ListTile(
        onTap: () => _selectContact(contact),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isAI
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : appColors.card,
              backgroundImage: (!isAI && contact.avatarUrl != null)
                  ? CachedNetworkImageProvider(contact.avatarUrl!)
                  : null,
              child: isAI
                  ? FaIcon(FontAwesomeIcons.robot, size: 14, color: theme.colorScheme.primary)
                  : (contact.avatarUrl == null
                      ? Text(
                          contact.nombre.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary),
                        )
                      : null),
            ),
            if (!isAI)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: onlineColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: appColors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          contact.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          isAI ? '🤖 Asistente IA' : contact.rol,
          style: TextStyle(color: appColors.textLow, fontSize: 11),
        ),
      ),
    );
  }

  // ─── CHAT PANEL ────────────────────────────────────────────────────────────
  Widget _buildChatPanel(BuildContext context, List<Mensaje> mensajes) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    if (_activeContact == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                    theme.colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: FaIcon(FontAwesomeIcons.comments, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text('Selecciona un contacto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('Elige una conversación para empezar a chatear', style: TextStyle(color: appColors.textLow, fontSize: 14)),
          ],
        ),
      );
    }

    final bool isAI = _activeContact!.id == 'aedus-ai-system';

    return Column(
      children: [
        // Cabecera del chat
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: appColors.surface,
            border: Border(bottom: BorderSide(color: appColors.border.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAI
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : appColors.card,
                    backgroundImage: (!isAI && _activeContact!.avatarUrl != null)
                        ? CachedNetworkImageProvider(_activeContact!.avatarUrl!)
                        : null,
                    child: isAI
                        ? FaIcon(FontAwesomeIcons.robot, size: 14, color: theme.colorScheme.primary)
                        : (_activeContact!.avatarUrl == null
                            ? Text(
                                _activeContact!.nombre.substring(0, 1).toUpperCase(),
                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              )
                            : null),
                  ),
                  if (!isAI)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: appColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: appColors.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeContact!.nombre,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      isAI ? 'Asistente inteligente · siempre activo' : _activeContact!.rol,
                      style: TextStyle(color: appColors.textLow, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!isAI) ...[
                _buildHeaderAction(context, Icons.videocam_outlined, appColors),
                const SizedBox(width: 4),
                _buildHeaderAction(context, Icons.phone_outlined, appColors),
                const SizedBox(width: 4),
              ],
              _buildHeaderAction(context, Icons.more_vert, appColors),
            ],
          ),
        ),
        // Mensajes
        Expanded(
          child: Container(
            color: appColors.surface.withValues(alpha: 0.3),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: mensajes.length + (_isAITyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isAITyping && index == mensajes.length) {
                  return _buildTypingIndicator(context);
                }
                final msg = mensajes[index];
                final isMe = msg.senderId == context.read<AppProvider>().currentUser?.id;

                if (_activeContact?.id == 'aedus-ai-system' && index == 0) {
                  return _buildAIResponse(context,
                      '¡Hola! Soy tu asistente Aedus. ¿En qué puedo ayudarte hoy con el sistema?');
                }

                if (msg.ticketLinkId != null && msg.ticketLinkId! > 0) {
                  return _buildSharedTicket(context, msg, isMe);
                }
                if (msg.contenido.startsWith('[TICKET_LINK]:')) {
                  return _buildSharedTicket(context, msg, isMe);
                }

                return _buildMessage(context, msg, isMe);
              },
            ),
          ),
        ),
        _buildChatInput(context),
      ],
    );
  }

  Widget _buildHeaderAction(BuildContext context, IconData icon, AppColors appColors) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: appColors.textLow, size: 20),
        ),
      ),
    );
  }

  Widget _buildSharedTicket(BuildContext context, Mensaje msg, bool isMe) {
    final theme = Theme.of(context);

    int ticketId = 0;
    if (msg.ticketLinkId != null && msg.ticketLinkId! > 0) {
      ticketId = msg.ticketLinkId!;
    } else {
      final parts = msg.contenido.split(':');
      if (parts.length > 1) {
        ticketId = int.tryParse(parts[1].replaceAll(']', '').trim()) ?? 0;
      }
    }

    final ticketIdStr = ticketId.toString();
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
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.confirmation_number, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ticket Compartido',
                        style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      ticket != null ? ticket.titulo : 'Ticket #$ticketIdStr',
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (ticket != null)
                      Text(ticket.estadoNombre,
                          style: TextStyle(color: theme.colorScheme.primary.withValues(alpha: 0.7), fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: theme.colorScheme.primary.withValues(alpha: 0.6), size: 14),
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
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 12, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Asistente Aedus',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 11, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 10),
            Text(text, style: TextStyle(color: theme.colorScheme.onSurface, height: 1.6, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: appColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.robot, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            _AnimatedDots(color: theme.colorScheme.primary),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary])
              : null,
          color: isMe ? null : appColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.imagenUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: msg.imagenUrl!,
                  placeholder: (context, url) =>
                      const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
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
              Text(
                msg.contenido,
                style: TextStyle(
                  color: isMe ? Colors.white : theme.colorScheme.onSurface,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: appColors.surface,
        border: Border(top: BorderSide(color: appColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          PopupMenuButton(
            icon: Icon(Icons.add_circle_outline, color: appColors.textLow, size: 24),
            color: appColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'img',
                onTap: _pickImage,
                child: Row(children: [
                  Icon(Icons.image_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  const Text('Adjuntar Imagen'),
                ]),
              ),
              PopupMenuItem(
                value: 'ticket',
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (!mounted) return;
                    _showShareTicketDialog(this.context);
                  });
                },
                child: Row(children: [
                  Icon(Icons.confirmation_number_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  const Text('Compartir Ticket'),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: _isRecording ? '🎙 Grabando audio...' : 'Escribe un mensaje...',
                hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5), fontSize: 13),
                fillColor: appColors.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                suffixIcon: GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: _stopRecording,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: FaIcon(
                      FontAwesomeIcons.microphone,
                      size: 15,
                      color: _isRecording ? appColors.danger : appColors.textLow,
                    ),
                  ),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showShareTicketDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: appColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: appColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.confirmation_number, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text('Compartir Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: provider.incidencias.length,
                itemBuilder: (c, idx) {
                  final inc = provider.incidencias[idx];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.confirmation_number_outlined, color: theme.colorScheme.primary, size: 16),
                    ),
                    title: Text(inc.titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text('#${inc.id} · ${inc.estadoNombre}', style: TextStyle(color: appColors.textLow, fontSize: 12)),
                    onTap: () {
                      _sendMessage(ticketLinkId: inc.id);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _sendMessage({String? imageUrl, String? audioUrl, int? ticketLinkId}) {
    if (_activeContact == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null && audioUrl == null && ticketLinkId == null) return;

    final isAI = _activeContact!.id == 'aedus-ai-system';
    if (isAI) setState(() => _isAITyping = true);

    context.read<AppProvider>().sendMessage(
      _activeContact!.id,
      text,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      ticketLinkId: ticketLinkId,
    ).then((_) {
      if (mounted && isAI) setState(() => _isAITyping = false);
      _scrollToBottom();
    });
    _messageController.clear();
    _scrollToBottom();
  }

  // ─── DETAILS PANEL ─────────────────────────────────────────────────────────
  Widget _buildDetailsPanel(BuildContext context) {
    if (_activeContact == null) return const SizedBox.shrink();
    return _UserDetailsWidget(contact: _activeContact!);
  }
}

// ─── USER DETAILS WIDGET ────────────────────────────────────────────────────
// =============================================
// ==== CLASE _UserDetailsWidget =====
// Descripción: Widget auxiliar de detalles que visualiza el perfil del contacto seleccionado en la barra lateral del Connect Hub de escritorio.
// =============================================
class _UserDetailsWidget extends StatelessWidget {
  final Usuario contact;
  const _UserDetailsWidget({required this.contact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final bool isAI = contact.id == 'aedus-ai-system';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Degradado de la cabecera del perfil
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.12),
                  theme.colorScheme.secondary.withValues(alpha: 0.06),
                ],
              ),
              border: Border(bottom: BorderSide(color: appColors.border.withValues(alpha: 0.5))),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: isAI
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : appColors.card,
                      backgroundImage: (!isAI && contact.avatarUrl != null)
                          ? CachedNetworkImageProvider(contact.avatarUrl!)
                          : null,
                      child: isAI
                          ? FaIcon(FontAwesomeIcons.robot, size: 28, color: theme.colorScheme.primary)
                          : (contact.avatarUrl == null
                              ? Text(contact.nombre.substring(0, 1).toUpperCase(),
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))
                              : null),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isAI ? theme.colorScheme.primary : appColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: appColors.surface, width: 2),
                      ),
                      child: Icon(
                        isAI ? Icons.auto_awesome : Icons.circle,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(contact.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAI ? 'IA · Siempre activo' : contact.rol,
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Campos de información
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INFORMACIÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appColors.textLow, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildInfoRow(context, Icons.email_outlined, 'Email', contact.email),
                const SizedBox(height: 12),
                _buildInfoRow(context, Icons.circle, 'Estado', contact.status),
                const SizedBox(height: 12),
                if (!isAI)
                  _buildInfoRow(context, Icons.monetization_on_outlined, 'AeduCoins', '${contact.aeduCoins}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: appColors.textLow, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AUDIO PLAYER ───────────────────────────────────────────────────────────
// =============================================
// ==== CLASE AudioPlayerWidget =====
// Descripción: Widget reproductor de audio interactivo integrado que gestiona y reproduce mensajes de voz del Connect Hub.
// =============================================
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
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                size: 20, color: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.play(UrlSource(widget.url));
              }
            },
          ),
          Text(
            '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / '
            '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─── ANIMATED DOTS ──────────────────────────────────────────────────────────
// =============================================
// ==== CLASE _AnimatedDots =====
// Descripción: Widget de animación simple para simular el indicador de escritura de la IA ("Typing Indicator") mediante puntos rebotantes.
// =============================================
class _AnimatedDots extends StatefulWidget {
  final Color color;
  const _AnimatedDots({required this.color});

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final bounce = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
            return Transform.translate(
              offset: Offset(0, -4 * bounce),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
