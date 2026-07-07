import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

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
const LinearGradient brandGradientVertical = LinearGradient(
  colors: [primaryBlue, primaryPink],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class CategoryItem {
  final String id;
  final String labelFr;
  final String emoji;
  final List<CategoryItem> children;
  const CategoryItem({required this.id, required this.labelFr, required this.emoji, this.children = const []});
}

CategoryItem? _findCategoryById(List<CategoryItem> list, String id) {
  for (final item in list) {
    if (item.id == id) return item;
    final found = _findCategoryById(item.children, id);
    if (found != null) return found;
  }
  return null;
}

String _resolveLastCategory(ProductModel product) {
  final allCats = [..._saleFlat, ..._rentalFlat];
  if (product.categoryItem != null && product.categoryItem!.isNotEmpty) {
    final found = _findCategoryById(allCats, product.categoryItem!);
    if (found != null) return '${found.emoji} ${found.labelFr}';
  }
  if (product.categorySub != null && product.categorySub!.isNotEmpty) {
    final found = _findCategoryById(allCats, product.categorySub!);
    if (found != null) return '${found.emoji} ${found.labelFr}';
  }
  if (product.categoryMain != null && product.categoryMain!.isNotEmpty) {
    final found = _findCategoryById(allCats, product.categoryMain!);
    if (found != null) return '${found.emoji} ${found.labelFr}';
  }
  return product.wilaya;
}

final List<CategoryItem> _saleFlat = [
  CategoryItem(id: 'women', labelFr: 'Femmes', emoji: '👩', children: [
    CategoryItem(id: 'women_clothes', labelFr: 'Vêtements', emoji: '👗', children: [
      CategoryItem(id: 'robes', labelFr: 'Robes', emoji: '👗'),
      CategoryItem(id: 'jupes', labelFr: 'Jupes', emoji: '🩱'),
      CategoryItem(id: 'pantalons_f', labelFr: 'Pantalons', emoji: '👖'),
      CategoryItem(id: 'blouses_f', labelFr: 'Blouses', emoji: '👚'),
      CategoryItem(id: 'chemises_f', labelFr: 'Chemises', emoji: '👔'),
      CategoryItem(id: 'vestes_f', labelFr: 'Vestes', emoji: '🧥'),
      CategoryItem(id: 'manteaux_f', labelFr: 'Manteaux', emoji: '🧥'),
      CategoryItem(id: 'cardigans_f', labelFr: 'Cardigans', emoji: '🧶'),
      CategoryItem(id: 'pulls_f', labelFr: 'Pulls', emoji: '🧶'),
      CategoryItem(id: 'sport_f', labelFr: 'Sport', emoji: '🏃‍♀️'),
      CategoryItem(id: 'sous_vetements_f', labelFr: 'Sous-vêtements', emoji: '🩲'),
      CategoryItem(id: 'pyjamas_f', labelFr: 'Pyjamas', emoji: '🌙'),
      CategoryItem(id: 'maillots_f', labelFr: 'Maillots de bain', emoji: '🩱'),
      CategoryItem(id: 'ensembles_f', labelFr: 'Ensembles', emoji: '👘'),
    ]),
    CategoryItem(id: 'women_shoes', labelFr: 'Chaussures', emoji: '👠', children: [
      CategoryItem(id: 'talons', labelFr: 'Talons', emoji: '👠'),
      CategoryItem(id: 'plates', labelFr: 'Plates', emoji: '🥿'),
      CategoryItem(id: 'sandales_f', labelFr: 'Sandales', emoji: '👡'),
      CategoryItem(id: 'bottes_f', labelFr: 'Bottes', emoji: '👢'),
      CategoryItem(id: 'sneakers_f', labelFr: 'Sneakers', emoji: '👟'),
      CategoryItem(id: 'chaussons_f', labelFr: 'Chaussons', emoji: '🩴'),
    ]),
    CategoryItem(id: 'women_bags', labelFr: 'Sacs', emoji: '👜', children: [
      CategoryItem(id: 'sac_main', labelFr: 'Main', emoji: '👜'),
      CategoryItem(id: 'sac_dos', labelFr: 'Dos', emoji: '🎒'),
      CategoryItem(id: 'sac_voyage', labelFr: 'Voyage', emoji: '🧳'),
      CategoryItem(id: 'portefeuilles_f', labelFr: 'Portefeuilles', emoji: '👛'),
      CategoryItem(id: 'clutch', labelFr: 'Clutch', emoji: '💼'),
    ]),
    CategoryItem(id: 'women_makeup', labelFr: 'Maquillage & Soins', emoji: '💄', children: [
      CategoryItem(id: 'visage', labelFr: 'Maquillage visage', emoji: '🧴'),
      CategoryItem(id: 'yeux', labelFr: 'Maquillage yeux', emoji: '👁️'),
      CategoryItem(id: 'levres', labelFr: 'Maquillage lèvres', emoji: '💋'),
      CategoryItem(id: 'soins_peau', labelFr: 'Soins peau', emoji: '🧖‍♀️'),
      CategoryItem(id: 'soins_cheveux', labelFr: 'Soins cheveux', emoji: '💇‍♀️'),
      CategoryItem(id: 'parfums_f', labelFr: 'Parfums', emoji: '🌸'),
    ]),
    CategoryItem(id: 'women_accessories', labelFr: 'Accessoires', emoji: '💍', children: [
      CategoryItem(id: 'bijoux_f', labelFr: 'Bijoux', emoji: '💎'),
      CategoryItem(id: 'bagues_f', labelFr: 'Bagues', emoji: '💍'),
      CategoryItem(id: 'montres_f', labelFr: 'Montres', emoji: '⌚'),
      CategoryItem(id: 'lunettes_f', labelFr: 'Lunettes', emoji: '🕶️'),
      CategoryItem(id: 'echarpes_f', labelFr: 'Écharpes', emoji: '🧣'),
      CategoryItem(id: 'chapeaux_f', labelFr: 'Chapeaux', emoji: '👒'),
      CategoryItem(id: 'ceintures_f', labelFr: 'Ceintures', emoji: '👜'),
      CategoryItem(id: 'acc_cheveux', labelFr: 'Acc. cheveux', emoji: '🎀'),
    ]),
  ]),
  CategoryItem(id: 'men', labelFr: 'Hommes', emoji: '👨', children: [
    CategoryItem(id: 'men_clothes', labelFr: 'Vêtements', emoji: '👔', children: [
      CategoryItem(id: 'tshirts_m', labelFr: 'T-shirts', emoji: '👕'),
      CategoryItem(id: 'chemises_m', labelFr: 'Chemises', emoji: '👔'),
      CategoryItem(id: 'pantalons_m', labelFr: 'Pantalons', emoji: '👖'),
      CategoryItem(id: 'vestes_m', labelFr: 'Vestes', emoji: '🧥'),
      CategoryItem(id: 'manteaux_m', labelFr: 'Manteaux', emoji: '🧥'),
      CategoryItem(id: 'costumes_m', labelFr: 'Costumes', emoji: '🤵'),
      CategoryItem(id: 'sport_m', labelFr: 'Sport', emoji: '🏃'),
      CategoryItem(id: 'sous_vetements_m', labelFr: 'Sous-vêtements', emoji: '🩲'),
      CategoryItem(id: 'pyjamas_m', labelFr: 'Pyjamas', emoji: '🌙'),
      CategoryItem(id: 'jeans_m', labelFr: 'Jeans', emoji: '👖'),
      CategoryItem(id: 'hoodies_m', labelFr: 'Hoodies', emoji: '🧥'),
      CategoryItem(id: 'sweats_m', labelFr: 'Sweats', emoji: '👕'),
    ]),
    CategoryItem(id: 'men_shoes', labelFr: 'Chaussures', emoji: '👟', children: [
      CategoryItem(id: 'formelles_m', labelFr: 'Formelles', emoji: '👞'),
      CategoryItem(id: 'sneakers_m', labelFr: 'Sneakers', emoji: '👟'),
      CategoryItem(id: 'sandales_m', labelFr: 'Sandales', emoji: '🩴'),
      CategoryItem(id: 'bottes_m', labelFr: 'Bottes', emoji: '👢'),
      CategoryItem(id: 'chaussons_m', labelFr: 'Chaussons', emoji: '🩴'),
    ]),
    CategoryItem(id: 'men_bags', labelFr: 'Sacs', emoji: '🎒', children: [
      CategoryItem(id: 'sac_dos_m', labelFr: 'Dos', emoji: '🎒'),
      CategoryItem(id: 'sac_voyage_m', labelFr: 'Voyage', emoji: '🧳'),
      CategoryItem(id: 'portefeuilles_m', labelFr: 'Portefeuilles', emoji: '👛'),
      CategoryItem(id: 'crossbody_m', labelFr: 'Crossbody', emoji: '💼'),
    ]),
    CategoryItem(id: 'men_accessories', labelFr: 'Accessoires', emoji: '⌚', children: [
      CategoryItem(id: 'montres_m', labelFr: 'Montres', emoji: '⌚'),
      CategoryItem(id: 'lunettes_m', labelFr: 'Lunettes', emoji: '🕶️'),
      CategoryItem(id: 'ceintures_m', labelFr: 'Ceintures', emoji: '🥋'),
      CategoryItem(id: 'cravates_m', labelFr: 'Cravates', emoji: '👔'),
      CategoryItem(id: 'noeuds_m', labelFr: 'Nœuds papillon', emoji: '🎀'),
      CategoryItem(id: 'casquettes_m', labelFr: 'Casquettes', emoji: '🧢'),
    ]),
  ]),
  CategoryItem(id: 'girls', labelFr: 'Filles', emoji: '👧', children: [
    CategoryItem(id: 'girls_clothes', labelFr: 'Vêtements', emoji: '👗', children: [
      CategoryItem(id: 'girls_robes', labelFr: 'Robes', emoji: '👗'),
      CategoryItem(id: 'girls_jupes', labelFr: 'Jupes', emoji: '🩱'),
      CategoryItem(id: 'girls_blouses', labelFr: 'Blouses', emoji: '👚'),
      CategoryItem(id: 'girls_chemises', labelFr: 'Chemises', emoji: '👕'),
      CategoryItem(id: 'girls_pantalons', labelFr: 'Pantalons', emoji: '👖'),
      CategoryItem(id: 'girls_manteaux', labelFr: 'Manteaux', emoji: '🧥'),
      CategoryItem(id: 'girls_vestes', labelFr: 'Vestes', emoji: '🧥'),
      CategoryItem(id: 'girls_sport', labelFr: 'Sport', emoji: '🏃‍♀️'),
      CategoryItem(id: 'girls_sous_vetements', labelFr: 'Sous-vêtements', emoji: '🩲'),
      CategoryItem(id: 'girls_pyjamas', labelFr: 'Pyjamas', emoji: '🌙'),
      CategoryItem(id: 'girls_ensembles', labelFr: 'Ensembles', emoji: '👘'),
    ]),
    CategoryItem(id: 'girls_shoes', labelFr: 'Chaussures', emoji: '👟', children: [
      CategoryItem(id: 'girls_sandales', labelFr: 'Sandales', emoji: '👡'),
      CategoryItem(id: 'girls_bottes', labelFr: 'Bottes', emoji: '👢'),
      CategoryItem(id: 'girls_sneakers', labelFr: 'Sneakers', emoji: '👟'),
      CategoryItem(id: 'girls_ballerines', labelFr: 'Ballerines', emoji: '🩰'),
    ]),
    CategoryItem(id: 'girls_accessories', labelFr: 'Accessoires', emoji: '💎', children: [
      CategoryItem(id: 'girls_acc_cheveux', labelFr: 'Acc. cheveux', emoji: '🎀'),
      CategoryItem(id: 'girls_sacs', labelFr: 'Sacs', emoji: '👜'),
      CategoryItem(id: 'girls_bijoux', labelFr: 'Bijoux enfants', emoji: '💍'),
      CategoryItem(id: 'girls_chapeaux', labelFr: 'Chapeaux', emoji: '🎩'),
    ]),
  ]),
  CategoryItem(id: 'boys', labelFr: 'Garçons', emoji: '👦', children: [
    CategoryItem(id: 'boys_clothes', labelFr: 'Vêtements', emoji: '👕', children: [
      CategoryItem(id: 'boys_tshirts', labelFr: 'T-shirts', emoji: '👕'),
      CategoryItem(id: 'boys_chemises', labelFr: 'Chemises', emoji: '👔'),
      CategoryItem(id: 'boys_pantalons', labelFr: 'Pantalons', emoji: '👖'),
      CategoryItem(id: 'boys_manteaux', labelFr: 'Manteaux', emoji: '🧥'),
      CategoryItem(id: 'boys_vestes', labelFr: 'Vestes', emoji: '🧥'),
      CategoryItem(id: 'boys_sport', labelFr: 'Sport', emoji: '🏃'),
      CategoryItem(id: 'boys_jeans', labelFr: 'Jeans', emoji: '👖'),
      CategoryItem(id: 'boys_sous_vetements', labelFr: 'Sous-vêtements', emoji: '🩲'),
      CategoryItem(id: 'boys_pyjamas', labelFr: 'Pyjamas', emoji: '🌙'),
      CategoryItem(id: 'boys_ensembles', labelFr: 'Ensembles', emoji: '👘'),
    ]),
    CategoryItem(id: 'boys_shoes', labelFr: 'Chaussures', emoji: '👟', children: [
      CategoryItem(id: 'boys_sneakers', labelFr: 'Sneakers', emoji: '👟'),
      CategoryItem(id: 'boys_sandales', labelFr: 'Sandales', emoji: '🩴'),
      CategoryItem(id: 'boys_bottes', labelFr: 'Bottes', emoji: '👢'),
      CategoryItem(id: 'boys_formelles', labelFr: 'Formelles', emoji: '👞'),
    ]),
    CategoryItem(id: 'boys_accessories', labelFr: 'Accessoires', emoji: '🎒', children: [
      CategoryItem(id: 'boys_sacs', labelFr: 'Sacs à dos', emoji: '🎒'),
      CategoryItem(id: 'boys_chapeaux', labelFr: 'Casquettes', emoji: '🧢'),
      CategoryItem(id: 'boys_ceintures', labelFr: 'Ceintures', emoji: '🥋'),
      CategoryItem(id: 'boys_lunettes', labelFr: 'Lunettes', emoji: '🕶️'),
    ]),
  ]),
];

final List<CategoryItem> _rentalFlat = [
  CategoryItem(id: 'women_rental', labelFr: 'Femmes', emoji: '👰', children: [
    CategoryItem(id: 'rental_women_clothes', labelFr: 'Vêtements', emoji: '👗', children: [
      CategoryItem(id: 'robe_mariee', labelFr: 'Robe de mariée', emoji: '👰'),
      CategoryItem(id: 'robe_soiree', labelFr: 'Robe de soirée', emoji: '✨'),
      CategoryItem(id: 'robes_rental', labelFr: 'Robes', emoji: '👗'),
      CategoryItem(id: 'jupes_rental', labelFr: 'Jupes', emoji: '🩱'),
      CategoryItem(id: 'pantalons_rental', labelFr: 'Pantalons', emoji: '👖'),
      CategoryItem(id: 'blouses_rental', labelFr: 'Blouses', emoji: '👚'),
      CategoryItem(id: 'chemises_rental', labelFr: 'Chemises', emoji: '👔'),
      CategoryItem(id: 'vestes_rental', labelFr: 'Vestes', emoji: '🧥'),
      CategoryItem(id: 'manteaux_rental', labelFr: 'Manteaux', emoji: '🧥'),
      CategoryItem(id: 'cardigans_rental', labelFr: 'Cardigans', emoji: '🧶'),
      CategoryItem(id: 'pulls_rental', labelFr: 'Pulls', emoji: '🧶'),
      CategoryItem(id: 'sport_rental', labelFr: 'Sport', emoji: '🏃‍♀️'),
      CategoryItem(id: 'ensembles_rental', labelFr: 'Ensembles', emoji: '👘'),
    ]),
    CategoryItem(id: 'rental_women_shoes', labelFr: 'Chaussures', emoji: '👠', children: [
      CategoryItem(id: 'talons_rental', labelFr: 'Talons', emoji: '👠'),
      CategoryItem(id: 'plates_rental', labelFr: 'Plates', emoji: '🥿'),
      CategoryItem(id: 'sandales_rental_f', labelFr: 'Sandales', emoji: '👡'),
      CategoryItem(id: 'bottes_rental_f', labelFr: 'Bottes', emoji: '👢'),
      CategoryItem(id: 'sneakers_rental_f', labelFr: 'Sneakers', emoji: '👟'),
    ]),
    CategoryItem(id: 'rental_women_bags', labelFr: 'Sacs', emoji: '👜', children: [
      CategoryItem(id: 'bags_rental_f', labelFr: 'Main', emoji: '👜'),
      CategoryItem(id: 'clutch_soiree', labelFr: 'Clutch soirée', emoji: '💼'),
      CategoryItem(id: 'sac_dos_rental_f', labelFr: 'Dos', emoji: '🎒'),
      CategoryItem(id: 'portefeuilles_rental_f', labelFr: 'Portefeuilles', emoji: '👛'),
    ]),
    CategoryItem(id: 'rental_women_accessories', labelFr: 'Accessoires', emoji: '💍', children: [
      CategoryItem(id: 'bijoux_rental_f', labelFr: 'Bijoux', emoji: '💎'),
      CategoryItem(id: 'bagues_rental_f', labelFr: 'Bagues', emoji: '💍'),
      CategoryItem(id: 'montres_rental_f', labelFr: 'Montres', emoji: '⌚'),
      CategoryItem(id: 'lunettes_rental_f', labelFr: 'Lunettes', emoji: '🕶️'),
      CategoryItem(id: 'echarpes_rental', labelFr: 'Écharpes', emoji: '🧣'),
      CategoryItem(id: 'chapeaux_rental', labelFr: 'Chapeaux', emoji: '👒'),
      CategoryItem(id: 'ceintures_rental_f', labelFr: 'Ceintures', emoji: '👜'),
    ]),
  ]),
  CategoryItem(id: 'men_rental', labelFr: 'Hommes', emoji: '🤵', children: [
    CategoryItem(id: 'rental_men_clothes', labelFr: 'Vêtements', emoji: '🤵', children: [
      CategoryItem(id: 'costume_arabe', labelFr: 'Costume arabe', emoji: '🧕'),
      CategoryItem(id: 'djebba', labelFr: 'Djebba arabe', emoji: '👳'),
      CategoryItem(id: 'costumes_formels', labelFr: 'Costume formel', emoji: '🤵'),
      CategoryItem(id: 'tshirts_rental', labelFr: 'T-shirts', emoji: '👕'),
      CategoryItem(id: 'chemises_rental_m', labelFr: 'Chemises', emoji: '👔'),
      CategoryItem(id: 'pantalons_rental_m', labelFr: 'Pantalons', emoji: '👖'),
      CategoryItem(id: 'vestes_rental_m', labelFr: 'Vestes', emoji: '🧥'),
      CategoryItem(id: 'manteaux_rental_m', labelFr: 'Manteaux', emoji: '🧥'),
      CategoryItem(id: 'sport_rental_m', labelFr: 'Sport', emoji: '🏃'),
      CategoryItem(id: 'jeans_rental', labelFr: 'Jeans', emoji: '👖'),
      CategoryItem(id: 'hoodies_rental', labelFr: 'Hoodies', emoji: '🧥'),
      CategoryItem(id: 'sweats_rental', labelFr: 'Sweats', emoji: '👕'),
    ]),
    CategoryItem(id: 'rental_men_shoes', labelFr: 'Chaussures', emoji: '👟', children: [
      CategoryItem(id: 'shoes_rental_m', labelFr: 'Formelles', emoji: '👞'),
      CategoryItem(id: 'sneakers_rental_m', labelFr: 'Sneakers', emoji: '👟'),
      CategoryItem(id: 'sandales_rental_m', labelFr: 'Sandales', emoji: '🩴'),
      CategoryItem(id: 'bottes_rental_m', labelFr: 'Bottes', emoji: '👢'),
    ]),
    CategoryItem(id: 'rental_men_bags', labelFr: 'Sacs', emoji: '🎒', children: [
      CategoryItem(id: 'bags_rental_m', labelFr: 'Dos', emoji: '🎒'),
      CategoryItem(id: 'sac_voyage_rental_m', labelFr: 'Voyage', emoji: '🧳'),
      CategoryItem(id: 'portefeuilles_rental_m', labelFr: 'Portefeuilles', emoji: '👛'),
    ]),
    CategoryItem(id: 'rental_men_accessories', labelFr: 'Accessoires', emoji: '⌚', children: [
      CategoryItem(id: 'accessories_rental_m', labelFr: 'Montres', emoji: '⌚'),
      CategoryItem(id: 'lunettes_rental_m', labelFr: 'Lunettes', emoji: '🕶️'),
      CategoryItem(id: 'ceintures_rental_m', labelFr: 'Ceintures', emoji: '🥋'),
      CategoryItem(id: 'cravates_rental', labelFr: 'Cravates', emoji: '👔'),
      CategoryItem(id: 'noeuds_rental', labelFr: 'Nœuds papillon', emoji: '🎀'),
      CategoryItem(id: 'casquettes_rental', labelFr: 'Casquettes', emoji: '🧢'),
    ]),
  ]),
];

class ProfileModel {
  final String id;
  final String? username;
  final String language;
  final String wilaya;
  final String accountType;
  final String? phone;
  final String? avatarUrl;
  final String? shopType;
  final double? shopLat;
  final double? shopLng;
  final double ratingAvg;
  final int ratingCount;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    this.username,
    required this.language,
    required this.wilaya,
    required this.accountType,
    this.phone,
    this.avatarUrl,
    this.shopType,
    this.shopLat,
    this.shopLng,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    required this.createdAt,
  });

  bool get isShop => accountType == 'shop';
  bool get hasLocation => shopLat != null && shopLng != null;
  String get displayName => username ?? 'Utilisateur';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      language: json['language'] as String? ?? 'fr',
      wilaya: json['wilaya'] as String? ?? '',
      accountType: json['account_type'] as String? ?? 'user',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      shopType: json['shop_type'] as String?,
      shopLat: (json['shop_lat'] as num?)?.toDouble(),
      shopLng: (json['shop_lng'] as num?)?.toDouble(),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
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
    fullName: json['username'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    accountType: json['account_type'] as String? ?? 'user',
    shopType: json['shop_type'] as String?,
    ratingAvg: double.tryParse(json['rating_avg']?.toString() ?? '0') ?? 0.0,
    ratingCount: json['rating_count'] as int? ?? 0,
  );
}

