import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n.dart';

const Color primaryBlue = Color(0xFF6BB8E8);
const Color textSecondary = Color(0xFF6B7280);
const Color errorColor = Color(0xFFE53935);
const Color successColor = Color(0xFF43A047);

// ── Simple view model for one blocked user row ──────────────────────────────
class _BlockedUser {
  final String id;
  final String? username;
  final String? avatarUrl;

  const _BlockedUser({required this.id, this.username, this.avatarUrl});

  String get displayName =>
      (username != null && username!.trim().isNotEmpty)
          ? username!.trim()
          : 'Utilisateur';
}

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final List<_BlockedUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      // Only rows the current user created (blocker_id = me). This deliberately
      // never surfaces people who blocked me (blocked_id = me), to protect the
      // other party's privacy. The FK hint disambiguates the two profiles FKs.
      final rows = await Supabase.instance.client
          .from('blocked_users')
          .select(
              'blocked_id, created_at, profiles!blocked_users_blocked_id_fkey(id, username, avatar_url)')
          .eq('blocker_id', user.id)
          .order('created_at', ascending: false);

      final list = (rows as List).map((r) {
        final p = r['profiles'] as Map<String, dynamic>?;
        return _BlockedUser(
          id: r['blocked_id'] as String,
          username: p?['username'] as String?,
          avatarUrl: p?['avatar_url'] as String?,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _users
            ..clear()
            ..addAll(list);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('blocked users load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmUnblock(_BlockedUser u) async {
    final name = u.displayName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Débloquer $name ?'),
        content: Text(
            'Vous pourrez à nouveau échanger des messages avec $name et voir ses articles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Débloquer', style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('blocked_users')
          .delete()
          .eq('blocker_id', user.id)
          .eq('blocked_id', u.id);
      if (mounted) {
        setState(() => _users.removeWhere((e) => e.id == u.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur débloqué'),
            backgroundColor: successColor,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur, réessayez'),
            backgroundColor: errorColor,
          ),
        );
      }
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
        title: Text(context.tr('blocked_users')),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }
    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 64, color: textSecondary),
            SizedBox(height: 16),
            Text('Aucun utilisateur bloqué',
                style: TextStyle(color: textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final u = _users[i];
        return ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(u.avatarUrl!)
                : null,
            child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                ? Icon(Icons.person, color: Colors.grey.shade400)
                : null,
          ),
          title: Text(u.displayName,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: TextButton(
            onPressed: () => _confirmUnblock(u),
            child: const Text('Débloquer',
                style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}
