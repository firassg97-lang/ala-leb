import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

const Color primaryBlue = Color(0xFF6BB8E8);
const Color primaryPink = Color(0xFFF28BA8);
const Color backgroundLight = Color(0xFFFFFFFF);
const Color backgroundDark = Color(0xFF121212);
const Color surfaceLight = Color(0xFFF8F9FA);
const Color surfaceDark = Color(0xFF1E1E1E);
const Color cardDark = Color(0xFF2A2A2A);
const Color textPrimary = Color(0xFF1A1A2E);
const Color textSecondary = Color(0xFF6B7280);
const Color dividerColor = Color(0xFFF0F0F0);
const Color errorColor = Color(0xFFE53935);
const Color successColor = Color(0xFF43A047);
const Color warningColor = Color(0xFFFFA726);
const LinearGradient brandGradient = LinearGradient(
  colors: [primaryBlue, primaryPink],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor:
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
        title: Container(height: 12, color: Colors.white),
        subtitle: Container(
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            color: Colors.white),
      ),
    );
  }
}

class ConversationModel {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final String? lastMessage;
  final String? lastMessageSenderId; // FIX: أضفنا معرف آخر مرسل
  final DateTime? lastMessageAt;
  final int unreadCount;
  final OtherParticipant? otherUser;

  const ConversationModel({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherUser,
  });

  factory ConversationModel.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    final p1 = json['participant1_id'] as String;
    final p2 = json['participant2_id'] as String;

    OtherParticipant? other;
    final otherJson = json['participant1_id'] == currentUserId
        ? json['profile2']
        : json['profile1'];
    if (otherJson != null) {
      other = OtherParticipant.fromJson(otherJson as Map<String, dynamic>);
    }

    return ConversationModel(
      id: json['id'] as String,
      participant1Id: p1,
      participant2Id: p2,
      lastMessage: json['last_message'] as String?,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      otherUser: other,
    );
  }
}

class OtherParticipant {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String accountType;

  const OtherParticipant({
    required this.id,
    this.fullName,
    this.avatarUrl,
    required this.accountType,
  });

  factory OtherParticipant.fromJson(Map<String, dynamic> json) =>
      OtherParticipant(
        id: json['id'] as String,
        fullName: json['username'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        accountType: json['account_type'] as String? ?? 'user',
      );

  String get displayName => fullName ?? 'User';
}

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    Supabase.instance.client
        .channel('conversations_${user.id}')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'conversations',
      callback: (_) => _load(),
    )
        .subscribe();
  }

  Future<void> _load() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await supabase
          .from('conversations')
          .select('''
            *,
            profile1:profiles!conversations_participant1_id_fkey(id, username, avatar_url, account_type),
            profile2:profiles!conversations_participant2_id_fkey(id, username, avatar_url, account_type)
          ''')
          .or('participant1_id.eq.${user.id},participant2_id.eq.${user.id}')
          .order('last_message_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _conversations = (data as List)
            .map((j) => ConversationModel.fromJson(
            j as Map<String, dynamic>, user.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? ListView.builder(
        itemCount: 8,
        itemBuilder: (_, i) => const ListItemShimmer(),
      )
          : _conversations.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: textSecondary),
            SizedBox(height: 16),
            Text('Aucun message',
                style:
                TextStyle(color: textSecondary, fontSize: 16)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        color: primaryBlue,
        child: ListView.builder(
          itemCount: _conversations.length,
          itemBuilder: (_, i) {
            final conv = _conversations[i];
            return _ConversationTile(
              conversation: conv,
              index: i,
              currentUserId: currentUserId,
              onReturn: _load,
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final int index;
  final String currentUserId;
  final VoidCallback onReturn;

  const _ConversationTile({
    required this.conversation,
    required this.index,
    required this.currentUserId,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherUser;
    final lastMsgAt = conversation.lastMessageAt;

    // FIX: لا تعرض badge إذا آخر رسالة أرسلها المستخدم الحالي
    final iSentLastMessage =
        conversation.lastMessageSenderId == currentUserId;
    final hasUnread =
        conversation.unreadCount > 0 && !iSentLastMessage;

    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: other?.avatarUrl != null
                ? CachedNetworkImageProvider(other!.avatarUrl!)
                : null,
            backgroundColor: primaryBlue.withOpacity(0.1),
            child: other?.avatarUrl == null
                ? Icon(
              other?.accountType == 'shop'
                  ? Icons.store
                  : Icons.person,
              color: primaryBlue,
            )
                : null,
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        other?.displayName ?? 'Utilisateur',
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'Démarrer une conversation',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? textPrimary : textSecondary,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMsgAt != null)
            Text(
              timeago.format(lastMsgAt, locale: 'fr'),
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? primaryBlue : textSecondary,
                fontWeight:
                hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      onTap: () async {
        await context.push('/chat/${conversation.id}', extra: {
          'otherUserId': other?.id ?? '',
          'otherUserName': other?.displayName ?? 'Utilisateur',
          'otherUserAvatar': other?.avatarUrl,
        });
        onReturn();
      },
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
  }
}
