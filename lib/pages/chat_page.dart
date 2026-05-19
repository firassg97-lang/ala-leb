import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../services/supabase_service.dart';
import '../services/image_utils.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isRecording = false;
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  void _subscribeRealtime() {
    SupabaseConfig.client
        .channel('chat_${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              final msg = MessageModel.fromJson(
                  payload.newRecord.cast<String, dynamic>());
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseConfig.client
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: true);

      setState(() {
        _messages.addAll((data as List)
            .map((j) => MessageModel.fromJson(j as Map<String, dynamic>))
            .toList());
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    final user = ref.read(currentUserProvider)!;
    try {
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': user.id,
        'message_type': 'text',
        'content': text,
      });
    } catch (e) {
      debugPrint('Send text error: $e');
    }
  }

  Future<void> _sendImage() async {
    final source = await _showImageSourcePicker();
    if (source == null) return;
    final file = await ImageUtils.pickAndCompress(source: source);
    if (file == null) return;

    final user = ref.read(currentUserProvider)!;
    try {
      final path = '${const Uuid().v4()}.jpg';
      await SupabaseConfig.client.storage.from('products').upload(path, file);
      final url = SupabaseConfig.client.storage.from('products').getPublicUrl(path);
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': user.id,
        'message_type': 'image',
        'media_url': url,
      });
    } catch (e) {
      debugPrint('Send image error: $e');
    }
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryBlue),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryPink),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;

    final user = ref.read(currentUserProvider)!;
    try {
      final file = File(path);
      final uuid = const Uuid().v4();
      await SupabaseConfig.client.storage
          .from('voice_messages')
          .upload('$uuid.m4a', file);
      final url = SupabaseConfig.client.storage
          .from('voice_messages')
          .getPublicUrl('$uuid.m4a');
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': user.id,
        'message_type': 'voice',
        'media_url': url,
      });
    } catch (e) {
      debugPrint('Send voice error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUserAvatar != null
                  ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                  : null,
              backgroundColor: primaryBlue.withOpacity(0.1),
              child: widget.otherUserAvatar == null
                  ? const Icon(Icons.person, size: 18, color: primaryBlue)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/user/${widget.otherUserId}'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMine = msg.senderId == currentUserId;
                      return _MessageBubble(
                        message: msg,
                        isMine: isMine,
                        index: i,
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: dividerColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera_outlined, color: primaryBlue),
              onPressed: _sendImage,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Votre message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            _msgCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: _sendText,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                    ),
                  )
                : GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isRecording ? primaryPink : primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final int index;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.isProductReply) _buildProductReply(context),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: message.isImage
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine
                      ? primaryBlue
                      : Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                ),
                child: _buildContent(context),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              timeago.format(message.createdAt, locale: 'fr'),
              style: const TextStyle(fontSize: 10, color: textSecondary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 20));
  }

  Widget _buildContent(BuildContext context) {
    if (message.isText) {
      return Text(
        message.content ?? '',
        style: TextStyle(
            color: isMine ? Colors.white : null, fontSize: 15),
      );
    }
    if (message.isImage && message.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
        ),
      );
    }
    if (message.isVoice && message.mediaUrl != null) {
      return _VoicePlayer(url: message.mediaUrl!, isMine: isMine);
    }
    if (message.isProductReply) {
      return const SizedBox.shrink();
    }
    return Text(message.content ?? '',
        style: TextStyle(color: isMine ? Colors.white : null));
  }

  Widget _buildProductReply(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (message.productImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: message.productImageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.productTitle ?? 'Article',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.productPrice != null)
                  Text(
                    '${message.productPrice!.toStringAsFixed(0)} TND',
                    style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoicePlayer extends StatefulWidget {
  final String url;
  final bool isMine;

  const _VoicePlayer({required this.url, required this.isMine});

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.setUrl(widget.url);
      await _player.play();
      setState(() => _isPlaying = true);
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Icon(
            _isPlaying ? Icons.pause_circle : Icons.play_circle,
            color: widget.isMine ? Colors.white : primaryBlue,
            size: 36,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Message vocal',
          style: TextStyle(color: widget.isMine ? Colors.white : null),
        ),
      ],
    );
  }
}
