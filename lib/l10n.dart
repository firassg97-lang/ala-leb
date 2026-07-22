import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppL10n — lightweight translation helper
//
// Usage:
//   context.tr('settings')          → "Paramètres" / "Settings" / "الإعدادات"
//   AppL10n.catLabel(ctx, fr, ar)   → locale-aware category label
//   AppL10n.conditionLabel(ctx, c)  → locale-aware condition label
//   AppL10n.pricePerDay(ctx)        → "/jour" / "/day" / "/يوم"
// ─────────────────────────────────────────────────────────────────────────────

class AppL10n {
  AppL10n._();

  static String tr(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    final map = _data[lang] ?? _data['fr']!;
    return map[key] ?? _data['fr']![key] ?? key;
  }

  /// Returns locale-aware label for a category node.
  /// Falls back to [labelFr] if no Arabic label exists.
  static String catLabel(BuildContext context, String labelFr, String labelAr) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'ar') return labelAr.isNotEmpty ? labelAr : labelFr;
    return labelFr;
  }

  /// Returns locale-aware label using a category id → Tunisian Darija lookup,
  /// with [labelFr] as fallback.
  static String catLabelById(BuildContext context, String id, String labelFr) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'ar') {
      return _catArLabels[id] ?? labelFr;
    }
    return labelFr;
  }

  /// Context-free lookup of the Tunisian Darija label for a category [id].
  /// Returns null if not found.
  static String? categoryArLabelById(String id) => _catArLabels[id];

  /// Condition label (new / good_used / used)
  static String conditionLabel(BuildContext context, String condition) {
    switch (condition) {
      case 'new':       return tr(context, 'cond_new');
      case 'good_used': return tr(context, 'cond_good');
      case 'used':      return tr(context, 'cond_used');
      default:          return condition;
    }
  }

  /// "/jour" or "/day" or "/يوم" depending on locale
  static String pricePerDay(BuildContext context) => tr(context, 'price_day_suffix');

  // ── Translations ────────────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _data = {
    // ── FRENCH ────────────────────────────────────────────────────────────────
    'fr': {
      // Navigation
      'nav_home':     'Accueil',
      'nav_search':   'Recherche',
      'nav_add':      'Ajouter',
      'nav_messages': 'Messages',
      'nav_profile':  'Profil',

      // Settings
      'settings':               'Paramètres',
      'account':                'Compte',
      'edit_profile':           'Modifier le profil',
      'blocked_users':          'Utilisateurs bloqués',
      'change_password':        'Changer le mot de passe',
      'email_sent':             'Email envoyé',
      'appearance':             'Apparence',
      'dark_mode':              'Mode sombre',
      'language':               'Langue',
      'choose_language':        'Choisir la langue',
      'information':            'Informations',
      'privacy_policy':         'Politique de confidentialité',
      'contact_label':          'Contact',
      'logout':                 'Se déconnecter',
      'logout_confirm_title':   'Se déconnecter ?',
      'cancel':                 'Annuler',
      'logout_btn':             'Déconnecter',
      'delete_account':         'Supprimer le compte',
      'delete_account_title':   'Supprimer le compte ?',
      'delete_account_warning': 'Cette action est irréversible. Toutes vos données seront supprimées.',
      'delete':                 'Supprimer',

      // Profile page
      'user_label':      'Utilisateur',
      'no_published':    'Aucun article publié',
      'start_selling':   'Ajoutez votre premier article et commencez à vendre !',
      'add_first':       'Ajoutez votre premier article',
      'take_photo':      'Prendre une photo',
      'choose_gallery':  'Choisir depuis la galerie',
      'photo_profile':   'Photo de profil',
      'rate_shop':       'Évaluer votre boutique',
      'modify_rating':   'Modifier votre note',
      'send_btn':        'Envoyer',
      'update_btn':      'Mettre à jour',
      'see_on_map':      '📍 Voir sur la carte',
      'evaluate':        'Évaluer',
      'modify':          'Modifier',
      'rating_1':        'Mauvais',
      'rating_2':        'Passable',
      'rating_3':        'Bien',
      'rating_4':        'Très bien',
      'rating_5':        'Excellent',
      'rating_submitted':'Évaluation soumise !',
      'error_prefix':    'Erreur',
      'reviews_label':   'avis',

      // Common badges / product card
      'sale_badge':    'Vente',
      'rental_badge':  'Location',
      'original_badge':'Original',
      'vendor_label':  'Vendeur',
      'for_sale':      '🛍️ Pour vente',
      'for_rental':    '👗 Pour location',

      // Conditions
      'cond_new':  'Nouveau',
      'cond_good': 'Bon état',
      'cond_used': 'Utilisé',

      // Price
      'price_day_suffix': ' TND/jour',

      // Filter sheet
      'filters':       'Filtres',
      'clear':         'Effacer',
      'type_label':    'Type',
      'original_only': 'Original seulement',
      'show_originals':'Afficher uniquement les articles originaux',
      'category':      'Catégorie',
      'subcategory':   'Sous-catégorie',
      'item_label':    'Article',
      'regions':       'Gouvernorats',
      'back_apply':    'Appliquer et retour',
      'sponsored':     'Sponsorisé',

      // Auth
      'login':               'Connexion',
      'register':            "S'inscrire",
      'email':               'Email',
      'password':            'Mot de passe',
      'confirm_password':    'Confirmer le mot de passe',
      'sign_in':             'Se connecter',
      'sign_up':             "S'inscrire",
      'forgot_password':     'Mot de passe oublié ?',
      'step_label':          'Étape',
      'continue_btn':        'Continuer',
      'create_account_btn':  'Créer mon compte',
      'create_account_title':'Créer un compte',
      'choose_method':       "Choisissez votre méthode d'inscription",
      'email_password':      'Email / Mot de passe',
      'classic_register':    'Inscription classique',
      'continue_apple':      'Continuer avec Apple',
      'apple_required':      'Requis pour iOS App Store',
      'continue_google':     'Continuer avec Google',
      'quick_login':         'Connexion rapide',
      'credentials_title':   'Vos identifiants',
      'pref_language':       'Langue préférée',
      'choose_lang_sub':     'Choisissez votre langue',
      'your_region':         'Votre gouvernorat',
      'select_region':       'Sélectionnez votre région',
      'account_type':        'Type de compte',
      'who_are_you':         'Qui êtes-vous sur Lebesty ?',
      'shop':                'Boutique',
      'user_type':           'Utilisateur',
      'shop_type':           'Type de boutique',
      'what_shop':           'Quel type de boutique avez-vous ?',
      'shop_info':           'Informations boutique',
      'your_profile':        'Votre profil',
      'shop_name':           'Nom de la boutique *',
      'full_name':           'Nom complet *',
      'phone_opt':           'Téléphone (optionnel)',
      'pick_location':       'Choisir la localisation sur la carte',
      'location_saved':      '✅ Localisation enregistrée',
      'email_required':      'Email requis',
      'email_invalid':       'Email invalide',
      'min_6_chars':         'Minimum 6 caractères',
      'passwords_mismatch':  'Les mots de passe ne correspondent pas',
      'verify_email':        'Vérifiez votre email pour confirmer le compte',
      'email_used':          'Email déjà utilisé',
      'session_expired':     'Session expirée, veuillez réessayer',
      'photos_denied':       'Permission photos refusée',
    },

    // ── ENGLISH ───────────────────────────────────────────────────────────────
    'en': {
      // Navigation
      'nav_home':     'Home',
      'nav_search':   'Search',
      'nav_add':      'Add',
      'nav_messages': 'Messages',
      'nav_profile':  'Profile',

      // Settings
      'settings':               'Settings',
      'account':                'Account',
      'edit_profile':           'Edit profile',
      'blocked_users':          'Blocked users',
      'change_password':        'Change password',
      'email_sent':             'Email sent',
      'appearance':             'Appearance',
      'dark_mode':              'Dark mode',
      'language':               'Language',
      'choose_language':        'Choose language',
      'information':            'Information',
      'privacy_policy':         'Privacy policy',
      'contact_label':          'Contact',
      'logout':                 'Sign out',
      'logout_confirm_title':   'Sign out?',
      'cancel':                 'Cancel',
      'logout_btn':             'Sign out',
      'delete_account':         'Delete account',
      'delete_account_title':   'Delete account?',
      'delete_account_warning': 'This action is irreversible. All your data will be deleted.',
      'delete':                 'Delete',

      // Profile page
      'user_label':      'User',
      'no_published':    'No published products',
      'start_selling':   'Add your first product and start selling!',
      'add_first':       'Add your first product',
      'take_photo':      'Take a photo',
      'choose_gallery':  'Choose from gallery',
      'photo_profile':   'Profile photo',
      'rate_shop':       'Rate your shop',
      'modify_rating':   'Modify your rating',
      'send_btn':        'Send',
      'update_btn':      'Update',
      'see_on_map':      '📍 View on map',
      'evaluate':        'Rate',
      'modify':          'Edit',
      'rating_1':        'Bad',
      'rating_2':        'OK',
      'rating_3':        'Good',
      'rating_4':        'Very good',
      'rating_5':        'Excellent',
      'rating_submitted':'Rating submitted!',
      'error_prefix':    'Error',
      'reviews_label':   'reviews',

      // Common badges / product card
      'sale_badge':    'Sale',
      'rental_badge':  'Rental',
      'original_badge':'Original',
      'vendor_label':  'Seller',
      'for_sale':      '🛍️ For sale',
      'for_rental':    '👗 For rent',

      // Conditions
      'cond_new':  'New',
      'cond_good': 'Good',
      'cond_used': 'Used',

      // Price
      'price_day_suffix': ' TND/day',

      // Filter sheet
      'filters':       'Filters',
      'clear':         'Clear',
      'type_label':    'Type',
      'original_only': 'Original only',
      'show_originals':'Show only original items',
      'category':      'Category',
      'subcategory':   'Subcategory',
      'item_label':    'Item',
      'regions':       'Regions',
      'back_apply':    'Apply and back',
      'sponsored':     'Sponsored',

      // Auth
      'login':               'Login',
      'register':            'Register',
      'email':               'Email',
      'password':            'Password',
      'confirm_password':    'Confirm password',
      'sign_in':             'Sign in',
      'sign_up':             'Sign up',
      'forgot_password':     'Forgot password?',
      'step_label':          'Step',
      'continue_btn':        'Continue',
      'create_account_btn':  'Create account',
      'create_account_title':'Create account',
      'choose_method':       'Choose your registration method',
      'email_password':      'Email / Password',
      'classic_register':    'Classic registration',
      'continue_apple':      'Continue with Apple',
      'apple_required':      'Required for iOS App Store',
      'continue_google':     'Continue with Google',
      'quick_login':         'Quick login',
      'credentials_title':   'Your credentials',
      'pref_language':       'Preferred language',
      'choose_lang_sub':     'Choose your language',
      'your_region':         'Your region',
      'select_region':       'Select your region',
      'account_type':        'Account type',
      'who_are_you':         'Who are you on Lebesty?',
      'shop':                'Shop',
      'user_type':           'User',
      'shop_type':           'Shop type',
      'what_shop':           'What type of shop do you have?',
      'shop_info':           'Shop information',
      'your_profile':        'Your profile',
      'shop_name':           'Shop name *',
      'full_name':           'Full name *',
      'phone_opt':           'Phone (optional)',
      'pick_location':       'Choose location on map',
      'location_saved':      '✅ Location saved',
      'email_required':      'Email required',
      'email_invalid':       'Invalid email',
      'min_6_chars':         'Minimum 6 characters',
      'passwords_mismatch':  'Passwords do not match',
      'verify_email':        'Check your email to confirm your account',
      'email_used':          'Email already in use',
      'session_expired':     'Session expired, please try again',
      'photos_denied':       'Photo permission denied',
    },

    // ── ARABIC (عربي فصيح للنصوص العامة + دارجة تونسية للتصنيفات) ────────────
    'ar': {
      // Navigation — فصيح
      'nav_home':     'الرئيسية',
      'nav_search':   'البحث',
      'nav_add':      'إضافة',
      'nav_messages': 'الرسائل',
      'nav_profile':  'ملفي',

      // Settings — فصيح
      'settings':               'الإعدادات',
      'account':                'الحساب',
      'edit_profile':           'تعديل الملف الشخصي',
      'blocked_users':          'المستخدمون المحظورون',
      'change_password':        'تغيير كلمة المرور',
      'email_sent':             'تم إرسال البريد الإلكتروني',
      'appearance':             'المظهر',
      'dark_mode':              'الوضع الليلي',
      'language':               'اللغة',
      'choose_language':        'اختر اللغة',
      'information':            'معلومات',
      'privacy_policy':         'سياسة الخصوصية',
      'contact_label':          'تواصل معنا',
      'logout':                 'تسجيل الخروج',
      'logout_confirm_title':   'تأكيد الخروج؟',
      'cancel':                 'إلغاء',
      'logout_btn':             'خروج',
      'delete_account':         'حذف الحساب',
      'delete_account_title':   'حذف الحساب؟',
      'delete_account_warning': 'هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع بياناتك.',
      'delete':                 'حذف',

      // Profile page — فصيح
      'user_label':      'مستخدم',
      'no_published':    'لم تنشر أي منتجات بعد',
      'start_selling':   'أضف منتجك الأول وابدأ البيع!',
      'add_first':       'أضف منتجك الأول',
      'take_photo':      'التقاط صورة',
      'choose_gallery':  'اختيار من المعرض',
      'photo_profile':   'صورة الملف الشخصي',
      'rate_shop':       'قيّم متجرك',
      'modify_rating':   'تعديل تقييمك',
      'send_btn':        'إرسال',
      'update_btn':      'تحديث',
      'see_on_map':      '📍 عرض على الخريطة',
      'evaluate':        'تقييم',
      'modify':          'تعديل',
      'rating_1':        'سيئ',
      'rating_2':        'مقبول',
      'rating_3':        'جيد',
      'rating_4':        'جيد جداً',
      'rating_5':        'ممتاز',
      'rating_submitted':'تم إرسال التقييم!',
      'error_prefix':    'خطأ',
      'reviews_label':   'تقييم',

      // Common badges / product card — فصيح
      'sale_badge':    'للبيع',
      'rental_badge':  'للكراء',
      'original_badge':'أصلي',
      'vendor_label':  'بائع',
      'for_sale':      '🛍️ للبيع',
      'for_rental':    '👗 للكراء',

      // Conditions — فصيح
      'cond_new':  'جديد',
      'cond_good': 'حالة جيدة',
      'cond_used': 'مستعمل',

      // Price
      'price_day_suffix': ' دينار/يوم',

      // Filter sheet — فصيح
      'filters':       'تصفية',
      'clear':         'مسح',
      'type_label':    'النوع',
      'original_only': 'الأصلي فقط',
      'show_originals':'عرض المنتجات الأصلية فقط',
      'category':      'الفئة',
      'subcategory':   'فئة فرعية',
      'item_label':    'منتج',
      'regions':       'الولايات',
      'back_apply':    'تطبيق والرجوع',
      'sponsored':     'إعلان',

      // Auth — فصيح
      'login':               'تسجيل الدخول',
      'register':            'إنشاء حساب',
      'email':               'البريد الإلكتروني',
      'password':            'كلمة المرور',
      'confirm_password':    'تأكيد كلمة المرور',
      'sign_in':             'دخول',
      'sign_up':             'إنشاء حساب',
      'forgot_password':     'نسيت كلمة المرور؟',
      'step_label':          'خطوة',
      'continue_btn':        'متابعة',
      'create_account_btn':  'إنشاء الحساب',
      'create_account_title':'إنشاء حساب',
      'choose_method':       'اختر طريقة التسجيل',
      'email_password':      'البريد وكلمة المرور',
      'classic_register':    'تسجيل عادي',
      'continue_apple':      'المتابعة مع Apple',
      'apple_required':      'مطلوب لمتجر iOS',
      'continue_google':     'المتابعة مع Google',
      'quick_login':         'تسجيل دخول سريع',
      'credentials_title':   'بيانات الدخول',
      'pref_language':       'اللغة المفضلة',
      'choose_lang_sub':     'اختر لغتك',
      'your_region':         'ولايتك',
      'select_region':       'اختر ولايتك',
      'account_type':        'نوع الحساب',
      'who_are_you':         'من أنت على ليبستي؟',
      'shop':                'متجر',
      'user_type':           'مستخدم',
      'shop_type':           'نوع المتجر',
      'what_shop':           'ما نوع متجرك؟',
      'shop_info':           'معلومات المتجر',
      'your_profile':        'ملفك الشخصي',
      'shop_name':           'اسم المتجر *',
      'full_name':           'الاسم الكامل *',
      'phone_opt':           'الهاتف (اختياري)',
      'pick_location':       'اختر الموقع على الخريطة',
      'location_saved':      '✅ تم حفظ الموقع',
      'email_required':      'البريد الإلكتروني مطلوب',
      'email_invalid':       'بريد إلكتروني غير صالح',
      'min_6_chars':         'الحد الأدنى 6 أحرف',
      'passwords_mismatch':  'كلمتا المرور غير متطابقتين',
      'verify_email':        'تحقق من بريدك لتأكيد الحساب',
      'email_used':          'البريد الإلكتروني مستخدم مسبقاً',
      'session_expired':     'انتهت الجلسة، يرجى المحاولة مجدداً',
      'photos_denied':       'لم يُمنح إذن الصور',
    },
  };

  // ── Tunisian Darija category labels (used when locale == 'ar') ────────────
  static const Map<String, String> _catArLabels = {
    // Main categories
    'women':        'ستات',
    'men':          'رجالة',
    'girls':        'بنيّات',
    'boys':         'أولاد',
    'women_rental': 'كراء ستات',
    'men_rental':   'كراء رجالة',

    // Women clothes
    'women_clothes':    'ملابس ستات',
    'robes':            'فساتين',
    'jupes':            'جيبات',
    'pantalons_f':      'بنطلونات',
    'blouses_f':        'بلوزات',
    'chemises_f':       'قمجات',
    'vestes_f':         'جاكيطات',
    'manteaux_f':       'كابوطات',
    'cardigans_f':      'كارديقان',
    'pulls_f':          'تريكو',
    'sport_f':          'رياضة',
    'sous_vetements_f': 'تحتانيات',
    'pyjamas_f':        'بيجامات',
    'maillots_f':       'مايّوهات',
    'ensembles_f':      'طقمات',

    // Women shoes
    'women_shoes':  'كشاكش ستات',
    'talons':       'كعب',
    'plates':       'بلاطو',
    'sandales_f':   'صنادل',
    'bottes_f':     'بوط',
    'sneakers_f':   'باسكات',
    'chaussons_f':  'شباط بيت',

    // Women bags
    'women_bags':       'حقايب ستات',
    'sac_main':         'حقيبة يد',
    'sac_dos':          'ساك دو',
    'sac_voyage':       'فاليز',
    'portefeuilles_f':  'بورتوفوي',
    'clutch':           'كلتش',

    // Women makeup
    'women_makeup':   'ماكياج وعناية',
    'visage':         'ماكياج وجه',
    'yeux':           'ماكياج عيون',
    'levres':         'روج',
    'soins_peau':     'عناية بشرة',
    'soins_cheveux':  'عناية بالشعر',
    'parfums_f':      'عطور',

    // Women accessories
    'women_accessories': 'إكسسوارات ستات',
    'bijoux_f':          'حلي',
    'bagues_f':          'خيتم',
    'montres_f':         'مونطر',
    'lunettes_f':        'لونيط',
    'echarpes_f':        'فولار',
    'chapeaux_f':        'كابّور',
    'ceintures_f':       'سانطور',
    'acc_cheveux':       'كليبات',

    // Men clothes
    'men_clothes':      'ملابس رجالة',
    'tshirts_m':        'تيشيرت',
    'chemises_m':       'شيميزة',
    'pantalons_m':      'سروال',
    'vestes_m':         'جاكيط',
    'manteaux_m':       'كابوط',
    'costumes_m':       'كوستيم',
    'sport_m':          'رياضة',
    'sous_vetements_m': 'تحتانيات',
    'pyjamas_m':        'بيجامة',
    'jeans_m':          'جان',
    'hoodies_m':        'هودي',
    'sweats_m':         'سويتشيرت',

    // Men shoes
    'men_shoes':    'كشاكش رجالة',
    'formelles_m':  'صابو',
    'sneakers_m':   'باسكات',
    'sandales_m':   'صنادل',
    'bottes_m':     'بوط',
    'chaussons_m':  'شباط بيت',

    // Men bags
    'men_bags':         'حقايب رجالة',
    'sac_dos_m':        'ساك دو',
    'sac_voyage_m':     'فاليز',
    'portefeuilles_m':  'بورتوفوي',
    'crossbody_m':      'كروسبودي',

    // Men accessories
    'men_accessories':  'إكسسوارات رجالة',
    'montres_m':        'مونطر',
    'lunettes_m':       'لونيط',
    'ceintures_m':      'سانطور',
    'cravates_m':       'كرافاط',
    'noeuds_m':         'نونود',
    'casquettes_m':     'كاسكيط',

    // Girls clothes
    'girls_clothes':          'ملابس بنيّات',
    'girls_robes':            'فساتين',
    'girls_jupes':            'جيبات',
    'girls_blouses':          'بلوزات',
    'girls_chemises':         'قمجات',
    'girls_pantalons':        'بنطلونات',
    'girls_manteaux':         'كابوطات',
    'girls_vestes':           'جاكيطات',
    'girls_sport':            'رياضة',
    'girls_sous_vetements':   'تحتانيات',
    'girls_pyjamas':          'بيجامات',
    'girls_ensembles':        'طقمات',

    // Girls shoes
    'girls_shoes':      'كشاكش بنيّات',
    'girls_sandales':   'صنادل',
    'girls_bottes':     'بوط',
    'girls_sneakers':   'باسكات',
    'girls_ballerines': 'باليرينا',

    // Girls accessories
    'girls_accessories':  'إكسسوارات بنيّات',
    'girls_acc_cheveux':  'كليبات',
    'girls_sacs':         'حقايب',
    'girls_bijoux':       'حلي أطفال',
    'girls_chapeaux':     'كابّور',

    // Boys clothes
    'boys_clothes':         'ملابس أولاد',
    'boys_tshirts':         'تيشيرت',
    'boys_chemises':        'شيميزة',
    'boys_pantalons':       'سروال',
    'boys_manteaux':        'كابوط',
    'boys_vestes':          'جاكيط',
    'boys_sport':           'رياضة',
    'boys_jeans':           'جان',
    'boys_sous_vetements':  'تحتانيات',
    'boys_pyjamas':         'بيجامة',
    'boys_ensembles':       'طقمات',

    // Boys shoes
    'boys_shoes':     'كشاكش أولاد',
    'boys_sneakers':  'باسكات',
    'boys_sandales':  'صنادل',
    'boys_bottes':    'بوط',
    'boys_formelles': 'صابو',

    // Boys accessories
    'boys_accessories': 'إكسسوارات أولاد',
    'boys_sacs':        'ساك دو',
    'boys_chapeaux':    'كاسكيط',
    'boys_ceintures':   'سانطور',
    'boys_lunettes':    'لونيط',

    // Rental women
    'rental_women_clothes':     'ملابس كراء',
    'robe_mariee':              'روبة عروسة',
    'robe_soiree':              'فستان سهرة',
    'robes_rental':             'فساتين',
    'jupes_rental':             'جيبات',
    'pantalons_rental':         'بنطلونات',
    'blouses_rental':           'بلوزات',
    'chemises_rental':          'قمجات',
    'vestes_rental':            'جاكيطات',
    'manteaux_rental':          'كابوطات',
    'cardigans_rental':         'كارديقان',
    'pulls_rental':             'تريكو',
    'sport_rental':             'رياضة',
    'ensembles_rental':         'طقمات',
    'rental_women_shoes':       'كشاكش كراء',
    'talons_rental':            'كعب',
    'plates_rental':            'بلاطو',
    'sandales_rental_f':        'صنادل',
    'bottes_rental_f':          'بوط',
    'sneakers_rental_f':        'باسكات',
    'rental_women_bags':        'حقايب كراء',
    'bags_rental_f':            'حقيبة يد',
    'clutch_soiree':            'كلتش سهرة',
    'sac_dos_rental_f':         'ساك دو',
    'portefeuilles_rental_f':   'بورتوفوي',
    'rental_women_accessories': 'إكسسوارات كراء',
    'bijoux_rental_f':          'حلي',
    'bagues_rental_f':          'خيتم',
    'montres_rental_f':         'مونطر',
    'lunettes_rental_f':        'لونيط',
    'echarpes_rental':          'فولار',
    'chapeaux_rental':          'كابّور',
    'ceintures_rental_f':       'سانطور',

    // Rental men
    'rental_men_clothes':       'ملابس كراء رجالة',
    'costume_arabe':            'كوستيم عربي',
    'djebba':                   'جبة',
    'costumes_formels':         'كوستيم',
    'tshirts_rental':           'تيشيرت',
    'chemises_rental_m':        'شيميزة',
    'pantalons_rental_m':       'سروال',
    'vestes_rental_m':          'جاكيط',
    'manteaux_rental_m':        'كابوط',
    'sport_rental_m':           'رياضة',
    'jeans_rental':             'جان',
    'hoodies_rental':           'هودي',
    'sweats_rental':            'سويتشيرت',
    'rental_men_shoes':         'كشاكش كراء رجالة',
    'shoes_rental_m':           'صابو',
    'sneakers_rental_m':        'باسكات',
    'sandales_rental_m':        'صنادل',
    'bottes_rental_m':          'بوط',
    'rental_men_bags':          'حقايب كراء رجالة',
    'bags_rental_m':            'ساك دو',
    'sac_voyage_rental_m':      'فاليز',
    'portefeuilles_rental_m':   'بورتوفوي',
    'rental_men_accessories':   'إكسسوارات كراء رجالة',
    'accessories_rental_m':     'مونطر',
    'lunettes_rental_m':        'لونيط',
    'ceintures_rental_m':       'سانطور',
    'cravates_rental':          'كرافاط',
    'noeuds_rental':            'نونود',
    'casquettes_rental':        'كاسكيط',
  };
}

// ── Extension shorthand ────────────────────────────────────────────────────────
extension AppL10nExt on BuildContext {
  String tr(String key) => AppL10n.tr(this, key);
}
