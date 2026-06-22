import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/components.ts.
const Map<String, Map<Lang, String>> components = {
  // ─── ErrorFallback ───
  'error.unexpected': {
    Lang.ar: 'حدث خطأ غير متوقع',
    Lang.en: 'An unexpected error occurred',
    Lang.ku: 'هەڵەیەکی چاوەڕواننەکراو ڕوویدا',
  },
  'error.restartHint': {
    Lang.ar: 'يرجى إعادة تشغيل التطبيق للمتابعة.',
    Lang.en: 'Please restart the app to continue.',
    Lang.ku: 'تکایە ئەپەکە دووبارە دەستپێبکەرەوە بۆ بەردەوامبوون.',
  },
  'error.retry': {
    Lang.ar: 'إعادة المحاولة',
    Lang.en: 'Retry',
    Lang.ku: 'هەوڵدانەوە',
  },
  'error.details': {
    Lang.ar: 'تفاصيل الخطأ',
    Lang.en: 'Error details',
    Lang.ku: 'وردەکاری هەڵە',
  },
  'error.showDetails': {
    Lang.ar: 'عرض تفاصيل الخطأ',
    Lang.en: 'Show error details',
    Lang.ku: 'پیشاندانی وردەکاری هەڵە',
  },
  'error.close': {Lang.ar: 'إغلاق', Lang.en: 'Close', Lang.ku: 'داخستن'},
  'error.errorPrefix': {Lang.ar: 'خطأ', Lang.en: 'Error', Lang.ku: 'هەڵە'},
  'error.detailsPrefix': {
    Lang.ar: 'تفاصيل',
    Lang.en: 'Details',
    Lang.ku: 'وردەکاری',
  },
};
