# Lebesty — سجل الفحص النهائي قبل إصدار iOS

آخر تحديث: 2026-07-05
الهدف: مراجعة شاملة ملف-بملف قبل النشر على App Store.
الحالات: ⬜ لم تُفحص | 🔄 قيد الفحص | ✅ تم الفحص

## ملاحظات عامة (مكتشفة قبل بدء الدفعات)
- ❗ لا يوجد ملف `ios/Runner/PrivacyInfo.xcprivacy` (Privacy Manifest) — إلزامي من Apple. بانتظار قرار الإنشاء.

## الدفعة 1 — مفاتيح وإعدادات أساسية ✅ (تم الفحص — بانتظار قرارات)
- [x] pubspec.yaml — النسخة 1.0.0+1 (سؤال معلق عن build number)، حزمة sign_in_with_apple غير مستخدمة
- [x] lib/main.dart — نظيف؛ مفتاح Supabase مطابق للمشروع الحقيقي النشط (تم التحقق عبر API)
- [x] ios/Runner/Info.plist — ✅ أُضيف CFBundleURLTypes (io.supabase.lebesty) المطلوب لعودة OAuth؛ أسئلة معلقة: لغة نص ATT، الاتجاهات landscape، ITSAppUsesNonExemptEncryption
- [x] ios/Runner/Runner.entitlements — aps-environment=development (Xcode يحولها لـ production عند التصدير للمتجر — تحقق عند الأرشفة)
- [x] ios/Runner/GoogleService-Info.plist — ❗ لا يحتوي CLIENT_ID/REVERSED_CLIENT_ID → Google Sign-In سيفشل على iOS (يحتاج إعادة تنزيل الملف من Firebase بعد إضافة iOS OAuth client)

## الدفعة 2 — خدمات وإعدادات iOS ✅ (تم الفحص)
- [x] lib/services/ads_service.dart — نظيف؛ معرفات AdMob حقيقية (وليست test IDs) ومطابقة لـ GADApplicationIdentifier
- [x] lib/services/onesignal_service.dart — App ID صحيح؛ ملاحظتان: debugPrint عند نقر الإشعار + النقر لا يؤدي لأي تنقل (منطق ناقص — سؤال معلق)
- [x] ios/Podfile — سليم؛ ملاحظة: pod Meta mediation بدون تثبيت نسخة (يُتحقق منها عند pod install على Mac)
- [x] ios/Runner/AppDelegate.swift — قالب Flutter قياسي، سليم
- [x] ios/Flutter/Release.xcconfig + Debug.xcconfig — قياسية، سليمة

## الدفعة 3 — نواة التطبيق ✅ (تم الفحص)
- [x] lib/app.dart — نظيف؛ LTR مقصود؛ supportedLocales = ar/fr/en (لا tn)
- [x] lib/app_providers.dart — نظيف
- [x] lib/router.dart — سليم؛ ملاحظات ثانوية: قناة Realtime بلا unsubscribe (AppShell دائم)، لا auth guard (splash يتكفل)، تكرار ثوابت ألوان
- [x] lib/l10n.dart — الفرنسية سليمة لغويا، fallback fr لكل مفتاح
- [x] lib/data/categories.dart — سؤال معلق: كلمات فرنسية في labelEn (Baskets/Claquettes) وتضارب تسمية chaussons

## الدفعة 4 — صفحات (1/3) ✅ (تم الفحص)
- [x] lib/pages/splash_page.dart — نظيف؛ ATT قبل الإعلانات على iOS صحيح
- [x] lib/pages/login_page.dart — نظيف؛ ملاحظة: نصوص فرنسية hardcoded بدل l10n (سؤال 16)
- [x] lib/pages/register_page.dart — ✅ حُذف الكود الميت (_LanguageStep + _oauthEmail)؛ منطق التسجيل سليم
- [x] lib/pages/home_page.dart — منطق feed/إعلانات سليم؛ 5 debugPrint في مسارات الأخطاء (سؤال 15)
- [x] lib/pages/search_page.dart — ⚠️ select() يجلب كل الأعمدة بما فيها phone لأي مستخدم (بند 17 — يُدقق مع RLS في الدفعة 7)

