import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../services/supabase_service.dart';
import '../models/product_model.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;
  const EditProductScreen({super.key, required this.productId});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
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

  Future<void> _load() async {
    try {
      final data = await SupabaseConfig.client
          .from('products')
          .select()
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
      await SupabaseConfig.client.from('products').update({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'size': _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
        'condition': _condition,
        'is_original': _isOriginal,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'published_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.productId);

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
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Taille',
                controller: _sizeCtrl,
                prefix: const Icon(Icons.straighten_outlined),
              ),
              const SizedBox(height: 16),
              const Text('État',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 15)),
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
              Row(
                children: [
                  const Expanded(
                    child: Text('Article original',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                  Switch(
                    value: _isOriginal,
                    onChanged: (v) => setState(() => _isOriginal = v),
                    activeColor: primaryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ConditionChip(String label, String value) {
    final isSelected = _condition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _condition = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryBlue.withOpacity(0.1)
                : Colors.transparent,
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
}