class ProductModel {
  final String id;
  final String userId;
  final String productType;
  final String? categoryMain;
  final String? categorySub;
  final String? categoryItem;
  final String title;
  final String? description;
  final String? size;
  final String condition;
  final bool isOriginal;
  final double price;
  final List<String> imageUrls;
  final String? thumbnailUrl;
  final String wilaya;
  final DateTime publishedAt;
  final ProfileOwner? owner;

  const ProductModel({
    required this.id,
    required this.userId,
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
  String get mainImage => thumbnailUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> images = [];
    if (rawImages is List) images = rawImages.map((e) => e.toString()).toList();
    ProfileOwner? owner;
    if (json['profiles'] != null) owner = ProfileOwner.fromJson(json['profiles'] as Map<String, dynamic>);
    return ProductModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productType: json['product_type'] as String? ?? 'sale',
      categoryMain: json['category_main'] as String?,
      categorySub: json['category_sub'] as String?,
      categoryItem: json['category_item'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      size: json['taille'] as String?,
      condition: json['condition'] as String? ?? 'used',
      isOriginal: json['is_original'] as bool? ?? false,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrls: images,
      thumbnailUrl: json['main_image_url'] as String?,
      wilaya: json['wilaya'] as String? ?? '',
      publishedAt: DateTime.parse(json['published_at'] as String? ?? DateTime.now().toIso8601String()),
      owner: owner,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  const ShimmerBox({super.key, required this.width, required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: Container(width: width, height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(borderRadius))),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(aspectRatio: 1 / 1.2, child: Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))))),
          Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 12, width: double.infinity, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 10, width: 80, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 10, width: 60, color: Colors.white),
          ])),
        ]),
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  final bool showCount;
  const RatingStars({super.key, required this.rating, this.count = 0, this.size = 16, this.showCount = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          if (i < rating.floor()) return Icon(Icons.star, size: size, color: warningColor);
          if (i < rating && rating - i >= 0.5) return Icon(Icons.star_half, size: size, color: warningColor);
          return Icon(Icons.star_border, size: size, color: Colors.grey[300]);
        }),
        if (showCount && count > 0) ...[const SizedBox(width: 4), Text('($count)', style: TextStyle(fontSize: size * 0.75, color: Colors.grey))],
      ],
    );
  }
}

