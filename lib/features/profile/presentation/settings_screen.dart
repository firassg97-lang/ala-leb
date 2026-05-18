import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          _SectionHeader('Compte'),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Modifier le profil',
            onTap: () => context.push('/edit-profile'),
          ),
          _SettingsTile(
            icon: Icons.lock_outlined,
            title: 'Changer le mot de passe',
            onTap: () async {
              final profile =
                  ref.read(authNotifierProvider).valueOrNull;
              if (profile == null) return;
              try {
                await ref
                    .read(supabaseClientProvider)
                    .auth
                    .resetPasswordForEmail(profile.email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Email envoyé'),
                        backgroundColor: successColor),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: errorColor),
                  );
                }
              }
            },
          ),

          const Divider(),
          _SectionHeader('Apparence'),
          SwitchListTile(
            secondary: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.indigo.withOpacity(0.15)
                    : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: isDark ? Colors.indigo : Colors.orange,
              ),
            ),
            title: const Text('Mode sombre'),
            value: isDark,
            onChanged: (v) => ref.read(themeProvider.notifier).setDark(v),
            activeColor: primaryBlue,
          ),

          const Divider(),
          _SectionHeader('Langue'),
          _LanguageTile(
            current: locale.languageCode,
            onSelect: (lang) =>
                ref.read(localeProvider.notifier).setLocale(lang),
          ),

          const Divider(),
          _SectionHeader('Informations'),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            onTap: () async {
              final uri = Uri.parse(AppStrings.privacyPolicyUrl);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Contact: ${AppStrings.contactEmail}',
            onTap: () async {
              final uri =
                  Uri.parse('mailto:${AppStrings.contactEmail}');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),

          const Divider(),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Se déconnecter',
            color: errorColor,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Déconnecter',
                            style: TextStyle(color: errorColor))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authNotifierProvider.notifier).signOut();
                context.go('/login');
              }
            },
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Supprimer le compte',
            color: errorColor,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Supprimer le compte ?'),
                  content: const Text(
                      'Cette action est irréversible. Toutes vos données seront supprimées.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Supprimer',
                            style: TextStyle(color: errorColor))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                try {
                  await ref.read(authNotifierProvider.notifier).deleteAccount();
                  if (context.mounted) context.go('/login');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: errorColor),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
            color: textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: c),
      ),
      title: Text(title, style: TextStyle(color: color)),
      trailing: color != null
          ? null
          : const Icon(Icons.chevron_right, color: textSecondary),
      onTap: onTap,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String current;
  final void Function(String) onSelect;

  const _LanguageTile({required this.current, required this.onSelect});

  // Fix 8: removed 'tn' locale
  static const _languages = [
    {'code': 'ar', 'label': '🇸🇦 العربية'},
    {'code': 'en', 'label': '🇬🇧 English'},
    {'code': 'fr', 'label': '🇫🇷 Français'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentLabel = _languages
        .firstWhere((l) => l['code'] == current,
            orElse: () => _languages[2])['label']!;
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.language, color: primaryBlue),
      ),
      title: const Text('Langue'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentLabel, style: const TextStyle(color: textSecondary)),
          const Icon(Icons.chevron_right, color: textSecondary),
        ],
      ),
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choisir la langue',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._languages.map(
                (l) => ListTile(
                  title: Text(l['label']!),
                  trailing: current == l['code']
                      ? const Icon(Icons.check, color: primaryBlue)
                      : null,
                  onTap: () {
                    onSelect(l['code']!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
