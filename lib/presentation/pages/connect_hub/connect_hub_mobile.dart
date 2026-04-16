import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/incident_model.dart';
import '../../widgets/incident_detail_dialog.dart';

class ConnectHubMobile extends StatefulWidget {
  const ConnectHubMobile({super.key});

  @override
  State<ConnectHubMobile> createState() => _ConnectHubMobileState();
}

class _ConnectHubMobileState extends State<ConnectHubMobile> {
  Usuario? _activeContact;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _refreshTimer;

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
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
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectContact(Usuario contact) {
    setState(() => _activeContact = contact);
    context.read<AppProvider>().fetchMessages(contact.id);
    _startRefreshTimer();
  }

  void _closeChat() {
    setState(() => _activeContact = null);
    _refreshTimer?.cancel();
  }

  void _sendMessage({int? ticketLinkId}) {
    if (_activeContact == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && ticketLinkId == null) return;

    context.read<AppProvider>().sendMessage(
      _activeContact!.id,
      text,
      ticketLinkId: ticketLinkId,
    );
    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showShareTicketDialog() {
    final provider = context.read<AppProvider>();
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    showModalBottomSheet(
      context: context,
      backgroundColor: appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final incidencias = provider.incidencias;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: appColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.confirmation_number, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Compartir Ticket',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (incidencias.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No tienes tickets disponibles.', style: TextStyle(color: appColors.textLow)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: incidencias.length,
                  itemBuilder: (c, idx) {
                    final inc = incidencias[idx];
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
                        Navigator.pop(ctx);
                        _sendMessage(ticketLinkId: inc.id);
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
        child: _activeContact != null
            ? _buildChatView(key: const ValueKey('chat'))
            : _buildContactsView(key: const ValueKey('contacts')),
      ),
    );
  }

  Widget _buildContactsView({Key? key}) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final allContactos = provider.contactos;
    final contactos = _searchQuery.isEmpty
        ? allContactos
        : allContactos.where((c) =>
            c.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.rol.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connect Hub', style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: 4),
              Text('Conversaciones activas', style: TextStyle(color: appColors.textLow)),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Buscar contacto...',
                  hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.search, size: 20, color: appColors.textLow),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: appColors.textLow),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  fillColor: appColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: contactos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 40, color: appColors.textLow),
                      const SizedBox(height: 8),
                      Text('Sin resultados', style: TextStyle(color: appColors.textLow)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: contactos.length,
                  itemBuilder: (ctx, i) {
                    final contact = contactos[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        onTap: () => _selectContact(contact),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            _buildAvatar(contact, theme, 24),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(
                                  color: _onlineColor(contact.lastSeen, appColors),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: appColors.card, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(contact.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(contact.rol, style: TextStyle(color: appColors.textLow, fontSize: 12)),
                        trailing: Icon(Icons.chevron_right, color: appColors.textLow, size: 20),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatView({Key? key}) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    return Scaffold(
      key: key,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _closeChat,
        ),
        title: Row(
          children: [
            _buildAvatar(_activeContact!, theme, 16),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_activeContact!.nombre,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(_activeContact!.rol,
                    style: TextStyle(fontSize: 11, color: appColors.textLow)),
              ],
            ),
          ],
        ),
        backgroundColor: appColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.mensajes.length,
              itemBuilder: (ctx, i) {
                final msg = provider.mensajes[i];
                final isMe = msg.senderId == provider.currentUser?.id;

                // Detect ticket messages
                if ((msg.ticketLinkId != null && msg.ticketLinkId! > 0) ||
                    msg.contenido.startsWith('[TICKET_LINK]:')) {
                  return _buildSharedTicket(msg, isMe);
                }

                return _buildMessage(msg, isMe);
              },
            ),
          ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildSharedTicket(Mensaje msg, bool isMe) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    // Parse ticket ID
    int ticketId = 0;
    if (msg.ticketLinkId != null && msg.ticketLinkId! > 0) {
      ticketId = msg.ticketLinkId!;
    } else {
      final parts = msg.contenido.split(':');
      if (parts.length > 1) {
        ticketId = int.tryParse(parts.last.trim()) ?? 0;
      }
    }

    final allIncidencias = context.watch<AppProvider>().incidencias;
    final Incidencia? ticket = allIncidencias.where((i) => i.id == ticketId).firstOrNull;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          if (ticket != null) {
            showDialog(
              context: context,
              builder: (ctx) => IncidentDetailDialog(
                incidencia: ticket,
                showAdminActions: false,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No tienes acceso al ticket #$ticketId'),
                backgroundColor: appColors.danger,
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.confirmation_number, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket Compartido',
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket != null ? ticket.titulo : 'Ticket #$ticketId',
                      style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    if (ticket != null)
                      Text(
                        ticket.estadoNombre,
                        style: TextStyle(color: appColors.textLow, fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new, color: theme.colorScheme.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Mensaje msg, bool isMe) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : appColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.contenido,
          style: TextStyle(
            color: isMe ? Colors.white : theme.colorScheme.onSurface,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: appColors.surface,
        border: Border(top: BorderSide(color: appColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Attach / Share ticket button
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: appColors.textLow, size: 26),
            tooltip: 'Compartir ticket',
            onPressed: _showShareTicketDialog,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: TextStyle(color: appColors.textLow.withValues(alpha: 0.5)),
                fillColor: appColors.card,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
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

  Widget _buildAvatar(Usuario usuario, ThemeData theme, double radius) {
    final initial = usuario.nombre.isNotEmpty
        ? usuario.nombre.substring(0, 1).toUpperCase()
        : '?';
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );

    if (usuario.avatarUrl == null || usuario.avatarUrl!.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: usuario.avatarUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }

  Color _onlineColor(DateTime? lastSeen, AppColors appColors) {
    if (lastSeen == null) return appColors.textLow;
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 5) return appColors.success;
    if (diff.inMinutes < 30) return Colors.orange;
    return appColors.textLow;
  }
}
