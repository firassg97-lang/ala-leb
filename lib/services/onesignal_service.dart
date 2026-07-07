import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router.dart' show rootNavigatorKey;

/// Centralized wrapper around the OneSignal Flutter SDK.
///
/// All OneSignal SDK calls should go through this class so that
/// initialization, identity, and listener setup are managed in one place.
class OneSignalService {
  OneSignalService._internal();
  static final OneSignalService instance = OneSignalService._internal();

  static const String appId = '2235d678-579c-4b35-ba44-f8c50538f1ba';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    OneSignal.initialize(appId);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      // عند الإقلاع البارد قد لا يكون الـ router جاهزاً بعد — عندها يفتح
      // التطبيق طبيعياً عبر السبلاش ولا نتدخل.
      final context = rootNavigatorKey.currentContext;
      if (context != null &&
          Supabase.instance.client.auth.currentUser != null) {
        GoRouter.of(context).go('/conversations');
      }
    });

    _isInitialized = true;
  }

  Future<bool> requestPermission() {
    return OneSignal.Notifications.requestPermission(true);
  }

  Future<void> login(String externalId) async {
    if (externalId.isEmpty) return;
    OneSignal.login(externalId);

    await Supabase.instance.client
        .from('profiles')
        .update({'last_seen_at': DateTime.now().toIso8601String()})
        .eq('id', externalId);
  }

  Future<void> logout() async {
    OneSignal.logout();
  }

  Future<void> addEmail(String email) async {
    if (email.isEmpty) return;
    OneSignal.User.addEmail(email);
  }

  Future<void> removeEmail(String email) async {
    if (email.isEmpty) return;
    OneSignal.User.removeEmail(email);
  }

  Future<void> addSms(String number) async {
    if (number.isEmpty) return;
    OneSignal.User.addSms(number);
  }

  Future<void> removeSms(String number) async {
    if (number.isEmpty) return;
    OneSignal.User.removeSms(number);
  }

  Future<void> setTag(String key, String value) async {
    OneSignal.User.addTagWithKey(key, value);
  }

  Future<void> setTags(Map<String, String> tags) async {
    if (tags.isEmpty) return;
    OneSignal.User.addTags(tags);
  }

  Future<void> removeTag(String key) async {
    OneSignal.User.removeTag(key);
  }
}