## الدفعة 5 — صفحات (2/3) ✅ (تم الفحص)
- [x] lib/pages/product_detail_page.dart — سليم؛ ملاحظة: حقل تعليق التقييم يُعرض ولا يُرسل (بند 20)
- [x] lib/pages/add_product_page.dart — سليم؛ ثابت kNsfwPendingMessageAr ميت + لا رسالة "قيد المراجعة" عند pending (بند 21)؛ NSFW يفشل بصمت لو تعذرت التهيئة (بند 22)
- [x] lib/pages/edit_product_page.dart — سليم؛ كل تعديل يرفع المنتج لأعلى الفيد (published_at=now) — يبدو مقصودا
- [x] lib/pages/my_profile_page.dart — ❓ المستخدم يستطيع تقييم نفسه (بند 19)
- [x] lib/pages/user_profile_page.dart — ✅ debugPrint لُفّت بـ kDebugMode (امتداد بند 15)؛ ملاحظة: جلب منتجات البروفايل بدون فلتر is_active

## الدفعة 6 — صفحات (3/3) ✅ (تم الفحص)
- [x] lib/pages/edit_profile_page.dart — سليم
- [x] lib/pages/settings_page.dart — ✅ رابط سياسة الخصوصية حي (تحقق 200)؛ ❗ حذف الحساب ناقص (بند 23 — خطر رفض Apple 5.1.1)؛ _LanguageTile كود ميت
- [x] lib/pages/chat_page.dart — ✅ debugPrint لُفّت بـ kDebugMode؛ ملاحظة: وسائط المحادثات في buckets عامة (بند 24)
- [x] lib/pages/conversations_page.dart — سليم (Realtime يعتمد على RLS — تُفحص في الدفعة 7)
- [x] lib/pages/location_picker_page.dart — سليم؛ تدفق إذن الموقع صحيح وOSM policy محترمة (userAgentPackageName)

## الدفعة 7 — Supabase (RLS وإعدادات) ✅ (تم الفحص + فُحصت القاعدة الحية مباشرة)
- [x] supabase/config.toml — يشير للمشروع الصحيح xojuclsmzenpfumzzpuo
- [x] الـ 4 migrations المحلية — قديمة عن الواقع؛ القاعدة الحية فيها RLS مفعلة على كل الجداول بسياسات سليمة (تحقق مباشر عبر pg_policies)
- [x] RLS الجداول: profiles/products/ratings select عام (مقصود)، الكتابة مقيدة بالمالك ✓؛ conversations/messages مقيدة بالمشاركين ✓
- [x] ❗ Storage: سياسة open_access كانت تسمح للجميع بحذف/تعديل أي ملف — أُصلحت (سياسات مالك)
- [x] ❗ حذف الحساب: نُفذت delete_account() SECURITY DEFINER + إصلاح FK حاجبة + تحديث الزر في settings_page
- [x] messages_insert شُددت (المرسل يجب أن يكون مشاركا في المحادثة)
- [x] revoke EXECUTE على 9 دوال داخلية SECURITY DEFINER كانت قابلة للاستدعاء REST من anon
- [x] get_advisors (security) أعيد تشغيله بعد الإصلاح: كل تحذيرات الدوال القابلة للاستدعاء زالت
- الملف الجديد: supabase/migrations/20260705120000_account_deletion_and_security_hardening.sql (مطبق على الإنتاج)

