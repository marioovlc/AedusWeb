import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/message_model.dart';

class ConnectHubDesktop extends StatefulWidget {
  const ConnectHubDesktop({super.key});

  @override
  State<ConnectHubDesktop> createState() => _ConnectHubDesktopState();
}

class _ConnectHubDesktopState extends State<ConnectHubDesktop> {
  Usuario? _activeContact;
  final _messageController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
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
    super.dispose();
  }

  void _selectContact(Usuario contact) {
    setState(() => _activeContact = contact);
    context.read<AppProvider>().fetchMessages(contact.id);
  }

  Future<void> _sendMessage({String? imageUrl, String? audioUrl, int? ticketLinkId}) async {
    if (_activeContact == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null && audioUrl == null && ticketLinkId == null) return;
    
    context.read<AppProvider>().sendMessage(_activeContact!.id, text, imageUrl: imageUrl, audioUrl: audioUrl, ticketLinkId: ticketLinkId);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<AppProvider>();

    return Row(
      children: [
        Expanded(flex: 2, child: _buildContactsPanel(context, provider)),
        VerticalDivider(width: 1, color: appColors.border),
        Expanded(flex: 4, child: _buildChatPanel(context, provider.mensajes)),
        VerticalDivider(width: 1, color: appColors.border),
        Expanded(flex: 2, child: _buildDetailsPanel(context)),
      ],
    );
  }

  Widget _buildContactsPanel(BuildContext context, AppProvider provider) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final contactos = provider.contactos;
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(24.0), child: TextField(decoration: InputDecoration(hintText: 'Buscar...', prefixIcon: Icon(Icons.search, size: 20, color: appColors.textLow)))),
        const SizedBox(height: 16),
        Expanded(child: ListView.builder(itemCount: contactos.length, itemBuilder: (context, index) => _buildContactItem(context, contactos[index], _activeContact?.id == contactos[index].id))),
      ],
    );
  }

  Widget _buildContactItem(BuildContext context, Usuario contact, bool isActive) {
    final theme = Theme.of(context);
    return ListTile(onTap: () => _selectContact(contact), selected: isActive, leading: CircleAvatar(child: Text(contact.nombre.substring(0, 1).toUpperCase())), title: Text(contact.nombre, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(contact.rol), trailing: isActive ? CircleAvatar(radius: 4, backgroundColor: theme.colorScheme.primary) : null);
  }

  Widget _buildChatPanel(BuildContext context, List<Mensaje> mensajes) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    if (_activeContact == null) return Center(child: Text('Selecciona un contacto', style: TextStyle(color: appColors.textLow)));
    return Column(
      children: [
        Container(padding: const EdgeInsets.all(24), child: Row(children: [Text(_activeContact!.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const Spacer(), Icon(Icons.more_vert, color: appColors.textLow)])),
        const Divider(height: 1),
        Expanded(child: ListView.builder(itemCount: mensajes.length, itemBuilder: (context, index) => _buildMessage(context, mensajes[index]))),
        _buildChatInput(context),
      ],
    );
  }

  Widget _buildMessage(BuildContext context, Mensaje msg) {
    final isMe = msg.senderId == context.read<AppProvider>().currentUser?.id;
    return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).extension<AppColors>()!.card, borderRadius: BorderRadius.circular(16)), child: Text(msg.contenido, style: TextStyle(color: isMe ? Colors.white : null))));
  }

  Widget _buildChatInput(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(24), child: Row(children: [Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Escribe un mensaje...'))), IconButton(icon: const Icon(Icons.send), onPressed: () => _sendMessage())]));
  }

  Widget _buildDetailsPanel(BuildContext context) {
    if (_activeContact == null) return const SizedBox.shrink();
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 40, child: Text(_activeContact!.nombre.substring(0,1))), const SizedBox(height: 16), Text(_activeContact!.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(_activeContact!.rol)]));
  }
}
