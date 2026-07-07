import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../l10n.dart';
import '../services/ads_service.dart';
import 'package:lebesty/data/categories.dart';

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

const List<String> tunisiaWilayas = [
  'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
  'Bizerte', 'Béja', 'Jendouba', 'Le Kef', 'Siliana', 'Sousse',
  'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
  'Gabès', 'Medenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kebili',
];


CategoryItem? _findCategoryById(String id, List<CategoryItem> list) {
  for (final cat in list) {
    if (cat.id == id) return cat;
    final found = _findCategoryById(id, cat.children);
    if (found != null) return found;
  }
  return null;
}

CategoryItem? _resolveDisplayCategory(ProductModel product) {
  final allLists = [saleCategories, rentalCategories];
  for (final list in allLists) {
    if (product.categoryItem != null && product.categoryItem!.isNotEmpty) {
      final found = _findCategoryById(product.categoryItem!, list);
      if (found != null) return found;
    }
    if (product.categorySub != null && product.categorySub!.isNotEmpty) {
      final found = _findCategoryById(product.categorySub!, list);
      if (found != null) return found;
    }
    if (product.categoryMain != null && product.categoryMain!.isNotEmpty) {
      final found = _findCategoryById(product.categoryMain!, list);
      if (found != null) return found;
    }
  }
  return null;
}

class ProductFilter {
  final List<String> wilayas;
  final String productType;
  final bool originalOnly;
  final String? categoryMain;
  final String? categorySub;
  final List<String> categoryItems;

  const ProductFilter({
    this.wilayas = const [],
    this.productType = 'sale',
    this.originalOnly = false,
    this.categoryMain,
    this.categorySub,
    this.categoryItems = const [],
  });

  bool get hasCategory => categoryMain != null;

  bool get hasActiveFilters =>
      wilayas.isNotEmpty ||
          originalOnly ||
          hasCategory ||
          categoryItems.isNotEmpty ||
          productType != 'sale';

