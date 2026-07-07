import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

const Color primaryBlue = Color(0xFF6BB8E8);
const Color primaryPink = Color(0xFFF28BA8);
const Color textSecondary = Color(0xFF6B7280);
const Color dividerColor = Color(0xFFF0F0F0);

// ─── Model ────────────────────────────────────────────────────────────────────

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageType;
  final String? content;
  final String? mediaUrl;
  final String? productId;
  final String? productTitle;
  final String? productImageUrl;
  final double? productPrice;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    this.content,
    this.mediaUrl,
    this.productId,
    this.productTitle,
    this.productImageUrl,
    this.productPrice,
    this.isRead = false,
    required this.createdAt,
  });

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isVoice => messageType == 'voice';
  bool get isProductReply => messageType == 'product_reply';

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    senderId: json['sender_id'] as String,
    messageType: json['message_type'] as String? ?? 'text',
    content: json['content'] as String?,
    mediaUrl: json['media_url'] as String?,
    productId: json['product_id'] as String?,
    productTitle: json['product_title'] as String?,
    productImageUrl: json['product_image_url'] as String?,
    productPrice: (json['product_price'] as num?)?.toDouble(),
    isRead: json['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String()),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Future<File?> _pickAndCompress({required ImageSource source}) async {
  final XFile? picked = await ImagePicker().pickImage(
    source: source,
    imageQuality: 100,
    maxWidth: 2048,
    maxHeight: 2048,
    requestFullMetadata: false,
  );
  if (picked == null) return null;
  final dir = await getTemporaryDirectory();
  final target =
      '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final result = await FlutterImageCompress.compressAndGetFile(
    picked.path, target,
    quality: 85, minWidth: 1024, minHeight: 1024,
    format: CompressFormat.jpeg,
  );
  if (result == null) return null;
  return File(result.path);
}

