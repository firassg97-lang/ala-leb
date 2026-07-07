import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String labelAr;
  final String labelFr;
  final String labelEn;
  final Color color;
  final IconData icon;
  final String emoji;
  final bool isSpecial;
  final List<CategoryItem> children;

  const CategoryItem({
    required this.id,
    required this.labelAr,
    required this.labelFr,
    required this.labelEn,
    required this.color,
    required this.icon,
    this.emoji = '🏷️',
    this.isSpecial = false,
    this.children = const [],
  });
}

const _womenColor = Color(0xFFE91E8C);
const _menColor = Color(0xFF1565C0);
const _girlsColor = Color(0xFFAD1457);
const _boysColor = Color(0xFF0277BD);
const _rentalWomenColor = Color(0xFFC2185B);

final List<CategoryItem> saleCategories = [
  CategoryItem(id: 'women', labelAr: 'نساء', labelFr: 'Femmes', labelEn: 'Women', color: _womenColor, icon: Icons.woman, emoji: '👩', children: [
    CategoryItem(id: 'women_clothes', labelAr: 'حوايج', labelFr: 'Vêtements', labelEn: 'Clothing', color: _womenColor, icon: Icons.checkroom, emoji: '👗', children: [
      CategoryItem(id: 'robes', labelAr: 'روبات', labelFr: 'Robes', labelEn: 'Dresses', color: _womenColor, icon: Icons.checkroom, emoji: '👗'),
      CategoryItem(id: 'jupes', labelAr: 'جيب', labelFr: 'Jupes', labelEn: 'Skirts', color: _womenColor, icon: Icons.checkroom, emoji: '💃'),
      CategoryItem(id: 'pantalons_f', labelAr: 'سراويل', labelFr: 'Pantalons', labelEn: 'Pants', color: _womenColor, icon: Icons.checkroom, emoji: '👖'),
      CategoryItem(id: 'gaftan', labelAr: 'قفطان', labelFr: 'Kaftan', labelEn: 'Kaftan', color: _womenColor, icon: Icons.checkroom, emoji: '👘'),
      CategoryItem(id: 'chemises_f', labelAr: 'قمجات', labelFr: 'Chemises', labelEn: 'Shirts', color: _womenColor, icon: Icons.dry_cleaning, emoji: '👔'),
      CategoryItem(id: 'vestes_f', labelAr: 'فيستات', labelFr: 'Vestes', labelEn: 'Jackets', color: _womenColor, icon: Icons.cases, emoji: '🧥'),
      CategoryItem(id: 'ensembles_f', labelAr: 'أنسومبل', labelFr: 'Ensembles', labelEn: 'Outfits', color: _womenColor, icon: Icons.checkroom, emoji: '👘'),
      CategoryItem(id: 'pulls_f', labelAr: 'بولات', labelFr: 'Pulls', labelEn: 'Sweaters', color: _womenColor, icon: Icons.dry_cleaning, emoji: '👚'),
      CategoryItem(id: 'sport_f', labelAr: 'حوايج سبور', labelFr: 'Sport', labelEn: 'Sportswear', color: _womenColor, icon: Icons.sports, emoji: '🏃‍♀️'),
      CategoryItem(id: 'sous_vetements_f', labelAr: 'صوبيات', labelFr: 'Sous-vêtements', labelEn: 'Underwear', color: _womenColor, icon: Icons.dry_cleaning, emoji: '🩲'),
      CategoryItem(id: 'pyjamas_f', labelAr: 'بيجامات', labelFr: 'Pyjamas', labelEn: 'Pajamas', color: _womenColor, icon: Icons.bedtime, emoji: '🌙'),
      CategoryItem(id: 'maillots_f', labelAr: 'مايو', labelFr: 'Maillots de bain', labelEn: 'Swimwear', color: _womenColor, icon: Icons.pool, emoji: '🩱'),
      CategoryItem(id: 'manteaux_f', labelAr: 'كبابيط', labelFr: 'Manteaux', labelEn: 'Coats', color: _womenColor, icon: Icons.umbrella, emoji: '🧥'),
    ]),
    CategoryItem(id: 'women_shoes', labelAr: 'صباط', labelFr: 'Chaussures', labelEn: 'Shoes', color: _womenColor, icon: Icons.man, emoji: '👠', children: [
      CategoryItem(id: 'talons', labelAr: 'صباط بالكعب', labelFr: 'Talons', labelEn: 'Heels', color: _womenColor, icon: Icons.man, emoji: '👠'),
      CategoryItem(id: 'plates', labelAr: 'صباط مسطح', labelFr: 'Plates', labelEn: 'Flats', color: _womenColor, icon: Icons.man, emoji: '🥿'),
      CategoryItem(id: 'sandales_f', labelAr: 'صندالة', labelFr: 'Sandales', labelEn: 'Sandals', color: _womenColor, icon: Icons.man, emoji: '👡'),
      CategoryItem(id: 'bottes_f', labelAr: 'بوط', labelFr: 'Bottes', labelEn: 'Boots', color: _womenColor, icon: Icons.man, emoji: '👢'),
      CategoryItem(id: 'sneakers_f', labelAr: 'سبادري', labelFr: 'Baskets', labelEn: 'Baskets', color: _womenColor, icon: Icons.man, emoji: '👟'),
      CategoryItem(id: 'chaussons_f', labelAr: 'سبادري', labelFr: 'Claquettes', labelEn: 'Claquettes', color: _womenColor, icon: Icons.man, emoji: '🩴'),
    ]),
    CategoryItem(id: 'women_bags', labelAr: 'سكارة', labelFr: 'Sacs', labelEn: 'Bags', color: _womenColor, icon: Icons.shopping_bag, emoji: '👜', children: [
      CategoryItem(id: 'sac_main', labelAr: 'سكارة يد', labelFr: 'Main', labelEn: 'Handbags', color: _womenColor, icon: Icons.shopping_bag, emoji: '👜'),
      CategoryItem(id: 'sac_dos', labelAr: 'سكارة ظهر', labelFr: 'Dos', labelEn: 'Backpacks', color: _womenColor, icon: Icons.backpack, emoji: '🎒'),
      CategoryItem(id: 'sac_voyage', labelAr: 'فاليز', labelFr: 'Valise', labelEn: 'Suitcase', color: _womenColor, icon: Icons.luggage, emoji: '🧳'),
      CategoryItem(id: 'portefeuilles_f', labelAr: 'بورتفاي', labelFr: 'Portefeuilles', labelEn: 'Wallets', color: _womenColor, icon: Icons.account_balance_wallet, emoji: '👛'),
    ]),
    CategoryItem(id: 'women_makeup', labelAr: 'ماكياج وعناية', labelFr: 'Maquillage & Soins', labelEn: 'Makeup & Care', color: _womenColor, icon: Icons.face_retouching_natural, emoji: '💄', children: [
      CategoryItem(id: 'visage', labelAr: 'ماكياج وجه', labelFr: 'Maquillage visage', labelEn: 'Face Makeup', color: _womenColor, icon: Icons.face, emoji: '🧴'),
      CategoryItem(id: 'yeux', labelAr: 'ماكياج عين', labelFr: 'Maquillage yeux', labelEn: 'Eye Makeup', color: _womenColor, icon: Icons.remove_red_eye, emoji: '👁️'),
      CategoryItem(id: 'levres', labelAr: 'ماكياج شفاه', labelFr: 'Maquillage lèvres', labelEn: 'Lip Makeup', color: _womenColor, icon: Icons.face, emoji: '💋'),
      CategoryItem(id: 'soins_peau', labelAr: 'عناية بالبشرة', labelFr: 'Soins peau', labelEn: 'Skincare', color: _womenColor, icon: Icons.spa, emoji: '🧖‍♀️'),
      CategoryItem(id: 'soins_cheveux', labelAr: 'عناية بالشعر', labelFr: 'Soins cheveux', labelEn: 'Haircare', color: _womenColor, icon: Icons.dry, emoji: '💇‍♀️'),
      CategoryItem(id: 'parfums_f', labelAr: 'ريحة', labelFr: 'Parfums', labelEn: 'Perfumes', color: _womenColor, icon: Icons.local_florist, emoji: '🌸'),
    ]),
    CategoryItem(id: 'women_accessories', labelAr: 'أكسسوارات', labelFr: 'Accessoires', labelEn: 'Accessories', color: _womenColor, icon: Icons.diamond, emoji: '💍', children: [
      CategoryItem(id: 'bijoux_f', labelAr: 'مصاغ', labelFr: 'Bijoux', labelEn: 'Jewelry', color: _womenColor, icon: Icons.diamond, emoji: '💎'),
      CategoryItem(id: 'montres_f', labelAr: 'مغانة', labelFr: 'Montres', labelEn: 'Watches', color: _womenColor, icon: Icons.watch, emoji: '⌚'),
      CategoryItem(id: 'lunettes_f', labelAr: 'نظاضر', labelFr: 'Lunettes', labelEn: 'Eyewear', color: _womenColor, icon: Icons.visibility, emoji: '🕶️'),
      CategoryItem(id: 'echarpes_f', labelAr: 'شال', labelFr: 'Écharpes', labelEn: 'Scarves', color: _womenColor, icon: Icons.ac_unit, emoji: '🧣'),
      CategoryItem(id: 'chapeaux_f', labelAr: 'شابو', labelFr: 'Chapeaux', labelEn: 'Hats', color: _womenColor, icon: Icons.sports_baseball, emoji: '👒'),
      CategoryItem(id: 'ceintures_f', labelAr: 'سبتة', labelFr: 'Ceintures', labelEn: 'Belts', color: _womenColor, icon: Icons.horizontal_rule, emoji: '🪢'),
      CategoryItem(id: 'acc_cheveux', labelAr: 'أكسسوارات شعر', labelFr: 'Acc. cheveux', labelEn: 'Hair Accessories', color: _womenColor, icon: Icons.face_retouching_natural, emoji: '🎀'),
    ]),
  ]),
  CategoryItem(id: 'men', labelAr: 'رجال', labelFr: 'Hommes', labelEn: 'Men', color: _menColor, icon: Icons.man, emoji: '👨', children: [
    CategoryItem(id: 'men_clothes', labelAr: 'حوايج', labelFr: 'Vêtements', labelEn: 'Clothing', color: _menColor, icon: Icons.checkroom, emoji: '👔', children: [
      CategoryItem(id: 'tshirts_m', labelAr: 'تريكوات', labelFr: 'T-shirts', labelEn: 'T-shirts', color: _menColor, icon: Icons.checkroom, emoji: '👕'),
      CategoryItem(id: 'chemises_m', labelAr: 'قمجات', labelFr: 'Chemises', labelEn: 'Shirts', color: _menColor, icon: Icons.dry_cleaning, emoji: '👔'),
      CategoryItem(id: 'pantalons_m', labelAr: 'سراويل', labelFr: 'Pantalons', labelEn: 'Pants', color: _menColor, icon: Icons.checkroom, emoji: '👖'),
      CategoryItem(id: 'vestes_m', labelAr: 'فيستات', labelFr: 'Vestes', labelEn: 'Jackets', color: _menColor, icon: Icons.cases, emoji: '🧥'),
      CategoryItem(id: 'short_m', labelAr: 'شورت', labelFr: 'Short', labelEn: 'Shorts', color: _menColor, icon: Icons.checkroom, emoji: '🩳'),
      CategoryItem(id: 'costumes_m', labelAr: 'كوستيمات', labelFr: 'Costumes', labelEn: 'Suits', color: _menColor, icon: Icons.checkroom, emoji: '🤵'),
      CategoryItem(id: 'sport_m', labelAr: 'حوايج سبور', labelFr: 'Sport', labelEn: 'Sportswear', color: _menColor, icon: Icons.sports, emoji: '🏃'),
      CategoryItem(id: 'sous_vetements_m', labelAr: 'صوبيات', labelFr: 'Sous-vêtements', labelEn: 'Underwear', color: _menColor, icon: Icons.dry_cleaning, emoji: '🩲'),
      CategoryItem(id: 'pyjamas_m', labelAr: 'بيجامات', labelFr: 'Pyjamas', labelEn: 'Pajamas', color: _menColor, icon: Icons.bedtime, emoji: '🌙'),
      CategoryItem(id: 'jeans_m', labelAr: 'جينز', labelFr: 'Jeans', labelEn: 'Jeans', color: _menColor, icon: Icons.checkroom, emoji: '👖'),
    ]),
    CategoryItem(id: 'men_shoes', labelAr: 'صباط', labelFr: 'Chaussures', labelEn: 'Shoes', color: _menColor, icon: Icons.man, emoji: '👟', children: [
      CategoryItem(id: 'formelles_m', labelAr: 'صباط رسمي', labelFr: 'Formelles', labelEn: 'Dress Shoes', color: _menColor, icon: Icons.man, emoji: '👞'),
      CategoryItem(id: 'sneakers_m', labelAr: 'سبادري', labelFr: 'Baskets', labelEn: 'Baskets', color: _menColor, icon: Icons.man, emoji: '👟'),
      CategoryItem(id: 'sandales_m', labelAr: 'صندالة', labelFr: 'Sandales', labelEn: 'Sandals', color: _menColor, icon: Icons.man, emoji: '🩴'),
      CategoryItem(id: 'bottes_m', labelAr: 'بوط', labelFr: 'Bottes', labelEn: 'Boots', color: _menColor, icon: Icons.man, emoji: '👢'),
      CategoryItem(id: 'chaussons_m', labelAr: 'سبادري', labelFr: 'Claquettes', labelEn: 'Claquettes', color: _menColor, icon: Icons.man, emoji: '🩴'),
      CategoryItem(id: 'crampons_m', labelAr: 'كرامبون', labelFr: 'Crampons', labelEn: 'Cleats', color: _menColor, icon: Icons.sports_soccer, emoji: '⚽'),
    ]),
    CategoryItem(id: 'men_bags', labelAr: 'سكارة', labelFr: 'Sacs', labelEn: 'Bags', color: _menColor, icon: Icons.shopping_bag, emoji: '🎒', children: [
      CategoryItem(id: 'sac_dos_m', labelAr: 'سكارة ظهر', labelFr: 'Dos', labelEn: 'Backpacks', color: _menColor, icon: Icons.backpack, emoji: '🎒'),
      CategoryItem(id: 'sac_voyage_m', labelAr: 'فاليز', labelFr: 'Valise', labelEn: 'Suitcase', color: _menColor, icon: Icons.luggage, emoji: '🧳'),
      CategoryItem(id: 'portefeuilles_m', labelAr: 'بورتفاي', labelFr: 'Portefeuilles', labelEn: 'Wallets', color: _menColor, icon: Icons.account_balance_wallet, emoji: '👛'),
      CategoryItem(id: 'crossbody_m', labelAr: 'سكارة كروسبودي', labelFr: 'Crossbody', labelEn: 'Crossbody Bags', color: _menColor, icon: Icons.shopping_bag, emoji: '💼'),
    ]),
    CategoryItem(id: 'men_accessories', labelAr: 'أكسسوارات', labelFr: 'Accessoires', labelEn: 'Accessories', color: _menColor, icon: Icons.watch, emoji: '⌚', children: [
      CategoryItem(id: 'montres_m', labelAr: 'مغانة', labelFr: 'Montres', labelEn: 'Watches', color: _menColor, icon: Icons.watch, emoji: '⌚'),
      CategoryItem(id: 'lunettes_m', labelAr: 'نظاضر', labelFr: 'Lunettes', labelEn: 'Eyewear', color: _menColor, icon: Icons.visibility, emoji: '🕶️'),
      CategoryItem(id: 'ceintures_m', labelAr: 'سبتة', labelFr: 'Ceintures', labelEn: 'Belts', color: _menColor, icon: Icons.horizontal_rule, emoji: '🥋'),
      CategoryItem(id: 'cravates_m', labelAr: 'كرافات', labelFr: 'Cravates', labelEn: 'Ties', color: _menColor, icon: Icons.style, emoji: '👔'),
      CategoryItem(id: 'noeuds_m', labelAr: 'نود بابيون', labelFr: 'Nœuds papillon', labelEn: 'Bow Ties', color: _menColor, icon: Icons.blur_circular, emoji: '🎀'),
      CategoryItem(id: 'casquettes_m', labelAr: 'كاسكيط', labelFr: 'Casquettes', labelEn: 'Caps', color: _menColor, icon: Icons.sports_baseball, emoji: '🧢'),
    ]),
  ]),
  CategoryItem(id: 'girls', labelAr: 'بنات', labelFr: 'Filles', labelEn: 'Girls', color: _girlsColor, icon: Icons.child_care, emoji: '👧', children: [
    CategoryItem(id: 'girls_clothes', labelAr: 'حوايج', labelFr: 'Vêtements', labelEn: 'Clothing', color: _girlsColor, icon: Icons.checkroom, emoji: '👗', children: [
      CategoryItem(id: 'girls_robes', labelAr: 'روبات', labelFr: 'Robes', labelEn: 'Dresses', color: _girlsColor, icon: Icons.checkroom, emoji: '👗'),
      CategoryItem(id: 'girls_jupes', labelAr: 'جيب', labelFr: 'Jupes', labelEn: 'Skirts', color: _girlsColor, icon: Icons.checkroom, emoji: '💃'),
      CategoryItem(id: 'girls_pantalons', labelAr: 'سراويل', labelFr: 'Pantalons', labelEn: 'Pants', color: _girlsColor, icon: Icons.checkroom, emoji: '👖'),
      CategoryItem(id: 'girls_gaftan', labelAr: 'قفطان', labelFr: 'Kaftan', labelEn: 'Kaftan', color: _girlsColor, icon: Icons.checkroom, emoji: '👘'),
      CategoryItem(id: 'girls_chemises', labelAr: 'قمجات', labelFr: 'Chemises', labelEn: 'Shirts', color: _girlsColor, icon: Icons.dry_cleaning, emoji: '👔'),
      CategoryItem(id: 'girls_vestes', labelAr: 'فيستات', labelFr: 'Vestes', labelEn: 'Jackets', color: _girlsColor, icon: Icons.cases, emoji: '🧥'),
      CategoryItem(id: 'girls_ensembles', labelAr: 'أنسومبل', labelFr: 'Ensembles', labelEn: 'Outfits', color: _girlsColor, icon: Icons.checkroom, emoji: '👘'),
      CategoryItem(id: 'girls_pulls', labelAr: 'بولات', labelFr: 'Pulls', labelEn: 'Sweaters', color: _girlsColor, icon: Icons.dry_cleaning, emoji: '👚'),
      CategoryItem(id: 'girls_sport', labelAr: 'حوايج سبور', labelFr: 'Sport', labelEn: 'Sportswear', color: _girlsColor, icon: Icons.sports, emoji: '🏃‍♀️'),
      CategoryItem(id: 'girls_sous_vetements', labelAr: 'صوبيات', labelFr: 'Sous-vêtements', labelEn: 'Underwear', color: _girlsColor, icon: Icons.dry_cleaning, emoji: '🩲'),
      CategoryItem(id: 'girls_pyjamas', labelAr: 'بيجامات', labelFr: 'Pyjamas', labelEn: 'Pajamas', color: _girlsColor, icon: Icons.bedtime, emoji: '🌙'),
      CategoryItem(id: 'girls_maillots', labelAr: 'مايو', labelFr: 'Maillots de bain', labelEn: 'Swimwear', color: _girlsColor, icon: Icons.pool, emoji: '🩱'),
      CategoryItem(id: 'girls_manteaux', labelAr: 'كبابيط', labelFr: 'Manteaux', labelEn: 'Coats', color: _girlsColor, icon: Icons.umbrella, emoji: '🧥'),
    ]),
    CategoryItem(id: 'girls_shoes', labelAr: 'صباط', labelFr: 'Chaussures', labelEn: 'Shoes', color: _girlsColor, icon: Icons.man, emoji: '👟', children: [
      CategoryItem(id: 'girls_sandales', labelAr: 'صندالة', labelFr: 'Sandales', labelEn: 'Sandals', color: _girlsColor, icon: Icons.man, emoji: '👡'),
      CategoryItem(id: 'girls_bottes', labelAr: 'بوط', labelFr: 'Bottes', labelEn: 'Boots', color: _girlsColor, icon: Icons.man, emoji: '👢'),
      CategoryItem(id: 'girls_sneakers', labelAr: 'سبادري', labelFr: 'Baskets', labelEn: 'Baskets', color: _girlsColor, icon: Icons.man, emoji: '👟'),
      CategoryItem(id: 'girls_ballerines', labelAr: 'باليرينا', labelFr: 'Ballerines', labelEn: 'Ballet Flats', color: _girlsColor, icon: Icons.man, emoji: '🩰'),
    ]),
    CategoryItem(id: 'girls_accessories', labelAr: 'أكسسوارات', labelFr: 'Accessoires', labelEn: 'Accessories', color: _girlsColor, icon: Icons.diamond, emoji: '💎', children: [
      CategoryItem(id: 'girls_acc_cheveux', labelAr: 'أكسسوارات شعر', labelFr: 'Acc. cheveux', labelEn: 'Hair Accessories', color: _girlsColor, icon: Icons.face_retouching_natural, emoji: '🎀'),
      CategoryItem(id: 'girls_sacs', labelAr: 'سكارة', labelFr: 'Sacs', labelEn: 'Bags', color: _girlsColor, icon: Icons.shopping_bag, emoji: '👜'),
      CategoryItem(id: 'girls_bijoux', labelAr: 'مصاغ صغار', labelFr: 'Bijoux enfants', labelEn: 'Kids Jewelry', color: _girlsColor, icon: Icons.diamond, emoji: '💍'),
      CategoryItem(id: 'girls_chapeaux', labelAr: 'شابو', labelFr: 'Chapeaux', labelEn: 'Hats', color: _girlsColor, icon: Icons.sports_baseball, emoji: '🎩'),
    ]),
  ]),
  CategoryItem(id: 'boys', labelAr: 'أولاد', labelFr: 'Garçons', labelEn: 'Boys', color: _boysColor, icon: Icons.child_care, emoji: '👦', children: [
    CategoryItem(id: 'boys_clothes', labelAr: 'حوايج', labelFr: 'Vêtements', labelEn: 'Clothing', color: _boysColor, icon: Icons.checkroom, emoji: '👔', children: [
      CategoryItem(id: 'boys_tshirts', labelAr: 'تريكوات', labelFr: 'T-shirts', labelEn: 'T-shirts', color: _boysColor, icon: Icons.checkroom, emoji: '👕'),
      CategoryItem(id: 'boys_chemises', labelAr: 'قمجات', labelFr: 'Chemises', labelEn: 'Shirts', color: _boysColor, icon: Icons.dry_cleaning, emoji: '👔'),
      CategoryItem(id: 'boys_pantalons', labelAr: 'سراويل', labelFr: 'Pantalons', labelEn: 'Pants', color: _boysColor, icon: Icons.checkroom, emoji: '👖'),
      CategoryItem(id: 'boys_vestes', labelAr: 'فيستات', labelFr: 'Vestes', labelEn: 'Jackets', color: _boysColor, icon: Icons.cases, emoji: '🧥'),
      CategoryItem(id: 'boys_short', labelAr: 'شورت', labelFr: 'Short', labelEn: 'Shorts', color: _boysColor, icon: Icons.checkroom, emoji: '🩳'),
      CategoryItem(id: 'boys_costumes', labelAr: 'كوستيمات', labelFr: 'Costumes', labelEn: 'Suits', color: _boysColor, icon: Icons.checkroom, emoji: '🤵'),
      CategoryItem(id: 'boys_sport', labelAr: 'حوايج سبور', labelFr: 'Sport', labelEn: 'Sportswear', color: _boysColor, icon: Icons.sports, emoji: '🏃'),
      CategoryItem(id: 'boys_sous_vetements', labelAr: 'صوبيات', labelFr: 'Sous-vêtements', labelEn: 'Underwear', color: _boysColor, icon: Icons.dry_cleaning, emoji: '🩲'),
      CategoryItem(id: 'boys_pyjamas', labelAr: 'بيجامات', labelFr: 'Pyjamas', labelEn: 'Pajamas', color: _boysColor, icon: Icons.bedtime, emoji: '🌙'),
      CategoryItem(id: 'boys_jeans', labelAr: 'جينز', labelFr: 'Jeans', labelEn: 'Jeans', color: _boysColor, icon: Icons.checkroom, emoji: '👖'),
    ]),
    CategoryItem(id: 'boys_shoes', labelAr: 'صباط', labelFr: 'Chaussures', labelEn: 'Shoes', color: _boysColor, icon: Icons.man, emoji: '👟', children: [
      CategoryItem(id: 'boys_formelles', labelAr: 'صباط رسمي', labelFr: 'Formelles', labelEn: 'Dress Shoes', color: _boysColor, icon: Icons.man, emoji: '👞'),
      CategoryItem(id: 'boys_sneakers', labelAr: 'سبادري', labelFr: 'Baskets', labelEn: 'Baskets', color: _boysColor, icon: Icons.man, emoji: '👟'),
      CategoryItem(id: 'boys_sandales', labelAr: 'صندالة', labelFr: 'Sandales', labelEn: 'Sandals', color: _boysColor, icon: Icons.man, emoji: '🩴'),
      CategoryItem(id: 'boys_bottes', labelAr: 'بوط', labelFr: 'Bottes', labelEn: 'Boots', color: _boysColor, icon: Icons.man, emoji: '👢'),
      CategoryItem(id: 'boys_chaussons', labelAr: 'سبادري', labelFr: 'Claquettes', labelEn: 'Claquettes', color: _boysColor, icon: Icons.man, emoji: '🩴'),
      CategoryItem(id: 'boys_crampons', labelAr: 'كرامبون', labelFr: 'Crampons', labelEn: 'Cleats', color: _boysColor, icon: Icons.sports_soccer, emoji: '⚽'),
    ]),
    CategoryItem(id: 'boys_bags', labelAr: 'سكارة', labelFr: 'Sacs', labelEn: 'Bags', color: _boysColor, icon: Icons.shopping_bag, emoji: '🎒', children: [
      CategoryItem(id: 'boys_sac_dos', labelAr: 'سكارة ظهر', labelFr: 'Dos', labelEn: 'Backpacks', color: _boysColor, icon: Icons.backpack, emoji: '🎒'),
      CategoryItem(id: 'boys_sac_voyage', labelAr: 'فاليز', labelFr: 'Valise', labelEn: 'Suitcase', color: _boysColor, icon: Icons.luggage, emoji: '🧳'),
      CategoryItem(id: 'boys_portefeuilles', labelAr: 'بورتفاي', labelFr: 'Portefeuilles', labelEn: 'Wallets', color: _boysColor, icon: Icons.account_balance_wallet, emoji: '👛'),
      CategoryItem(id: 'boys_crossbody', labelAr: 'سكارة كروسبودي', labelFr: 'Crossbody', labelEn: 'Crossbody Bags', color: _boysColor, icon: Icons.shopping_bag, emoji: '💼'),
    ]),
    CategoryItem(id: 'boys_accessories', labelAr: 'أكسسوارات', labelFr: 'Accessoires', labelEn: 'Accessories', color: _boysColor, icon: Icons.watch, emoji: '⌚', children: [
      CategoryItem(id: 'boys_montres', labelAr: 'مغانة', labelFr: 'Montres', labelEn: 'Watches', color: _boysColor, icon: Icons.watch, emoji: '⌚'),
      CategoryItem(id: 'boys_lunettes', labelAr: 'نظاضر', labelFr: 'Lunettes', labelEn: 'Eyewear', color: _boysColor, icon: Icons.visibility, emoji: '🕶️'),
      CategoryItem(id: 'boys_ceintures', labelAr: 'سبتة', labelFr: 'Ceintures', labelEn: 'Belts', color: _boysColor, icon: Icons.horizontal_rule, emoji: '🥋'),
      CategoryItem(id: 'boys_cravates', labelAr: 'كرافات', labelFr: 'Cravates', labelEn: 'Ties', color: _boysColor, icon: Icons.style, emoji: '👔'),
      CategoryItem(id: 'boys_noeuds', labelAr: 'نود بابيون', labelFr: 'Nœuds papillon', labelEn: 'Bow Ties', color: _boysColor, icon: Icons.blur_circular, emoji: '🎀'),
      CategoryItem(id: 'boys_casquettes', labelAr: 'كاسكيط', labelFr: 'Casquettes', labelEn: 'Caps', color: _boysColor, icon: Icons.sports_baseball, emoji: '🧢'),
    ]),
  ]),
];

