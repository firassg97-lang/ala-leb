import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../app_providers.dart';
import '../l10n.dart';

// ══════════════════════════════════════════════════════════════
// ── بيانات التصنيفات لاستخراج التصنيف النهائي ────────────────
// ══════════════════════════════════════════════════════════════
class _CatNode {
  final String id;
  final String labelFr;
  final String emoji;
  final List<_CatNode> children;
  const _CatNode({required this.id, required this.labelFr, required this.emoji, this.children = const []});
}

_CatNode? _findCat(List<_CatNode> list, String id) {
  for (final item in list) {
    if (item.id == id) return item;
    final found = _findCat(item.children, id);
    if (found != null) return found;
  }
  return null;
}

String _resolveLastCategory(ProductModel product, {String lang = 'fr'}) {
  final all = [..._saleCats, ..._rentalCats];

  String _nodeLabel(_CatNode f) {
    if (lang == 'ar') {
      return AppL10n.categoryArLabelById(f.id) ?? f.labelFr;
    }
    return f.labelFr;
  }

  if (product.categoryItem != null && product.categoryItem!.isNotEmpty) {
    final f = _findCat(all, product.categoryItem!);
    if (f != null) return '${f.emoji} ${_nodeLabel(f)}';
  }
  if (product.categorySub != null && product.categorySub!.isNotEmpty) {
    final f = _findCat(all, product.categorySub!);
    if (f != null) return '${f.emoji} ${_nodeLabel(f)}';
  }
  if (product.categoryMain != null && product.categoryMain!.isNotEmpty) {
    final f = _findCat(all, product.categoryMain!);
    if (f != null) return '${f.emoji} ${_nodeLabel(f)}';
  }
  return product.wilaya;
}

