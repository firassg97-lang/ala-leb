import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/product/presentation/add_product_screen.dart';
import '../../features/product/presentation/product_detail_screen.dart';
import '../../features/product/presentation/edit_product_screen.dart';
import '../../features/chat/presentation/conversations_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/profile/presentation/my_profile_screen.dart';
import '../../features/profile/presentation/user_profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../shared/widgets/app_bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (ctx, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (ctx, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (ctx, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/add-product',
            builder: (ctx, state) => const AddProductScreen(),
          ),
          GoRoute(
            path: '/conversations',
            builder: (ctx, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (ctx, state) => const MyProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        builder: (ctx, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/product/:id/edit',
        builder: (ctx, state) => EditProductScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (ctx, state) {
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
        builder: (ctx, state) => UserProfileScreen(
          userId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (ctx, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (ctx, state) => const EditProfileScreen(),
      ),
    ],
  );
});