// ─── ChatScreen ───────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
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
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<MessageModel> _messages = [];
  bool _isLoading = true;

  // ─── Voice recording state ─────────────────────────────────────────────────
  bool _isRecording = false;
  bool _isSendingVoice = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  final List<double> _waveformBars = [];
  final _recorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() => setState(() {}));
    _load();
    _subscribeRealtime();
    _resetUnread();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _recordingTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _resetUnread() async {
    try {
      await Supabase.instance.client.rpc(
        'reset_unread_count',
        params: {'conv_id': widget.conversationId},
      );
    } catch (_) {}
  }

  void _subscribeRealtime() {
    Supabase.instance.client
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
        if (!mounted) return;
        if (payload.newRecord.isNotEmpty) {
          final msg = MessageModel.fromJson(
              payload.newRecord.cast<String, dynamic>());
          if (_messages.any((m) => m.id == msg.id)) return;
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      },
    )
        .subscribe();
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _messages.addAll((data as List)
            .map((j) => MessageModel.fromJson(j as Map<String, dynamic>))
            .toList());
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Send text ─────────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser!;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _messages.add(MessageModel(
      id: tempId,
      conversationId: widget.conversationId,
      senderId: user.id,
      messageType: 'text',
      content: text,
      isRead: false,
      createdAt: DateTime.now(),
    )));
    _scrollToBottom();

    try {
      final result = await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': user.id,
        'message_type': 'text',
        'content': text,
      }).select().single();

      if (mounted) {
        final real = MessageModel.fromJson(result);
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) _messages[idx] = real;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _messages.removeWhere((m) => m.id == tempId));
    }
  }

  // ─── Send image ────────────────────────────────────────────────────────────

  Future<void> _sendImage() async {
    final source = await _showImageSourcePicker();
    if (source == null || !mounted) return;
    final file = await _pickAndCompress(source: source);
    if (file == null) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser!;
    final tempId = 'temp_img_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _messages.add(MessageModel(
      id: tempId,
      conversationId: widget.conversationId,
      senderId: user.id,
      messageType: 'image',
      mediaUrl: null,
      isRead: false,
      createdAt: DateTime.now(),
    )));
    _scrollToBottom();

    try {
      final path = '${const Uuid().v4()}.jpg';
      await supabase.storage.from('products').upload(path, file);
      final url = supabase.storage.from('products').getPublicUrl(path);
      final result = await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': user.id,
        'message_type': 'image',
        'media_url': url,
      }).select().single();

      if (mounted) {
        final real = MessageModel.fromJson(result);
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) _messages[idx] = real;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _messages.removeWhere((m) => m.id == tempId));
    }
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt, color: primaryBlue),
                ),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library, color: primaryPink),
                ),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Voice — tap to start, tap to stop ────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording(send: true);
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _recordingDuration = Duration.zero;
    _waveformBars.clear();

    // تحديث الأمواج كل 100ms
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          _recordingDuration += const Duration(milliseconds: 100);
          _waveformBars.add(0.2 + Random().nextDouble() * 0.8);
          if (_waveformBars.length > 40) _waveformBars.removeAt(0);
        });
      }
    });

    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopRecording({required bool send}) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final path = await _recorder.stop();
    if (mounted) setState(() => _isRecording = false);

    if (!send || path == null) {
      // حذف التسجيل
      _waveformBars.clear();
      return;
    }

    if (mounted) setState(() => _isSendingVoice = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser!;
    try {
      final file = File(path);
      final uuid = const Uuid().v4();
      await supabase.storage.from('voice_messages').upload('$uuid.m4a', file);
      final url =
      supabase.storage.from('voice_messages').getPublicUrl('$uuid.m4a');
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': user.id,
        'message_type': 'voice',
        'media_url': url,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Send voice error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingVoice = false;
          _waveformBars.clear();
        });
      }
    }
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () => context.push('/user/${widget.otherUserId}'),
          child: Row(
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
                ? const Center(
                child: CircularProgressIndicator(color: primaryBlue))
                : _messages.isEmpty
                ? const Center(
                child: Text('Démarrez la conversation 👋',
                    style: TextStyle(color: textSecondary)))
                : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

  // ─── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    // أثناء التسجيل — اعرض شريط التسجيل بالكامل
    if (_isRecording) {
      return _buildRecordingBar();
    }

    // أثناء الإرسال
    if (_isSendingVoice) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: dividerColor, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: primaryBlue, strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Envoi...', style: TextStyle(color: textSecondary)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera_outlined, color: primaryBlue),
              onPressed: _sendImage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
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
                ),
              ),
            ),
            const SizedBox(width: 8),
            _msgCtrl.text.trim().isNotEmpty
                ? GestureDetector(
              onTap: _sendText,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                    color: primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.send,
                    color: Colors.white, size: 20),
              ),
            )
                : GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                    color: primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.mic,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Recording bar — مثل Messenger ────────────────────────────────────────

  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // زر حذف
            GestureDetector(
              onTap: () => _stopRecording(send: false),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
              ),
            ),
            const SizedBox(width: 8),

            // أمواج + وقت
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    // نقطة حمراء تنبض
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    // الوقت
                    Text(
                      _fmtDuration(_recordingDuration),
                      style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    // أمواج الصوت
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: _waveformBars
                            .map((h) => Container(
                          width: 3,
                          height: 4 + h * 24,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // زر إرسال
            GestureDetector(
              onTap: () => _stopRecording(send: true),
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                    color: primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final int index;

  const _MessageBubble(
      {required this.message, required this.isMine, required this.index});

  @override
  Widget build(BuildContext context) {
    final isTemp = message.id.startsWith('temp_');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: message.isImage
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine
                      ? isTemp
                      ? primaryBlue.withOpacity(0.65)
                      : primaryBlue
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  timeago.format(message.createdAt, locale: 'fr'),
                  style:
                  const TextStyle(fontSize: 10, color: textSecondary),
                ),
                if (isMine) ...[
                  const SizedBox(width: 3),
                  Icon(
                    isTemp ? Icons.access_time : Icons.done,
                    size: 11,
                    color: textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 20));
  }

  Widget _buildContent(BuildContext context) {
    if (message.isImage && message.mediaUrl == null) {
      return Container(
        width: 220, height: 220,
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2),
        ),
      );
    }
    if (message.isText) {
      return Text(
        message.content ?? '',
        style:
        TextStyle(color: isMine ? Colors.white : null, fontSize: 15),
      );
    }
    if (message.isImage && message.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: 220, height: 220, fit: BoxFit.cover,
        ),
      );
    }
    if (message.isVoice && message.mediaUrl != null) {
      return _VoicePlayer(url: message.mediaUrl!, isMine: isMine);
    }
    if (message.isProductReply) return const SizedBox.shrink();
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
                width: 56, height: 56, fit: BoxFit.cover,
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
                  maxLines: 2, overflow: TextOverflow.ellipsis,
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

// ─── Voice Player ─────────────────────────────────────────────────────────────

class _VoicePlayer extends StatefulWidget {
  final String url;
  final bool isMine;
  const _VoicePlayer({required this.url, required this.isMine});

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _posSub, _durSub, _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _durSub = _player.durationStream.listen(
            (d) { if (mounted && d != null) setState(() => _duration = d); });
    _posSub = _player.positionStream.listen(
            (p) { if (mounted) setState(() => _position = p); });
    _stateSub = _player.playerStateStream.listen((s) {
      if (mounted && s.processingState == ProcessingState.completed) {
        setState(() { _isPlaying = false; _position = Duration.zero; });
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel(); _durSub?.cancel(); _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_player.processingState == ProcessingState.idle) {
        await _player.setUrl(widget.url);
      }
      await _player.play();
      setState(() => _isPlaying = true);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _duration.inSeconds > 0 ? _duration.inSeconds : 1;
    final progress = (_position.inSeconds / total).clamp(0.0, 1.0);
    final color = widget.isMine ? Colors.white : primaryBlue;
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: color, size: 38,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(_position)} / ${_fmt(_duration)}',
                  style: TextStyle(
                      fontSize: 10, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