final List<CategoryItem> rentalCategories = [
  CategoryItem(id: 'women_rental', labelAr: 'نساء', labelFr: 'Femmes', labelEn: 'Women', color: _rentalWomenColor, icon: Icons.woman, emoji: '👰', children: [
    CategoryItem(id: 'rental_women_clothes', labelAr: 'حوايج', labelFr: 'Vêtements', labelEn: 'Clothing', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '👗', children: [
      CategoryItem(id: 'robe_mariee', labelAr: 'روبة عرس', labelFr: 'Robe de mariée ★', labelEn: 'Wedding Dress ★', color: _rentalWomenColor, icon: Icons.favorite, emoji: '👰', isSpecial: true),
      CategoryItem(id: 'robe_soiree', labelAr: 'روبة سواريه', labelFr: 'Robe de soirée ★', labelEn: 'Evening Gown ★', color: _rentalWomenColor, icon: Icons.star, emoji: '✨', isSpecial: true),
      CategoryItem(id: 'ensemble_arabi', labelAr: 'أنسومبل عربي', labelFr: 'Ensemble arabe ★', labelEn: 'Arabic Ensemble ★', color: _rentalWomenColor, icon: Icons.star, emoji: '👑', isSpecial: true),
      CategoryItem(id: 'robes_rental', labelAr: 'روبات', labelFr: 'Robes', labelEn: 'Dresses', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '👗'),
      CategoryItem(id: 'gaftan_rental', labelAr: 'قفطان', labelFr: 'Kaftan', labelEn: 'Kaftan', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '👘'),
      CategoryItem(id: 'jupes_rental', labelAr: 'جيب', labelFr: 'Jupes', labelEn: 'Skirts', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '💃'),
      CategoryItem(id: 'pantalons_rental', labelAr: 'سراويل', labelFr: 'Pantalons', labelEn: 'Pants', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '👖'),
      CategoryItem(id: 'chemises_rental', labelAr: 'قمجات', labelFr: 'Chemises', labelEn: 'Shirts', color: _rentalWomenColor, icon: Icons.dry_cleaning, emoji: '👔'),
      CategoryItem(id: 'vestes_rental', labelAr: 'فيستات', labelFr: 'Vestes', labelEn: 'Jackets', color: _rentalWomenColor, icon: Icons.cases, emoji: '🧥'),
      CategoryItem(id: 'ensembles_rental', labelAr: 'أنسومبل', labelFr: 'Ensembles', labelEn: 'Outfits', color: _rentalWomenColor, icon: Icons.checkroom, emoji: '👘'),
      CategoryItem(id: 'pulls_rental', labelAr: 'بولات', labelFr: 'Pulls', labelEn: 'Sweaters', color: _rentalWomenColor, icon: Icons.dry_cleaning, emoji: '👚'),
      CategoryItem(id: 'sport_rental', labelAr: 'حوايج سبور', labelFr: 'Sport', labelEn: 'Sportswear', color: _rentalWomenColor, icon: Icons.sports, emoji: '🏃‍♀️'),
      CategoryItem(id: 'manteaux_rental', labelAr: 'كبابيط', labelFr: 'Manteaux', labelEn: 'Coats', color: _rentalWomenColor, icon: Icons.umbrella, emoji: '🧥'),
    ]),
    CategoryItem(id: 'rental_women_shoes', labelAr: 'صباط', labelFr: 'Chaussures', labelEn: 'Shoes', color: _rentalWomenColor, icon: Icons.man, emoji: '👠', children: [
      CategoryItem(id: 'talons_rental', labelAr: 'صباط بالكعب', labelFr: 'Talons', labelEn: 'Heels', color: _rentalWomenColor, icon: Icons.man, emoji: '👠'),
      CategoryItem(id: 'plates_rental', labelAr: 'صباط مسطح', labelFr: 'Plates', labelEn: 'Flats', color: _rentalWomenColor, icon: Icons.man, emoji: '🥿'),
      CategoryItem(id: 'sandales_rental_f', labelAr: 'صندالة', labelFr: 'Sandales', labelEn: 'Sandals', color: _rentalWomenColor, icon: Icons.man, emoji: '👡'),
      CategoryItem(id: 'bottes_rental_f', labelAr: 'بوط', labelFr: 'Bottes', labelEn: 'Boots', color: _rentalWomenColor, icon: Icons.man, emoji: '👢'),
      CategoryItem(id: 'sneakers_rental_f', labelAr: 'سبادري', labelFr: 'Baskets', labelEn: 'Baskets', color: _rentalWomenColor, icon: Icons.man, emoji: '👟'),
    ]),
    CategoryItem(id: 'rental_women_bags', labelAr: 'سكارة', labelFr: 'Sacs', labelEn: 'Bags', color: _rentalWomenColor, icon: Icons.shopping_bag, emoji: '👜', children: [
      CategoryItem(id: 'bags_rental_f', labelAr: 'سكارة يد', labelFr: 'Main', labelEn: 'Handbags', color: _rentalWomenColor, icon: Icons.shopping_bag, emoji: '👜'),
      CategoryItem(id: 'clutch_soiree', labelAr: 'كلتش سواريه', labelFr: 'Clutch soirée', labelEn: 'Evening Clutch', color: _rentalWomenColor, icon: Icons.shopping_bag, emoji: '💼'),
      CategoryItem(id: 'sac_dos_rental_f', labelAr: 'سكارة ظهر', labelFr: 'Dos', labelEn: 'Backpacks', color: _rentalWomenColor, icon: Icons.backpack, emoji: '🎒'),
      CategoryItem(id: 'sac_voyage_rental_f', labelAr: 'فاليز', labelFr: 'Valise', labelEn: 'Suitcase', color: _rentalWomenColor, icon: Icons.luggage, emoji: '🧳'),
      CategoryItem(id: 'portefeuilles_rental_f', labelAr: 'بورتفاي', labelFr: 'Portefeuilles', labelEn: 'Wallets', color: _rentalWomenColor, icon: Icons.account_balance_wallet, emoji: '👛'),
    ]),
    CategoryItem(id: 'rental_women_accessories', labelAr: 'أكسسوارات', labelFr: 'Accessoires', labelEn: 'Accessories', color: _rentalWomenColor, icon: Icons.diamond, emoji: '💍', children: [
      CategoryItem(id: 'bijoux_rental_f', labelAr: 'مصاغ', labelFr: 'Bijoux', labelEn: 'Jewelry', color: _rentalWomenColor, icon: Icons.diamond, emoji: '💎'),
      CategoryItem(id: 'montres_rental_f', labelAr: 'مغانة', labelFr: 'Montres', labelEn: 'Watches', color: _rentalWomenColor, icon: Icons.watch, emoji: '⌚'),
      CategoryItem(id: 'lunettes_rental_f', labelAr: 'نظاضر', labelFr: 'Lunettes', labelEn: 'Eyewear', color: _rentalWomenColor, icon: Icons.visibility, emoji: '🕶️'),
      CategoryItem(id: 'echarpes_rental', labelAr: 'شال', labelFr: 'Écharpes', labelEn: 'Scarves', color: _rentalWomenColor, icon: Icons.ac_unit, emoji: '🧣'),
      CategoryItem(id: 'chapeaux_rental', labelAr: 'شابو', labelFr: 'Chapeaux', labelEn: 'Hats', color: _rentalWomenColor, icon: Icons.sports_baseball, emoji: '👒'),
      CategoryItem(id: 'ceintures_rental_f', labelAr: 'سبتة', labelFr: 'Ceintures', labelEn: 'Belts', color: _rentalWomenColor, icon: Icons.horizontal_rule, emoji: '🪢'),
    ]),
  ]),
  CategoryItem(id: 'men_rental', labelAr: 'رجال', labelFr: 'Hommes', labelEn: 'Men', color: _menColor, icon: Icons.man, emoji: '🤵', children: [
    CategoryItem(id: 'rental_men_clothes', labelAr: 'حوايج', labelFr: 'Vêtements', labelEn: 'Clothing', color: _menColor, icon: Icons.checkroom, emoji: '🤵', children: [
      CategoryItem(id: 'costume_arabe', labelAr: 'كوستيم عربي', labelFr: 'Costume arabe ★', labelEn: 'Arabic Suit ★', color: _menColor, icon: Icons.star, emoji: '👳‍♂️', isSpecial: true),
      CategoryItem(id: 'djebba', labelAr: 'جبة عربي', labelFr: 'Djebba arabe ★', labelEn: 'Arabic Djebba ★', color: _menColor, icon: Icons.star, emoji: '👳', isSpecial: true),
      CategoryItem(id: 'costumes_formels', labelAr: 'كوستيم رسمي', labelFr: 'Costume formel', labelEn: 'Formal Suit', color: _menColor, icon: Icons.checkroom, emoji: '🤵'),
      CategoryItem(id: 'tshirts_rental', labelAr: 'تريكوات', labelFr: 'T-shirts', labelEn: 'T-shirts', color: _menColor, icon: Icons.checkroom, emoji: '👕'),
      CategoryItem(id: 'chemises_rental_m', labelAr: 'قمجات', labelFr: 'Chemises', labelEn: 'Shirts', color: _menColor, icon: Icons.dry_cleaning, emoji: '👔'),
      CategoryItem(id: 'pantalons_rental_m', labelAr: 'سراويل', labelFr: 'Pantalons', labelEn: 'Pants', color: _menColor, icon: Icons.checkroom, emoji: '👖'),
      CategoryItem(id: 'vestes_rental_m', labelAr: 'فيستات', labelFr: 'Vestes', labelEn: 'Jackets', color: _menColor, icon: Icons.cases, emoji: '🧥'),
      CategoryItem(id: 'short_rental_m', labelAr: 'شورت', labelFr: 'Short', labelEn: 'Shorts', color: _menColor, icon: Icons.checkroom, emoji: '🩳'),
      CategoryItem(id: 'sport_rental_m', labelAr: 'حوايج سبور', labelFr: 'Sport', labelEn: 'Sportswear', color: _menColor, icon: Icons.sports, emoji: '🏃'),
      CategoryItem(id: 'jeans_rental', labelAr: 'جينز', labelFr: 'Jeans', labelEn: 'Jeans', color: _menColor, icon: Icons.checkroom, emoji: '👖'),
    ]),
    CategoryItem(id: 'rental_men_shoes', labelAr: 'صباط', labelFr: 'Chaussures', labelEn: 'Shoes', color: _menColor, icon: Icons.man, emoji: '👟', children: [
      CategoryItem(id: 'shoes_rental_m', labelAr: 'صباط رسمي', labelFr: 'Formelles', labelEn: 'Dress Shoes', color: _menColor, icon: Icons.man, emoji: '👞'),
      CategoryItem(id: 'sneakers_rental_m', labelAr: 'سبادري', labelFr: 'Baskets', labelEn: 'Baskets', color: _menColor, icon: Icons.man, emoji: '👟'),
      CategoryItem(id: 'sandales_rental_m', labelAr: 'صندالة', labelFr: 'Sandales', labelEn: 'Sandals', color: _menColor, icon: Icons.man, emoji: '🩴'),
      CategoryItem(id: 'bottes_rental_m', labelAr: 'بوط', labelFr: 'Bottes', labelEn: 'Boots', color: _menColor, icon: Icons.man, emoji: '👢'),
      CategoryItem(id: 'crampons_rental_m', labelAr: 'كرامبون', labelFr: 'Crampons', labelEn: 'Cleats', color: _menColor, icon: Icons.sports_soccer, emoji: '⚽'),
    ]),
    CategoryItem(id: 'rental_men_bags', labelAr: 'سكارة', labelFr: 'Sacs', labelEn: 'Bags', color: _menColor, icon: Icons.shopping_bag, emoji: '🎒', children: [
      CategoryItem(id: 'bags_rental_m', labelAr: 'سكارة ظهر', labelFr: 'Dos', labelEn: 'Backpacks', color: _menColor, icon: Icons.backpack, emoji: '🎒'),
      CategoryItem(id: 'sac_voyage_rental_m', labelAr: 'فاليز', labelFr: 'Valise', labelEn: 'Suitcase', color: _menColor, icon: Icons.luggage, emoji: '🧳'),
      CategoryItem(id: 'portefeuilles_rental_m', labelAr: 'بورتفاي', labelFr: 'Portefeuilles', labelEn: 'Wallets', color: _menColor, icon: Icons.account_balance_wallet, emoji: '👛'),
    ]),
    CategoryItem(id: 'rental_men_accessories', labelAr: 'أكسسوارات', labelFr: 'Accessoires', labelEn: 'Accessories', color: _menColor, icon: Icons.watch, emoji: '⌚', children: [
      CategoryItem(id: 'accessories_rental_m', labelAr: 'مغانة', labelFr: 'Montres', labelEn: 'Watches', color: _menColor, icon: Icons.watch, emoji: '⌚'),
      CategoryItem(id: 'lunettes_rental_m', labelAr: 'نظاضر', labelFr: 'Lunettes', labelEn: 'Eyewear', color: _menColor, icon: Icons.visibility, emoji: '🕶️'),
      CategoryItem(id: 'ceintures_rental_m', labelAr: 'سبتة', labelFr: 'Ceintures', labelEn: 'Belts', color: _menColor, icon: Icons.horizontal_rule, emoji: '🥋'),
      CategoryItem(id: 'cravates_rental', labelAr: 'كرافات', labelFr: 'Cravates', labelEn: 'Ties', color: _menColor, icon: Icons.style, emoji: '👔'),
      CategoryItem(id: 'noeuds_rental', labelAr: 'نود بابيون', labelFr: 'Nœuds papillon', labelEn: 'Bow Ties', color: _menColor, icon: Icons.blur_circular, emoji: '🎀'),
      CategoryItem(id: 'casquettes_rental', labelAr: 'كاسكيط', labelFr: 'Casquettes', labelEn: 'Caps', color: _menColor, icon: Icons.sports_baseball, emoji: '🧢'),
    ]),
  ]),
];