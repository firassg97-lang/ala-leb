import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/categories_data.dart';
import '../../../../core/constants/tunisia_wilayas.dart';

class ProductFilter {
  final List<String> wilayas;
  final String productType; // 'all' | 'sale' | 'rental'
  final bool originalOnly;
  final String? categoryMain;
  final String? categorySub;
  final String? categoryItem;

  const ProductFilter({
    this.wilayas = const [],
    this.productType = 'all',
    this.originalOnly = false,
    this.categoryMain,
    this.categorySub,
    this.categoryItem,
  });

  bool get hasCategory => categoryMain != null;

  ProductFilter copyWith({
    List<String>? wilayas,
    String? productType,
    bool? originalOnly,
    String? categoryMain,
    String? categorySub,
    String? categoryItem,
    bool clearCategory = false,
  }) {
    return ProductFilter(
      wilayas: wilayas ?? this.wilayas,
      productType: productType ?? this.productType,
      originalOnly: originalOnly ?? this.originalOnly,
      categoryMain: clearCategory ? null : (categoryMain ?? this.categoryMain),
      categorySub: clearCategory ? null : (categorySub ?? this.categorySub),
      categoryItem: clearCategory ? null : (categoryItem ?? this.categoryItem),
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
  String? _categorySub;
  String? _categoryItem;

  @override
  void initState() {
    super.initState();
    _selectedWilayas = List.from(widget.current.wilayas);
    _productType = widget.current.productType;
    _originalOnly = widget.current.originalOnly;
    _categoryMain = widget.current.categoryMain;
    _categorySub = widget.current.categorySub;
    _categoryItem = widget.current.categoryItem;
  }

  List<CategoryItem> get _categories =>
      _productType == 'rental' ? rentalCategories : saleCategories;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildTitle(),
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
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Filtres',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedWilayas = [];
                _productType = 'all';
                _originalOnly = false;
                _categoryMain = null;
                _categorySub = null;
                _categoryItem = null;
              });
            },
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _TypeTab('Tout', 'all'),
              _TypeTab('Pour vente', 'sale'),
              _TypeTab('Pour location', 'rental'),
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
        onTap: () => setState(() => _productType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              fontSize: 13,
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
              Text(
                'Original seulement',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                'Afficher uniquement les articles originaux',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Switch(
          value: _originalOnly,
          onChanged: (v) => setState(() => _originalOnly = v),
          activeColor: primaryBlue,
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Catégorie',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (_categoryMain != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() {
                  _categoryMain = null;
                  _categorySub = null;
                  _categoryItem = null;
                }),
                child: const Icon(Icons.close, size: 18, color: textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Level 1: main category chips
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isSelected = _categoryMain == cat.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _categoryMain = isSelected ? null : cat.id;
                  _categorySub = null;
                  _categoryItem = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 72,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryBlue.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                        color: isSelected ? primaryBlue : const Color(0xFFE0E0E0),
                        width: isSelected ? 2 : 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        cat.labelFr,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? primaryBlue : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Level 2: sub-category chips
        if (_categoryMain != null) ...[
          const SizedBox(height: 12),
          const Text('Sous-catégorie',
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .firstWhere((c) => c.id == _categoryMain)
                .children
                .map((sub) {
              final isSelected = _categorySub == sub.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _categorySub = isSelected ? null : sub.id;
                  _categoryItem = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryBlue : Colors.transparent,
                    border: Border.all(
                        color: isSelected
                            ? primaryBlue
                            : const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sub.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(
                        sub.labelFr,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // Level 3: specific items
        if (_categorySub != null) ...[
          () {
            final level3 = _categories
                .firstWhere((c) => c.id == _categoryMain)
                .children
                .firstWhere((c) => c.id == _categorySub)
                .children;
            if (level3.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('Article',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: level3.map((item) {
                    final isSelected = _categoryItem == item.id;
                    final chipColor = item.isSpecial ? Colors.amber.shade700 : primaryBlue;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _categoryItem = isSelected ? null : item.id;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? chipColor
                              : chipColor.withOpacity(0.07),
                          border: Border.all(
                              color: isSelected
                                  ? chipColor
                                  : chipColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.isSpecial) ...[
                              const Text('★', style: TextStyle(fontSize: 11, color: Colors.amber)),
                              const SizedBox(width: 3),
                            ],
                            Text(item.emoji,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Text(
                              item.labelFr,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? Colors.white : chipColor,
                                fontWeight: isSelected || item.isSpecial
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }(),
        ],
      ],
    );
  }

  Widget _buildWilayaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Gouvernorats',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            if (_selectedWilayas.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedWilayas.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tunisiaWilayas.map((w) {
            final isSelected = _selectedWilayas.contains(w);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedWilayas.remove(w);
                  } else {
                    _selectedWilayas.add(w);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryBlue : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? primaryBlue : const Color(0xFFE0E0E0),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  w,
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            widget.onApply(ProductFilter(
              wilayas: _selectedWilayas,
              productType: _productType,
              originalOnly: _originalOnly,
              categoryMain: _categoryMain,
              categorySub: _categorySub,
              categoryItem: _categoryItem,
            ));
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: primaryBlue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Appliquer les filtres',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