  ProductFilter copyWith({
    List<String>? wilayas,
    String? productType,
    bool? originalOnly,
    String? categoryMain,
    String? categorySub,
    List<String>? categoryItems,
    bool clearCategory = false,
  }) {
    return ProductFilter(
      wilayas: wilayas ?? this.wilayas,
      productType: productType ?? this.productType,
      originalOnly: originalOnly ?? this.originalOnly,
      categoryMain: clearCategory ? null : (categoryMain ?? this.categoryMain),
      categorySub: clearCategory ? null : (categorySub ?? this.categorySub),
      categoryItems: clearCategory ? [] : (categoryItems ?? this.categoryItems),
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final ProductFilter current;
  final void Function(ProductFilter) onApply;

  const FilterBottomSheet({
    super.key,
    required this.current,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<String> _selectedWilayas;
  late String _productType;
  late bool _originalOnly;
  String? _categoryMain;
  late List<String> _categoryItems;

  @override
  void initState() {
    super.initState();
    _selectedWilayas = List.from(widget.current.wilayas);
    _productType = widget.current.productType;
    _originalOnly = widget.current.originalOnly;
    _categoryMain = widget.current.categoryMain;
    _categoryItems = List.from(widget.current.categoryItems);
  }

  List<CategoryItem> get _categories =>
      _productType == 'rental' ? rentalCategories : saleCategories;

  CategoryItem? get _selectedMainCat {
    if (_categoryMain == null) return null;
    final idx = _categories.indexWhere((c) => c.id == _categoryMain);
    return idx == -1 ? null : _categories[idx];
  }

  void _reset() {
    setState(() {
      _selectedWilayas = [];
      _productType = 'sale';
      _originalOnly = false;
      _categoryMain = null;
      _categoryItems = [];
    });
  }

  ProductFilter _buildCurrentFilter() {
    return ProductFilter(
      wilayas: _selectedWilayas,
      productType: _productType,
      originalOnly: _originalOnly,
      categoryMain: _categoryMain,
      categorySub: null,
      categoryItems: _categoryItems,
    );
  }

  List<String> _itemIdsOf(CategoryItem sub) =>
      sub.children.map((e) => e.id).toList();

  bool _isSubFullyOn(CategoryItem sub) {
    final ids = _itemIdsOf(sub);
    if (ids.isEmpty) return false;
    return ids.every((id) => _categoryItems.contains(id));
  }

  void _toggleSubAll(CategoryItem sub, bool value) {
    final ids = _itemIdsOf(sub);
    setState(() {
      if (value) {
        for (final id in ids) {
          if (!_categoryItems.contains(id)) _categoryItems.add(id);
        }
      } else {
        _categoryItems.removeWhere((id) => ids.contains(id));
      }
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_categoryItems.contains(id)) {
        _categoryItems.remove(id);
      } else {
        _categoryItems.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: isDark ? surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildTitle(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeToggle(),
                  const SizedBox(height: 24),
                  _buildOriginalToggle(),
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  _buildWilayaSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              widget.onApply(_buildCurrentFilter());
              Navigator.of(context).pop();
            },
            tooltip: context.tr('back_apply'),
          ),
          Expanded(
            child: Text(context.tr('filters'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: _reset,
            child: Text(context.tr('clear'), style: const TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('type_label'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        _buildTypeToggleWidget(context, _productType, (value) {
          setState(() {
            _productType = value;
            _categoryMain = null;
            _categoryItems = [];
          });
        }),
      ],
    );
  }

  Widget _buildOriginalToggle() {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('original_only'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Text(context.tr('show_originals'), style: const TextStyle(color: textSecondary, fontSize: 13)),
          ]),
        ),
        Switch(value: _originalOnly, onChanged: (v) => setState(() => _originalOnly = v), activeColor: primaryBlue),
      ],
    );
  }

  Widget _buildCategorySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(context.tr('category'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          if (_categoryItems.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(12)),
              child: Text('${_categoryItems.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
          const Spacer(),
          if (_categoryItems.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _categoryItems = []),
              child: Text(context.tr('clear'), style: const TextStyle(color: textSecondary, fontSize: 13)),
            ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isSelected = _categoryMain == cat.id;
              final showCheck = isSelected && _categoryItems.isEmpty;
              return GestureDetector(
                onTap: () => setState(() {
                  if (_categoryMain != cat.id) {
                    _categoryMain = cat.id;
                    _categoryItems = [];
                  }
                }),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.transparent,
                        border: Border.all(color: isSelected ? primaryBlue : const Color(0xFFE0E0E0), width: isSelected ? 2 : 1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(AppL10n.catLabel(context, cat.labelFr, cat.labelAr), textAlign: TextAlign.center, maxLines: 2,
                            style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? primaryBlue : null)),
                      ]),
                    ),
                    if (showCheck)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? surfaceDark : Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.check, size: 11, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_selectedMainCat != null) ...[
          const SizedBox(height: 8),
          ..._selectedMainCat!.children.map((sub) => _buildSubGroup(sub)).toList(),
        ],
      ],
    );
  }

  Widget _buildSubGroup(CategoryItem sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = sub.children;
    final fullyOn = _isSubFullyOn(sub);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(sub.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppL10n.catLabel(context, sub.labelFr, sub.labelAr).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white : textPrimary,
                ),
              ),
            ),
            if (items.isNotEmpty)
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: fullyOn,
                  onChanged: (v) => _toggleSubAll(sub, v),
                  activeColor: primaryBlue,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final item = items[i];
                final isSelected = _categoryItems.contains(item.id);
                return _buildItemCircle(item, isSelected, isDark);
              },
            ),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildItemCircle(CategoryItem item, bool isSelected, bool isDark) {
    final accent = item.isSpecial ? Colors.amber.shade700 : primaryBlue;
    final circleBg = isDark ? const Color(0xFFEFF3F4) : const Color(0xFFF4F7FA);
    return GestureDetector(
      onTap: () => _toggleItem(item.id),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? accent : const Color(0xFFD8DEE4),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? surfaceDark : Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check, size: 13, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppL10n.catLabel(context, item.labelFr, item.labelAr),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? accent : (isDark ? Colors.white70 : textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWilayaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(context.tr('regions'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          if (_selectedWilayas.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(12)),
              child: Text('${_selectedWilayas.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: tunisiaWilayas.map((w) {
            final isSelected = _selectedWilayas.contains(w);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) { _selectedWilayas.remove(w); }
                else { _selectedWilayas.add(w); }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryBlue : Colors.transparent,
                  border: Border.all(color: isSelected ? primaryBlue : const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(w, style: TextStyle(color: isSelected ? Colors.white : null, fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

Widget _buildTypeToggleWidget(BuildContext context, String currentType, void Function(String) onChanged) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      _buildTypeTabWidget(context.tr('for_sale'), 'sale', currentType, onChanged),
      _buildTypeTabWidget(context.tr('for_rental'), 'rental', currentType, onChanged),
    ]),
  );
}

Widget _buildTypeTabWidget(String label, String value, String current, void Function(String) onTap) {
  final isSelected = current == value;
  return Expanded(
    child: GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            )),
      ),
    ),
  );
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
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(5, (i) {
        if (i < rating.floor()) return Icon(Icons.star, size: size, color: warningColor);
        else if (i < rating && rating - i >= 0.5) return Icon(Icons.star_half, size: size, color: warningColor);
        else return Icon(Icons.star_border, size: size, color: Colors.grey[300]);
      }),
      if (showCount && count > 0) ...[const SizedBox(width: 4), Text('($count)', style: TextStyle(fontSize: size * 0.75, color: Colors.grey))],
    ]);
  }
}

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
    // ← AspectRatio يضمن أن خانة الإعلان لها نفس حجم كارد المنتج دائماً،
    //   سواء تحمّل الإعلان أو فشل. هذا يمنع انهيار الصف لارتفاع صفر،
    //   وهو سبب اختفاء المنتجات التي تأتي بعد الإعلان.
    return AspectRatio(
      aspectRatio: 1 / 1.6, // نفس نسبة كارد المنتج في القائمة
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
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildImage(context),
          _buildInfo(context, isDark),
        ]),
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
          Positioned(top: 8, left: 8, child: _buildBadge(product.isRental ? context.tr('rental_badge') : context.tr('sale_badge'), product.isRental ? primaryPink : primaryBlue)),
          if (product.isOriginal) Positioned(top: 8, right: 8, child: _buildBadge(context.tr('original_badge'), Colors.amber.shade700)),
        ]),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)));
  }

  Widget _buildInfo(BuildContext context, bool isDark) {
    final displayCat = _resolveDisplayCategory(product);
    final priceNum = product.price == product.price.truncateToDouble()
        ? product.price.toInt().toString()
        : product.price.toStringAsFixed(2);
    final priceStr = product.isRental
        ? '$priceNum${AppL10n.pricePerDay(context)}'
        : '$priceNum TND';
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Text(priceStr, style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: _conditionColor(product.condition).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(AppL10n.conditionLabel(context, product.condition), style: TextStyle(fontSize: 10, color: _conditionColor(product.condition), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 4),
          if (displayCat != null) ...[
            Text(displayCat.emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 3),
            Expanded(
              child: Text(AppL10n.catLabel(context, displayCat.labelFr, displayCat.labelAr),
                  style: const TextStyle(fontSize: 10, color: textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ]),
        if (product.owner != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.store, size: 11, color: textSecondary),
            const SizedBox(width: 2),
            Expanded(child: Text(product.owner!.fullName ?? context.tr('vendor_label'), style: const TextStyle(fontSize: 10, color: textSecondary), overflow: TextOverflow.ellipsis)),
            if (product.owner!.ratingAvg > 0) RatingStars(rating: product.owner!.ratingAvg, size: 10, showCount: false),
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

const _ownerSelect = 'profiles(id, username, avatar_url, account_type, shop_type, rating_avg, rating_count)';

class _HomeTypeToggleDelegate extends SliverPersistentHeaderDelegate {
  final String currentType;
  final void Function(String) onChanged;
  final Color bgColor;

  const _HomeTypeToggleDelegate({
    required this.currentType,
    required this.onChanged,
    required this.bgColor,
  });

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildTypeToggleWidget(context, currentType, onChanged),
    );
  }

  @override
  bool shouldRebuild(_HomeTypeToggleDelegate old) =>
      old.currentType != currentType || old.bgColor != bgColor;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _scrollCtrl = ScrollController();

  // Feed is two segments stitched together:
  //   1) [_todayProducts]  — pinned at top, fetched once per filter/refresh.
  //   2) [_olderProducts]  — paginated infinite loop starting at [_startPosition].
  final List<ProductModel> _todayProducts = [];
  final List<ProductModel> _olderProducts = [];

  // Cutoff = most recent 4 AM Africa/Tunis, as a UTC instant.
  // Products with published_at >= cutoff are "today's", others are "older".
  DateTime? _todayCutoffUtc;

  // Daily-rotating offset into the older feed (read from display_settings).
  int? _startPosition;

  // How many older items we've shown so far (a virtual offset, may exceed
  // [_olderTotalCount] — the real DB offset is computed mod count).
  int _olderShownCount = 0;

  // Discovered the first time pagination hits end-of-list. null = unknown.
  int? _olderTotalCount;

  bool _isLoading = false;
  bool _initialLoaded = false;

  static const int _pageSize = 10;

  ProductFilter _filter = const ProductFilter();

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  List<ConnectivityResult> _lastConn = const [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollCtrl.addListener(_onScroll);
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = _lastConn.isEmpty ||
          _lastConn.every((r) => r == ConnectivityResult.none);
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (wasOffline && isOnline && _todayProducts.isEmpty &&
          _olderProducts.isEmpty && !_isLoading) {
        _refresh();
      }
      _lastConn = results;
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300) {
      if (!_isLoading && _hasMoreOlder) _loadMoreOlder();
    }
  }

  // Older feed shows every matching product exactly once starting from
  // start_position and wrapping once at the oldest. When _olderShownCount
  // reaches the total, we're done.
  bool get _hasMoreOlder {
    final count = _olderTotalCount;
    if (count == null) return false;
    return _olderShownCount < count;
  }

  // Africa/Tunis is UTC+1 year-round (no DST), so 4 AM Tunis == 3 AM UTC of
  // the same Tunis-local calendar date.
  DateTime _computeTodayCutoffUtc() {
    final nowUtc = DateTime.now().toUtc();
    final nowTunis = nowUtc.add(const Duration(hours: 1));
    var cutoff = DateTime.utc(nowTunis.year, nowTunis.month, nowTunis.day, 3);
    if (nowUtc.isBefore(cutoff)) {
      cutoff = cutoff.subtract(const Duration(days: 1));
    }
    return cutoff;
  }

  Future<int> _fetchStartPosition() async {
    try {
      final row = await Supabase.instance.client
          .from('display_settings')
          .select('start_position')
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return 0;
      return (row['start_position'] as int?) ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('display_settings fetch error: $e');
      return 0;
    }
  }

  // Builds the products select+filters used by both today and older queries.
  // [olderThan]      -> requires published_at < olderThan
  // [newerOrEqualTo] -> requires published_at >= newerOrEqualTo
  dynamic _buildProductsQuery({DateTime? olderThan, DateTime? newerOrEqualTo}) {
    final supabase = Supabase.instance.client;
    var query = supabase
        .from('products')
        .select(
            'id, user_id, product_type, category_main, category_sub, category_item, title, condition, is_original, price, main_image_url, published_at, $_ownerSelect')
        .eq('is_active', true)
        .eq('nsfw_status', 'approved')
        .eq('product_type', _filter.productType);

    if (olderThan != null) {
      query = query.lt('published_at', olderThan.toIso8601String());
    }
    if (newerOrEqualTo != null) {
      query = query.gte('published_at', newerOrEqualTo.toIso8601String());
    }
    if (_filter.originalOnly) query = query.eq('is_original', true);
    if (_filter.wilayas.isNotEmpty) {
      query = query.inFilter('wilaya', _filter.wilayas);
    }
    if (_filter.categoryItems.isNotEmpty) {
      query = query.inFilter('category_item', _filter.categoryItems);
    } else if (_filter.categorySub != null) {
      query = query.eq('category_sub', _filter.categorySub!);
    } else if (_filter.categoryMain != null) {
      query = query.eq('category_main', _filter.categoryMain!);
    }
    return query;
  }

  Future<List<ProductModel>> _fetchTodayProducts(DateTime cutoff) async {
    try {
      final query = _buildProductsQuery(newerOrEqualTo: cutoff);
      final response = await query
          .order('published_at', ascending: false)
          .limit(200);
      return (response as List)
          .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('today products error: $e');
      return [];
    }
  }

  Future<List<ProductModel>> _queryOlderRange(int offset, int limit) async {
    if (limit <= 0 || _todayCutoffUtc == null) return [];
    final query = _buildProductsQuery(olderThan: _todayCutoffUtc!);
    final response = await query
        .order('published_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Total count of older products matching the current filter. Fetched once
  // per refresh/filter change so pagination can stop after exactly one cycle.
  // `range(0, 0)` keeps the returned data at a single row; the exact total
  // still comes back via the `Prefer: count=exact` header.
  Future<int> _fetchOlderTotalCount() async {
    if (_todayCutoffUtc == null) return 0;
    try {
      final query = _buildProductsQuery(olderThan: _todayCutoffUtc!);
      final response = await query
          .order('published_at', ascending: false)
          .range(0, 0)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      if (kDebugMode) debugPrint('older count error: $e');
      return 0;
    }
  }

  // Full reload: cutoff + start_position + today's products in parallel,
  // then first older page.
  Future<void> _loadInitial() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _initialLoaded = false;
      _todayProducts.clear();
      _olderProducts.clear();
      _olderShownCount = 0;
      _olderTotalCount = null;
      _startPosition = null;
    });

    _todayCutoffUtc = _computeTodayCutoffUtc();

    try {
      final results = await Future.wait<dynamic>([
        _fetchStartPosition(),
        _fetchTodayProducts(_todayCutoffUtc!),
        _fetchOlderTotalCount(),
      ]);
      _startPosition = results[0] as int;
      final todayList = results[1] as List<ProductModel>;
      _olderTotalCount = results[2] as int;

      if (!mounted) return;
      setState(() {
        _todayProducts.addAll(todayList);
        _initialLoaded = true;
      });

      // First older page uses start_position; keep _isLoading true throughout.
      await _loadMoreOlder(reentrant: true);
    } catch (e) {
      if (kDebugMode) debugPrint('initial load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // [reentrant] = true means we're being called from inside another load that
  // already owns _isLoading; we skip the toggling.
  Future<void> _loadMoreOlder({bool reentrant = false}) async {
    if (_startPosition == null || _todayCutoffUtc == null) return;
    if (!_hasMoreOlder) return;
    if (!reentrant) {
      if (_isLoading) return;
      setState(() => _isLoading = true);
    }
    try {
      final batch = await _fetchNextOlderPage();
      if (!mounted) return;
      setState(() => _olderProducts.addAll(batch));
    } catch (e) {
      if (kDebugMode) debugPrint('older page error: $e');
    } finally {
      if (!reentrant && mounted) setState(() => _isLoading = false);
    }
  }

  // Returns the next batch of older products. The sequence is:
  //   start, start+1, ..., count-1, 0, 1, ..., start-1
  // Each product appears exactly once; after the full cycle _hasMoreOlder
  // becomes false. `start` is clamped mod count in case filters shrank the
  // pool below the cron's unfiltered count.
  Future<List<ProductModel>> _fetchNextOlderPage() async {
    final count = _olderTotalCount ?? 0;
    if (count == 0) return [];
    final remaining = count - _olderShownCount;
    if (remaining <= 0) return [];

    final start = _startPosition! % count;
    final pageWant = remaining < _pageSize ? remaining : _pageSize;
    final target = (start + _olderShownCount) % count;
    final preWrap = count - target;

    List<ProductModel> batch;
    if (pageWant <= preWrap) {
      batch = await _queryOlderRange(target, pageWant);
    } else {
      final firstPart = await _queryOlderRange(target, preWrap);
      final secondPart = await _queryOlderRange(0, pageWant - preWrap);
      batch = [...firstPart, ...secondPart];
    }

    _olderShownCount += batch.length;
    return batch;
  }

  Future<void> _refresh() async {
    await _loadInitial();
  }

  void _applyFilter(ProductFilter filter) {
    setState(() => _filter = filter);
    _loadInitial();
  }

  void _changeType(String newType) {
    if (newType == _filter.productType) return;
    _applyFilter(ProductFilter(
      wilayas: _filter.wilayas,
      originalOnly: _filter.originalOnly,
      productType: newType,
    ));
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(current: _filter, onApply: _applyFilter),
    );
  }

  List<dynamic> _buildFeedItems() {
    final items = <dynamic>[];
    final all = [..._todayProducts, ..._olderProducts];
    for (int i = 0; i < all.length; i++) {
      items.add(all[i]);
      if ((i + 1) % 5 == 0) items.add('ad');
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final feedItems = _buildFeedItems();
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: primaryBlue,
          child: CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
                elevation: 0,
                backgroundColor: bgColor,
                title: _buildLogo(context),
                actions: [
                  Stack(children: [
                    IconButton(icon: const Icon(Icons.tune_rounded), onPressed: _openFilter, iconSize: 26, constraints: const BoxConstraints(minWidth: 48, minHeight: 48)),
                    if (_filter.hasActiveFilters)
                      Positioned(right: 8, top: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: primaryPink, shape: BoxShape.circle))),
                  ]),
                ],
              ),

              SliverPersistentHeader(
                pinned: false, floating: true,
                delegate: _HomeTypeToggleDelegate(
                  currentType: _filter.productType,
                  onChanged: _changeType,
                  bgColor: bgColor,
                ),
              ),

              if (!_initialLoaded && _todayProducts.isEmpty && _olderProducts.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((_, i) => const ProductCardShimmer(), childCount: 6),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1 / 1.6),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (ctx, index) {
                      if (index >= feedItems.length) {
                        return _isLoading
                            ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)))
                            : const SizedBox(height: 80);
                      }
                      final item = feedItems[index];
                      if (item == 'ad') return const SizedBox.shrink();
                      final product = item as ProductModel;
                      final isFirstInPair = index % 2 == 0;
                      final nextItem = index + 1 < feedItems.length ? feedItems[index + 1] : null;
                      if (isFirstInPair) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: ProductCard(product: product, index: index)),
                                const SizedBox(width: 8),
                                if (nextItem is ProductModel) Expanded(child: ProductCard(product: nextItem, index: index + 1))
                                else if (nextItem == 'ad') const Expanded(child: NativeAdCard())
                                else const Expanded(child: SizedBox()),
                              ]),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: feedItems.length + 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: brandGradient),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset('assets/images/lebesty_logo.png', fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Text('LB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))),
        ),
      ),
      const SizedBox(width: 10),
      ShaderMask(
        shaderCallback: (bounds) => brandGradient.createShader(bounds),
        child: const Text('Lebesty', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    ]);
  }
}