final List<_CatNode> _saleCats = [
  _CatNode(id: 'women', labelFr: 'Femmes', emoji: '👩', children: [
    _CatNode(id: 'women_clothes', labelFr: 'Vêtements', emoji: '👗', children: [
      _CatNode(id: 'robes', labelFr: 'Robes', emoji: '👗'),
      _CatNode(id: 'jupes', labelFr: 'Jupes', emoji: '🩱'),
      _CatNode(id: 'pantalons_f', labelFr: 'Pantalons', emoji: '👖'),
      _CatNode(id: 'blouses_f', labelFr: 'Blouses', emoji: '👚'),
      _CatNode(id: 'chemises_f', labelFr: 'Chemises', emoji: '👔'),
      _CatNode(id: 'vestes_f', labelFr: 'Vestes', emoji: '🧥'),
      _CatNode(id: 'manteaux_f', labelFr: 'Manteaux', emoji: '🧥'),
      _CatNode(id: 'cardigans_f', labelFr: 'Cardigans', emoji: '🧶'),
      _CatNode(id: 'pulls_f', labelFr: 'Pulls', emoji: '🧶'),
      _CatNode(id: 'sport_f', labelFr: 'Sport', emoji: '🏃‍♀️'),
      _CatNode(id: 'sous_vetements_f', labelFr: 'Sous-vêtements', emoji: '🩲'),
      _CatNode(id: 'pyjamas_f', labelFr: 'Pyjamas', emoji: '🌙'),
      _CatNode(id: 'maillots_f', labelFr: 'Maillots de bain', emoji: '🩱'),
      _CatNode(id: 'ensembles_f', labelFr: 'Ensembles', emoji: '👘'),
    ]),
    _CatNode(id: 'women_shoes', labelFr: 'Chaussures', emoji: '👠', children: [
      _CatNode(id: 'talons', labelFr: 'Talons', emoji: '👠'),
      _CatNode(id: 'plates', labelFr: 'Plates', emoji: '🥿'),
      _CatNode(id: 'sandales_f', labelFr: 'Sandales', emoji: '👡'),
      _CatNode(id: 'bottes_f', labelFr: 'Bottes', emoji: '👢'),
      _CatNode(id: 'sneakers_f', labelFr: 'Sneakers', emoji: '👟'),
      _CatNode(id: 'chaussons_f', labelFr: 'Chaussons', emoji: '🩴'),
    ]),
    _CatNode(id: 'women_bags', labelFr: 'Sacs', emoji: '👜', children: [
      _CatNode(id: 'sac_main', labelFr: 'Main', emoji: '👜'),
      _CatNode(id: 'sac_dos', labelFr: 'Dos', emoji: '🎒'),
      _CatNode(id: 'sac_voyage', labelFr: 'Voyage', emoji: '🧳'),
      _CatNode(id: 'portefeuilles_f', labelFr: 'Portefeuilles', emoji: '👛'),
      _CatNode(id: 'clutch', labelFr: 'Clutch', emoji: '💼'),
    ]),
    _CatNode(id: 'women_makeup', labelFr: 'Maquillage & Soins', emoji: '💄', children: [
      _CatNode(id: 'visage', labelFr: 'Maquillage visage', emoji: '🧴'),
      _CatNode(id: 'yeux', labelFr: 'Maquillage yeux', emoji: '👁️'),
      _CatNode(id: 'levres', labelFr: 'Maquillage lèvres', emoji: '💋'),
      _CatNode(id: 'soins_peau', labelFr: 'Soins peau', emoji: '🧖‍♀️'),
      _CatNode(id: 'soins_cheveux', labelFr: 'Soins cheveux', emoji: '💇‍♀️'),
      _CatNode(id: 'parfums_f', labelFr: 'Parfums', emoji: '🌸'),
    ]),
    _CatNode(id: 'women_accessories', labelFr: 'Accessoires', emoji: '💍', children: [
      _CatNode(id: 'bijoux_f', labelFr: 'Bijoux', emoji: '💎'),
      _CatNode(id: 'bagues_f', labelFr: 'Bagues', emoji: '💍'),
      _CatNode(id: 'montres_f', labelFr: 'Montres', emoji: '⌚'),
      _CatNode(id: 'lunettes_f', labelFr: 'Lunettes', emoji: '🕶️'),
      _CatNode(id: 'echarpes_f', labelFr: 'Écharpes', emoji: '🧣'),
      _CatNode(id: 'chapeaux_f', labelFr: 'Chapeaux', emoji: '👒'),
      _CatNode(id: 'ceintures_f', labelFr: 'Ceintures', emoji: '👜'),
      _CatNode(id: 'acc_cheveux', labelFr: 'Acc. cheveux', emoji: '🎀'),
    ]),
  ]),
  _CatNode(id: 'men', labelFr: 'Hommes', emoji: '👨', children: [
    _CatNode(id: 'men_clothes', labelFr: 'Vêtements', emoji: '👔', children: [
      _CatNode(id: 'tshirts_m', labelFr: 'T-shirts', emoji: '👕'),
      _CatNode(id: 'chemises_m', labelFr: 'Chemises', emoji: '👔'),
      _CatNode(id: 'pantalons_m', labelFr: 'Pantalons', emoji: '👖'),
      _CatNode(id: 'vestes_m', labelFr: 'Vestes', emoji: '🧥'),
      _CatNode(id: 'manteaux_m', labelFr: 'Manteaux', emoji: '🧥'),
      _CatNode(id: 'costumes_m', labelFr: 'Costumes', emoji: '🤵'),
      _CatNode(id: 'sport_m', labelFr: 'Sport', emoji: '🏃'),
      _CatNode(id: 'sous_vetements_m', labelFr: 'Sous-vêtements', emoji: '🩲'),
      _CatNode(id: 'pyjamas_m', labelFr: 'Pyjamas', emoji: '🌙'),
      _CatNode(id: 'jeans_m', labelFr: 'Jeans', emoji: '👖'),
      _CatNode(id: 'hoodies_m', labelFr: 'Hoodies', emoji: '🧥'),
      _CatNode(id: 'sweats_m', labelFr: 'Sweats', emoji: '👕'),
    ]),
    _CatNode(id: 'men_shoes', labelFr: 'Chaussures', emoji: '👟', children: [
      _CatNode(id: 'formelles_m', labelFr: 'Formelles', emoji: '👞'),
      _CatNode(id: 'sneakers_m', labelFr: 'Sneakers', emoji: '👟'),
      _CatNode(id: 'sandales_m', labelFr: 'Sandales', emoji: '🩴'),
      _CatNode(id: 'bottes_m', labelFr: 'Bottes', emoji: '👢'),
      _CatNode(id: 'chaussons_m', labelFr: 'Chaussons', emoji: '🩴'),
    ]),
    _CatNode(id: 'men_bags', labelFr: 'Sacs', emoji: '🎒', children: [
      _CatNode(id: 'sac_dos_m', labelFr: 'Dos', emoji: '🎒'),
      _CatNode(id: 'sac_voyage_m', labelFr: 'Voyage', emoji: '🧳'),
      _CatNode(id: 'portefeuilles_m', labelFr: 'Portefeuilles', emoji: '👛'),
      _CatNode(id: 'crossbody_m', labelFr: 'Crossbody', emoji: '💼'),
    ]),
    _CatNode(id: 'men_accessories', labelFr: 'Accessoires', emoji: '⌚', children: [
      _CatNode(id: 'montres_m', labelFr: 'Montres', emoji: '⌚'),
      _CatNode(id: 'lunettes_m', labelFr: 'Lunettes', emoji: '🕶️'),
      _CatNode(id: 'ceintures_m', labelFr: 'Ceintures', emoji: '🥋'),
      _CatNode(id: 'cravates_m', labelFr: 'Cravates', emoji: '👔'),
      _CatNode(id: 'noeuds_m', labelFr: 'Nœuds papillon', emoji: '🎀'),
      _CatNode(id: 'casquettes_m', labelFr: 'Casquettes', emoji: '🧢'),
    ]),
  ]),
  _CatNode(id: 'girls', labelFr: 'Filles', emoji: '👧', children: [
    _CatNode(id: 'girls_clothes', labelFr: 'Vêtements', emoji: '👗', children: [
      _CatNode(id: 'girls_robes', labelFr: 'Robes', emoji: '👗'),
      _CatNode(id: 'girls_jupes', labelFr: 'Jupes', emoji: '🩱'),
      _CatNode(id: 'girls_blouses', labelFr: 'Blouses', emoji: '👚'),
      _CatNode(id: 'girls_chemises', labelFr: 'Chemises', emoji: '👕'),
      _CatNode(id: 'girls_pantalons', labelFr: 'Pantalons', emoji: '👖'),
      _CatNode(id: 'girls_manteaux', labelFr: 'Manteaux', emoji: '🧥'),
      _CatNode(id: 'girls_vestes', labelFr: 'Vestes', emoji: '🧥'),
      _CatNode(id: 'girls_sport', labelFr: 'Sport', emoji: '🏃‍♀️'),
      _CatNode(id: 'girls_sous_vetements', labelFr: 'Sous-vêtements', emoji: '🩲'),
      _CatNode(id: 'girls_pyjamas', labelFr: 'Pyjamas', emoji: '🌙'),
      _CatNode(id: 'girls_ensembles', labelFr: 'Ensembles', emoji: '👘'),
    ]),
    _CatNode(id: 'girls_shoes', labelFr: 'Chaussures', emoji: '👟', children: [
      _CatNode(id: 'girls_sandales', labelFr: 'Sandales', emoji: '👡'),
      _CatNode(id: 'girls_bottes', labelFr: 'Bottes', emoji: '👢'),
      _CatNode(id: 'girls_sneakers', labelFr: 'Sneakers', emoji: '👟'),
      _CatNode(id: 'girls_ballerines', labelFr: 'Ballerines', emoji: '🩰'),
    ]),
    _CatNode(id: 'girls_accessories', labelFr: 'Accessoires', emoji: '💎', children: [
      _CatNode(id: 'girls_acc_cheveux', labelFr: 'Acc. cheveux', emoji: '🎀'),
      _CatNode(id: 'girls_sacs', labelFr: 'Sacs', emoji: '👜'),
      _CatNode(id: 'girls_bijoux', labelFr: 'Bijoux enfants', emoji: '💍'),
      _CatNode(id: 'girls_chapeaux', labelFr: 'Chapeaux', emoji: '🎩'),
    ]),
  ]),
  _CatNode(id: 'boys', labelFr: 'Garçons', emoji: '👦', children: [
    _CatNode(id: 'boys_clothes', labelFr: 'Vêtements', emoji: '👕', children: [
      _CatNode(id: 'boys_tshirts', labelFr: 'T-shirts', emoji: '👕'),
      _CatNode(id: 'boys_chemises', labelFr: 'Chemises', emoji: '👔'),
      _CatNode(id: 'boys_pantalons', labelFr: 'Pantalons', emoji: '👖'),
      _CatNode(id: 'boys_manteaux', labelFr: 'Manteaux', emoji: '🧥'),
      _CatNode(id: 'boys_vestes', labelFr: 'Vestes', emoji: '🧥'),
      _CatNode(id: 'boys_sport', labelFr: 'Sport', emoji: '🏃'),
      _CatNode(id: 'boys_jeans', labelFr: 'Jeans', emoji: '👖'),
      _CatNode(id: 'boys_sous_vetements', labelFr: 'Sous-vêtements', emoji: '🩲'),
      _CatNode(id: 'boys_pyjamas', labelFr: 'Pyjamas', emoji: '🌙'),
      _CatNode(id: 'boys_ensembles', labelFr: 'Ensembles', emoji: '👘'),
    ]),
    _CatNode(id: 'boys_shoes', labelFr: 'Chaussures', emoji: '👟', children: [
      _CatNode(id: 'boys_sneakers', labelFr: 'Sneakers', emoji: '👟'),
      _CatNode(id: 'boys_sandales', labelFr: 'Sandales', emoji: '🩴'),
      _CatNode(id: 'boys_bottes', labelFr: 'Bottes', emoji: '👢'),
      _CatNode(id: 'boys_formelles', labelFr: 'Formelles', emoji: '👞'),
    ]),
    _CatNode(id: 'boys_accessories', labelFr: 'Accessoires', emoji: '🎒', children: [
      _CatNode(id: 'boys_sacs', labelFr: 'Sacs à dos', emoji: '🎒'),
      _CatNode(id: 'boys_chapeaux', labelFr: 'Casquettes', emoji: '🧢'),
      _CatNode(id: 'boys_ceintures', labelFr: 'Ceintures', emoji: '🥋'),
      _CatNode(id: 'boys_lunettes', labelFr: 'Lunettes', emoji: '🕶️'),
    ]),
  ]),
];

