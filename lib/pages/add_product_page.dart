import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../constants/categories_data.dart';
import '../services/supabase_service.dart';
import '../services/image_utils.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _productType = 'sale';
  String _condition = 'new';
  bool _isOriginal = false;
  bool _isLoading = false;

  File? _mainImage;
  final List<File?> _extraImages = [null, null, null, null];

  String? _categoryMain;
  String? _categorySub;
  String? _categoryItem;

  List<CategoryItem> get _currentCategories =>
      _productType == 'sale' ? saleCategories : rentalCategories;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _sizeCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  bool get _showOriginalToggle {
    final profile = ref.read(authNotifierProvider).valueOrNull;
    if (profile == null) return false;
    if (profile.accountType == 'user') return true;
    if (profile.shopType == 'superfripe' || profile.shopType == 'rental') {
      return true;
    }
    return false;
  }

  Future<void> _pickImage({int? extraIndex}) async {
    final source = await _showImageSourcePicker();
    if (source == null) return;

    final file = await ImageUtils.pickAndCompress(source: source);
    if (file == null) return;

    setState(() {
      if (extraIndex == null) {
        _mainImage = file;
      } else {
        _extraImages[extraIndex] = file;
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
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Choisir une image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt, color: primaryBlue),
              ),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library, color: primaryPink),
              ),
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
    final uuid = const Uuid().v4();
    final path = '$uuid.jpg';
    await SupabaseConfig.client.storage.from(bucket).upload(path, file);
    return SupabaseConfig.client.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter une image principale')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      final profile = ref.read(authNotifierProvider).valueOrNull;

      final thumbUrl = await _uploadImage(_mainImage!, 'products');
      final List<String> imageUrls = [thumbUrl ?? ''];

      for (final extra in _extraImages) {
        if (extra != null) {
          final url = await _uploadImage(extra, 'products');
          if (url != null) imageUrls.add(url);
        }
      }

      await SupabaseConfig.client.from('products').insert({
        'owner_id': user.id,
        'product_type': _productType,
        'category_main': _categoryMain,
        'category_sub': _categorySub,
        'category_item': _categoryItem,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'size': _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
        'condition': _condition,
        'is_original': _isOriginal,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'image_urls': imageUrls,
        'thumbnail_url': thumbUrl,
        'wilaya': profile?.wilaya ?? '',
        'published_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Produit publié avec succès'),
              backgroundColor: successColor),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _canPublish() {
    if (_mainImage == null) return false;
    if (_categoryMain == null || _categorySub == null) return false;
    // Require level 3 only if the subcategory has children
    final sub = _currentCategories
        .firstWhere((c) => c.id == _categoryMain,
            orElse: () => _currentCategories.first)
        .children
        .firstWhere((c) => c.id == _categorySub,
            orElse: () => _currentCategories.first.children.first);
    if (sub.children.isNotEmpty && _categoryItem == null) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_priceCtrl.text.trim().isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Ajouter un article'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
        const Text('Photos',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickImage(),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _mainImage != null
                      ? primaryBlue
                      : const Color(0xFFE0E0E0),
                  width: 2,
                  style: BorderStyle.solid),
            ),
            child: _mainImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(_mainImage!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 40, color: primaryBlue),
                      SizedBox(height: 8),
                      Text('Photo principale *',
                          style: TextStyle(color: primaryBlue)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: GestureDetector(
                onTap: () => _pickImage(extraIndex: i),
                child: Container(
                  height: 80,
                  margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: _extraImages[i] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(_extraImages[i]!,
                              fit: BoxFit.cover),
                        )
                      : const Icon(Icons.add_photo_alternate,
                          color: textSecondary, size: 24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type d\'article',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _TypeTab('🛍️ Pour vente', 'sale'),
              _TypeTab('👗 Pour location', 'rental'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _TypeTab(String label, String value) {
    final isSelected = _productType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _productType = value;
          _categoryMain = null;
          _categorySub = null;
          _categoryItem = null;
        }),
        child: AnimatedContainer(
          duration: 200.ms,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : textSecondary,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    // Breadcrumb display
    final mainCat = _categoryMain != null
        ? _currentCategories.firstWhere((c) => c.id == _categoryMain,
            orElse: () => _currentCategories.first)
        : null;
    final subCat = mainCat != null && _categorySub != null
        ? mainCat.children.firstWhere((c) => c.id == _categorySub,
            orElse: () => mainCat.children.first)
        : null;
    final itemCat = subCat != null && _categoryItem != null
        ? subCat.children.firstWhere((c) => c.id == _categoryItem,
            orElse: () => subCat.children.first)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catégorie',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 4),

        // Breadcrumb trail
        if (mainCat != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 4,
              children: [
                _BreadcrumbChip(label: '${mainCat.emoji} ${mainCat.labelFr}'),
                if (subCat != null) ...[
                  const Icon(Icons.chevron_right, size: 16, color: textSecondary),
                  _BreadcrumbChip(label: '${subCat.emoji} ${subCat.labelFr}'),
                ],
                if (itemCat != null) ...[
                  const Icon(Icons.chevron_right, size: 16, color: textSecondary),
                  _BreadcrumbChip(label: '${itemCat.emoji} ${itemCat.labelFr}', isLeaf: true),
                ],
              ],
            ),
          ),

        // Level 1: main category
        DropdownButtonFormField<String>(
          value: _categoryMain,
          hint: const Text('Catégorie principale'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _currentCategories
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      Text(c.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(c.labelFr),
                    ]),
                  ))
              .toList(),
          onChanged: (v) => setState(() {
            _categoryMain = v;
            _categorySub = null;
            _categoryItem = null;
          }),
        ),

        // Level 2: sub-category
        if (_categoryMain != null &&
            _currentCategories
                .firstWhere((c) => c.id == _categoryMain)
                .children
                .isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categorySub,
            hint: const Text('Sous-catégorie'),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _currentCategories
                .firstWhere((c) => c.id == _categoryMain)
                .children
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(children: [
                        Text(c.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Flexible(child: Text(c.labelFr)),
                      ]),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _categorySub = v;
              _categoryItem = null;
            }),
          ),
        ],

        // Level 3: specific item
        if (_categorySub != null) ...[
          () {
            final level3 = _currentCategories
                .firstWhere((c) => c.id == _categoryMain)
                .children
                .firstWhere((c) => c.id == _categorySub)
                .children;
            if (level3.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _categoryItem,
                  hint: const Text('Article spécifique'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: primaryBlue.withOpacity(0.04),
                  ),
                  items: level3
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(children: [
                              if (c.isSpecial)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('★', style: TextStyle(fontSize: 10, color: Colors.white)),
                                ),
                              Text(c.emoji,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  c.labelFr,
                                  style: TextStyle(
                                    fontWeight: c.isSpecial ? FontWeight.w600 : FontWeight.normal,
                                    color: c.isSpecial ? Colors.amber.shade800 : null,
                                  ),
                                ),
                              ),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryItem = v),
                ),
              ],
            );
          }(),
        ],
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 12),
        AppTextField(
          label: 'Description',
          controller: _descCtrl,
          maxLines: 4,
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
        const Text('État',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
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
            border: Border.all(
                color: isSelected ? primaryBlue : const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? primaryBlue : null,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalToggle() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Article original',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              Text('Marque originale',
                  style: TextStyle(color: textSecondary, fontSize: 13)),
            ],
          ),
        ),
        Switch(
          value: _isOriginal,
          onChanged: (v) => setState(() => _isOriginal = v),
          activeColor: primaryBlue,
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prix',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        AppTextField(
          label: _productType == 'rental' ? 'Prix par jour (TND) *' : 'Prix (TND) *',
          controller: _priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefix: const Icon(Icons.attach_money),
          validator: (v) =>
              v == null || v.isEmpty ? 'Le prix est requis' : null,
        ),
      ],
    );
  }
}

// Breadcrumb chip helper widget
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isLeaf ? primaryBlue : textSecondary,
          fontWeight: isLeaf ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
