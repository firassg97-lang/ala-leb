import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// خدمة مركزية للإعلانات (AdMob + Meta Audience Network عبر Mediation).
///
/// - Android: تُستدعى initialize() من main() قبل runApp — نفس السلوك السابق تماماً.
/// - iOS: تُستدعى initialize() من صفحة السبلاش بعد ظهورها، حيث يُطلب إذن
///   App Tracking Transparency أولاً ثم تُهيّأ الإعلانات — قبل أول طلب إعلان.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;

  /// معرّف الإعلان الأصلي (Native) لكل منصة.
  /// معرّف Android هو المعرّف الشغال حالياً على Google Play — لا يُغيَّر.
  static String get nativeAdUnitId => Platform.isIOS
      ? 'ca-app-pub-7394481534051178/7413563491'
      : 'ca-app-pub-7394481534051178/5157469231';

  Future<void> initialize() async {
    if (_initialized) return;
    if (Platform.isIOS) {
      await _requestTrackingAuthorization();
    }
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// إذن ATT مطلوب على iOS 14+ قبل تهيئة الإعلانات حتى تستطيع AdMob وMeta
  /// استخدام IDFA للإعلانات المخصصة (Meta bidding يعتمد عليه بشكل خاص).
  Future<void> _requestTrackingAuthorization() async {
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // مهلة قصيرة لضمان أن التطبيق في الواجهة قبل عرض نافذة الإذن،
        // وإلا قد يتجاهل النظام الطلب ولا تظهر النافذة.
        await Future.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {
      // فشل طلب الإذن يجب ألا يمنع تهيئة الإعلانات (ستُعرض إعلانات غير مخصصة).
    }
  }
}
