import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/auth.ts.
const Map<String, Map<Lang, String>> auth = {
  // ─── login screen ───
  'welcome': {Lang.ar: 'أهلاً بك', Lang.en: 'Welcome', Lang.ku: 'بەخێربێیت'},
  'subtitle': {
    Lang.ar: 'سجّل دخولك للوصول إلى جميع الخدمات القانونية',
    Lang.en: 'Sign in to access all legal services',
    Lang.ku: 'چوونەژوورەوە بۆ دەستگەیشتن بە هەموو خزمەتگوزاریە یاساییەکان',
  },
  'continueWithGoogle': {
    Lang.ar: 'المتابعة عبر Google',
    Lang.en: 'Continue with Google',
    Lang.ku: 'بەردەوامبوون لە ڕێگەی Google',
  },
  'continueWithApple': {
    Lang.ar: 'المتابعة عبر Apple',
    Lang.en: 'Continue with Apple',
    Lang.ku: 'بەردەوامبوون لە ڕێگەی Apple',
  },
  'continueWithPhone': {
    Lang.ar: 'المتابعة برقم الهاتف',
    Lang.en: 'Continue with phone',
    Lang.ku: 'بەردەوامبوون بە ژمارەی مۆبایل',
  },
  'phonePlaceholder': {
    Lang.ar: '7XX XXX XXXX',
    Lang.en: '7XX XXX XXXX',
    Lang.ku: '7XX XXX XXXX',
  },
  'phoneInvalidIraq': {
    Lang.ar:
        'أدخل رقماً عراقياً صحيحاً: ١٠ أرقام يبدأ بـ 7 أو ١١ رقماً يبدأ بـ 0',
    Lang.en:
        'Enter a valid Iraqi number: 10 digits starting with 7, or 11 digits starting with 0',
    Lang.ku:
        'ژمارەیەکی عێراقی دروست بنووسە: ١٠ ژمارە بە 7 دەست پێبکات، یان ١١ ژمارە بە 0',
  },
  'whatsappRequired': {
    Lang.ar: 'يجب أن يكون الرقم مرتبطاً بحساب واتساب لاستلام الرمز',
    Lang.en: 'The number must have a WhatsApp account to receive the code',
    Lang.ku: 'ژمارەکە دەبێت هەژماری واتساپی هەبێت بۆ وەرگرتنی کۆد',
  },
  'countryPickerTitle': {
    Lang.ar: 'اختر الدولة',
    Lang.en: 'Select country',
    Lang.ku: 'وڵات هەڵبژێرە',
  },
  'countrySearchPlaceholder': {
    Lang.ar: 'ابحث عن دولة أو رمز',
    Lang.en: 'Search country or code',
    Lang.ku: 'گەڕان بۆ وڵات یان کۆد',
  },
  'countryNoResults': {
    Lang.ar: 'لا توجد نتائج',
    Lang.en: 'No results',
    Lang.ku: 'هیچ ئەنجامێک نییە',
  },
  'browseAsGuest': {
    Lang.ar: 'تصفح كزائر',
    Lang.en: 'Browse as guest',
    Lang.ku: 'گەڕان وەک میوان',
  },
  'guestHint': {
    Lang.ar: 'ستحتاج إلى تسجيل الدخول عند حجز استشارة أو رفع قضية',
    Lang.en:
        'You will need to sign in when booking a consultation or filing a case',
    Lang.ku:
        'پێویستت بە چوونەژوورەوەیە کاتێک ڕاوێژ بکەیت یان دۆسیە تۆمار بکەیت',
  },

  // ─── google picker modal ───
  'googleSignInTitle': {
    Lang.ar: 'تسجيل الدخول باستخدام Google',
    Lang.en: 'Sign in with Google',
    Lang.ku: 'چوونەژوورەوە لە ڕێگەی Google',
  },
  'googlePickAccount': {
    Lang.ar: 'اختر حساباً للمتابعة',
    Lang.en: 'Choose an account to continue',
    Lang.ku: 'ئەکاونتێک هەڵبژێرە بۆ بەردەوامبوون',
  },

  // ─── otp screen ───
  'otpTitle': {
    Lang.ar: 'رمز التحقق',
    Lang.en: 'Verification code',
    Lang.ku: 'کۆدی دڵنیاکردنەوە',
  },
  'otpSubtitle': {
    Lang.ar: 'أرسلنا رمزاً مكوناً من ٦ أرقام إلى',
    Lang.en: 'We sent a 6-digit code to',
    Lang.ku: 'کۆدێکی ٦ ژمارەمان نێردووە بۆ',
  },
  'otpVerify': {Lang.ar: 'تحقق', Lang.en: 'Verify', Lang.ku: 'دڵنیاکردنەوە'},
  'otpVerifying': {
    Lang.ar: 'جاري التحقق...',
    Lang.en: 'Verifying...',
    Lang.ku: 'دڵنیاکردنەوە...',
  },
  'otpResendAfter': {
    Lang.ar: 'إعادة الإرسال بعد {seconds}s',
    Lang.en: 'Resend after {seconds}s',
    Lang.ku: 'نێردنەوەی دووبارە لە دوای {seconds}s',
  },
  'otpResend': {
    Lang.ar: 'إعادة إرسال الرمز',
    Lang.en: 'Resend code',
    Lang.ku: 'کۆد دووبارە بنێرە',
  },
  'otpSendFailed': {
    Lang.ar: 'تعذّر إرسال الرمز. حاول مرة أخرى.',
    Lang.en: 'Could not send the code. Please try again.',
    Lang.ku: 'نەتوانرا کۆدەکە بنێردرێت. دووبارە هەوڵبدەوە.',
  },
  'otpInvalid': {
    Lang.ar: 'الرمز غير صحيح. حاول مرة أخرى.',
    Lang.en: 'The code is incorrect. Try again.',
    Lang.ku: 'کۆدەکە هەڵەیە. دووبارە هەوڵبدەوە.',
  },
  'otpExpired': {
    Lang.ar: 'انتهت صلاحية الرمز. أعد إرساله.',
    Lang.en: 'The code has expired. Resend it.',
    Lang.ku: 'کۆدەکە بەسەرچووە. دووبارە بینێرەوە.',
  },
  'otpTooMany': {
    Lang.ar: 'محاولات خاطئة كثيرة. أعد إرسال الرمز.',
    Lang.en: 'Too many wrong attempts. Resend the code.',
    Lang.ku: 'هەوڵی هەڵە زۆر بوو. کۆدەکە دووبارە بنێرەوە.',
  },
  'otpThrottled': {
    Lang.ar: 'محاولات كثيرة. يرجى الانتظار قليلاً.',
    Lang.en: 'Too many attempts. Please wait a moment.',
    Lang.ku: 'هەوڵی زۆر. تکایە کەمێک چاوەڕێ بکە.',
  },
  'phoneNotRegistered': {
    Lang.ar: 'هذا الرقم غير مسجّل في النظام. يرجى التواصل مع المكتب.',
    Lang.en:
        'This number has no account in the system. Please contact the office.',
    Lang.ku:
        'ئەم ژمارەیە لە سیستەمدا تۆمارنەکراوە. تکایە پەیوەندی بە نووسینگەوە بکە.',
  },

  // ─── AuthSheet ───
  'sheetTitle': {
    Lang.ar: 'تسجيل الدخول مطلوب',
    Lang.en: 'Sign in required',
    Lang.ku: 'چوونەژوورەوە پێویستە',
  },
  'sheetSubtitle': {
    Lang.ar: 'يرجى تسجيل الدخول للوصول إلى {action}',
    Lang.en: 'Please sign in to access {action}',
    Lang.ku: 'تکایە بچۆ ژوورەوە بۆ دەستگەیشتن بە {action}',
  },
  'sheetDefaultAction': {
    Lang.ar: 'هذه الخدمة',
    Lang.en: 'this service',
    Lang.ku: 'ئەم خزمەتگوزارییە',
  },
  'sheetLogin': {
    Lang.ar: 'تسجيل الدخول',
    Lang.en: 'Sign in',
    Lang.ku: 'چوونەژوورەوە',
  },
  'sheetNotNow': {Lang.ar: 'ليس الآن', Lang.en: 'Not now', Lang.ku: 'ئێستا نا'},
};