final List<_CatNode> _rentalCats = [
  _CatNode(id: 'women_rental', labelFr: 'Femmes', emoji: '👰', children: [
    _CatNode(id: 'rental_women_clothes', labelFr: 'Vêtements', emoji: '👗', children: [
      _CatNode(id: 'robe_mariee', labelFr: 'Robe de mariée', emoji: '👰'),
      _CatNode(id: 'robe_soiree', labelFr: 'Robe de soirée', emoji: '✨'),
      _CatNode(id: 'robes_rental', labelFr: 'Robes', emoji: '👗'),
      _CatNode(id: 'jupes_rental', labelFr: 'Jupes', emoji: '🩱'),
      _CatNode(id: 'pantalons_rental', labelFr: 'Pantalons', emoji: '👖'),
      _CatNode(id: 'blouses_rental', labelFr: 'Blouses', emoji: '👚'),
      _CatNode(id: 'chemises_rental', labelFr: 'Chemises', emoji: '👔'),
      _CatNode(id: 'vestes_rental', labelFr: 'Vestes', emoji: '🧥'),
      _CatNode(id: 'manteaux_rental', labelFr: 'Manteaux', emoji: '🧥'),
      _CatNode(id: 'cardigans_rental', labelFr: 'Cardigans', emoji: '🧶'),
      _CatNode(id: 'pulls_rental', labelFr: 'Pulls', emoji: '🧶'),
      _CatNode(id: 'sport_rental', labelFr: 'Sport', emoji: '🏃‍♀️'),
      _CatNode(id: 'ensembles_rental', labelFr: 'Ensembles', emoji: '👘'),
    ]),
    _CatNode(id: 'rental_women_shoes', labelFr: 'Chaussures', emoji: '👠', children: [
      _CatNode(id: 'talons_rental', labelFr: 'Talons', emoji: '👠'),
      _CatNode(id: 'plates_rental', labelFr: 'Plates', emoji: '🥿'),
      _CatNode(id: 'sandales_rental_f', labelFr: 'Sandales', emoji: '👡'),
      _CatNode(id: 'bottes_rental_f', labelFr: 'Bottes', emoji: '👢'),
      _CatNode(id: 'sneakers_rental_f', labelFr: 'Sneakers', emoji: '👟'),
    ]),
    _CatNode(id: 'rental_women_bags', labelFr: 'Sacs', emoji: '👜', children: [
      _CatNode(id: 'bags_rental_f', labelFr: 'Main', emoji: '👜'),
      _CatNode(id: 'clutch_soiree', labelFr: 'Clutch soirée', emoji: '💼'),
      _CatNode(id: 'sac_dos_rental_f', labelFr: 'Dos', emoji: '🎒'),
      _CatNode(id: 'portefeuilles_rental_f', labelFr: 'Portefeuilles', emoji: '👛'),
    ]),
    _CatNode(id: 'rental_women_accessories', labelFr: 'Accessoires', emoji: '💍', children: [
      _CatNode(id: 'bijoux_rental_f', labelFr: 'Bijoux', emoji: '💎'),
      _CatNode(id: 'bagues_rental_f', labelFr: 'Bagues', emoji: '💍'),
      _CatNode(id: 'montres_rental_f', labelFr: 'Montres', emoji: '⌚'),
      _CatNode(id: 'lunettes_rental_f', labelFr: 'Lunettes', emoji: '🕶️'),
      _CatNode(id: 'echarpes_rental', labelFr: 'Écharpes', emoji: '🧣'),
      _CatNode(id: 'chapeaux_rental', labelFr: 'Chapeaux', emoji: '👒'),
      _CatNode(id: 'ceintures_rental_f', labelFr: 'Ceintures', emoji: '👜'),
    ]),
  ]),
  _CatNode(id: 'men_rental', labelFr: 'Hommes', emoji: '🤵', children: [
    _CatNode(id: 'rental_men_clothes', labelFr: 'Vêtements', emoji: '🤵', children: [
      _CatNode(id: 'costume_arabe', labelFr: 'Costume arabe', emoji: '🧕'),
      _CatNode(id: 'djebba', labelFr: 'Djebba arabe', emoji: '👳'),
      _CatNode(id: 'costumes_formels', labelFr: 'Costume formel', emoji: '🤵'),
      _CatNode(id: 'tshirts_rental', labelFr: 'T-shirts', emoji: '👕'),
      _CatNode(id: 'chemises_rental_m', labelFr: 'Chemises', emoji: '👔'),
      _CatNode(id: 'pantalons_rental_m', labelFr: 'Pantalons', emoji: '👖'),
      _CatNode(id: 'vestes_rental_m', labelFr: 'Vestes', emoji: '🧥'),
      _CatNode(id: 'manteaux_rental_m', labelFr: 'Manteaux', emoji: '🧥'),
      _CatNode(id: 'sport_rental_m', labelFr: 'Sport', emoji: '🏃'),
      _CatNode(id: 'jeans_rental', labelFr: 'Jeans', emoji: '👖'),
      _CatNode(id: 'hoodies_rental', labelFr: 'Hoodies', emoji: '🧥'),
      _CatNode(id: 'sweats_rental', labelFr: 'Sweats', emoji: '👕'),
    ]),
    _CatNode(id: 'rental_men_shoes', labelFr: 'Chaussures', emoji: '👟', children: [
      _CatNode(id: 'shoes_rental_m', labelFr: 'Formelles', emoji: '👞'),
      _CatNode(id: 'sneakers_rental_m', labelFr: 'Sneakers', emoji: '👟'),
      _CatNode(id: 'sandales_rental_m', labelFr: 'Sandales', emoji: '🩴'),
      _CatNode(id: 'bottes_rental_m', labelFr: 'Bottes', emoji: '👢'),
    ]),
    _CatNode(id: 'rental_men_bags', labelFr: 'Sacs', emoji: '🎒', children: [
      _CatNode(id: 'bags_rental_m', labelFr: 'Dos', emoji: '🎒'),
      _CatNode(id: 'sac_voyage_rental_m', labelFr: 'Voyage', emoji: '🧳'),
      _CatNode(id: 'portefeuilles_rental_m', labelFr: 'Portefeuilles', emoji: '👛'),
    ]),
    _CatNode(id: 'rental_men_accessories', labelFr: 'Accessoires', emoji: '⌚', children: [
      _CatNode(id: 'accessories_rental_m', labelFr: 'Montres', emoji: '⌚'),
      _CatNode(id: 'lunettes_rental_m', labelFr: 'Lunettes', emoji: '🕶️'),
      _CatNode(id: 'ceintures_rental_m', labelFr: 'Ceintures', emoji: '🥋'),
      _CatNode(id: 'cravates_rental', labelFr: 'Cravates', emoji: '👔'),
      _CatNode(id: 'noeuds_rental', labelFr: 'Nœuds papillon', emoji: '🎀'),
      _CatNode(id: 'casquettes_rental', labelFr: 'Casquettes', emoji: '🧢'),
    ]),
  ]),
];

