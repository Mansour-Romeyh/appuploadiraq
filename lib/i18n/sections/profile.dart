import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/profile.ts.
const Map<String, Map<Lang, String>> profile = {
  'title': {
    Lang.ar: 'الملف الشخصي',
    Lang.en: 'My Profile',
    Lang.ku: 'پرۆفایلی من',
  },
  'account': {
    Lang.ar: 'معلومات الحساب',
    Lang.en: 'Account information',
    Lang.ku: 'زانیاری هەژمار',
  },

  'name': {Lang.ar: 'الاسم', Lang.en: 'Name', Lang.ku: 'ناو'},
  'phone': {
    Lang.ar: 'رقم الهاتف',
    Lang.en: 'Phone number',
    Lang.ku: 'ژمارەی تەلەفۆن',
  },
  'email': {Lang.ar: 'البريد الإلكتروني', Lang.en: 'Email', Lang.ku: 'ئیمەیڵ'},
  'loginMethod': {
    Lang.ar: 'طريقة تسجيل الدخول',
    Lang.en: 'Sign-in method',
    Lang.ku: 'شێوازی چوونەژوورەوە',
  },
  'accountType': {
    Lang.ar: 'نوع الحساب',
    Lang.en: 'Account type',
    Lang.ku: 'جۆری هەژمار',
  },
  'registered': {
    Lang.ar: 'مستخدم مسجّل',
    Lang.en: 'Registered user',
    Lang.ku: 'بەکارهێنەری تۆمارکراو',
  },
  'notProvided': {
    Lang.ar: 'غير متوفّر',
    Lang.en: 'Not provided',
    Lang.ku: 'بەردەست نییە',
  },

  // sign-in method values
  'method.google': {
    Lang.ar: 'حساب Google',
    Lang.en: 'Google account',
    Lang.ku: 'هەژماری گووگڵ',
  },
  'method.apple': {
    Lang.ar: 'حساب Apple',
    Lang.en: 'Apple account',
    Lang.ku: 'هەژماری Apple',
  },
  'method.phone': {
    Lang.ar: 'رقم الهاتف',
    Lang.en: 'Phone number',
    Lang.ku: 'ژمارەی تەلەفۆن',
  },

  // sign out
  'signOut': {
    Lang.ar: 'تسجيل الخروج',
    Lang.en: 'Sign out',
    Lang.ku: 'چوونەدەرەوە',
  },
  'signOutConfirm': {
    Lang.ar: 'هل أنت متأكد من تسجيل الخروج؟',
    Lang.en: 'Are you sure you want to sign out?',
    Lang.ku: 'دڵنیایت دەتەوێت بچیتە دەرەوە؟',
  },

  // guest state
  'guestTitle': {Lang.ar: 'زائر', Lang.en: 'Guest', Lang.ku: 'میوان'},
  'guestSubtitle': {
    Lang.ar: 'أنت تتصفح كزائر. سجّل الدخول للوصول إلى ملفك الشخصي.',
    Lang.en: 'You are browsing as a guest. Sign in to access your profile.',
    Lang.ku: 'وەک میوان دەگەڕێیت. بچۆ ژوورەوە بۆ گەیشتن بە پرۆفایلەکەت.',
  },
  'signIn': {
    Lang.ar: 'تسجيل الدخول',
    Lang.en: 'Sign in',
    Lang.ku: 'چوونەژوورەوە',
  },

  // legal & account section (store compliance)
  'legalSection': {
    Lang.ar: 'الخصوصية والحساب',
    Lang.en: 'Privacy & account',
    Lang.ku: 'تایبەتمەندی و هەژمار',
  },
  'privacyPolicy': {
    Lang.ar: 'سياسة الخصوصية',
    Lang.en: 'Privacy Policy',
    Lang.ku: 'سیاسەتی تایبەتمەندی',
  },
  'deleteAccount': {
    Lang.ar: 'حذف الحساب',
    Lang.en: 'Delete account',
    Lang.ku: 'سڕینەوەی هەژمار',
  },
  'deleteConfirm': {
    Lang.ar: 'هل أنت متأكد من حذف حسابك؟',
    Lang.en: 'Are you sure you want to delete your account?',
    Lang.ku: 'دڵنیایت دەتەوێت هەژمارەکەت بسڕیتەوە؟',
  },
  'deleteWarning': {
    Lang.ar: 'سيتم تعطيل حسابك وإزالة بياناتك الشخصية نهائيًا. لا يمكن التراجع عن هذا الإجراء.',
    Lang.en: 'Your account will be disabled and your personal data permanently removed. This cannot be undone.',
    Lang.ku: 'هەژمارەکەت ناچالاک دەکرێت و زانیاری کەسیت بۆ هەمیشە لادەبرێت. ناگەڕێتەوە.',
  },
  'deleting': {
    Lang.ar: 'جارٍ الحذف…',
    Lang.en: 'Deleting…',
    Lang.ku: 'سڕینەوە…',
  },
  'deleteError': {
    Lang.ar: 'تعذّر حذف الحساب. حاول مرة أخرى.',
    Lang.en: 'Could not delete the account. Please try again.',
    Lang.ku: 'سڕینەوەی هەژمار سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.',
  },
};
