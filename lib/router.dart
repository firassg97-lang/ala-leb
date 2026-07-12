import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/add_product_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/edit_product_page.dart';
import 'pages/conversations_page.dart';
import 'pages/chat_page.dart';
import 'pages/my_profile_page.dart';
import 'pages/user_profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/edit_profile_page.dart';
import 'l10n.dart';

const Color primaryBlue = Color(0xFF6BB8E8);
const Color primaryPink = Color(0xFFF28BA8);
const Color textSecondary = Color(0xFF6B7280);
const LinearGradient brandGradient = LinearGradient(
  colors: [primaryBlue, primaryPink],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

final unreadCountProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerStatefulWidget {
  // ← الآن يستقبل StatefulNavigationShell بدل Widget child
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _subscribeUnread();
  }

  Future<void> _loadUnreadCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('conversations')
          .select('participant1_id, unread_count_p1, unread_count_p2')
          .or('participant1_id.eq.${user.id},participant2_id.eq.${user.id}');

      // اجمع عدّاد المستخدم الحالي فقط (p1 أو p2 حسب موقعه في المحادثة)
      final total = (data as List).fold<int>(0, (sum, row) {
        final count = row['participant1_id'] == user.id
            ? row['unread_count_p1']
            : row['unread_count_p2'];
        return sum + (count as int? ?? 0);
      });

      if (mounted) ref.read(unreadCountProvider.notifier).state = total;
    } catch (_) {}
  }

  void _subscribeUnread() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // أي تغيّر (رسالة جديدة أو تحديث عدّادات) → أعد القراءة من قاعدة البيانات
    // فتبقى الشارة متزامنة دائماً مع الحالة الفعلية بدون تراكم وهمي
    Supabase.instance.client
        .channel('unread_messages_${user.id}')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        if (!mounted) return;
        final senderId = payload.newRecord['sender_id'] as String?;
        if (senderId != null && senderId != user.id) _loadUnreadCount();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'conversations',
      callback: (_) {
        if (mounted) _loadUnreadCount();
      },
    )
        .subscribe();
  }

  // ← التنقل عبر الـ branch مع الحفاظ على state كل tab
  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      // إعادة الضغط على نفس التاب يرجعه لجذره (سلوك قياسي)
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTap,
          selectedItemColor: primaryBlue,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: context.tr('nav_home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_outlined),
              activeIcon: const Icon(Icons.search),
              label: context.tr('nav_search'),
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              label: context.tr('nav_add'),
            ),
            BottomNavigationBarItem(
              icon: _BadgeIcon(icon: Icons.chat_bubble_outline, count: unread),
              activeIcon: _BadgeIcon(icon: Icons.chat_bubble, count: unread),
              label: context.tr('nav_messages'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: context.tr('nav_profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: primaryPink,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// عام ليُستخدم من خدمة OneSignal للتنقل عند نقر الإشعار
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (_, state) =>
            RegisterScreen(oauthProvider: state.extra as String?),
      ),
      // ← StatefulShellRoute للحفاظ على state كل tab بشكل مستقل
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/add-product', builder: (_, __) => const AddProductScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/conversations', builder: (_, __) => const ConversationsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (_, __) => const MyProfileScreen()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/product/:id/edit',
        builder: (_, state) =>
            EditProductScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            conversationId: state.pathParameters['conversationId']!,
            otherUserId: extra?['otherUserId'] ?? '',
            otherUserName: extra?['otherUserName'] ?? '',
            otherUserAvatar: extra?['otherUserAvatar'],
          );
        },
      ),
      GoRoute(
        path: '/user/:id',
        builder: (_, state) =>
            UserProfileScreen(userId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
    ],
  );
});