// ══════════════════════════════════════════════════════════════
// ── Models ────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════
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
  String get mainImage =>
      thumbnailUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> images = [];
    if (rawImages is List) images = rawImages.map((e) => e.toString()).toList();
    ProfileOwner? owner;
    if (json['profiles'] != null) {
      owner = ProfileOwner.fromJson(json['profiles'] as Map<String, dynamic>);
    }
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
      publishedAt: DateTime.parse(
          json['published_at'] as String? ?? DateTime.now().toIso8601String()),
      owner: owner,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ── Shared Widgets ────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════
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
      child: Container(width: width, height: height,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(borderRadius))),
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
          AspectRatio(aspectRatio: 1 / 1.2,
              child: Container(decoration: const BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16))))),
          Padding(padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        if (showCount && count > 0) ...[
          const SizedBox(width: 4),
          Text('($count)', style: TextStyle(fontSize: size * 0.75, color: Colors.grey)),
        ],
      ],
    );
  }
}

String _formatPrice(double price, {bool isRental = false}) {
  final formatted = price == price.truncateToDouble()
      ? price.toInt().toString()
      : price.toStringAsFixed(2);
  if (isRental) return '$formatted TND/jour';
  return '$formatted TND';
}

// ══════════════════════════════════════════════════════════════
// ── ProductCard — التعديل 2: التصنيف النهائي بدل الولاية ──────
// ══════════════════════════════════════════════════════════════
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final int index;

  const ProductCard({super.key, required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: Card(
          elevation: 2, shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildImage(context),
            _buildInfo(context, isDark),
          ]),
        ),
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
              errorWidget: (_, __, ___) => Container(color: primaryBlue.withOpacity(0.1),
                  child: const Icon(Icons.image_not_supported, color: primaryBlue, size: 40)))
              : Container(color: primaryBlue.withOpacity(0.1),
              child: const Icon(Icons.image, color: primaryBlue, size: 40)),
          Positioned(top: 8, left: 8,
              child: _buildBadge(
                  product.isRental
                      ? context.tr('rental_badge')
                      : context.tr('sale_badge'),
                  product.isRental ? primaryPink : primaryBlue)),
          if (product.isOriginal)
            Positioned(top: 8, right: 8,
                child: _buildBadge(
                    context.tr('original_badge'), Colors.amber.shade700)),
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
    final lang = Localizations.localeOf(context).languageCode;
    final categoryLabel = _resolveLastCategory(product, lang: lang);

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
            child: Text(AppL10n.conditionLabel(context, product.condition),
                style: TextStyle(fontSize: 10, color: _conditionColor(product.condition),
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 4),
          // ── التعديل 2: بدون أيقونة location، نص التصنيف مباشرة ──
          Expanded(
            child: Text(categoryLabel,
                style: const TextStyle(fontSize: 10, color: textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        if (product.owner != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.store, size: 11, color: textSecondary),
            const SizedBox(width: 2),
            Expanded(child: Text(product.owner!.fullName ?? context.tr('vendor_label'),
                style: const TextStyle(fontSize: 10, color: textSecondary),
                overflow: TextOverflow.ellipsis)),
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
// ── MyProfileScreen ───────────────────────────────────────────
// ══════════════════════════════════════════════════════════════
const _ownerSelect =
    'profiles(id, username, avatar_url, account_type, shop_type, rating_avg, rating_count)';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _scrollCtrl = ScrollController();
  final List<ProductModel> _products = [];
  final Set<String> _productIds = {};
  bool _isLoadingProducts = true;
  bool _hasMore = true;
  int _offset = 0;
  bool _isUploadingAvatar = false;

  // ── التعديل 3: state للتقييم ──
  int? _myRating;
  bool _isSubmittingRating = false;

  AsyncValue<ProfileModel?> _authState = const AsyncValue.loading();

  static const _shopTypeLabels = {
    'clothing': 'Vente de vêtements',
    'superfripe': 'Super Fripe',
    'rental': 'Location de robes et costumes',
    'accessories': 'Accessoires',
  };

  @override
  void initState() {
    super.initState();
    _loadAuth();
    _loadProducts();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAuth() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _authState = const AsyncValue.data(null));
        return;
      }
      final data = await Supabase.instance.client
          .from('profiles').select().eq('id', user.id).maybeSingle();
      if (mounted) {
        setState(() => _authState =
            AsyncValue.data(data != null ? ProfileModel.fromJson(data) : null));
      }
      // ── التعديل 3: تحميل تقييم المستخدم لنفسه ──
      await _loadMyRating(user.id);
    } catch (e, st) {
      if (mounted) setState(() => _authState = AsyncValue.error(e, st));
    }
  }

  // ── التعديل 3: تحميل التقييم الحالي ──
  Future<void> _loadMyRating(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('ratings')
          .select()
          .eq('rater_id', userId)
          .eq('rated_id', userId)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() => _myRating = data['score'] as int? ?? data['rating'] as int?);
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300) {
      if (!_isLoadingProducts && _hasMore) _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingProducts = false);
      return;
    }
    if (_isLoadingProducts && _offset > 0) return;
    setState(() => _isLoadingProducts = true);
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('id, user_id, product_type, category_main, category_sub, category_item, title, condition, is_original, price, main_image_url, published_at, $_ownerSelect')
          .eq('user_id', user.id)
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
    } catch (_) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_outlined, color: primaryBlue)),
              title: Text(context.tr('take_photo'),
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_outlined, color: primaryPink)),
              title: Text(context.tr('choose_gallery'),
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    try {
      Uint8List? bytes = await FlutterImageCompress.compressWithFile(
          picked.path, quality: 80, minWidth: 400, minHeight: 400);
      if (bytes == null || !mounted) return;
      if (bytes.lengthInBytes > 200 * 1024) {
        bytes = await FlutterImageCompress.compressWithList(bytes, quality: 60);
      }
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser!;
      final path = '${user.id}/avatar.jpg';
      await supabase.storage.from('avatars').uploadBinary(path, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
      final url = supabase.storage.from('avatars').getPublicUrl(path);
      await supabase.from('profiles').update({
        'avatar_url': url,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      await _loadAuth();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${context.tr('error_prefix')}: ${e.toString()}'),
            backgroundColor: errorColor));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _openInMaps(double lat, double lng) {
    launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
        mode: LaunchMode.externalApplication);
  }

  // ── التعديل 3: نفس dialog التقييم من user_page ──
  Future<void> _showRatingDialog() async {
    int tempRating = _myRating ?? 0;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            _myRating != null
                ? context.tr('modify_rating')
                : context.tr('rate_shop'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
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
                ['',
                  context.tr('rating_1'),
                  context.tr('rating_2'),
                  context.tr('rating_3'),
                  context.tr('rating_4'),
                  context.tr('rating_5'),
                ][tempRating],
                style: const TextStyle(color: textSecondary, fontSize: 13),
              ),
            ],
          ]),
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

  // ── التعديل 3: إرسال التقييم ──
  Future<void> _submitRating(int rating) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _isSubmittingRating = true);
    try {
      await supabase.from('ratings').upsert(
        {'rater_id': user.id, 'rated_id': user.id, 'score': rating},
        onConflict: 'rater_id,rated_id',
      );
      if (mounted) {
        setState(() { _myRating = rating; _isSubmittingRating = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Évaluation soumise !'), backgroundColor: successColor),
        );
      }
      // ── إعادة تحميل البروفايل لتحديث المعدل ──
      final profileData = await supabase.from('profiles').select()
          .eq('id', user.id).single();
      if (mounted) setState(() => _authState = AsyncValue.data(ProfileModel.fromJson(profileData)));
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: errorColor),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ── Build ─────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final authState = _authState;

    // ── التعديل 1: الكل في CustomScrollView واحد — الهيدر يسكرول مع المحتوى ──
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ── AppBar مع زر الإعدادات ──
          SliverAppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            floating: true,
            snap: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
                tooltip: context.tr('settings'),
              ),
            ],
          ),

          // ── التعديل 1: الهيدر كـ SliverToBoxAdapter يسكرول مع المحتوى ──
          SliverToBoxAdapter(
            child: authState.when(
              loading: () => _buildShimmer(),
              error: (_, __) => const SizedBox.shrink(),
              data: (profile) => profile != null
                  ? _buildProfileInfo(profile)
                  : const SizedBox.shrink(),
            ),
          ),

          // ── المنتجات ──
          if (_isLoadingProducts && _products.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                        (_, __) => const ProductCardShimmer(), childCount: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8,
                    childAspectRatio: 1 / 1.6),
              ),
            )
          else if (!_isLoadingProducts && _products.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 96, height: 96,
                        decoration: BoxDecoration(color: primaryBlue.withOpacity(0.08),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.add_shopping_cart_outlined, size: 48, color: primaryBlue)),
                    const SizedBox(height: 20),
                    Text(context.tr('no_published'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(context.tr('start_selling'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textSecondary, fontSize: 14)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/add-product'),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(context.tr('add_first'),
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ]),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductCard(product: _products[i], index: i),
                    childCount: _products.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8,
                    childAspectRatio: 1 / 1.6),
              ),
            ),

          SliverToBoxAdapter(
            child: _isLoadingProducts && _products.isNotEmpty
                ? const Padding(padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)))
                : const SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(children: [
        ShimmerBox(width: 90, height: 90, borderRadius: 45),
        const SizedBox(height: 16),
        ShimmerBox(width: 160, height: 20, borderRadius: 8),
        const SizedBox(height: 10),
        ShimmerBox(width: 120, height: 14, borderRadius: 6),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildProfileInfo(ProfileModel profile) {
    final phone = profile.phone;
    final hasPhone = phone != null && phone.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(children: [
        // ── Avatar ──
        Stack(clipBehavior: Clip.none, children: [
          _isUploadingAvatar
              ? Container(width: 90, height: 90,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest),
              child: const Center(child: CircularProgressIndicator(color: primaryBlue, strokeWidth: 2)))
              : CircleAvatar(
            radius: 45,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            backgroundImage: profile.avatarUrl != null
                ? CachedNetworkImageProvider(profile.avatarUrl!)
                : const AssetImage('assets/images/lebesty_logo.png') as ImageProvider,
          ),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isUploadingAvatar ? Colors.grey : primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
          ),
        ]),

        const SizedBox(height: 12),

        // ── Username ──
        Text(profile.username ?? 'Utilisateur',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),

        // ── Shop type badge ──
        if (profile.isShop && profile.shopType != null && profile.shopType!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(20)),
            child: Text(_shopTypeLabels[profile.shopType] ?? profile.shopType!,
                style: const TextStyle(fontSize: 12, color: textSecondary)),
          ),
        ],

        // ── Phone ──
        if (hasPhone) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.phone_outlined, size: 16, color: textSecondary),
            const SizedBox(width: 6),
            Text(phone, style: const TextStyle(fontSize: 15, color: textPrimary)),
          ]),
        ],

        // ── Voir sur la carte ──
        if (profile.hasLocation) ...[
          const SizedBox(height: 2),
          TextButton(
            onPressed: () => _openInMaps(profile.shopLat!, profile.shopLng!),
            style: TextButton.styleFrom(foregroundColor: textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('📍 Voir sur la carte', style: TextStyle(fontSize: 13)),
          ),
        ],

        // ── التعديل 3: Rating قابل للضغط لتقييم نفسه ──
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isSubmittingRating ? null : _showRatingDialog,
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
                return Icon(filled, color: color, size: 24);
              }),
              const SizedBox(width: 6),
              if (profile.ratingCount > 0) ...[
                Text(profile.ratingAvg.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('(${profile.ratingCount} avis)',
                    style: const TextStyle(fontSize: 13, color: textSecondary)),
              ] else ...[
                Text(_myRating != null ? 'Modifier' : 'Évaluer',
                    style: const TextStyle(fontSize: 12, color: primaryBlue)),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}