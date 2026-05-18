import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../shared/models/conversation_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    SupabaseConfig.client
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
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final data = await SupabaseConfig.client
          .from('conversations')
          .select('''
            *,
            profile1:profiles!conversations_participant1_id_fkey(id, full_name, avatar_url, account_type),
            profile2:profiles!conversations_participant2_id_fkey(id, full_name, avatar_url, account_type)
          ''')
          .or('participant1_id.eq.${user.id},participant2_id.eq.${user.id}')
          .order('last_message_at', ascending: false);

      setState(() {
        _conversations = (data as List)
            .map((j) =>
                ConversationModel.fromJson(j as Map<String, dynamic>, user.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          style: TextStyle(color: textSecondary, fontSize: 16)),
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

  const _ConversationTile({
    required this.conversation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherUser;
    final lastMsgAt = conversation.lastMessageAt;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: other?.avatarUrl != null
            ? CachedNetworkImageProvider(other!.avatarUrl!)
            : null,
        backgroundColor: primaryBlue.withOpacity(0.1),
        child: other?.avatarUrl == null
            ? Icon(
                other?.accountType == 'shop' ? Icons.store : Icons.person,
                color: primaryBlue,
              )
            : null,
      ),
      title: Text(
        other?.displayName ?? 'Utilisateur',
        style: TextStyle(
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'Démarrer une conversation',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conversation.unreadCount > 0 ? textPrimary : textSecondary,
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.w500
              : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMsgAt != null)
            Text(
              timeago.format(lastMsgAt, locale: 'fr'),
              style: const TextStyle(fontSize: 11, color: textSecondary),
            ),
          if (conversation.unreadCount > 0) ...[
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
      onTap: () => context.push('/chat/${conversation.id}', extra: {
        'otherUserId': other?.id ?? '',
        'otherUserName': other?.displayName ?? 'Utilisateur',
        'otherUserAvatar': other?.avatarUrl,
      }),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
  }
}
