import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

// ══════════════════════════════════════════════════════════════
// ── نموذج التصنيف ─────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════
// ── Models ────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════
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
    if (rawImages is List) {
      images = rawImages.map((e) => e.toString()).toList();
    }
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
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final int maxLines;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextDirection? textDirection;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.textDirection,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: widget.obscureText ? _obscure : false,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textDirection: widget.textDirection,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefix,
        suffixIcon: widget.obscureText
            ? IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        )
            : widget.suffix,
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? brandGradient
              : const LinearGradient(colors: [Colors.grey, Colors.grey]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: onPressed != null
              ? [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              // Safety net: shrinks the label only if it would overflow the
              // fixed-height button; renders identically when it fits.
              : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ── EditProductScreen ──────────────────────────────────────────
// ══════════════════════════════════════════════════════════════
const _ownerSelect =
    'profiles(id, username, avatar_url, account_type, shop_type, rating_avg, rating_count)';

class EditProductScreen extends StatefulWidget {
  final String productId;
  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  ProductModel? _product;
  bool _isLoading = true;
  bool _isSaving = false;
  String _condition = 'new';
  bool _isOriginal = false;

  // ── حالة التصنيفات (جديد) ──
  String? _categoryMain;
  String? _categorySub;
  String? _categoryItem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _sizeCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── قائمة التصنيفات حسب نوع المنتج ──
  List<CategoryItem> get _currentCategories =>
      (_product?.isRental ?? false) ? rentalCategories : saleCategories;

  Future<void> _load() async {
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select('*, $_ownerSelect')
          .eq('id', widget.productId)
          .single();
      final product = ProductModel.fromJson(data);
      setState(() {
        _product = product;
        _titleCtrl.text = product.title;
        _descCtrl.text = product.description ?? '';
        _sizeCtrl.text = product.size ?? '';
        _priceCtrl.text = product.price.toString();
        _condition = product.condition;
        _isOriginal = product.isOriginal;
        // ── تعبئة التصنيفات من المنتج (جديد) ──
        _categoryMain = product.categoryMain;
        _categorySub = product.categorySub;
        _categoryItem = product.categoryItem;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client
          .from('products')
          .update({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'taille':
        _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
        'condition': _condition,
        'is_original': _isOriginal,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        // ── حفظ التصنيفات المحدّثة (جديد) ──
        'category_main': _categoryMain ?? '',
        'category_sub': _categorySub ?? '',
        'category_item': _categoryItem ?? '',
        'published_at': DateTime.now().toIso8601String(),
      })
          .eq('id', widget.productId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Produit mis à jour'),
              backgroundColor: successColor),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Modifier l\'article'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── التصنيف (جديد) ──
              _buildCategorySelector(),
              const SizedBox(height: 24),

              // ── التفاصيل ──
              const Text('Détails du produit',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Titre *',
                controller: _titleCtrl,
                validator: (v) =>
                v == null || v.isEmpty ? 'Le titre est requis' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                controller: _descCtrl,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Taille',
                controller: _sizeCtrl,
                prefix: const Icon(Icons.straighten_outlined),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // ── الحالة ──
              const Text('État',
                  style:
                  TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ConditionChip('✨ Nouveau', 'new'),
                  const SizedBox(width: 8),
                  _ConditionChip('👍 Bon état', 'good_used'),
                  const SizedBox(width: 8),
                  _ConditionChip('👕 Utilisé', 'used'),
                ],
              ),
              const SizedBox(height: 16),

              // ── أصلي ──
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Article original',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        Text('Marque originale',
                            style: TextStyle(
                                color: textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOriginal,
                    onChanged: (v) => setState(() => _isOriginal = v),
                    activeColor: primaryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── السعر ──
              const Text('Prix',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 12),
              AppTextField(
                label: _product?.isRental == true
                    ? 'Prix par jour (TND) *'
                    : 'Prix (TND) *',
                controller: _priceCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                prefix: const Icon(Icons.attach_money),
                validator: (v) =>
                v == null || v.isEmpty ? 'Le prix est requis' : null,
              ),
              const SizedBox(height: 32),

              GradientButton(
                label: 'Sauvegarder',
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
                icon: const Icon(Icons.save_outlined, color: Colors.white),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── Widget اختيار التصنيف (جديد — نفس منطق AddProductScreen) ─
  // ══════════════════════════════════════════════════════════════
  Widget _buildCategorySelector() {
    final categories = _currentCategories;

    final mainExists =
        _categoryMain != null && categories.any((c) => c.id == _categoryMain);
    final subList = mainExists
        ? categories.firstWhere((c) => c.id == _categoryMain).children
        : <CategoryItem>[];
    final subExists =
        _categorySub != null && subList.any((c) => c.id == _categorySub);
    final level3 = subExists
        ? subList.firstWhere((c) => c.id == _categorySub).children
        : <CategoryItem>[];

    final mainCat =
    mainExists ? categories.firstWhere((c) => c.id == _categoryMain) : null;
    final subCat =
    subExists ? subList.firstWhere((c) => c.id == _categorySub) : null;
    final itemCat = level3.isNotEmpty &&
        _categoryItem != null &&
        level3.any((c) => c.id == _categoryItem)
        ? level3.firstWhere((c) => c.id == _categoryItem)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── العنوان ──
        const Text('Catégorie',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 4),

        // ── Breadcrumb المرئي ──
        if (mainCat != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              _BreadcrumbChip(label: '${mainCat.emoji} ${mainCat.labelFr}', color: mainCat.color),
              if (subCat != null) ...[
                Icon(Icons.chevron_right, size: 16, color: textSecondary.withOpacity(0.6)),
                _BreadcrumbChip(label: '${subCat.emoji} ${subCat.labelFr}', color: subCat.color),
              ],
              if (itemCat != null) ...[
                Icon(Icons.chevron_right, size: 16, color: textSecondary.withOpacity(0.6)),
                _BreadcrumbChip(
                  label: '${itemCat.emoji} ${itemCat.labelFr}',
                  color: itemCat.color,
                  isLeaf: true,
                  isSpecial: itemCat.isSpecial,
                ),
              ],
            ]),
          ),

        // ── Level 1 — الرئيسي ──
        _buildDropdown(
          value: mainExists ? _categoryMain : null,
          hint: 'Catégorie principale',
          items: categories,
          onChanged: (v) => setState(() {
            _categoryMain = v;
            _categorySub = null;
            _categoryItem = null;
          }),
        ),

        // ── Level 2 — الفرعي ──
        if (mainExists && subList.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDropdown(
            value: subExists ? _categorySub : null,
            hint: 'Sous-catégorie',
            items: subList,
            onChanged: (v) => setState(() {
              _categorySub = v;
              _categoryItem = null;
            }),
          ),
        ],

        // ── Level 3 — المحدد ──
        if (subExists && level3.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDropdown(
            value: level3.any((c) => c.id == _categoryItem) ? _categoryItem : null,
            hint: 'Article spécifique',
            items: level3,
            onChanged: (v) => setState(() => _categoryItem = v),
            filled: true,
            showSpecial: true,
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<CategoryItem> items,
    required void Function(String?) onChanged,
    bool filled = false,
    bool showSpecial = false,
  }) {
    final safeValue = items.any((c) => c.id == value) ? value : null;

    return Container(
      decoration: BoxDecoration(
        color: filled ? primaryBlue.withOpacity(0.04) : Colors.transparent,
        border: Border.all(color: const Color(0xFFBDBDBD)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButton<String>(
        value: safeValue,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(hint, style: const TextStyle(color: textSecondary)),
        items: items.map((c) {
          return DropdownMenuItem<String>(
            value: c.id,
            child: Row(children: [
              if (showSpecial && c.isSpecial)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('★',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              Text(c.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  c.labelFr,
                  style: TextStyle(
                    fontWeight: (showSpecial && c.isSpecial)
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: (showSpecial && c.isSpecial)
                        ? Colors.amber.shade800
                        : null,
                  ),
                ),
              ),
            ]),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ── Condition Chip ─────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════
  Widget _ConditionChip(String label, String value) {
    final isSelected = _condition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _condition = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
            isSelected ? primaryBlue.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
                color: isSelected ? primaryBlue : const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(10),
          ),
          // Safety net: shrinks the label only if it would overflow the chip.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? primaryBlue : textSecondary,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ── BreadcrumbChip ─────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════
class _BreadcrumbChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLeaf;
  final bool isSpecial;

  const _BreadcrumbChip({
    required this.label,
    required this.color,
    this.isLeaf = false,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLeaf ? color.withOpacity(0.13) : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: isLeaf ? Border.all(color: color.withOpacity(0.35)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isLeaf ? color : textSecondary,
                  fontWeight:
                  isLeaf ? FontWeight.w600 : FontWeight.normal)),
          if (isSpecial) ...[
            const SizedBox(width: 4),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('★',
                  style: TextStyle(fontSize: 9, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
