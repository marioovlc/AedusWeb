import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    if (_activeContact != null) {
      return _buildChatView();
    }
    return _buildContactsView();
  }

  Widget _buildContactsView() {
    final provider = context.watch<AppProvider>();
    final contactos = provider.contactos;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Connect Hub'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView.builder(
        itemCount: contactos.length,
        itemBuilder: (ctx, i) => ListTile(
          onTap: () => _selectContact(contactos[i]),
          leading: CircleAvatar(child: Text(contactos[i].nombre.substring(0,1))),
          title: Text(contactos[i].nombre),
          subtitle: Text(contactos[i].rol),
        ),
      ),
    );
  }

  Widget _buildChatView() {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _closeChat),
        title: Text(_activeContact!.nombre),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.mensajes.length,
              itemBuilder: (ctx, i) => _buildMessage(provider.mensajes[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Escribe...'))),
                IconButton(icon: const Icon(Icons.send), onPressed: () {
                  if (_messageController.text.isNotEmpty) {
                    context.read<AppProvider>().sendMessage(_activeContact!.id, _messageController.text);
                    _messageController.clear();
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Mensaje msg) {
    final isMe = msg.senderId == context.read<AppProvider>().currentUser?.id;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).extension<AppColors>()!.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg.contenido, style: TextStyle(color: isMe ? Colors.white : null)),
      ),
    );
  }
}
