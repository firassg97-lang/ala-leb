import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'services/ads_service.dart';
import 'services/onesignal_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp();

  await OneSignalService.instance.initialize();

  await Hive.initFlutter();
  await Supabase.initialize(
    url: 'https://xojuclsmzenpfumzzpuo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhvanVjbHNtemVucGZ1bXp6cHVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NTQ1NDMsImV4cCI6MjA5NDUzMDU0M30.gX2v9lBSsg50lKcVXj7CMbro3RDJkTy0J6AwGFEOmUY',
  );

  _syncOneSignalWithSupabaseAuth();

  await OneSignalService.instance.requestPermission();

  // Android: تهيئة الإعلانات هنا كما كانت دائماً (سلوك Google Play الحالي).
  // iOS: التهيئة تتم في صفحة السبلاش بعد طلب إذن التتبع (ATT) — انظر AdsService.
  if (!Platform.isIOS) {
    await AdsService.instance.initialize();
  }

  runApp(
    const ProviderScope(
      child: LebestyApp(),
    ),
  );
}

void _syncOneSignalWithSupabaseAuth() {
  final auth = Supabase.instance.client.auth;

  final currentUser = auth.currentUser;
  if (currentUser != null) {
    OneSignalService.instance.login(currentUser.id);
    final email = currentUser.email;
    if (email != null && email.isNotEmpty) {
      OneSignalService.instance.addEmail(email);
    }
  }

  auth.onAuthStateChange.listen((data) {
    final user = data.session?.user;
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.tokenRefreshed:
        if (user != null) {
          OneSignalService.instance.login(user.id);
          final email = user.email;
          if (email != null && email.isNotEmpty) {
            OneSignalService.instance.addEmail(email);
          }
        }
        break;
      case AuthChangeEvent.signedOut:
        OneSignalService.instance.logout();
        break;
      default:
        break;
    }
  });
}
