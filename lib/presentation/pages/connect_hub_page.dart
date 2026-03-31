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
import '../../core/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ConnectHubPage extends StatefulWidget {
  const ConnectHubPage({super.key});

  @override
  State<ConnectHubPage> createState() => _ConnectHubPageState();
}

class _ConnectHubPageState extends State<ConnectHubPage> {
  Usuario? _activeContact;
  final _messageController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _imagePicker = ImagePicker();
  bool _isRecording = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_activeContact != null && mounted) {
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
    final provider = context.watch<AppProvider>();
    final contactos = provider.contactos;
    final mensajes = provider.mensajes;

    return Row(
      children: [
        // Panel 1: Contacts (Left)
        Expanded(flex: 2, child: _buildContactsPanel(contactos)),
        const VerticalDivider(width: 1, color: AppTheme.borders),
        // Panel 2: Chat (Center)
        Expanded(flex: 4, child: _buildChatPanel(mensajes)),
        const VerticalDivider(width: 1, color: AppTheme.borders),
        // Panel 3: Details (Right)
        Expanded(flex: 2, child: _buildDetailsPanel()),
      ],
    );
  }

  Widget _buildContactsPanel(List<Usuario> contactos) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: const Icon(Icons.search, size: 20),
              fillColor: AppTheme.surface,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              _TabItem(title: 'Personas', isActive: true),
              SizedBox(width: 16),
              _TabItem(title: 'Tickets', isActive: false),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: contactos.length,
            itemBuilder: (context, index) {
              final contact = contactos[index];
              return _buildContactItem(contact, _activeContact?.id == contact.id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(Usuario contact, bool isActive) {
    bool isAI = contact.id == 'aedus-ai-system';
    
    return ListTile(
      onTap: () => _selectContact(contact),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      selected: isActive,
      selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
      leading: CircleAvatar(
        backgroundColor: isAI ? AppTheme.primaryBlue.withValues(alpha: 0.1) : AppTheme.cards,
        child: isAI 
          ? const FaIcon(FontAwesomeIcons.robot, size: 14, color: AppTheme.primaryBlue)
          : Text(contact.nombre.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
      ),
      title: Text(contact.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(contact.rol, style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 12)),
      trailing: isActive ? CircleAvatar(radius: 4, backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.05)) : null,
    );
  }

  Widget _buildChatPanel(List<Mensaje> mensajes) {
    if (_activeContact == null) {
      return const Center(child: Text('Selecciona un contacto para chatear', style: TextStyle(color: AppTheme.textLowPriority)));
    }

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: AppTheme.background),
          child: Row(
            children: [
              Text(_activeContact!.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Spacer(),
              const Icon(Icons.videocam_outlined, color: AppTheme.textLowPriority),
              const SizedBox(width: 16),
              const Icon(Icons.phone_outlined, color: AppTheme.textLowPriority),
              const SizedBox(width: 16),
              const Icon(Icons.more_vert, color: AppTheme.textLowPriority),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borders),
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
                  return _buildAIResponse("¡Hola! Soy tu asistente Aedus. ¿En qué puedo ayudarte hoy con el sistema?");
                }

                return _buildMessage(msg, isMe);
              },
            ),
          ),
        ),
        // Chat Input
        _buildChatInput(),
      ],
    );
  }

  Widget _buildAIResponse(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 14, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Text('Sugerencia IA', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: AppTheme.textHighPriority, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Mensaje msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryBlue : AppTheme.cards,
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
              Text(msg.contenido, style: const TextStyle(color: Colors.white, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.textLowPriority),
            onPressed: _pickImage,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _isRecording ? 'Grabando audio...' : 'Escribe un mensaje...',
                fillColor: AppTheme.cards,
                suffixIcon: GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: _stopRecording,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: FaIcon(
                      FontAwesomeIcons.microphone, 
                      size: 16, 
                      color: _isRecording ? AppTheme.danger : AppTheme.textLowPriority
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
            decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage({String? imageUrl, String? audioUrl}) {
    if (_activeContact == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null && audioUrl == null) return;
    
    context.read<AppProvider>().sendMessage(
      _activeContact!.id, 
      text,
      imagenUrl: imageUrl,
      audioUrl: audioUrl,
    );
    _messageController.clear();
  }

  Widget _buildDetailsPanel() {
    if (_activeContact == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Detalles del Usuario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
            child: Text(_activeContact!.nombre.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          ),
          const SizedBox(height: 24),
          Text(_activeContact!.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(_activeContact!.rol, style: const TextStyle(color: AppTheme.textLowPriority)),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          _buildInfoRow('Email', _activeContact!.email),
          _buildInfoRow('Estado', _activeContact!.status),
          _buildInfoRow('Coins', _activeContact!.aeduCoins.toString()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textLowPriority, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 20, color: Colors.white),
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
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final bool isActive;
  const _TabItem({required this.title, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.primaryBlue : AppTheme.textLowPriority,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 20,
            height: 2,
            color: AppTheme.primaryBlue,
          ),
      ],
    );
  }
}
