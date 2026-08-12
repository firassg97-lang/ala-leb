import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_providers.dart';
import '../l10n.dart';

const _privacyPolicyUrl =
    'https://lebesty.netlify.app/lebesty-politique-confidentialite';
const _contactEmail = 'lebesty21@gmail.com';

// مخفي مؤقتًا — أعده إلى true لإظهار "Changer le mot de passe"
const bool _showChangePassword = false;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark    = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        children: [
          _SectionHeader(context.tr('account')),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: context.tr('edit_profile'),
            onTap: () => context.push('/edit-profile'),
          ),
          _SettingsTile(
            icon: Icons.block_outlined,
            title: context.tr('blocked_users'),
            onTap: () => context.push('/blocked-users'),
          ),
          if (_showChangePassword)
            _SettingsTile(
              icon: Icons.lock_outlined,
              title: context.tr('change_password'),
              onTap: () async {
                final email = Supabase.instance.client.auth.currentUser?.email;
                if (email == null) return;
                try {
                  await Supabase.instance.client.auth.resetPasswordForEmail(email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('email_sent')),
                        backgroundColor: successColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: errorColor,
                      ),
                    );
                  }
                }
              },
            ),

          const Divider(),
          _SectionHeader(context.tr('appearance')),
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
            title: Text(context.tr('dark_mode')),
            value: isDark,
            onChanged: (v) => ref.read(themeProvider.notifier).setDark(v),
            activeColor: primaryBlue,
          ),

          const Divider(),
          _SectionHeader(context.tr('information')),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: context.tr('privacy_policy'),
            onTap: () async {
              final uri = Uri.parse(_privacyPolicyUrl);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: '${context.tr('contact_label')}: $_contactEmail',
            onTap: () async {
              final uri = Uri.parse('mailto:$_contactEmail');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),

          const Divider(),
          _SettingsTile(
            icon: Icons.logout,
            title: context.tr('logout'),
            color: errorColor,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(context.tr('logout_confirm_title')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.tr('cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        context.tr('logout_btn'),
                        style: const TextStyle(color: errorColor),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: context.tr('delete_account'),
            color: errorColor,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(context.tr('delete_account_title')),
                  content: Text(context.tr('delete_account_warning')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.tr('cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        context.tr('delete'),
                        style: const TextStyle(color: errorColor),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                try {
                  final supabase = Supabase.instance.client;
                  final user = supabase.auth.currentUser;
                  if (user == null) return;

                  // خطوة 1: حذف ملفات Storage (الصورة الشخصية وغيرها) عبر
                  // Storage API الصحيح — الحذف المباشر عبر SQL ممنوع من
                  // Supabase (خطأ 42501)، لذا يجب أن يتم من هنا.
                  try {
                    final avatarFiles = await supabase.storage
                        .from('avatars')
                        .list(path: user.id);
                    if (avatarFiles.isNotEmpty) {
                      final paths = avatarFiles
                          .map((f) => '${user.id}/${f.name}')
                          .toList();
                      await supabase.storage.from('avatars').remove(paths);
                    }
                  } catch (_) {
                    // لا نمنع حذف الحساب إن لم توجد ملفات أو فشل الحذف
                    // الجزئي لها — الحساب نفسه يبقى الأولوية.
                  }

                  // خطوة 2: حذف كامل للحساب (auth.users) — يُفعّل تلقائياً
                  // حذف profiles وكل الجداول المرتبطة عبر FK cascades
                  // (متطلب Apple 5.1.1).
                  await supabase.rpc('delete_account');
                  await supabase.auth.signOut();
                  if (context.mounted) context.go('/login');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${context.tr('error_prefix')}: ${e.toString()}'),
                        backgroundColor: errorColor,
                      ),
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

// ── Section header ──────────────────────────────────────────────────────
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
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Generic settings tile ───────────────────────────────────────────────
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