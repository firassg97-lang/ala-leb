import 'package:flutter/material.dart';

/// Single source of truth for all category data.
/// Used by: Add Product screen, Filter bottom sheet, Search screen.
class CategoryItem {
  final String id;
  final String labelAr;
  final String labelFr;
  final Color color;
  final IconData icon;
  final String emoji;

  /// True for premium/special rental items (★) — displayed with gold highlight.
  final bool isSpecial;
  final List<CategoryItem> children;

  const CategoryItem({
    required this.id,
    required this.labelAr,
    required this.labelFr,
    required this.color,
    required this.icon,
    this.emoji = '🏷️',
    this.isSpecial = false,
    this.children = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SALE CATEGORIES (للبيع)
// ─────────────────────────────────────────────────────────────────────────────

const _womenColor = Color(0xFFE91E8C);
const _menColor = Color(0xFF1565C0);
const _girlsColor = Color(0xFFAD1457);
const _boysColor = Color(0xFF0277BD);
const _rentalWomenColor = Color(0xFFC2185B);

final List<CategoryItem> saleCategories = [
  // ── النساء ──────────────────────────────────────────────────────────────────
  CategoryItem(
    id: 'women',
    labelAr: 'النساء',
    labelFr: 'Femmes',
    color: _womenColor,
    icon: Icons.woman,
    emoji: '👩',
    children: [
      CategoryItem(
        id: 'women_clothes',
        labelAr: 'الملابس',
        labelFr: 'Vêtements',
        color: _womenColor,
        icon: Icons.checkroom,
        emoji: '👗',
        children: [
          CategoryItem(id: 'robes', labelAr: 'فساتين', labelFr: 'Robes', color: _womenColor, icon: Icons.checkroom, emoji: '👗'),
          CategoryItem(id: 'jupes', labelAr: 'تنانير', labelFr: 'Jupes', color: _womenColor, icon: Icons.checkroom, emoji: '🩱'),
          CategoryItem(id: 'pantalons_f', labelAr: 'بنطلونات', labelFr: 'Pantalons', color: _womenColor, icon: Icons.checkroom, emoji: '👖'),
          CategoryItem(id: 'blouses', labelAr: 'بلوزات وقمصان', labelFr: 'Blouses & Chemises', color: _womenColor, icon: Icons.checkroom, emoji: '👚'),
          CategoryItem(id: 'vestes_f', labelAr: 'جاكيتات ومعاطف', labelFr: 'Vestes & Manteaux', color: _womenColor, icon: Icons.checkroom, emoji: '🧥'),
          CategoryItem(id: 'cardigans', labelAr: 'سترات وكارديغان', labelFr: 'Cardigans & Pulls', color: _womenColor, icon: Icons.checkroom, emoji: '🧶'),
          CategoryItem(id: 'sport_f', labelAr: 'ملابس رياضية', labelFr: 'Sport', color: _womenColor, icon: Icons.sports, emoji: '🏃‍♀️'),
          CategoryItem(id: 'sous_vetements_f', labelAr: 'ملابس داخلية وبيجامات', labelFr: 'Sous-vêtements & Pyjamas', color: _womenColor, icon: Icons.checkroom, emoji: '🩲'),
          CategoryItem(id: 'maillots_f', labelAr: 'ملابس سباحة', labelFr: 'Maillots de bain', color: _womenColor, icon: Icons.pool, emoji: '🩱'),
          CategoryItem(id: 'ensembles_f', labelAr: 'طقم / أنسامبل', labelFr: 'Ensembles', color: _womenColor, icon: Icons.checkroom, emoji: '👘'),
        ],
      ),
      CategoryItem(
        id: 'women_shoes',
        labelAr: 'الأحذية',
        labelFr: 'Chaussures',
        color: _womenColor,
        icon: Icons.man,
        emoji: '👠',
        children: [
          CategoryItem(id: 'talons', labelAr: 'كعب عالي', labelFr: 'Talons', color: _womenColor, icon: Icons.man, emoji: '👠'),
          CategoryItem(id: 'plates', labelAr: 'أحذية مسطحة', labelFr: 'Plates', color: _womenColor, icon: Icons.man, emoji: '🥿'),
          CategoryItem(id: 'sandales_f', labelAr: 'صنادل', labelFr: 'Sandales', color: _womenColor, icon: Icons.man, emoji: '👡'),
          CategoryItem(id: 'bottes_f', labelAr: 'بوتات', labelFr: 'Bottes', color: _womenColor, icon: Icons.man, emoji: '👢'),
          CategoryItem(id: 'sneakers_f', labelAr: 'رياضي / سنيكرز', labelFr: 'Sneakers', color: _womenColor, icon: Icons.man, emoji: '👟'),
          CategoryItem(id: 'chaussons_f', labelAr: 'شبشب / صنادل منزلية', labelFr: 'Chaussons', color: _womenColor, icon: Icons.man, emoji: '🩴'),
        ],
      ),
      CategoryItem(
        id: 'women_bags',
        labelAr: 'الحقائب',
        labelFr: 'Sacs',
        color: _womenColor,
        icon: Icons.shopping_bag,
        emoji: '👜',
        children: [
          CategoryItem(id: 'sac_main', labelAr: 'حقائب يد', labelFr: 'Main', color: _womenColor, icon: Icons.shopping_bag, emoji: '👜'),
          CategoryItem(id: 'sac_dos', labelAr: 'حقائب ظهر', labelFr: 'Dos', color: _womenColor, icon: Icons.shopping_bag, emoji: '🎒'),
          CategoryItem(id: 'sac_voyage', labelAr: 'حقائب سفر', labelFr: 'Voyage', color: _womenColor, icon: Icons.luggage, emoji: '🧳'),
          CategoryItem(id: 'portefeuilles_f', labelAr: 'محافظ', labelFr: 'Portefeuilles', color: _womenColor, icon: Icons.account_balance_wallet, emoji: '👛'),
          CategoryItem(id: 'clutch', labelAr: 'كلتش', labelFr: 'Clutch', color: _womenColor, icon: Icons.shopping_bag, emoji: '💼'),
        ],
      ),
      CategoryItem(
        id: 'women_makeup',
        labelAr: 'المكياج والعناية',
        labelFr: 'Maquillage & Soins',
        color: _womenColor,
        icon: Icons.face_retouching_natural,
        emoji: '💄',
        children: [
          CategoryItem(id: 'visage', labelAr: 'مكياج الوجه', labelFr: 'Maquillage visage', color: _womenColor, icon: Icons.face, emoji: '🧴'),
          CategoryItem(id: 'yeux', labelAr: 'مكياج العيون', labelFr: 'Maquillage yeux', color: _womenColor, icon: Icons.remove_red_eye, emoji: '👁️'),
          CategoryItem(id: 'levres', labelAr: 'مكياج الشفاه', labelFr: 'Maquillage lèvres', color: _womenColor, icon: Icons.face, emoji: '💋'),
          CategoryItem(id: 'soins_peau', labelAr: 'عناية بالبشرة', labelFr: 'Soins peau', color: _womenColor, icon: Icons.spa, emoji: '🧖‍♀️'),
          CategoryItem(id: 'soins_cheveux', labelAr: 'عناية بالشعر', labelFr: 'Soins cheveux', color: _womenColor, icon: Icons.dry, emoji: '💇‍♀️'),
          CategoryItem(id: 'parfums_f', labelAr: 'عطور', labelFr: 'Parfums', color: _womenColor, icon: Icons.local_florist, emoji: '🌸'),
        ],
      ),
      CategoryItem(
        id: 'women_accessories',
        labelAr: 'الإكسسوارات',
        labelFr: 'Accessoires',
        color: _womenColor,
        icon: Icons.diamond,
        emoji: '💍',
        children: [
          CategoryItem(id: 'bijoux', labelAr: 'مجوهرات وخواتم', labelFr: 'Bijoux & Bagues', color: _womenColor, icon: Icons.diamond, emoji: '💍'),
          CategoryItem(id: 'montres_f', labelAr: 'ساعات', labelFr: 'Montres', color: _womenColor, icon: Icons.watch, emoji: '⌚'),
          CategoryItem(id: 'lunettes_f', labelAr: 'نظارات', labelFr: 'Lunettes', color: _womenColor, icon: Icons.visibility, emoji: '🕶️'),
          CategoryItem(id: 'echarpes', labelAr: 'أوشحة وقبعات', labelFr: 'Écharpes & Chapeaux', color: _womenColor, icon: Icons.ac_unit, emoji: '🧣'),
          CategoryItem(id: 'ceintures_f', labelAr: 'أحزمة', labelFr: 'Ceintures', color: _womenColor, icon: Icons.horizontal_rule, emoji: '👒'),
          CategoryItem(id: 'acc_cheveux', labelAr: 'إكسسوارات الشعر', labelFr: 'Acc. cheveux', color: _womenColor, icon: Icons.face_retouching_natural, emoji: '🎀'),
        ],
      ),
    ],
  ),

  // ── الرجال ──────────────────────────────────────────────────────────────────
  CategoryItem(
    id: 'men',
    labelAr: 'الرجال',
    labelFr: 'Hommes',
    color: _menColor,
    icon: Icons.man,
    emoji: '👨',
    children: [
      CategoryItem(
        id: 'men_clothes',
        labelAr: 'الملابس',
        labelFr: 'Vêtements',
        color: _menColor,
        icon: Icons.checkroom,
        emoji: '👔',
        children: [
          CategoryItem(id: 'tshirts', labelAr: 'تيشيرتات وقمصان', labelFr: 'T-shirts & Chemises', color: _menColor, icon: Icons.checkroom, emoji: '👕'),
          CategoryItem(id: 'pantalons_m', labelAr: 'بنطلونات', labelFr: 'Pantalons', color: _menColor, icon: Icons.checkroom, emoji: '👖'),
          CategoryItem(id: 'vestes_m', labelAr: 'جاكيتات ومعاطف', labelFr: 'Vestes & Manteaux', color: _menColor, icon: Icons.checkroom, emoji: '🧥'),
          CategoryItem(id: 'costumes', labelAr: 'بدلات رسمية', labelFr: 'Costumes', color: _menColor, icon: Icons.checkroom, emoji: '🤵'),
          CategoryItem(id: 'sport_m', labelAr: 'ملابس رياضية', labelFr: 'Sport', color: _menColor, icon: Icons.sports, emoji: '🏃'),
          CategoryItem(id: 'sous_vetements_m', labelAr: 'ملابس داخلية وبيجامات', labelFr: 'Sous-vêtements & Pyjamas', color: _menColor, icon: Icons.checkroom, emoji: '🩲'),
          CategoryItem(id: 'jeans', labelAr: 'جينز', labelFr: 'Jeans', color: _menColor, icon: Icons.checkroom, emoji: '👖'),
          CategoryItem(id: 'hoodies', labelAr: 'هودي وسويتشيرت', labelFr: 'Hoodies & Sweats', color: _menColor, icon: Icons.checkroom, emoji: '🧥'),
        ],
      ),
      CategoryItem(
        id: 'men_shoes',
        labelAr: 'الأحذية',
        labelFr: 'Chaussures',
        color: _menColor,
        icon: Icons.man,
        emoji: '👟',
        children: [
          CategoryItem(id: 'formelles', labelAr: 'أحذية رسمية', labelFr: 'Formelles', color: _menColor, icon: Icons.man, emoji: '👞'),
          CategoryItem(id: 'sneakers_m', labelAr: 'رياضي / سنيكرز', labelFr: 'Sneakers', color: _menColor, icon: Icons.man, emoji: '👟'),
          CategoryItem(id: 'sandales_m', labelAr: 'صنادل', labelFr: 'Sandales', color: _menColor, icon: Icons.man, emoji: '🩴'),
          CategoryItem(id: 'bottes_m', labelAr: 'بوتات', labelFr: 'Bottes', color: _menColor, icon: Icons.man, emoji: '👢'),
          CategoryItem(id: 'chaussons_m', labelAr: 'شبشب / صنادل منزلية', labelFr: 'Chaussons', color: _menColor, icon: Icons.man, emoji: '🩴'),
        ],
      ),
      CategoryItem(
        id: 'men_bags',
        labelAr: 'الحقائب',
        labelFr: 'Sacs',
        color: _menColor,
        icon: Icons.shopping_bag,
        emoji: '🎒',
        children: [
          CategoryItem(id: 'sac_dos_m', labelAr: 'حقائب ظهر', labelFr: 'Dos', color: _menColor, icon: Icons.shopping_bag, emoji: '🎒'),
          CategoryItem(id: 'sac_voyage_m', labelAr: 'حقائب سفر', labelFr: 'Voyage', color: _menColor, icon: Icons.luggage, emoji: '🧳'),
          CategoryItem(id: 'portefeuilles_m', labelAr: 'محافظ', labelFr: 'Portefeuilles', color: _menColor, icon: Icons.account_balance_wallet, emoji: '👛'),
          CategoryItem(id: 'crossbody', labelAr: 'حقائب كروس بودي', labelFr: 'Crossbody', color: _menColor, icon: Icons.shopping_bag, emoji: '💼'),
        ],
      ),
      CategoryItem(
        id: 'men_accessories',
        labelAr: 'الإكسسوارات',
        labelFr: 'Accessoires',
        color: _menColor,
        icon: Icons.watch,
        emoji: '⌚',
        children: [
          CategoryItem(id: 'montres_m', labelAr: 'ساعات', labelFr: 'Montres', color: _menColor, icon: Icons.watch, emoji: '⌚'),
          CategoryItem(id: 'lunettes_m', labelAr: 'نظارات', labelFr: 'Lunettes', color: _menColor, icon: Icons.visibility, emoji: '🕶️'),
          CategoryItem(id: 'ceintures_m', labelAr: 'أحزمة', labelFr: 'Ceintures', color: _menColor, icon: Icons.horizontal_rule, emoji: '🥋'),
          CategoryItem(id: 'cravates', labelAr: 'كرافات وربطات عنق', labelFr: 'Cravates & Nœuds', color: _menColor, icon: Icons.style, emoji: '👔'),
          CategoryItem(id: 'casquettes', labelAr: 'قبعات', labelFr: 'Casquettes', color: _menColor, icon: Icons.sports_baseball, emoji: '🧢'),
        ],
      ),
    ],
  ),

  // ── الفتيات ─────────────────────────────────────────────────────────────────
  CategoryItem(
    id: 'girls',
    labelAr: 'الفتيات',
    labelFr: 'Filles',
    color: _girlsColor,
    icon: Icons.child_care,
    emoji: '👧',
    children: [
      CategoryItem(
        id: 'girls_clothes',
        labelAr: 'الملابس',
        labelFr: 'Vêtements',
        color: _girlsColor,
        icon: Icons.checkroom,
        emoji: '👗',
        children: [
          CategoryItem(id: 'girls_robes', labelAr: 'فساتين', labelFr: 'Robes', color: _girlsColor, icon: Icons.checkroom, emoji: '👗'),
          CategoryItem(id: 'girls_jupes', labelAr: 'تنانير', labelFr: 'Jupes', color: _girlsColor, icon: Icons.checkroom, emoji: '🩱'),
          CategoryItem(id: 'girls_blouses', labelAr: 'بلوزات وقمصان', labelFr: 'Blouses & Chemises', color: _girlsColor, icon: Icons.checkroom, emoji: '👚'),
          CategoryItem(id: 'girls_pantalons', labelAr: 'بنطلونات', labelFr: 'Pantalons', color: _girlsColor, icon: Icons.checkroom, emoji: '👖'),
          CategoryItem(id: 'girls_manteaux', labelAr: 'معاطف وسترات', labelFr: 'Manteaux & Vestes', color: _girlsColor, icon: Icons.checkroom, emoji: '🧥'),
          CategoryItem(id: 'girls_sport', labelAr: 'ملابس رياضية', labelFr: 'Sport', color: _girlsColor, icon: Icons.sports, emoji: '🏃‍♀️'),
          CategoryItem(id: 'girls_pyjamas', labelAr: 'ملابس داخلية وبيجامات', labelFr: 'Sous-vêtements & Pyjamas', color: _girlsColor, icon: Icons.checkroom, emoji: '🩲'),
          CategoryItem(id: 'girls_ensembles', labelAr: 'طقم / أنسامبل', labelFr: 'Ensembles', color: _girlsColor, icon: Icons.checkroom, emoji: '👘'),
        ],
      ),
      CategoryItem(
        id: 'girls_shoes',
        labelAr: 'الأحذية',
        labelFr: 'Chaussures',
        color: _girlsColor,
        icon: Icons.man,
        emoji: '👟',
        children: [
          CategoryItem(id: 'girls_sandales', labelAr: 'صنادل', labelFr: 'Sandales', color: _girlsColor, icon: Icons.man, emoji: '👡'),
          CategoryItem(id: 'girls_bottes', labelAr: 'بوتات', labelFr: 'Bottes', color: _girlsColor, icon: Icons.man, emoji: '👢'),
          CategoryItem(id: 'girls_sneakers', labelAr: 'رياضي / سنيكرز', labelFr: 'Sneakers', color: _girlsColor, icon: Icons.man, emoji: '👟'),
          CategoryItem(id: 'girls_ballerines', labelAr: 'باليرينا', labelFr: 'Ballerines', color: _girlsColor, icon: Icons.man, emoji: '🩰'),
        ],
      ),
      CategoryItem(
        id: 'girls_accessories',
        labelAr: 'الإكسسوارات',
        labelFr: 'Accessoires',
        color: _girlsColor,
        icon: Icons.diamond,
        emoji: '💎',
        children: [
          CategoryItem(id: 'girls_acc_cheveux', labelAr: 'إكسسوارات الشعر', labelFr: 'Acc. cheveux', color: _girlsColor, icon: Icons.face_retouching_natural, emoji: '🎀'),
          CategoryItem(id: 'girls_sacs', labelAr: 'حقائب', labelFr: 'Sacs', color: _girlsColor, icon: Icons.shopping_bag, emoji: '👜'),
          CategoryItem(id: 'girls_bijoux', labelAr: 'مجوهرات أطفال', labelFr: 'Bijoux enfants', color: _girlsColor, icon: Icons.diamond, emoji: '💍'),
          CategoryItem(id: 'girls_chapeaux', labelAr: 'قبعات', labelFr: 'Chapeaux', color: _girlsColor, icon: Icons.sports_baseball, emoji: '🎩'),
        ],
      ),
    ],
  ),

  // ── الأولاد ─────────────────────────────────────────────────────────────────
  CategoryItem(
    id: 'boys',
    labelAr: 'الأولاد',
    labelFr: 'Garçons',
    color: _boysColor,
    icon: Icons.child_care,
    emoji: '👦',
    children: [
      CategoryItem(
        id: 'boys_clothes',
        labelAr: 'الملابس',
        labelFr: 'Vêtements',
        color: _boysColor,
        icon: Icons.checkroom,
        emoji: '👕',
        children: [
          CategoryItem(id: 'boys_tshirts', labelAr: 'تيشيرتات وقمصان', labelFr: 'T-shirts & Chemises', color: _boysColor, icon: Icons.checkroom, emoji: '👕'),
          CategoryItem(id: 'boys_pantalons', labelAr: 'بنطلونات', labelFr: 'Pantalons', color: _boysColor, icon: Icons.checkroom, emoji: '👖'),
          CategoryItem(id: 'boys_manteaux', labelAr: 'معاطف وسترات', labelFr: 'Manteaux & Vestes', color: _boysColor, icon: Icons.checkroom, emoji: '🧥'),
          CategoryItem(id: 'boys_sport', labelAr: 'ملابس رياضية', labelFr: 'Sport', color: _boysColor, icon: Icons.sports, emoji: '🏃'),
          CategoryItem(id: 'boys_jeans', labelAr: 'جينز', labelFr: 'Jeans', color: _boysColor, icon: Icons.checkroom, emoji: '👖'),
          CategoryItem(id: 'boys_pyjamas', labelAr: 'ملابس داخلية وبيجامات', labelFr: 'Sous-vêtements & Pyjamas', color: _boysColor, icon: Icons.checkroom, emoji: '🩲'),
          CategoryItem(id: 'boys_ensembles', labelAr: 'طقم / أنسامبل', labelFr: 'Ensembles', color: _boysColor, icon: Icons.checkroom, emoji: '👘'),
        ],
      ),
      CategoryItem(
        id: 'boys_shoes',
        labelAr: 'الأحذية',
        labelFr: 'Chaussures',
        color: _boysColor,
        icon: Icons.man,
        emoji: '👟',
        children: [
          CategoryItem(id: 'boys_sneakers', labelAr: 'رياضي / سنيكرز', labelFr: 'Sneakers', color: _boysColor, icon: Icons.man, emoji: '👟'),
          CategoryItem(id: 'boys_sandales', labelAr: 'صنادل', labelFr: 'Sandales', color: _boysColor, icon: Icons.man, emoji: '🩴'),
          CategoryItem(id: 'boys_bottes', labelAr: 'بوتات', labelFr: 'Bottes', color: _boysColor, icon: Icons.man, emoji: '👢'),
          CategoryItem(id: 'boys_formelles', labelAr: 'أحذية رسمية', labelFr: 'Formelles', color: _boysColor, icon: Icons.man, emoji: '👞'),
        ],
      ),
      CategoryItem(
        id: 'boys_accessories',
        labelAr: 'الإكسسوارات',
        labelFr: 'Accessoires',
        color: _boysColor,
        icon: Icons.watch,
        emoji: '🎒',
        children: [
          CategoryItem(id: 'boys_sacs', labelAr: 'حقائب ظهر', labelFr: 'Sacs à dos', color: _boysColor, icon: Icons.shopping_bag, emoji: '🎒'),
          CategoryItem(id: 'boys_chapeaux', labelAr: 'قبعات', labelFr: 'Casquettes', color: _boysColor, icon: Icons.sports_baseball, emoji: '🧢'),
          CategoryItem(id: 'boys_ceintures', labelAr: 'أحزمة', labelFr: 'Ceintures', color: _boysColor, icon: Icons.horizontal_rule, emoji: '🥋'),
          CategoryItem(id: 'boys_lunettes', labelAr: 'نظارات', labelFr: 'Lunettes', color: _boysColor, icon: Icons.visibility, emoji: '🕶️'),
        ],
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// RENTAL CATEGORIES (للكراء)
// ─────────────────────────────────────────────────────────────────────────────

final List<CategoryItem> rentalCategories = [
  // ── النساء (location) ────────────────────────────────────────────────────────
  CategoryItem(
    id: 'women_rental',
    labelAr: 'النساء',
    labelFr: 'Femmes',
    color: _rentalWomenColor,
    icon: Icons.woman,
    emoji: '👰',
    children: [
      CategoryItem(
        id: 'rental_women_clothes',
        labelAr: 'الملابس',
        labelFr: 'Vêtements',
        color: _rentalWomenColor,
        icon: Icons.checkroom,
        emoji: '👗',
        children: [
          CategoryItem(id: 'robe_mariee', labelAr: 'روبة العروسة', labelFr: 'Robe de mariée ★', color: _rentalWomenColor, icon: Icons.favorite, emoji: '👰', isSpecial: true),
          CategoryItem(id: 'robe_soiree', labelAr: 'فستان سهرة', labelFr: 'Robe de soirée ★', color: _rentalWomenColor, icon: Icons.star, emoji: '✨', isSpecial: true),
          CategoryItem(id: 'robes_rental', labelAr: 'فساتين', labelFr: 'Robes', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '👗'),
          CategoryItem(id: 'jupes_rental', labelAr: 'تنانير', labelFr: 'Jupes', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '🩱'),
          CategoryItem(id: 'pantalons_rental', labelAr: 'بنطلونات', labelFr: 'Pantalons', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '👖'),
          CategoryItem(id: 'blouses_rental', labelAr: 'بلوزات وقمصان', labelFr: 'Blouses & Chemises', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '👚'),
          CategoryItem(id: 'vestes_rental', labelAr: 'جاكيتات ومعاطف', labelFr: 'Vestes & Manteaux', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '🧥'),
          CategoryItem(id: 'cardigans_rental', labelAr: 'سترات وكارديغان', labelFr: 'Cardigans & Pulls', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '🧶'),
          CategoryItem(id: 'sport_rental', labelAr: 'ملابس رياضية', labelFr: 'Sport', color: _rentalWomenColor, icon: Icons.sports, emoji: '🏃‍♀️'),
          CategoryItem(id: 'ensembles_rental', labelAr: 'طقم / أنسامبل', labelFr: 'Ensembles', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '👘'),
        ],
      ),
      CategoryItem(
        id: 'rental_women_shoes',
        labelAr: 'الأحذية',
        labelFr: 'Chaussures',
        color: _rentalWomenColor,
        icon: Icons.man,
        emoji: '👠',
        children: [
          CategoryItem(id: 'talons_rental', labelAr: 'كعب عالي', labelFr: 'Talons', color: _rentalWomenColor, icon: Icons.man, emoji: '👠'),
          CategoryItem(id: 'plates_rental', labelAr: 'أحذية مسطحة', labelFr: 'Plates', color: _rentalWomenColor, icon: Icons.man, emoji: '🥿'),
          CategoryItem(id: 'sandales_rental_f', labelAr: 'صنادل', labelFr: 'Sandales', color: _rentalWomenColor, icon: Icons.man, emoji: '👡'),
          CategoryItem(id: 'bottes_rental_f', labelAr: 'بوتات', labelFr: 'Bottes', color: _rentalWomenColor, icon: Icons.man, emoji: '👢'),
          CategoryItem(id: 'sneakers_rental_f', labelAr: 'رياضي / سنيكرز', labelFr: 'Sneakers', color: _rentalWomenColor, icon: Icons.man, emoji: '👟'),
        ],
      ),
      CategoryItem(
        id: 'rental_women_bags',
        labelAr: 'الحقائب',
        labelFr: 'Sacs',
        color: _rentalWomenColor,
        icon: Icons.shopping_bag,
        emoji: '👜',
        children: [
          CategoryItem(id: 'bags_rental_f', labelAr: 'حقائب يد', labelFr: 'Main', color: _rentalWomenColor, icon: Icons.shopping_bag, emoji: '👜'),
          CategoryItem(id: 'clutch_soiree', labelAr: 'كلتش سهرة', labelFr: 'Clutch soirée', color: _rentalWomenColor, icon: Icons.shopping_bag, emoji: '💼'),
          CategoryItem(id: 'sac_dos_rental_f', labelAr: 'حقائب ظهر', labelFr: 'Dos', color: _rentalWomenColor, icon: Icons.shopping_bag, emoji: '🎒'),
          CategoryItem(id: 'portefeuilles_rental_f', labelAr: 'محافظ', labelFr: 'Portefeuilles', color: _rentalWomenColor, icon: Icons.account_balance_wallet, emoji: '👛'),
        ],
      ),
      CategoryItem(
        id: 'rental_women_accessories',
        labelAr: 'الإكسسوارات',
        labelFr: 'Accessoires',
        color: _rentalWomenColor,
        icon: Icons.diamond,
        emoji: '💍',
        children: [
          CategoryItem(id: 'accessories_rental_f', labelAr: 'مجوهرات وخواتم', labelFr: 'Bijoux & Bagues', color: _rentalWomenColor, icon: Icons.diamond, emoji: '💍'),
          CategoryItem(id: 'montres_rental_f', labelAr: 'ساعات', labelFr: 'Montres', color: _rentalWomenColor, icon: Icons.watch, emoji: '⌚'),
          CategoryItem(id: 'lunettes_rental_f', labelAr: 'نظارات', labelFr: 'Lunettes', color: _rentalWomenColor, icon: Icons.visibility, emoji: '🕶️'),
          CategoryItem(id: 'echarpes_rental', labelAr: 'أوشحة وقبعات', labelFr: 'Écharpes & Chapeaux', color: _rentalWomenColor, icon: Icons.ac_unit, emoji: '🧣'),
          CategoryItem(id: 'ceintures_rental_f', labelAr: 'أحزمة', labelFr: 'Ceintures', color: _rentalWomenColor, icon: Icons.horizontal_rule, emoji: '👒'),
        ],
      ),
    ],
  ),

  // ── الرجال (location) ────────────────────────────────────────────────────────
  CategoryItem(
    id: 'men_rental',
    labelAr: 'الرجال',
    labelFr: 'Hommes',
    color: _menColor,
    icon: Icons.man,
    emoji: '🤵',
    children: [
      CategoryItem(
        id: 'rental_men_clothes',
        labelAr: 'الملابس',
        labelFr: 'Vêtements',
        color: _menColor,
        icon: Icons.checkroom,
        emoji: '🤵',
        children: [
          CategoryItem(id: 'costume_arabe', labelAr: 'كوستيم عربي', labelFr: 'Costume arabe ★', color: _menColor, icon: Icons.star, emoji: '🧕', isSpecial: true),
          CategoryItem(id: 'djebba', labelAr: 'جبة عربية', labelFr: 'Djebba arabe ★', color: _menColor, icon: Icons.star, emoji: '👳', isSpecial: true),
          CategoryItem(id: 'costumes_formels', labelAr: 'بدلة رسمية', labelFr: 'Costume formel', color: _menColor, icon: Icons.checkroom, emoji: '🤵'),
          CategoryItem(id: 'tshirts_rental', labelAr: 'تيشيرتات وقمصان', labelFr: 'T-shirts & Chemises', color: _menColor, icon: Icons.checkroom, emoji: '👕'),
          CategoryItem(id: 'pantalons_rental_m', labelAr: 'بنطلونات', labelFr: 'Pantalons', color: _menColor, icon: Icons.checkroom, emoji: '👖'),
          CategoryItem(id: 'vestes_rental_m', labelAr: 'جاكيتات ومعاطف', labelFr: 'Vestes & Manteaux', color: _menColor, icon: Icons.checkroom, emoji: '🧥'),
          CategoryItem(id: 'sport_rental_m', labelAr: 'ملابس رياضية', labelFr: 'Sport', color: _menColor, icon: Icons.sports, emoji: '🏃'),
          CategoryItem(id: 'jeans_rental', labelAr: 'جينز', labelFr: 'Jeans', color: _menColor, icon: Icons.checkroom, emoji: '👖'),
          CategoryItem(id: 'hoodies_rental', labelAr: 'هودي وسويتشيرت', labelFr: 'Hoodies & Sweats', color: _menColor, icon: Icons.checkroom, emoji: '🧥'),
        ],
      ),
      CategoryItem(
        id: 'rental_men_shoes',
        labelAr: 'الأحذية',
        labelFr: 'Chaussures',
        color: _menColor,
        icon: Icons.man,
        emoji: '👟',
        children: [
          CategoryItem(id: 'shoes_rental_m', labelAr: 'أحذية رسمية', labelFr: 'Formelles', color: _menColor, icon: Icons.man, emoji: '👞'),
          CategoryItem(id: 'sneakers_rental_m', labelAr: 'رياضي / سنيكرز', labelFr: 'Sneakers', color: _menColor, icon: Icons.man, emoji: '👟'),
          CategoryItem(id: 'sandales_rental_m', labelAr: 'صنادل', labelFr: 'Sandales', color: _menColor, icon: Icons.man, emoji: '🩴'),
          CategoryItem(id: 'bottes_rental_m', labelAr: 'بوتات', labelFr: 'Bottes', color: _menColor, icon: Icons.man, emoji: '👢'),
        ],
      ),
      CategoryItem(
        id: 'rental_men_bags',
        labelAr: 'الحقائب',
        labelFr: 'Sacs',
        color: _menColor,
        icon: Icons.shopping_bag,
        emoji: '🎒',
        children: [
          CategoryItem(id: 'bags_rental_m', labelAr: 'حقائب ظهر', labelFr: 'Dos', color: _menColor, icon: Icons.shopping_bag, emoji: '🎒'),
          CategoryItem(id: 'sac_voyage_rental_m', labelAr: 'حقائب سفر', labelFr: 'Voyage', color: _menColor, icon: Icons.luggage, emoji: '🧳'),
          CategoryItem(id: 'portefeuilles_rental_m', labelAr: 'محافظ', labelFr: 'Portefeuilles', color: _menColor, icon: Icons.account_balance_wallet, emoji: '👛'),
        ],
      ),
      CategoryItem(
        id: 'rental_men_accessories',
        labelAr: 'الإكسسوارات',
        labelFr: 'Accessoires',
        color: _menColor,
        icon: Icons.watch,
        emoji: '⌚',
        children: [
          CategoryItem(id: 'accessories_rental_m', labelAr: 'ساعات', labelFr: 'Montres', color: _menColor, icon: Icons.watch, emoji: '⌚'),
          CategoryItem(id: 'lunettes_rental_m', labelAr: 'نظارات', labelFr: 'Lunettes', color: _menColor, icon: Icons.visibility, emoji: '🕶️'),
          CategoryItem(id: 'ceintures_rental_m', labelAr: 'أحزمة', labelFr: 'Ceintures', color: _menColor, icon: Icons.horizontal_rule, emoji: '🥋'),
          CategoryItem(id: 'cravates_rental', labelAr: 'كرافات وربطات عنق', labelFr: 'Cravates & Nœuds', color: _menColor, icon: Icons.style, emoji: '👔'),
          CategoryItem(id: 'casquettes_rental', labelAr: 'قبعات', labelFr: 'Casquettes', color: _menColor, icon: Icons.sports_baseball, emoji: '🧢'),
        ],
      ),
    ],
  ),
];
