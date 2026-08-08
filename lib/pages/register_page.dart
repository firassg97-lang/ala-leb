import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

// مخفي مؤقتًا — أعده إلى true لإظهار خيار "Email / Mot de passe" في التسجيل
const bool _showEmailAuthOption = false;

const List<String> tunisiaWilayas = [
  'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
  'Bizerte', 'Béja', 'Jendouba', 'Le Kef', 'Siliana', 'Sousse',
  'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
  'Gabès', 'Medenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kebili',
];

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
              ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

String? _validateEmail(String? v) {
  if (v == null || v.isEmpty) return 'Email requis';
  if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) return 'Email invalide';
  return null;
}

String? _validatePassword(String? v) {
  if (v == null || v.length < 6) return 'Minimum 6 caractères';
  return null;
}

String? _validateConfirmPassword(String? v, String password) {
  if (v != password) return 'Les mots de passe ne correspondent pas';
  return null;
}

Future<File?> _pickAndCompress({required ImageSource source}) async {
  final XFile? picked = await ImagePicker().pickImage(
    source: source, imageQuality: 100, maxWidth: 2048, maxHeight: 2048,
    requestFullMetadata: false,
  );
  if (picked == null) return null;
  final dir = await getTemporaryDirectory();
  final target = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final result = await FlutterImageCompress.compressAndGetFile(
    picked.path, target, quality: 85, minWidth: 1024, minHeight: 1024,
    format: CompressFormat.jpeg,
  );
  if (result == null) return null;
  return File(result.path);
}

Future<String> _uploadAvatarFromFile(String userId, File file) async {
  final supabase = Supabase.instance.client;
  final bytes = await file.readAsBytes();
  final path = '$userId/avatar.jpg';
  await supabase.storage.from('avatars').uploadBinary(
    path, bytes,
    fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
  );
  return supabase.storage.from('avatars').getPublicUrl(path);
}

Future<void> _upsertAfterSignup({
  required String id,
  required String username,
  required String language,
  required String wilaya,
  required String accountType,
  String? phone,
  String? shopType,
  double? shopLat,
  double? shopLng,
  String? avatarUrl,
}) async {
  await Supabase.instance.client.from('profiles').upsert({
    'id': id,
    'username': username,
    'language': language,
    'wilaya': wilaya,
    'account_type': accountType,
    'phone': phone,
    'shop_type': shopType,
    'shop_lat': shopLat,
    'shop_lng': shopLng,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    'updated_at': DateTime.now().toIso8601String(),
  });
}

class RegisterScreen extends StatefulWidget {
  final String? oauthProvider;
  const RegisterScreen({super.key, this.oauthProvider});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // الافتراضي عند إخفاء خيار Email: Apple على iOS وGoogle على غيره
  String _authMethod = _showEmailAuthOption
      ? 'email'
      : (Platform.isIOS ? 'apple' : 'google');
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _credFormKey = GlobalKey<FormState>();
  String _language = 'fr';
  String? _wilaya;
  String _accountType = 'user';
  String? _shopType;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  File? _avatarFile;
  double? _locationLat;
  double? _locationLng;

  int get _totalSteps => _accountType == 'shop' ? 6 : 5;