## الدفعة 8 — ترجمات وسكربتات ✅ (تم الفحص)
- [x] assets/translations/*.json — حُذفت سابقا (بند 13، كانت ميتة)
- [x] scripts/test_signup.mjs — سكربت تطوير ينشئ حسابات تجريبية في الإنتاج (بند 28)
- [x] scripts/apply_migration.mjs — ⚠️ يشير للـ migration التدميرية (DELETE FROM auth.users + DROP للجداول) — تشغيله بالخطأ يمسح الإنتاج (بند 28)
- [x] test/widget_test.dart — placeholder غير ضار، لا يُشحن مع التطبيق
- [x] فحص الإنتاج عن بيانات تجريبية: وُجد حساب test@gmail.com + حساب Firebase Test Lab آلي + منتج "testgxcvh" نشط ومرئي في الفيد (بند 29)

## الدفعة 9 — أصول iOS المرئية والفحص الختامي ✅ (تم الفحص)
- [x] AppIcon — كل الـ19 مقاسا المطلوبة موجودة؛ ❗ أيقونة 1024 كانت بقناة alpha (رفض مؤكد عند الرفع) → أُضيف remove_alpha_ios وأعيد التوليد، تحقق: Format24bppRgb ✓
- [x] LaunchScreen.storyboard — قالب قياسي سليم (خلفية بيضاء + LaunchImage)
- [x] project.pbxproj — Bundle ID صحيح، entitlements مربوطة بكل الإعدادات، iOS 13.0، النسخة من pubspec؛ ملاحظة: DEVELOPMENT_TEAM غير محدد (يُضبط عند أول فتح في Xcode — طبيعي)
- [x] analysis_options.yaml قياسي؛ حُذف analysis_output.txt (مخرجات قديمة 2026-05-18)
- [x] flutter analyze النهائي الشامل: 0 أخطاء، 0 تحذيرات (بعد تنظيف 5 بقايا: 2 imports ميتة، _recordingPath، 2 cast زائدة، _isSubmittingRating) — المتبقي 90 ملاحظة info أسلوبية قديمة (withOpacity deprecated…) غير حاجبة

## سجل المشاكل — إضافات الدفعتين 8 و9
| # | الملف | المشكلة | التصنيف | الحالة |
|---|-------|---------|----------|--------|
| 28 | scripts/ | حُذف مجلد scripts بالكامل (test_signup.mjs + apply_migration.mjs) بموافقة المستخدم | معتمد — نُفذ | ✅ تم |
| 29 | قاعدة الإنتاج | بيانات تجريبية حية: حساب test@gmail.com (username: test) + حساب cloudtestlabaccounts.com (آلي من Play Console) + منتج "testgxcvh" 40 TND نشط ومرئي للمستخدمين في الفيد | يحتاج قرار: حذفها (تدميري — بانتظار التأكيد) | ⏳ معلق |
| 30 | AppIcon 1024 | قناة alpha أزيلت (remove_alpha_ios + إعادة توليد) | آمن — نُفذ | ✅ تم |
| 31 | جذر المشروع | حُذف analysis_output.txt (أثر تطوير قديم) | آمن — نُفذ | ✅ تم |

## الدفعة 10 — ملفات أندرويد والبناء (أضيفت بطلب المستخدم) ✅ (تم الفحص)
- [x] android/app/build.gradle.kts — جاهز للإنتاج: توقيع release من key.properties، minify+shrinkResources مفعلان، محول Meta مثبت 6.21.0.0 بتعليق يوثق سبب التوافق مع GMA 24. لا آثار debug
- [x] android/build.gradle.kts — قياسي، نظيف
- [x] android/gradle.properties — إعدادات ذاكرة وأعلام AndroidX قياسية، لا أعلام تجريبية
- [x] android/app/proguard-rules.pro — قواعد keep لـ Meta Audience Network صحيحة (البقية تأتي من consumer rules للمكتبات — مثبت عمليا لأن النسخة تعمل على Play)
- [x] codemagic.yaml — غير موجود في المشروع أصلا (لا CI config)
- [x] pubspec.yaml (مراجعة نهائية كاملة) — لا تبعيات تجريبية؛ dependency_override لـ record_linux خاص بتطوير Windows وغير مؤثر على iOS/Android؛ النسخة 1.0.0+1 (البند 8 ما زال معلقا)
- ملاحظة أمنية: lebesty.jks وkey.properties موجودان في جذر المشروع — المشروع ليس مستودع git حاليا فلا خطر تسريب، لكن عند إنشاء مستودع يجب إضافتهما لـ .gitignore فورا + الاحتفاظ بنسخة احتياطية من الـ keystore خارج المشروع (فقدانه = فقدان القدرة على تحديث تطبيق Play نهائيا)

## الدفعة 11 — تغطية شاملة لبقية الشجرة (بطلب المستخدم) ✅ (تم الفحص)
- [x] android/app/src/main/AndroidManifest.xml — الأذونات صحيحة ومبررة كلها، معرف AdMob أندرويد صحيح (مختلف عن iOS كما يجب)، Facebook AppId مطابق؛ ✅ أُضيف intent-filter لعودة OAuth (io.supabase.lebesty://login-callback) كان ناقصا — زر Apple على أندرويد لم يكن يستطيع العودة للتطبيق (بند 32)
- [x] manifests debug/profile — قياسية (INTERNET للتطوير فقط، لا تدخل release)
- [x] android/app/google-services.json — مطابق للمشروع 269819262841 والحزمة com.lebesty.lebesty
- [x] settings.gradle.kts / MainActivity.kt / styles.xml ×2 / launch_background ×2 / gradle-wrapper — قوالب قياسية نظيفة
- [x] local.properties — مولد آليا، مسارات محلية فقط
- [x] key.properties — كلمات مرور keystore بنص صريح (طبيعي محليا)؛ ✅ أُضيفت *.jks وkey.properties لـ .gitignore الجذري (كانت مغطاة في android/.gitignore فقط بينما lebesty.jks في الجذر) (بند 33)
- [x] ios/Runner.xcscheme — نظيف: لا launch arguments ولا env تجريبية، الأرشفة على Release ✓
- [x] ios: Main.storyboard / AppFrameworkInfo.plist / Runner-Bridging-Header.h / RunnerTests.swift / LaunchImage — قوالب Flutter قياسية
- [x] .metadata / lebesty.iml / .flutter-plugins-dependencies / pubspec.lock — مولدة/IDE، سليمة
- [x] README.md الجذري — boilerplate افتراضي (تجميلي، غير مؤثر)
- [x] supabase/README.md — ✅ صُحح: كان يشير للسكربت المحذوف ولملفات غير موجودة (lib/repositories) ويوجه لتشغيل SQL تدميري بلا تحذير كافٍ (بند 34)

| # | الملف | المشكلة | التصنيف | الحالة |
|---|-------|---------|----------|--------|
| 32 | AndroidManifest.xml | غياب intent-filter لعودة OAuth — أُضيف | آمن — نُفذ | ✅ تم |
| 33 | .gitignore الجذري | lebesty.jks وkey.properties لم يكونا مغطيين على مستوى الجذر — أُضيفا | آمن — نُفذ | ✅ تم |
| 34 | supabase/README.md | توثيق قديم/خطر — صُحح بتحذير صريح وإشارة للحالة الحية | آمن — نُفذ | ✅ تم |
| 35 | AndroidManifest.xml | android:label="lebesty" بحرف صغير (iOS تعرض "Lebesty") — سلوك النسخة الحية، لم يُلمس | ملاحظة تجميلية فقط | ℹ️ |

## سجل المشاكل والقرارات
| # | الملف | المشكلة | التصنيف | الحالة |
|---|-------|---------|----------|--------|
| 1 | ios/Runner/ | PrivacyInfo.xcprivacy غير موجود (إلزامي من Apple) | آمن — أُنشئ ورُبط في pbxproj | ✅ تم |
| 2 | ios/Runner/GoogleService-Info.plist | لا CLIENT_ID/REVERSED_CLIENT_ID → Google Sign-In كان سيفشل على iOS. استُبدل الملف بالنسخة الصحيحة من Firebase (2026-07-05) وأُضيف REVERSED_CLIENT_ID كـ URL scheme في Info.plist | أُصلح | ✅ تم |
| 3 | ios/Runner/Info.plist | غياب URL scheme لعودة OAuth (io.supabase.lebesty) | آمن — أُصلح | ✅ تم |
| 4 | ios/Runner/Info.plist | نص ATT وُحّد بالفرنسية | معتمد — نُفذ | ✅ تم |
| 5 | ios/Runner/Info.plist | قُفل على portrait (iPhone) + portrait لـ iPad مع UIRequiresFullScreen (شرط App Store عند قفل iPad) | معتمد — نُفذ | ✅ تم |
| 6 | ios/Runner/Info.plist | أُضيف ITSAppUsesNonExemptEncryption=false | معتمد — نُفذ | ✅ تم |
| 7 | login/register pages | Apple Sign-In حُوّل للتدفق الأصلي على iOS (nonce + signInWithIdToken)، أُضيف entitlement applesignin، وأُضيفت crypto للـ pubspec. ⚠️ يتطلب: تفعيل Sign In with Apple للـ App ID في Apple Developer Portal + إضافة com.lebesty.lebesty في Client IDs بإعدادات Apple provider في Supabase | معتمد — نُفذ | ✅ (مع خطوتين خارجيتين) |
| 8 | pubspec.yaml | version 1.0.0+1 — بانتظار آخر versionCode من Play Console | يحتاج معلومة من المستخدم | ⏳ معلق |
| 9 | ios/Runner.xcodeproj | GoogleService-Info.plist لم يكن مضافا للمشروع → Firebase كان سيفشل عند الإقلاع على iOS | آمن — أُضيف لـ Resources | ✅ تم |
| 10 | register_page.dart | (اكتُشف عرضا) حقل _oauthEmail يُكتب ولا يُقرأ + ودجت _LanguageStep غير مستخدمة | سيُراجع في الدفعة 4 | ⬜ |
| 11 | onesignal_service.dart | نقر الإشعار الآن ينقل لصفحة /conversations (إذا المستخدم مسجل والـ router جاهز)، حُذف debugPrint، وأصبح rootNavigatorKey عاما في router.dart | معتمد — نُفذ | ✅ تم |
| 12 | ios/Podfile | GoogleMobileAdsMediationFacebook بدون رقم نسخة — التحقق من توافقها مع GMA SDK 11 عند pod install على Mac | ملاحظة للبناء على Mac | ⏳ معلق |
| 13 | assets/translations/*.json | حُذف مجلد الترجمات الميت + سطر pubspec | معتمد — نُفذ | ✅ تم |
| 14 | lib/data/categories.dart | labelEn يحتوي كلمات فرنسية — قرار المستخدم: تجاوز (labelEn غير معروضة في الواجهة) | مغلق بقرار | ✅ مغلق |
| 15 | home_page.dart | 5 × debugPrint في catch (أسطر جلب المنتجات/العداد) — تُطبع حتى في release | يحتاج قرار: لفها بـ kDebugMode أم حذفها | ⏳ معلق |
| 16 | login/register/search | نصوص الواجهة فرنسية hardcoded رغم وجود مفاتيحها في l10n — مستخدم العربية/الإنجليزية يرى الفرنسية في شاشات الدخول والبحث | يحتاج قرار: مقصود أم يُربط بـ l10n | ⏳ معلق |
| 17 | search_page.dart | حُسم: قراءة profiles عامة بالتصميم (الهاتف يُعرض عمدا في البروفايل العام)، والكتابة مقيدة بالمالك عبر RLS — لا تسريب | مغلق — سليم | ✅ مغلق |
| 18 | register_page.dart | حُذف كود ميت: ودجت _LanguageStep كاملة + حقل _oauthEmail (يُكتب ولا يُقرأ) — flutter analyze نظيف | آمن — نُفذ | ✅ تم |
| 19 | my_profile_page.dart | تقييم الذات — قرار المستخدم: مقصود، لا يُغيَّر | مغلق بقرار | ✅ مغلق |
| 20 | product_detail_page.dart | حقل تعليق التقييم — قرار المستخدم: يُترك كما هو | مغلق بقرار | ✅ مغلق |
| 21 | add_product_page.dart | رسالة النشر عند pending — قرار المستخدم: تُترك كما هي | مغلق بقرار | ✅ مغلق |
| 22 | add_product_page.dart | فحص NSFW على iOS — أُضيف لقائمة اختبار الجهاز الحقيقي | قائمة الاختبار | ✅ سُجل |

## ⚠️ نطاق الفحص من الدفعة 6 فصاعدا (قرار المستخدم 2026-07-05)
التركيز حصريا على ما قد يسبب رفض Apple أو مشاكل أمان/خصوصية: متطلبات التقديم، الأذونات، الخصوصية، الأمان، RLS. تفاصيل منطق العمل وUX التي يرضى عنها المستخدم لا تُرفع كبنود.

## 📱 قائمة اختبار الجهاز الحقيقي (قبل رفع النسخة)
- [ ] Google Sign-In (native) — يفتح ويعود ويسجل
- [ ] Apple Sign-In (native sheet) — بعد تفعيل capability في Developer Portal وإضافة bundle id في Supabase Apple provider
- [ ] عودة OAuth عبر io.supabase.lebesty:// (تدفق أندرويد/الاحتياطي)
- [ ] وصول إشعار OneSignal push + النقر ينقل للمحادثات (يتطلب جهازا حقيقيا وليس Simulator)
- [ ] نافذة إذن ATT تظهر في السبلاش ثم تُحمَّل الإعلانات (AdMob + Meta bidding)
- [ ] فحص NSFW يعمل فعلا على iOS (جرّب صورة حساسة وتأكد أنها تصير pending) — بند 22
- [ ] الأذونات: كاميرا، معرض، ميكروفون (رسالة صوتية)، موقع (اختيار موقع المتجر)
- [ ] Firebase يقلع بلا أخطاء (بعد ربط GoogleService-Info.plist في المشروع)
- [ ] حذف الحساب: أنشئ حسابا تجريبيا، احذفه، وتأكد أن تسجيل الدخول به يفشل وأن إعادة التسجيل بنفس البريد تنجح (متطلب Apple 5.1.1)
- [ ] بعد تغيير سياسات Storage: رفع منتج جديد + حذف منتج (مع صوره) + تغيير الصورة الشخصية + إرسال صورة/صوت في محادثة — كلها يجب أن تعمل على أندرويد الحالي أيضا
| 15b | user_profile_page.dart | debugPrint في _openChat لُفّت بـ kDebugMode (نفس نمط 15 المعتمد) | آمن — نُفذ | ✅ تم |
| 15c | chat_page.dart | debugPrint في إرسال الصوت لُفّت بـ kDebugMode | آمن — نُفذ | ✅ تم |
| 23 | settings_page.dart + DB | ✅ نُفذ حذف الحساب الكامل: دالة delete_account() (تحذف ملفات storage الخاصة بالمستخدم ثم auth.users والباقي cascade)، أُصلح FK حاجب (last_message_sender_id → SET NULL — كان الاكتشاف: صف profiles لم يكن يُحذف أصلا لغياب سياسة DELETE)، والزر يستدعي rpc('delete_account'). ⚠️ يُختبر على جهاز حقيقي | معتمد — نُفذ ومطبق على الإنتاج | ✅ تم |
| 24 | Storage | ✅ أُصلحت: سياسة open_access (الكل يحذف/يعدل أي ملف!) استُبدلت بسياسات: قراءة/رفع للمسجلين، تعديل/حذف للمالك فقط. الـ buckets تبقى عامة للقراءة عبر URL (يعتمد عليه التطبيق). وسائط المحادثات وراء UUID عشوائي — مقبول | آمن — نُفذ على الإنتاج | ✅ تم |
| 25 | settings_page.dart | حُذف كود ميت: _LanguageTile + متغير locale (analyzer نظيف) | آمن — نُفذ | ✅ تم |
| 26 | Supabase Auth | توصية: تفعيل Leaked Password Protection من Dashboard → Authentication → Passwords (لا يمكن عبر SQL) | فعل يدوي للمستخدم | ⏳ معلق |
| 27 | Advisors المتبقية | تحذيرات search_path على دوال الترغرات (لم تُلمس عمدا حتى لا تنكسر notify_new_message التي قد تستعمل pg_net) + ضوضاء PostGIS (spatial_ref_sys/st_estimatedextent) — كلها WARN غير قابلة للاستغلال عمليا لأن CREATE على schema public ممنوع على anon/authenticated | موثقة — لا فعل | ✅ موثق |
