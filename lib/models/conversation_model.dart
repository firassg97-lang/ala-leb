class ConversationModel {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final String? lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final OtherParticipant? otherUser;

  const ConversationModel({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage,
    this.lastMessageType,
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
      lastMessageType: json['last_message_type'] as String?,
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
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        accountType: json['account_type'] as String? ?? 'user',
      );

  String get displayName => fullName ?? 'User';
}
