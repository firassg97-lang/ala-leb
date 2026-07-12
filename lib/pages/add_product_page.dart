import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:lebesty/data/categories.dart';

const double kNsfwThreshold = 0.6;
const String kNsfwPendingMessageAr =
    'هذه الصورة قيد المراجعة وستظهر بعد الموافقة عليها';

bool _nsfwReady = false;

Future<void> _ensureNsfwReady() async {
  if (_nsfwReady) return;
  try {
    await NsfwDetector.initialize(threshold: kNsfwThreshold);
    _nsfwReady = true;
  } catch (_) {
    _nsfwReady = false;
  }
}

Future<double> _detectNsfwScore(File file) async {
  await _ensureNsfwReady();
  if (!_nsfwReady) return 0.0;
  try {
    final result = await NsfwDetector.instance.detectNSFWFromFile(file);
    return result?.score ?? 0.0;
  } catch (_) {
    return 0.0;
  }
}

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
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
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
              ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              // Safety net: shrinks the label only if it would overflow the
              // fixed-height button; renders identically when it fits.
              : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ضغط الصورة الكاملة (للتفاصيل ~150-200KB) ───────────────────────────────
Future<File?> _pickAndCompress({required ImageSource source}) async {
  final XFile? picked = await ImagePicker().pickImage(
    source: source, imageQuality: 100, maxWidth: 2048, maxHeight: 2048, requestFullMetadata: false,
  );
  if (picked == null) return null;
  final dir = await getTemporaryDirectory();
  final target = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final result = await FlutterImageCompress.compressAndGetFile(
    picked.path, target, quality: 85, minWidth: 1024, minHeight: 1024, format: CompressFormat.jpeg,
  );
  if (result == null) return null;
  return File(result.path);
}

