import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Brand Colors ──────────────────────────────────────────────────────────────
const Color primaryBlue    = Color(0xFF6BB8E8);
const Color primaryPink    = Color(0xFFF28BA8);
const Color backgroundLight = Color(0xFFFFFFFF);
const Color backgroundDark  = Color(0xFF121212);
const Color surfaceLight    = Color(0xFFF8F9FA);
const Color surfaceDark     = Color(0xFF1E1E1E);
const Color cardDark        = Color(0xFF2A2A2A);
const Color textPrimary     = Color(0xFF1A1A2E);
const Color textSecondary   = Color(0xFF6B7280);
const Color dividerColor    = Color(0xFFF0F0F0);
const Color errorColor      = Color(0xFFE53935);
const Color successColor    = Color(0xFF43A047);
const Color warningColor    = Color(0xFFFFA726);

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

// ── Theme Provider — single source of truth ───────────────────────────────────
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _load();
  }

  static const _key = 'theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'dark') {
      state = ThemeMode.dark;
    } else if (value == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> setDark(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }

  Future<void> setSystem() async {
    state = ThemeMode.system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ── Locale Provider — single source of truth ──────────────────────────────────
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr')) {
    _load();
  }

  static const _key = 'app_locale';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_key) ?? 'fr';
    state = Locale(lang);
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }
}