String _formatPrice(double price, {bool isRental = false}) {
  final formatted = price == price.truncateToDouble() ? price.toInt().toString() : price.toStringAsFixed(2);
  return isRental ? '$formatted TND/jour' : '$formatted TND';
}

String _conditionLabel(String condition) {
  const map = {'new': 'Nouveau', 'good_used': 'Bon état', 'used': 'Utilisé'};
  return map[condition] ?? condition;
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  const ProductCard({super.key, required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Card(
        elevation: 2, shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildImage(context), _buildInfo(context, isDark)]),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Hero(
      tag: 'product_${product.id}',
      child: AspectRatio(
        aspectRatio: 1 / 1.2,
        child: Stack(fit: StackFit.expand, children: [
          product.mainImage.isNotEmpty
              ? CachedNetworkImage(imageUrl: product.mainImage, fit: BoxFit.cover,
              placeholder: (_, __) => const ShimmerBox(width: double.infinity, height: double.infinity, borderRadius: 0),
              errorWidget: (_, __, ___) => Container(color: primaryBlue.withOpacity(0.1), child: const Icon(Icons.image_not_supported, color: primaryBlue, size: 40)))
              : Container(color: primaryBlue.withOpacity(0.1), child: const Icon(Icons.image, color: primaryBlue, size: 40)),
          Positioned(top: 8, left: 8, child: _buildBadge(product.isRental ? 'Location' : 'Vente', product.isRental ? primaryPink : primaryBlue)),
          if (product.isOriginal) Positioned(top: 8, right: 8, child: _buildBadge('Original', Colors.amber.shade700)),
        ]),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfo(BuildContext context, bool isDark) {
    final categoryLabel = _resolveLastCategory(product);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Text(_formatPrice(product.price, isRental: product.isRental),
            style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: _conditionColor(product.condition).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4)),
            child: Text(_conditionLabel(product.condition),
                style: TextStyle(fontSize: 10, color: _conditionColor(product.condition), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(categoryLabel, style: const TextStyle(fontSize: 10, color: textSecondary), overflow: TextOverflow.ellipsis),
          ),
        ]),
        if (product.owner != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.store, size: 11, color: textSecondary),
            const SizedBox(width: 2),
            Expanded(child: Text(product.owner!.fullName ?? 'Vendeur',
                style: const TextStyle(fontSize: 10, color: textSecondary), overflow: TextOverflow.ellipsis)),
            if (product.owner!.ratingAvg > 0)
              RatingStars(rating: product.owner!.ratingAvg, size: 10, showCount: false),
          ]),
        ],
      ]),
    );
  }

  Color _conditionColor(String condition) {
    switch (condition) {
      case 'new': return const Color(0xFF43A047);
      case 'good_used': return const Color(0xFF1565C0);
      default: return textSecondary;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// ── NativeAdCard — مع AspectRatio لضمان حجم ثابت دائماً ──────
// ══════════════════════════════════════════════════════════════
final String _nativeAdUnitId = AdsService.nativeAdUnitId;

class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _nativeAd = null);
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.medium),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AspectRatio(
      aspectRatio: 1 / 1.6,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: _isLoaded && _nativeAd != null
            ? AdWidget(ad: _nativeAd!)
            : _buildShimmer(isDark),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
      child: Container(color: Colors.white),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ── UserProfileScreen ──────────────────────────────────────────
// ══════════════════════════════════════════════════════════════
const _ownerSelect = 'profiles(id, username, avatar_url, account_type, shop_type, rating_avg, rating_count)';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _scrollCtrl = ScrollController();
  ProfileModel? _profile;
  final List<ProductModel> _products = [];
  final Set<String> _productIds = {};
  bool _isLoadingProfile = true;
  bool _isLoadingProducts = true;
  bool _hasMore = true;
  int _offset = 0;
  int? _myRating;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300) {
      if (!_isLoadingProducts && _hasMore) _loadProducts();
    }
  }

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client.from('profiles').select().eq('id', widget.userId).maybeSingle();
      if (mounted) setState(() {
        _profile = data != null ? ProfileModel.fromJson(data) : null;
        _isLoadingProfile = false;
      });
      await Future.wait([_loadProducts(), _loadMyRating()]);
    } catch (e) {
      if (mounted) setState(() { _isLoadingProfile = false; _isLoadingProducts = false; });
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoadingProducts && _offset > 0) return;
    if (mounted) setState(() => _isLoadingProducts = true);
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('id, user_id, product_type, category_main, category_sub, category_item, title, condition, is_original, price, main_image_url, published_at, $_ownerSelect')
          .eq('user_id', widget.userId)
          .eq('nsfw_status', 'approved')
          .order('published_at', ascending: false)
          .range(_offset, _offset + 10 - 1);

      final incoming = (data as List)
          .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          final newItems = incoming.where((p) => !_productIds.contains(p.id)).toList();
          for (final p in newItems) {
            _productIds.add(p.id);
            _products.add(p);
          }
          _offset += incoming.length;
          _hasMore = incoming.length == 10;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _loadMyRating() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    try {
      final data = await Supabase.instance.client.from('ratings').select()
          .eq('rater_id', currentUser.id).eq('rated_id', widget.userId).maybeSingle();
      if (data != null && mounted) setState(() => _myRating = data['score'] as int? ?? data['rating'] as int?);
    } catch (_) {}
  }

  Future<void> _openChat() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null || _profile == null) return;
    try {
      final existing = await supabase.from('conversations').select()
          .or('and(participant1_id.eq.${user.id},participant2_id.eq.${widget.userId}),and(participant1_id.eq.${widget.userId},participant2_id.eq.${user.id})')
          .maybeSingle();
      String convId;
      if (existing != null) { convId = existing['id'] as String; }
      else {
        final created = await supabase.from('conversations').insert({'participant1_id': user.id, 'participant2_id': widget.userId}).select().single();
        convId = created['id'] as String;
      }
      if (mounted) context.push('/chat/$convId', extra: {
        'otherUserId': widget.userId,
        'otherUserName': _profile?.displayName ?? 'Utilisateur',
        'otherUserAvatar': _profile?.avatarUrl,
      });
    } catch (e) { if (kDebugMode) debugPrint('Open chat error: $e'); }
  }

  void _openInMaps(double lat, double lng) {
    launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _showRatingDialog() async {
    int tempRating = _myRating ?? 0;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _myRating != null ? 'Modifier votre note' : 'Évaluer cette boutique',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setDialogState(() => tempRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < tempRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: i < tempRating ? warningColor : Colors.grey[300],
                      size: 44,
                    ),
                  ),
                )),
              ),
              if (tempRating > 0) ...[
                const SizedBox(height: 8),
                Text(
                  ['', 'Mauvais', 'Passable', 'Bien', 'Très bien', 'Excellent'][tempRating],
                  style: const TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: tempRating == 0 ? null : () async {
                Navigator.pop(ctx);
                await _submitRating(tempRating);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _myRating != null ? 'Mettre à jour' : 'Envoyer',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(int rating) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('ratings').upsert(
        {'rater_id': user.id, 'rated_id': widget.userId, 'score': rating},
        onConflict: 'rater_id,rated_id',
      );
      if (mounted) {
        setState(() => _myRating = rating);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Évaluation soumise !'), backgroundColor: Colors.green),
        );
      }
      final profileData = await supabase.from('profiles').select().eq('id', widget.userId).single();
      if (mounted) setState(() => _profile = ProfileModel.fromJson(profileData));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: errorColor),
        );
      }
    }
  }

  // ── بناء feedItems مع إعلان نهائي إذا آخر منتج ليس مضاعف 5 ──
  List<dynamic> _buildFeedItems() {
    final items = <dynamic>[];
    for (int i = 0; i < _products.length; i++) {
      items.add(_products[i]);
      if ((i + 1) % 5 == 0) items.add('ad');
    }
    // إعلان نهائي فقط إذا لم يكن عدد المنتجات مضاعف 5
    // (لتجنب إعلانين متتاليين عند مضاعفات 5)
    if (_products.isNotEmpty && _products.length % 5 != 0 && !_hasMore) {
      items.add('ad');
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryBlue)));
    }
    if (_profile == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Profil non trouvé')));
    }

    final profile = _profile!;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnProfile = currentUser?.id == widget.userId;
    final feedItems = _buildFeedItems();

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverAppBar(
            pinned: true, floating: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0, scrolledUnderElevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(child: _buildProfileInfo(context, profile, isOwnProfile)),
          if (_isLoadingProducts && _products.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((_, i) => const ProductCardShimmer(), childCount: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1 / 1.6,
                ),
              ),
            )
          else if (!_isLoadingProducts && _products.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: textSecondary),
                SizedBox(height: 16),
                Text('Aucun article publié', style: TextStyle(color: textSecondary)),
              ])),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, index) {
                    if (index >= feedItems.length) return null;
                    final item = feedItems[index];
                    if (item == 'ad') return const SizedBox.shrink();
                    final product = item as ProductModel;
                    final nextItem = index + 1 < feedItems.length ? feedItems[index + 1] : null;
                    if (index % 2 == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: ProductCard(product: product, index: index)),
                            const SizedBox(width: 8),
                            if (nextItem is ProductModel)
                              Expanded(child: ProductCard(product: nextItem, index: index + 1))
                            else if (nextItem == 'ad')
                              const Expanded(child: NativeAdCard())
                            else
                              const Expanded(child: SizedBox()),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: feedItems.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _isLoadingProducts && _products.isNotEmpty
                ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
            )
                : const SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, ProfileModel profile, bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: profile.avatarUrl != null ? CachedNetworkImageProvider(profile.avatarUrl!) : null,
            child: profile.avatarUrl == null
                ? Icon(profile.isShop ? Icons.store : Icons.person, size: 50, color: Colors.grey.shade400)
                : null,
          ),
          const SizedBox(height: 12),
          Text(profile.displayName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (profile.phone != null && profile.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_outlined, size: 14, color: textSecondary),
                const SizedBox(width: 4),
                Text(profile.phone!, style: const TextStyle(fontSize: 14, color: textSecondary)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isOwnProfile ? null : _showRatingDialog,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(5, (i) {
                  final filled = profile.ratingAvg > 0
                      ? (i < profile.ratingAvg.floor()
                      ? Icons.star_rounded
                      : (i < profile.ratingAvg && profile.ratingAvg % 1 >= 0.3
                      ? Icons.star_half_rounded
                      : Icons.star_border_rounded))
                      : (_myRating != null && i < _myRating!
                      ? Icons.star_rounded
                      : Icons.star_border_rounded);
                  final color = (profile.ratingAvg > 0 || _myRating != null)
                      ? warningColor
                      : Colors.grey[300]!;
                  return Icon(filled, color: color, size: 28);
                }),
                if (profile.ratingAvg > 0) ...[
                  const SizedBox(width: 6),
                  Text(profile.ratingAvg.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13, color: textSecondary)),
                ] else if (!isOwnProfile) ...[
                  const SizedBox(width: 6),
                  Text(_myRating != null ? 'Modifier' : 'Évaluer',
                      style: const TextStyle(fontSize: 12, color: primaryBlue)),
                ],
              ],
            ),
          ),
          if (profile.hasLocation) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => _openInMaps(profile.shopLat!, profile.shopLng!),
              style: TextButton.styleFrom(
                foregroundColor: textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('📍 Voir sur la carte', style: TextStyle(fontSize: 13)),
            ),
          ],
          const SizedBox(height: 14),
          if (!isOwnProfile)
            OutlinedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 16, color: primaryBlue),
              label: const Text('Message', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryBlue),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
            ),
          const SizedBox(height: 20),
          const Divider(height: 1),
        ],
      ),
    );
  }
}