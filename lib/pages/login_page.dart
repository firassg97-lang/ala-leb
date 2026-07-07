import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
              : Row(
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
    );
  }
}

String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email requis';
  final regex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
  if (!regex.hasMatch(value)) return 'Email invalide';
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.length < 6) return 'Minimum 6 caractères';
  return null;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
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

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre email d\'abord')),
      );
      return;
    }
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(_emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email de réinitialisation envoyé'),
              backgroundColor: successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: errorColor),
        );
      }
    }
  }

  // ─── التحقق من اكتمال الحساب في profiles ─────────────────────────────
  Future<bool> _hasCompletedProfile(String userId) async {
    try {
      final result = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();
      if (result == null) return false;
      final username = result['username'] as String?;
      return username != null && username.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
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
        throw Exception('Impossible d\'obtenir les tokens Google');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (!mounted) return;
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final hasProfile = await _hasCompletedProfile(user.id);
      if (!mounted) return;

      if (hasProfile) {
        context.go('/home');
      } else {
        context.go('/register', extra: 'google');
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

  // ─── Apple Sign-In ────────────────────────────────────────────────────
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      if (Platform.isIOS) {
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
      } else {
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: 'io.supabase.lebesty://login-callback/',
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final hasProfile = await _hasCompletedProfile(user.id);
      if (!mounted) return;

      if (hasProfile) {
        context.go('/home');
      } else {
        context.go('/register', extra: 'apple');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: brandGradient,
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/lebesty_logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Text(
                            'LB',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn().scaleXY(begin: 0.8),
                const SizedBox(height: 32),
                Text(
                  'Connexion',
                  style: Theme.of(context).textTheme.headlineLarge,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 8),
                Text(
                  'Bienvenue sur Lebesty',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: textSecondary),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  prefix: const Icon(Icons.email_outlined),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Mot de passe',
                  controller: _passCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                  prefix: const Icon(Icons.lock_outlined),
                ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Se connecter',
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),
                _DividerWithText(text: 'OU'),
                const SizedBox(height: 16),
                _SocialButton(
                  label: 'Continuer avec Apple',
                  icon: Icons.apple,
                  onPressed: _isLoading ? null : _signInWithApple,
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 12),
                _SocialButton(
                  label: 'Continuer avec Google',
                  icon: Icons.g_mobiledata_rounded,
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(color: textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text(
                        'Inscription',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: const TextStyle(color: textSecondary)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}