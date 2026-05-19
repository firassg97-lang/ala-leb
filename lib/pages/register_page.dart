import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../constants/tunisia_wilayas.dart';
import '../services/supabase_service.dart';
import '../services/image_utils.dart';
import '../services/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'location_picker_page.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Step 1 - Auth method
  String _authMethod = 'email';

  // Step 2 - Credentials
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _credFormKey = GlobalKey<FormState>();

  // Step 3 - Language
  String _language = 'fr';

  // Step 4 - Wilaya
  String? _wilaya;

  // Step 5 - Account type
  String _accountType = 'user';

  // Step 6 - Shop type
  String? _shopType;

  // Step 7 - Profile info
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Profile photo (picked locally, uploaded on submit)
  File? _avatarFile;

  // GPS location (shop only)
  double? _locationLat;
  double? _locationLng;

  int get _totalSteps => _accountType == 'shop' ? 7 : 6;

  @override
  void initState() {
    super.initState();
    // Fix 2: Rebuild when text controllers change so _canProceed() updates
    _emailCtrl.addListener(_onTextChanged);
    _passCtrl.addListener(_onTextChanged);
    _nameCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _pageCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalSteps - 1) {
      _pageCtrl.nextPage(
        duration: 300.ms,
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: 300.ms,
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    } else {
      context.go('/login');
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return true;
      case 1:
        return _emailCtrl.text.isNotEmpty && _passCtrl.text.length >= 6;
      case 2:
        return _language.isNotEmpty;
      case 3:
        return _wilaya != null;
      case 4:
        return true;
      case 5:
        return _accountType == 'shop' ? _shopType != null : _nameCtrl.text.isNotEmpty;
      case 6:
        return _nameCtrl.text.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      // Upload avatar if selected
      String? avatarUrl;
      if (_avatarFile != null) {
        final uuid = const Uuid().v4();
        await SupabaseConfig.client.storage
            .from('avatars')
            .upload('$uuid.jpg', _avatarFile!);
        avatarUrl = SupabaseConfig.client.storage
            .from('avatars')
            .getPublicUrl('$uuid.jpg');
      }

      await ref.read(authNotifierProvider.notifier).signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        profileData: {
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          'language': _language,
          'wilaya': _wilaya ?? '',
          'account_type': _accountType,
          'shop_type': _accountType == 'shop' ? _shopType : null,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (_locationLat != null) 'location_lat': _locationLat,
          if (_locationLng != null) 'location_lng': _locationLng,
        },
      );
      // Fix 10: navigate directly to /home, no dialogs
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildPages(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _prevPage,
            icon: const Icon(Icons.arrow_back_ios),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          const Spacer(),
          Text(
            'Étape ${_currentPage + 1}/$_totalSteps',
            style: const TextStyle(color: textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: LinearProgressIndicator(
        value: (_currentPage + 1) / _totalSteps,
        backgroundColor: dividerColor,
        valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
        borderRadius: BorderRadius.circular(4),
        minHeight: 4,
      ),
    );
  }

  List<Widget> _buildPages() {
    final pages = <Widget>[
      _AuthMethodStep(
        selected: _authMethod,
        onSelect: (m) => setState(() => _authMethod = m),
      ),
      _CredentialsStep(
        emailCtrl: _emailCtrl,
        passCtrl: _passCtrl,
        confirmCtrl: _confirmPassCtrl,
        formKey: _credFormKey,
      ),
      _LanguageStep(
        selected: _language,
        onSelect: (l) => setState(() => _language = l),
      ),
      _WilayaStep(
        selected: _wilaya,
        onSelect: (w) => setState(() => _wilaya = w),
      ),
      _AccountTypeStep(
        selected: _accountType,
        onSelect: (t) => setState(() => _accountType = t),
      ),
    ];

    if (_accountType == 'shop') {
      pages.add(
        _ShopTypeStep(
          selected: _shopType,
          onSelect: (t) => setState(() => _shopType = t),
        ),
      );
      pages.add(
        _ProfileInfoStep(
          nameCtrl: _nameCtrl,
          phoneCtrl: _phoneCtrl,
          isShop: true,
          avatarFile: _avatarFile,
          locationLat: _locationLat,
          locationLng: _locationLng,
          onAvatarSelected: (file) => setState(() => _avatarFile = file),
          onLocationSelected: (lat, lng) => setState(() {
            _locationLat = lat;
            _locationLng = lng;
          }),
        ),
      );
    } else {
      pages.add(
        _ProfileInfoStep(
          nameCtrl: _nameCtrl,
          phoneCtrl: _phoneCtrl,
          isShop: false,
          avatarFile: _avatarFile,
          onAvatarSelected: (file) => setState(() => _avatarFile = file),
        ),
      );
    }

    return pages;
  }

  Widget _buildFooter() {
    final isLast = _currentPage == _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GradientButton(
        label: isLast ? 'Créer mon compte' : 'Continuer',
        onPressed: _canProceed() && !_isLoading ? _nextPage : null,
        isLoading: _isLoading,
        icon: isLast
            ? null
            : const Icon(Icons.arrow_forward, color: Colors.white),
      ),
    );
  }
}

