class ProfileModel {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String accountType; // user | shop
  final String? shopType; // clothing | superfripe | rental | accessories
  final String? phone;
  final bool phoneVisible; // owner can hide phone from visitors
  final String wilaya;
  final String language; // ar | fr | en
  final double? latitude;
  final double? longitude;
  final double ratingAvg;
  final int ratingCount;
  final String? fcmToken;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.accountType,
    this.shopType,
    this.phone,
    this.phoneVisible = true,
    required this.wilaya,
    required this.language,
    this.latitude,
    this.longitude,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.fcmToken,
    required this.createdAt,
  });

  bool get isShop => accountType == 'shop';
  bool get hasLocation => latitude != null && longitude != null;
  String get displayName => fullName ?? email;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      accountType: json['account_type'] as String? ?? 'user',
      shopType: json['shop_type'] as String?,
      phone: json['phone'] as String?,
      phoneVisible: json['phone_visible'] as bool? ?? true,
      wilaya: json['wilaya'] as String? ?? '',
      language: json['language'] as String? ?? 'fr',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      fcmToken: json['fcm_token'] as String?,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'account_type': accountType,
        'shop_type': shopType,
        'phone': phone,
        'phone_visible': phoneVisible,
        'wilaya': wilaya,
        'language': language,
        'latitude': latitude,
        'longitude': longitude,
        'fcm_token': fcmToken,
      };

  ProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
    String? phone,
    bool? phoneVisible,
    String? wilaya,
    String? language,
    double? latitude,
    double? longitude,
    double? ratingAvg,
    int? ratingCount,
    String? fcmToken,
  }) {
    return ProfileModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accountType: accountType,
      shopType: shopType,
      phone: phone ?? this.phone,
      phoneVisible: phoneVisible ?? this.phoneVisible,
      wilaya: wilaya ?? this.wilaya,
      language: language ?? this.language,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
