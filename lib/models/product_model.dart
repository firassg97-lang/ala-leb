class ProductModel {
  final String id;
  final String ownerId;
  final String productType; // sale | rental
  final String? categoryMain;
  final String? categorySub;
  final String? categoryItem;
  final String title;
  final String? description;
  final String? size;
  final String condition; // new | good_used | used
  final bool isOriginal;
  final double price;
  final List<String> imageUrls;
  final String? thumbnailUrl;
  final String wilaya;
  final DateTime publishedAt;
  final ProfileOwner? owner;

  const ProductModel({
    required this.id,
    required this.ownerId,
    required this.productType,
    this.categoryMain,
    this.categorySub,
    this.categoryItem,
    required this.title,
    this.description,
    this.size,
    required this.condition,
    this.isOriginal = false,
    required this.price,
    this.imageUrls = const [],
    this.thumbnailUrl,
    required this.wilaya,
    required this.publishedAt,
    this.owner,
  });

  bool get isRental => productType == 'rental';
  String get mainImage =>
      thumbnailUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['image_urls'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    }

    ProfileOwner? owner;
    if (json['profiles'] != null) {
      owner = ProfileOwner.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    return ProductModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      productType: json['product_type'] as String? ?? 'sale',
      categoryMain: json['category_main'] as String?,
      categorySub: json['category_sub'] as String?,
      categoryItem: json['category_item'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      size: json['size'] as String?,
      condition: json['condition'] as String? ?? 'used',
      isOriginal: json['is_original'] as bool? ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrls: images,
      thumbnailUrl: json['thumbnail_url'] as String?,
      wilaya: json['wilaya'] as String? ?? '',
      publishedAt: DateTime.parse(
          json['published_at'] as String? ?? DateTime.now().toIso8601String()),
      owner: owner,
    );
  }

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'product_type': productType,
        'category_main': categoryMain,
        'category_sub': categorySub,
        'category_item': categoryItem,
        'title': title,
        'description': description,
        'size': size,
        'condition': condition,
        'is_original': isOriginal,
        'price': price,
        'image_urls': imageUrls,
        'thumbnail_url': thumbnailUrl,
        'wilaya': wilaya,
      };
}

class ProfileOwner {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String accountType;
  final String? shopType;
  final double ratingAvg;
  final int ratingCount;

  const ProfileOwner({
    required this.id,
    this.fullName,
    this.avatarUrl,
    required this.accountType,
    this.shopType,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  factory ProfileOwner.fromJson(Map<String, dynamic> json) => ProfileOwner(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        accountType: json['account_type'] as String? ?? 'user',
        shopType: json['shop_type'] as String?,
        ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
        ratingCount: json['rating_count'] as int? ?? 0,
      );
}
