import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'widgets/app_bottom_nav.dart';

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