// ─── Step widgets ──────────────────────────────────────────────────────────────

class _AuthMethodStep extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _AuthMethodStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Créer un compte', style: Theme.of(context).textTheme.headlineLarge)
              .animate().fadeIn(),
          const SizedBox(height: 8),
          Text('Choisissez votre méthode d\'inscription',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),
          _MethodCard(
            icon: Icons.email_outlined,
            title: 'Email / Mot de passe',
            subtitle: 'Inscription classique',
            isSelected: selected == 'email',
            onTap: () => onSelect('email'),
          ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),
          const SizedBox(height: 12),
          _MethodCard(
            icon: Icons.apple,
            title: 'Continuer avec Apple',
            subtitle: 'Requis pour iOS App Store',
            isSelected: selected == 'apple',
            onTap: () => onSelect('apple'),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
          const SizedBox(height: 12),
          _MethodCard(
            icon: Icons.g_mobiledata_rounded,
            title: 'Continuer avec Google',
            subtitle: 'Connexion rapide',
            isSelected: selected == 'google',
            onTap: () => onSelect('google'),
          ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? primaryBlue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? primaryBlue : null)),
                  Text(subtitle,
                      style: const TextStyle(color: textSecondary, fontSize: 13)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: primaryBlue),
          ],
        ),
      ),
    );
  }
}

