class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageType; // text | image | voice | product_reply
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

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'message_type': messageType,
        'content': content,
        'media_url': mediaUrl,
        'product_id': productId,
        'product_title': productTitle,
        'product_image_url': productImageUrl,
        'product_price': productPrice,
      };
}
