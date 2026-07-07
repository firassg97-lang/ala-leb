import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_picker_page.dart';

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
              ? [BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ── EditProfileScreen ──────────────────────────────────────────
// ══════════════════════════════════════════════════════════════
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedWilaya;
  bool _isSaving = false;
  Map<String, dynamic>? _profileData;

  // ── الموقع GPS (للمحلات فقط) ──
  double? _locationLat;
  double? _locationLng;

  // ── هل الحساب من نوع shop ──
  bool get _isShop =>
      (_profileData?['account_type'] as String?) == 'shop';

  // ── هل يوجد موقع محدد ──
  bool get _hasLocation => _locationLat != null && _locationLng != null;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (mounted && data != null) {
      setState(() {
        _profileData = data;
        _nameCtrl.text = (data['username'] as String?) ?? '';
        _phoneCtrl.text = (data['phone'] as String?) ?? '';
        final wilaya = data['wilaya'] as String?;
        _selectedWilaya =
        wilaya != null && tunisiaWilayas.contains(wilaya) ? wilaya : null;
        // ── تحميل الموقع الحالي إذا كان موجوداً ──
        _locationLat = (data['shop_lat'] as num?)?.toDouble();
        _locationLng = (data['shop_lng'] as num?)?.toDouble();
      });
    }
  }

  // ── فتح LocationPickerScreen — نفس طريقة register ──
  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng?>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _locationLat,
          initialLng: _locationLng,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _locationLat = result.latitude;
        _locationLng = result.longitude;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      final newWilaya = _selectedWilaya ?? '';
      final oldWilaya = _profileData?['wilaya'] as String? ?? '';

      final updateMap = <String, dynamic>{
        'username': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'wilaya': newWilaya,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // ── حفظ الموقع فقط إذا كان shop ──
      if (_isShop) {
        updateMap['shop_lat'] = _locationLat;
        updateMap['shop_lng'] = _locationLng;
      }

      await supabase.from('profiles').update(updateMap).eq('id', userId);

      // ── تحديث الولاية في المنتجات إذا تغيرت ──
      if (_profileData != null && oldWilaya != newWilaya && newWilaya.isNotEmpty) {
        await supabase
            .from('products')
            .update({'wilaya': newWilaya})
            .eq('user_id', userId)
            .eq('is_active', true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil mis à jour'),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Modifier le profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── الاسم ──
            AppTextField(
              label: 'Nom complet',
              controller: _nameCtrl,
              prefix: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── الهاتف ──
            AppTextField(
              label: 'Téléphone',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefix: const Icon(Icons.phone_outlined),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),

            // ── الولاية ──
            DropdownButtonFormField<String>(
              value: _selectedWilaya,
              hint: const Text('Gouvernorat'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on_outlined),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: tunisiaWilayas
                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedWilaya = v),
            ),

            // ── الموقع GPS — يظهر فقط لـ shop ──
            if (_isShop) ...[
              const SizedBox(height: 24),
              const Text('Localisation de la boutique',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickLocation,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(
                      color: _hasLocation
                          ? primaryBlue
                          : const Color(0xFFE0E0E0)),
                  foregroundColor:
                  _hasLocation ? primaryBlue : textSecondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(_hasLocation
                    ? Icons.location_on
                    : Icons.location_on_outlined),
                label: Text(
                  _hasLocation
                      ? '📍 ${_locationLat!.toStringAsFixed(4)}, ${_locationLng!.toStringAsFixed(4)}'
                      : 'Choisir la localisation sur la carte',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _hasLocation
                      ? '✅ Localisation enregistrée'
                      : 'Aucune localisation définie',
                  style: TextStyle(
                      fontSize: 12,
                      color: _hasLocation
                          ? successColor
                          : textSecondary.withOpacity(0.8)),
                ),
              ),
            ],

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
    );
  }
}