class _CredentialsStep extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final GlobalKey<FormState> formKey;

  const _CredentialsStep({
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vos identifiants',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Email',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              prefix: const Icon(Icons.email_outlined),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Mot de passe',
              controller: passCtrl,
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
              prefix: const Icon(Icons.lock_outlined),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirmer le mot de passe',
              controller: confirmCtrl,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.confirmPassword(v, passCtrl.text),
              prefix: const Icon(Icons.lock_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageStep extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _LanguageStep({required this.selected, required this.onSelect});

  // Fix 8: removed 'tn' locale
  static const _languages = [
    {'code': 'ar', 'label': 'العربية', 'flag': '🇸🇦'},
    {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
    {'code': 'fr', 'label': 'Français', 'flag': '🇫🇷'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Langue préférée',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Choisissez votre langue',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textSecondary)),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _languages.length,
              itemBuilder: (ctx, i) {
                final lang = _languages[i];
                final isSelected = selected == lang['code'];
                return GestureDetector(
                  onTap: () => onSelect(lang['code']!),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue.withOpacity(0.08) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? primaryBlue : const Color(0xFFE0E0E0),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(lang['label']!,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? primaryBlue : null)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WilayaStep extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;

  const _WilayaStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Votre gouvernorat',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Sélectionnez votre région',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textSecondary)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2,
              ),
              itemCount: tunisiaWilayas.length,
              itemBuilder: (ctx, i) {
                final wilaya = tunisiaWilayas[i];
                final isSelected = selected == wilaya;
                return GestureDetector(
                  onTap: () => onSelect(wilaya),
                  child: AnimatedContainer(
                    duration: 150.ms,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? primaryBlue : const Color(0xFFE0E0E0),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        wilaya,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTypeStep extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _AccountTypeStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type de compte',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Qui êtes-vous sur Lebesty ?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textSecondary)),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    emoji: '🏪',
                    title: 'Boutique',
                    isSelected: selected == 'shop',
                    onTap: () => onSelect('shop'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TypeCard(
                    emoji: '👤',
                    title: 'Utilisateur',
                    isSelected: selected == 'user',
                    onTap: () => onSelect('user'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Improvement 1: No subtitle text
class _TypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.emoji,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        height: 200,
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? primaryBlue : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryBlue : null)),
            if (isSelected) ...[
              const SizedBox(height: 8),
              const Icon(Icons.check_circle, color: primaryBlue, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShopTypeStep extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;

  const _ShopTypeStep({required this.selected, required this.onSelect});

  // Improvement 2: Renamed "Location de robes" → "Location de robes et costumes"
  static const _types = [
    {'value': 'clothing', 'icon': '👔', 'label': 'Vente de vêtements'},
    {'value': 'superfripe', 'icon': '🛍️', 'label': 'Super Fripe'},
    {'value': 'rental', 'icon': '👗', 'label': 'Location de robes et costumes'},
    {'value': 'accessories', 'icon': '💍', 'label': 'Accessoires'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type de boutique',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Quel type de boutique avez-vous ?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textSecondary)),
          const SizedBox(height: 24),
          ..._types.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onSelect(t['value']!),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected == t['value']
                          ? primaryBlue.withOpacity(0.08)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected == t['value']
                            ? primaryBlue
                            : const Color(0xFFE0E0E0),
                        width: selected == t['value'] ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(t['icon']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            t['label']!,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected == t['value']
                                    ? primaryBlue
                                    : null),
                          ),
                        ),
                        if (selected == t['value'])
                          const Icon(Icons.check_circle, color: primaryBlue),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// Fix 3: Stateful with avatar picker + Fix 5: GPS for shop
class _ProfileInfoStep extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final bool isShop;
  final File? avatarFile;
  final double? locationLat;
  final double? locationLng;
  final void Function(File) onAvatarSelected;
  final void Function(double lat, double lng)? onLocationSelected;

  const _ProfileInfoStep({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.isShop,
    required this.avatarFile,
    required this.onAvatarSelected,
    this.locationLat,
    this.locationLng,
    this.onLocationSelected,
  });

  @override
  State<_ProfileInfoStep> createState() => _ProfileInfoStepState();
}

class _ProfileInfoStepState extends State<_ProfileInfoStep> {
  Future<void> _pickAvatar() async {
    // Request permission
    final status = await Permission.photos.request();
    if (status.isDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission photos refusée')),
      );
    }

    final source = await _showImageSourcePicker();
    if (source == null) return;

    final file = await ImageUtils.pickAndCompress(source: source);
    if (file != null) {
      widget.onAvatarSelected(file);
    }
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
            const Text('Photo de profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt, color: primaryBlue),
              ),
              title: const Text('📷 Prendre une photo'),
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
              title: const Text('🖼️ Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng?>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: widget.locationLat,
          initialLng: widget.locationLng,
        ),
      ),
    );
    if (result != null && widget.onLocationSelected != null) {
      widget.onLocationSelected!(result.latitude, result.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = widget.locationLat != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isShop ? 'Informations boutique' : 'Votre profil',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Dites-nous en plus sur ${widget.isShop ? 'votre boutique' : 'vous'}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 32),

          // Avatar picker
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryBlue, width: 2),
                    ),
                    child: widget.avatarFile != null
                        ? ClipOval(
                            child: Image.file(
                              widget.avatarFile!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            ),
                          )
                        : const Icon(Icons.person, size: 48, color: primaryBlue),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          AppTextField(
            label: widget.isShop ? 'Nom de la boutique *' : 'Nom complet *',
            controller: widget.nameCtrl,
            textInputAction: TextInputAction.next,
            prefix: Icon(widget.isShop ? Icons.store : Icons.person_outline),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Téléphone (optionnel)',
            controller: widget.phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            prefix: const Icon(Icons.phone_outlined),
          ),

          // Fix 5: GPS button for shop only
          if (widget.isShop) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickLocation,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: BorderSide(
                    color: hasLocation ? primaryBlue : const Color(0xFFE0E0E0)),
                foregroundColor: hasLocation ? primaryBlue : textSecondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(
                  hasLocation ? Icons.location_on : Icons.location_on_outlined),
              label: Text(
                hasLocation
                    ? '📍 ${widget.locationLat!.toStringAsFixed(4)}, ${widget.locationLng!.toStringAsFixed(4)}'
                    : 'Choisir la localisation sur la carte',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (hasLocation)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: Text(
                    '✅ Localisation enregistrée',
                    style: const TextStyle(color: successColor, fontSize: 12),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
