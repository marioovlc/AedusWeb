import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/message_model.dart';

class ConnectHubMobile extends StatefulWidget {
  const ConnectHubMobile({super.key});

  @override
  State<ConnectHubMobile> createState() => _ConnectHubMobileState();
}

class _ConnectHubMobileState extends State<ConnectHubMobile> {
  Usuario? _activeContact;
  final _messageController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _activeContact != null ? _buildChatView() : _buildContactsView(),
      ),
    );
  }

  Widget _buildContactsView() {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final contactos = provider.contactos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connect Hub', style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: 4),
              Text('Conversaciones activas', style: TextStyle(color: appColors.textLow)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: contactos.length,
            itemBuilder: (ctx, i) {
              final contact = contactos[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => _selectContact(contact),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: contact.avatarUrl != null ? CachedNetworkImageProvider(contact.avatarUrl!) : null,
                    child: contact.avatarUrl == null ? Text(contact.nombre.substring(0, 1).toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)) : null,
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

  Widget _buildChatView() {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: _closeChat),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: _activeContact!.avatarUrl != null ? CachedNetworkImageProvider(_activeContact!.avatarUrl!) : null,
              child: _activeContact!.avatarUrl == null ? Text(_activeContact!.nombre.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 10)) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_activeContact!.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(_activeContact!.rol, style: TextStyle(fontSize: 11, color: appColors.textLow)),
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
              padding: const EdgeInsets.all(20),
              itemCount: provider.mensajes.length,
              itemBuilder: (ctx, i) => _buildMessage(provider.mensajes[i]),
            ),
          ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.surface,
        border: Border(top: BorderSide(color: appColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
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
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  context.read<AppProvider>().sendMessage(_activeContact!.id, _messageController.text);
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Mensaje msg) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final isMe = msg.senderId == context.read<AppProvider>().currentUser?.id;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? theme.primaryColor : appColors.card,
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
}