  @override
  void initState() {
    super.initState();
    _language = 'fr';
    _emailCtrl.addListener(_onTextChanged);
    _passCtrl.addListener(_onTextChanged);
    _confirmPassCtrl.addListener(_onTextChanged);
    _nameCtrl.addListener(_onTextChanged);
    if (widget.oauthProvider != null) {
      _authMethod = widget.oauthProvider!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageCtrl.jumpToPage(2);
        setState(() => _currentPage = 2);
      });
    }
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

  // التعديل الوحيد: Google يفتح داخل التطبيق، Apple عبر OAuth
  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      if (provider == OAuthProvider.google) {
        const webClientId =
            '204250890964-lnhpmqk5gfi62pjrfnfjfrohn4vd1h30.apps.googleusercontent.com';
        final googleSignIn = GoogleSignIn(serverClientId: webClientId);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() => _isLoading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;
        if (accessToken == null || idToken == null) {
          throw Exception("Impossible d'obtenir les tokens Google");
        }
        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        // نفس منطق Apple: نعبّئ حقل "Nom complet" باسم Google كقيمة
        // افتراضية قابلة للتعديل الكامل، دون إجبار المستخدم على شيء.
        final googleDisplayName = googleUser.displayName;
        if (googleDisplayName != null &&
            googleDisplayName.trim().isNotEmpty &&
            _nameCtrl.text.isEmpty) {
          _nameCtrl.text = googleDisplayName.trim();
        }
      } else if (Platform.isIOS) {
        // iOS: تدفق Apple الأصلي (نافذة النظام) — مطلوب لتجربة أفضل وموافقة Apple
        final rawNonce = Supabase.instance.client.auth.generateRawNonce();
        final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        final idToken = credential.identityToken;
        if (idToken == null) {
          throw Exception("Impossible d'obtenir le token Apple");
        }

        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        );

        // Apple ترسل givenName/familyName مرة واحدة فقط، عند أول تسجيل دخول.
        // نعبّئ بها حقل "Nom complet" كقيمة افتراضية قابلة للتعديل الكامل
        // (المستخدم يبقى حراً في مسحها ووضع اسم محله بدلاً منها) —
        // هذا يحل ملاحظة Apple بخصوص Guideline 4 دون تقييد المستخدم.
        final givenName = credential.givenName;
        final familyName = credential.familyName;
        final appleFullName = [givenName, familyName]
            .where((n) => n != null && n.trim().isNotEmpty)
            .join(' ')
            .trim();
        if (appleFullName.isNotEmpty && _nameCtrl.text.isEmpty) {
          _nameCtrl.text = appleFullName;
        }
      } else {
        await Supabase.instance.client.auth.signInWithOAuth(
          provider,
          redirectTo: 'io.supabase.lebesty://login-callback/',
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      // المستخدم ألغى النافذة — لا نعرض خطأ
      if (e.code != AuthorizationErrorCode.canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: errorColor),
        );
      }
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

  Future<void> _nextPage() async {
    if (_currentPage == 0 && _authMethod != 'email') {
      final provider = _authMethod == 'google'
          ? OAuthProvider.google
          : OAuthProvider.apple;
      await _signInWithOAuth(provider);
      if (!mounted) return;
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        FocusScope.of(context).unfocus();
        _pageCtrl.animateToPage(2, duration: 300.ms, curve: Curves.easeInOut);
        setState(() => _currentPage = 2);
      }
      return;
    }
    if (_currentPage < _totalSteps - 1) {
      FocusScope.of(context).unfocus();
      _pageCtrl.nextPage(duration: 300.ms, curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      FocusScope.of(context).unfocus();
      if (_currentPage == 2 && _authMethod != 'email') {
        _pageCtrl.animateToPage(0, duration: 300.ms, curve: Curves.easeInOut);
        setState(() => _currentPage = 0);
        return;
      }
      _pageCtrl.previousPage(duration: 300.ms, curve: Curves.easeInOut);
      setState(() => _currentPage--);
    } else {
      context.go('/login');
    }
  }

  bool _canProceed() {
    if (_currentPage == 0 && _authMethod != 'email') return true;
    switch (_currentPage) {
      case 0: return true;
      case 1:
        return _emailCtrl.text.isNotEmpty &&
            _passCtrl.text.length >= 6 &&
            _confirmPassCtrl.text == _passCtrl.text &&
            _confirmPassCtrl.text.isNotEmpty;
      case 2: return _wilaya != null;
      case 3: return true;
      case 4: return _accountType == 'shop' ? _shopType != null : _nameCtrl.text.isNotEmpty;
      case 5: return _nameCtrl.text.isNotEmpty;
      default: return false;
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final phone = _phoneCtrl.text.trim();

      if (_authMethod == 'email') {
        final response = await supabase.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          data: {
            'username': _nameCtrl.text.trim(),
            'language': _language,
            'wilaya': _wilaya ?? '',
            'account_type': _accountType,
            'phone': phone.isEmpty ? null : phone,
            'shop_type': _shopType,
            'shop_lat': _locationLat?.toString(),
            'shop_lng': _locationLng?.toString(),
          },
        );
        final user = response.user;
        if (user != null) {
          String? avatarUrl;
          if (_avatarFile != null) avatarUrl = await _uploadAvatarFromFile(user.id, _avatarFile!);
          await _upsertAfterSignup(
            id: user.id, username: _nameCtrl.text.trim(),
            language: _language, wilaya: _wilaya ?? '',
            accountType: _accountType, phone: phone.isEmpty ? null : phone,
            shopType: _shopType, shopLat: _locationLat, shopLng: _locationLng,
            avatarUrl: avatarUrl,
          );
        }
        if (!mounted) return;
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vérifiez votre email pour confirmer le compte'),
              backgroundColor: successColor,
            ),
          );
          context.go('/login');
          return;
        }
      } else {
        final user = supabase.auth.currentUser;
        if (user == null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expirée, veuillez réessayer'), backgroundColor: errorColor),
          );
          return;
        }
        String? avatarUrl;
        if (_avatarFile != null) avatarUrl = await _uploadAvatarFromFile(user.id, _avatarFile!);
        await _upsertAfterSignup(
          id: user.id, username: _nameCtrl.text.trim(),
          language: _language, wilaya: _wilaya ?? '',
          accountType: _accountType, phone: phone.isEmpty ? null : phone,
          shopType: _shopType, shopLat: _locationLat, shopLng: _locationLng,
          avatarUrl: avatarUrl,
        );
      }

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('already exists')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email déjà utilisé'), backgroundColor: errorColor),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: errorColor));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: errorColor),
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
      _AuthMethodStep(selected: _authMethod, onSelect: (m) => setState(() => _authMethod = m)),
      _CredentialsStep(emailCtrl: _emailCtrl, passCtrl: _passCtrl, confirmCtrl: _confirmPassCtrl, formKey: _credFormKey),
      _WilayaStep(selected: _wilaya, onSelect: (w) => setState(() => _wilaya = w)),
      _AccountTypeStep(selected: _accountType, onSelect: (t) => setState(() => _accountType = t)),
    ];

    if (_accountType == 'shop') {
      pages.add(_ShopTypeStep(selected: _shopType, onSelect: (t) => setState(() => _shopType = t)));
      pages.add(_ProfileInfoStep(
        nameCtrl: _nameCtrl, phoneCtrl: _phoneCtrl, isShop: true,
        avatarFile: _avatarFile, locationLat: _locationLat, locationLng: _locationLng,
        onAvatarSelected: (file) => setState(() => _avatarFile = file),
        onLocationSelected: (lat, lng) => setState(() { _locationLat = lat; _locationLng = lng; }),
      ));
    } else {
      pages.add(_ProfileInfoStep(
        nameCtrl: _nameCtrl, phoneCtrl: _phoneCtrl, isShop: false,
        avatarFile: _avatarFile,
        onAvatarSelected: (file) => setState(() => _avatarFile = file),
      ));
    }
    return pages;
  }

  Widget _buildFooter() {
    final isLast = _currentPage == _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GradientButton(
        label: isLast ? 'Créer mon compte' : 'Continuer',
        onPressed: _canProceed() && !_isLoading ? (isLast ? _submit : _nextPage) : null,
        isLoading: _isLoading,
        icon: isLast ? null : const Icon(Icons.arrow_forward, color: Colors.white),
      ),
    );
  }
}