// ─── ضغط قوي لـ thumbnail الهوم (~20-30KB) ─────────────────────────────────
Future<File?> _compressThumbnail(File original) async {
  final dir = await getTemporaryDirectory();
  final target = '${dir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final result = await FlutterImageCompress.compressAndGetFile(
    original.path, target,
    quality: 35,        // جودة منخفضة كافية للقائمة الصغيرة
    minWidth: 400,      // أبعاد صغيرة
    minHeight: 400,
    format: CompressFormat.jpeg,
  );
  if (result == null) return null;
  return File(result.path);
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _scrollCtrl = ScrollController();
  int _formVersion = 0;
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _titleCtrl = TextEditingController();
  TextEditingController _descCtrl = TextEditingController();
  TextEditingController _sizeCtrl = TextEditingController();
  TextEditingController _priceCtrl = TextEditingController();

  String _productType = 'sale';
  String? _condition; // ← null افتراضياً — المستخدم يختار
  bool _isOriginal = false;
  bool _isLoading = false;

  File? _mainImage;
  final List<File?> _extraImages = [null, null, null, null];

  double _mainImageNsfwScore = 0.0;
  final List<double> _extraImagesNsfwScore = [0.0, 0.0, 0.0, 0.0];

  String? _categoryMain;
  String? _categorySub;
  String? _categoryItem;

  Map<String, dynamic>? _profile;

  List<CategoryItem> get _currentCategories =>
      _productType == 'sale' ? saleCategories : rentalCategories;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = await Supabase.instance.client
        .from('profiles').select().eq('id', user.id).maybeSingle();
    if (mounted && data != null) setState(() => _profile = data);
  }

  // ─── تصفير الصفحة بعد النشر ───
  void _resetForm() {
    // dispose القديمة وإنشاء جديدة — الحل الوحيد المضمون
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _sizeCtrl.dispose();
    _priceCtrl.dispose();
    setState(() {
      _formVersion++;
      _formKey = GlobalKey<FormState>();
      _titleCtrl = TextEditingController();
      _descCtrl = TextEditingController();
      _sizeCtrl = TextEditingController();
      _priceCtrl = TextEditingController();
      _productType = 'sale';
      _condition = null;
      _isOriginal = false;
      _mainImage = null;
      _mainImageNsfwScore = 0.0;
      for (int i = 0; i < _extraImages.length; i++) {
        _extraImages[i] = null;
        _extraImagesNsfwScore[i] = 0.0;
      }
      _categoryMain = null;
      _categorySub = null;
      _categoryItem = null;
    });
    // الرجوع للأعلى
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _sizeCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _showOriginalToggle {
    if (_profile == null) return false;
    final accountType = _profile!['account_type'] as String? ?? 'user';
    if (accountType == 'user') return true;
    final shopType = _profile!['shop_type'] as String?;
    if (shopType == 'superfripe' || shopType == 'rental') return true;
    return false;
  }

  Future<void> _pickImage({int? extraIndex}) async {
    final source = await _showImageSourcePicker();
    if (source == null) return;
    final file = await _pickAndCompress(source: source);
    if (file == null) return;

    final score = await _detectNsfwScore(file);

    if (!mounted) return;
    setState(() {
      if (extraIndex == null) {
        _mainImage = file;
        _mainImageNsfwScore = score;
      } else {
        _extraImages[extraIndex] = file;
        _extraImagesNsfwScore[extraIndex] = score;
      }
    });
  }

  Future<ImageSource?> _showImageSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Choisir une image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.camera_alt, color: primaryBlue)),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: primaryPink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.photo_library, color: primaryPink)),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File file, String bucket) async {
    final supabase = Supabase.instance.client;
    final uuid = const Uuid().v4();
    final path = '$uuid.jpg';
    await supabase.storage.from(bucket).upload(path, file);
    return supabase.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez ajouter une image principale')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser!;

      // 1. الصورة الرئيسية الكاملة (~200KB) — تظهر في صفحة التفاصيل
      final fullUrl = await _uploadImage(_mainImage!, 'products');

      // 2. thumbnail صغير (~20KB) — يظهر في الهوم فقط لتوفير Bandwidth
      final thumbFile = await _compressThumbnail(_mainImage!);
      final thumbUrl = thumbFile != null
          ? await _uploadImage(thumbFile, 'products')
          : fullUrl; // احتياطي إذا فشل الضغط

      // كل الصور الكاملة (الرئيسية + الإضافية) — تظهر في التفاصيل
      final List<String> imageUrls = [fullUrl ?? ''];
      for (final extra in _extraImages) {
        if (extra != null) {
          final url = await _uploadImage(extra, 'products');
          if (url != null) imageUrls.add(url);
        }
      }

      double maxNsfwScore = _mainImageNsfwScore;
      for (int i = 0; i < _extraImages.length; i++) {
        if (_extraImages[i] != null) {
          maxNsfwScore = math.max(maxNsfwScore, _extraImagesNsfwScore[i]);
        }
      }
      final bool isPending = maxNsfwScore >= kNsfwThreshold;
      final String nsfwStatus = isPending ? 'pending' : 'approved';

      await supabase.from('products').insert({
        'user_id': user.id,
        'product_type': _productType,
        'category_main': _categoryMain ?? '',
        'category_sub': _categorySub ?? '',
        'category_item': _categoryItem ?? '',
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'taille': _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
        'condition': _condition ?? 'used',
        'is_original': _isOriginal,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'images': imageUrls,                  // ← الصور الكاملة للتفاصيل
        'main_image_url': thumbUrl ?? '',     // ← thumbnail صغير للهوم ✅
        'wilaya': _profile?['wilaya'] as String? ?? '',
        'is_active': true,
        'published_at': DateTime.now().toIso8601String(),
        'nsfw_score': maxNsfwScore,
        'nsfw_status': nsfwStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit publié avec succès ✅'), backgroundColor: successColor),
        );
        // ← تصفير الصفحة بدل الانتقال
        _resetForm();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: errorColor));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _canPublish() {
    if (_mainImage == null) return false; // ← صورة رئيسية فقط كافية
    if (_categoryMain == null || _categorySub == null) return false;
    final main = _currentCategories.firstWhere((c) => c.id == _categoryMain, orElse: () => _currentCategories.first);
    final sub = main.children.firstWhere((c) => c.id == _categorySub, orElse: () => main.children.first);
    if (sub.children.isNotEmpty && _categoryItem == null) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_priceCtrl.text.trim().isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ← إخفاء زر الرجوع
        title: const Text('Ajouter un article'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          key: ValueKey(_formVersion),
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagesSection(),
              const SizedBox(height: 24),
              _buildTypeToggle(),
              const SizedBox(height: 24),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              _buildDetailsSection(),
              const SizedBox(height: 24),
              if (_showOriginalToggle) _buildOriginalToggle(),
              const SizedBox(height: 24),
              _buildPriceField(),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Publier l\'article',
                onPressed: _isLoading ? null : _canPublish() ? _submit : null,
                isLoading: _isLoading,
                icon: const Icon(Icons.publish, color: Colors.white),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickImage(),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _mainImage != null ? primaryBlue : const Color(0xFFE0E0E0), width: 2),
            ),
            child: _mainImage != null
                ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_mainImage!, fit: BoxFit.cover))
                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_a_photo, size: 40, color: primaryBlue),
              SizedBox(height: 8),
              Text('Photo principale *', style: TextStyle(color: primaryBlue)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(4, (i) => Expanded(
            child: GestureDetector(
              onTap: () => _pickImage(extraIndex: i),
              child: Container(
                height: 80,
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE0E0E0))),
                child: _extraImages[i] != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(_extraImages[i]!, fit: BoxFit.cover))
                    : const Icon(Icons.add_photo_alternate, color: textSecondary, size: 24),
              ),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type d\'article', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _TypeTab('🛍️ Pour vente', 'sale'),
            _TypeTab('👗 Pour location', 'rental'),
          ]),
        ),
      ],
    );
  }

  Widget _TypeTab(String label, String value) {
    final isSelected = _productType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_productType == value) return;
          setState(() {
            _productType = value;
            _categoryMain = null;
            _categorySub = null;
            _categoryItem = null;
          });
        },
        child: AnimatedContainer(
          duration: 200.ms,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          // Safety net: shrinks the label only if it would overflow the tab.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, textAlign: TextAlign.center,
                style: TextStyle(color: isSelected ? Colors.white : textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return KeyedSubtree(
      key: ValueKey('category_$_productType'),
      child: _CategorySelectorContent(
        productType: _productType,
        categories: _currentCategories,
        categoryMain: _categoryMain,
        categorySub: _categorySub,
        categoryItem: _categoryItem,
        onMainChanged: (v) => setState(() { _categoryMain = v; _categorySub = null; _categoryItem = null; }),
        onSubChanged: (v) => setState(() { _categorySub = v; _categoryItem = null; }),
        onItemChanged: (v) => setState(() => _categoryItem = v),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Détails du produit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Titre *',
          controller: _titleCtrl,
          validator: (v) => v == null || v.isEmpty ? 'Le titre est requis' : null,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Description',
          controller: _descCtrl,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Taille',
          controller: _sizeCtrl,
          textInputAction: TextInputAction.next,
          prefix: const Icon(Icons.straighten_outlined),
        ),
        const SizedBox(height: 16),
        const Text('État', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        const SizedBox(height: 8),
        Row(children: [
          _ConditionChip('✨ Nouveau', 'new'),
          const SizedBox(width: 8),
          _ConditionChip('👍 Bon état', 'good_used'),
          const SizedBox(width: 8),
          _ConditionChip('👕 Utilisé', 'used'),
        ]),
      ],
    );
  }

  Widget _ConditionChip(String label, String value) {
    final isSelected = _condition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _condition = value),
        child: AnimatedContainer(
          duration: 150.ms,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: isSelected ? primaryBlue : const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(10),
          ),
          // Safety net: shrinks the label only if it would overflow the chip.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: isSelected ? primaryBlue : textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalToggle() {
    return Row(
      children: [
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Article original', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Text('Marque originale', style: TextStyle(color: textSecondary, fontSize: 13)),
          ]),
        ),
        Switch(value: _isOriginal, onChanged: (v) => setState(() => _isOriginal = v), activeColor: primaryBlue),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prix', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        AppTextField(
          label: _productType == 'rental' ? 'Prix par jour (TND) *' : 'Prix (TND) *',
          controller: _priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefix: const Icon(Icons.attach_money),
          validator: (v) => v == null || v.isEmpty ? 'Le prix est requis' : null,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _CategorySelectorContent extends StatelessWidget {
  final String productType;
  final List<CategoryItem> categories;
  final String? categoryMain;
  final String? categorySub;
  final String? categoryItem;
  final void Function(String?) onMainChanged;
  final void Function(String?) onSubChanged;
  final void Function(String?) onItemChanged;

  const _CategorySelectorContent({
    required this.productType,
    required this.categories,
    required this.categoryMain,
    required this.categorySub,
    required this.categoryItem,
    required this.onMainChanged,
    required this.onSubChanged,
    required this.onItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mainExists = categoryMain != null && categories.any((c) => c.id == categoryMain);
    final subList = mainExists ? categories.firstWhere((c) => c.id == categoryMain).children : <CategoryItem>[];
    final subExists = categorySub != null && subList.any((c) => c.id == categorySub);
    final level3 = subExists ? subList.firstWhere((c) => c.id == categorySub).children : <CategoryItem>[];

    final mainCat = mainExists ? categories.firstWhere((c) => c.id == categoryMain) : null;
    final subCat = subExists ? subList.firstWhere((c) => c.id == categorySub) : null;
    final itemCat = level3.isNotEmpty && categoryItem != null && level3.any((c) => c.id == categoryItem)
        ? level3.firstWhere((c) => c.id == categoryItem)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 4),

        // Breadcrumb
        if (mainCat != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(spacing: 4, children: [
              _BreadcrumbChip(label: '${mainCat.emoji} ${mainCat.labelFr}'),
              if (subCat != null) ...[
                const Icon(Icons.chevron_right, size: 16, color: textSecondary),
                _BreadcrumbChip(label: '${subCat.emoji} ${subCat.labelFr}'),
              ],
              if (itemCat != null) ...[
                const Icon(Icons.chevron_right, size: 16, color: textSecondary),
                _BreadcrumbChip(label: '${itemCat.emoji} ${itemCat.labelFr}', isLeaf: true),
              ],
            ]),
          ),

        // Level 1
        _buildDropdown(
          value: mainExists ? categoryMain : null,
          hint: 'Catégorie principale',
          items: categories,
          onChanged: onMainChanged,
        ),

        // Level 2
        if (mainExists && subList.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDropdown(
            value: subExists ? categorySub : null,
            hint: 'Sous-catégorie',
            items: subList,
            onChanged: onSubChanged,
          ),
        ],

        // Level 3
        if (subExists && level3.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDropdown(
            value: level3.any((c) => c.id == categoryItem) ? categoryItem : null,
            hint: 'Article spécifique',
            items: level3,
            onChanged: onItemChanged,
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                  child: const Text('★', style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              Text(c.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(c.labelFr, style: TextStyle(
                  fontWeight: (showSpecial && c.isSpecial) ? FontWeight.w600 : FontWeight.normal,
                  color: (showSpecial && c.isSpecial) ? Colors.amber.shade800 : null,
                )),
              ),
            ]),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  final String label;
  final bool isLeaf;

  const _BreadcrumbChip({required this.label, this.isLeaf = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLeaf ? primaryBlue.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isLeaf ? Border.all(color: primaryBlue.withOpacity(0.3)) : null,
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: isLeaf ? primaryBlue : textSecondary, fontWeight: isLeaf ? FontWeight.w600 : FontWeight.normal)),
    );
  }
}