// ─── Steps ────────────────────────────────────────────────────────────────────

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
          Text('Créer un compte', style: Theme.of(context).textTheme.headlineLarge).animate().fadeIn(),
          const SizedBox(height: 8),
          Text("Choisissez votre méthode d'inscription",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),
          if (_showEmailAuthOption) ...[
            _MethodCard(icon: Icons.email_outlined, title: 'Email / Mot de passe',
                subtitle: 'Inscription classique', isSelected: selected == 'email',
                onTap: () => onSelect('email')).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),
            const SizedBox(height: 12),
          ],
          _MethodCard(icon: Icons.apple, title: 'Continuer avec Apple',
              subtitle: 'Connexion rapide avec votre Apple ID', isSelected: selected == 'apple',
              onTap: () => onSelect('apple')).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
          const SizedBox(height: 12),
          _MethodCard(icon: Icons.g_mobiledata_rounded, title: 'Continuer avec Google',
              subtitle: 'Connexion rapide avec votre compte Google', isSelected: selected == 'google',
              onTap: () => onSelect('google')).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
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
  const _MethodCard({required this.icon, required this.title, required this.subtitle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue.withOpacity(0.08) : Colors.transparent,
          border: Border.all(color: isSelected ? primaryBlue : const Color(0xFFE0E0E0), width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: isSelected ? primaryBlue : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: isSelected ? Colors.white : textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? primaryBlue : null)),
                  Text(subtitle, style: const TextStyle(color: textSecondary, fontSize: 13)),
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
  const _CredentialsStep({required this.emailCtrl, required this.passCtrl, required this.confirmCtrl, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vos identifiants', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 32),
            AppTextField(label: 'Email', controller: emailCtrl, keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next, validator: _validateEmail, prefix: const Icon(Icons.email_outlined), autofocus: true),
            const SizedBox(height: 16),
            AppTextField(label: 'Mot de passe', controller: passCtrl, obscureText: true,
                textInputAction: TextInputAction.next, validator: _validatePassword, prefix: const Icon(Icons.lock_outlined)),
            const SizedBox(height: 16),
            AppTextField(label: 'Confirmer le mot de passe', controller: confirmCtrl, obscureText: true,
                textInputAction: TextInputAction.done, validator: (v) => _validateConfirmPassword(v, passCtrl.text),
                prefix: const Icon(Icons.lock_outlined)),
          ],
        ),
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
          Text('Votre gouvernorat', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Sélectionnez votre région', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2),
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
                      border: Border.all(color: isSelected ? primaryBlue : const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      // Safety net: shrinks the name only if it would
                      // overflow the fixed grid cell.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(wilaya, textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : null)),
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
          Text('Type de compte', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Qui êtes-vous sur Lebesty ?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary)),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _TypeCard(emoji: '🏪', title: 'Boutique', isSelected: selected == 'shop', onTap: () => onSelect('shop'))),
                const SizedBox(width: 16),
                Expanded(child: _TypeCard(emoji: '👤', title: 'Utilisateur', isSelected: selected == 'user', onTap: () => onSelect('user'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  const _TypeCard({required this.emoji, required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        height: 200,
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue.withOpacity(0.08) : Colors.transparent,
          border: Border.all(color: isSelected ? primaryBlue : const Color(0xFFE0E0E0), width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(20),
        ),
        // Safety net: scales the content down only if it would overflow the
        // fixed card; renders identically when it fits.
        child: LayoutBuilder(builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? primaryBlue : null)),
                  if (isSelected) ...[const SizedBox(height: 8), const Icon(Icons.check_circle, color: primaryBlue, size: 20)],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ShopTypeStep extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _ShopTypeStep({required this.selected, required this.onSelect});

  static const _types = [
    // الأيقونتان متبادلتان عمدًا (طلب تصميمي) — القيم المخزنة لم تتغير
    {'value': 'clothing', 'icon': '🛍️', 'label': 'Vente de vêtements'},
    {'value': 'superfripe', 'icon': '👔', 'label': 'Super Fripe'},
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
          Text('Type de boutique', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Quel type de boutique avez-vous ?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary)),
          const SizedBox(height: 24),
          ..._types.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onSelect(t['value']!),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected == t['value'] ? primaryBlue.withOpacity(0.08) : Colors.transparent,
                  border: Border.all(color: selected == t['value'] ? primaryBlue : const Color(0xFFE0E0E0), width: selected == t['value'] ? 2 : 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(t['icon']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(t['label']!, style: TextStyle(fontWeight: FontWeight.w600, color: selected == t['value'] ? primaryBlue : null))),
                    if (selected == t['value']) const Icon(Icons.check_circle, color: primaryBlue),
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
    required this.nameCtrl, required this.phoneCtrl,
    required this.isShop, required this.avatarFile,
    required this.onAvatarSelected,
    this.locationLat, this.locationLng, this.onLocationSelected,
  });

  @override
  State<_ProfileInfoStep> createState() => _ProfileInfoStepState();
}

class _ProfileInfoStepState extends State<_ProfileInfoStep> {
  Future<void> _pickAvatar() async {
    final status = await Permission.photos.request();
    if (status.isDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission photos refusée')));
    }
    final source = await _showImageSourcePicker();
    if (source == null) return;
    final file = await _pickAndCompress(source: source);
    if (file != null) widget.onAvatarSelected(file);
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
            const Text('Photo de profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.camera_alt, color: primaryBlue)),
              title: const Text('📷 Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: primaryPink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.photo_library, color: primaryPink)),
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
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initialLat: widget.locationLat, initialLng: widget.locationLng)),
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
          Text(widget.isShop ? 'Informations boutique' : 'Votre profil', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Dites-nous en plus sur ${widget.isShop ? "votre boutique" : "vous"}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary)),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: primaryBlue, width: 2)),
                    child: widget.avatarFile != null
                        ? ClipOval(child: Image.file(widget.avatarFile!, fit: BoxFit.cover, width: 100, height: 100))
                        : const Icon(Icons.person, size: 48, color: primaryBlue),
                  ),
                  Positioned(bottom: 0, right: 0,
                      child: Container(width: 32, height: 32,
                          decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: widget.isShop ? 'Nom de la boutique *' : 'Nom complet *',
            controller: widget.nameCtrl, textInputAction: TextInputAction.next,
            prefix: Icon(widget.isShop ? Icons.store : Icons.person_outline),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Téléphone (optionnel)', controller: widget.phoneCtrl,
            keyboardType: TextInputType.phone, textInputAction: TextInputAction.done,
            prefix: const Icon(Icons.phone_outlined),
          ),
          if (widget.isShop) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickLocation,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: BorderSide(color: hasLocation ? primaryBlue : const Color(0xFFE0E0E0)),
                foregroundColor: hasLocation ? primaryBlue : textSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(hasLocation ? Icons.location_on : Icons.location_on_outlined),
              label: Text(
                hasLocation
                    ? '📍 ${widget.locationLat!.toStringAsFixed(4)}, ${widget.locationLng!.toStringAsFixed(4)}'
                    : 'Choisir la localisation sur la carte',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (hasLocation)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Center(child: Text('✅ Localisation enregistrée', style: TextStyle(color: successColor, fontSize: 12))),
              ),
          ],
        ],
      ),
    );
  }
}
