import '../lang.dart';

/// Shared UI strings (tab bar, generic actions, brand, language switcher).
/// Ported 1:1 from law-firm-app/i18n/sections/common.ts.
const Map<String, Map<Lang, String>> common = {
  // ─── brand ───
  'firmName': {
    Lang.ar: 'شركة ظل العدالة',
    Lang.en: 'Shadow of Justice Law Firm',
    Lang.ku: 'کۆمپانیای سێبەری دادپەروەری',
  },
  'firmShort': {
    Lang.ar: 'ظل العدالة',
    Lang.en: 'Shadow of Justice',
    Lang.ku: 'سێبەری دادپەروەری',
  },
  'company': {Lang.ar: 'شركة', Lang.en: 'Company', Lang.ku: 'کۆمپانیا'},

  // ─── tab bar ───
  'tab.home': {Lang.ar: 'الرئيسية', Lang.en: 'Home', Lang.ku: 'سەرەکی'},
  'tab.team': {Lang.ar: 'الفريق', Lang.en: 'Team', Lang.ku: 'تیم'},
  'tab.cases': {Lang.ar: 'القضايا', Lang.en: 'Cases', Lang.ku: 'دۆسیەکان'},
  'tab.laws': {Lang.ar: 'القوانين', Lang.en: 'Laws', Lang.ku: 'یاساکان'},
  'tab.ai': {Lang.ar: 'المستشار', Lang.en: 'AI', Lang.ku: 'یاریدەدەر'},
  'tab.contact': {Lang.ar: 'تواصل', Lang.en: 'Contact', Lang.ku: 'پەیوەندی'},
  'tab.office': {Lang.ar: 'مكتبي', Lang.en: 'Office', Lang.ku: 'نووسینگە'},

  // ─── generic actions ───
  'back': {Lang.ar: 'رجوع', Lang.en: 'Back', Lang.ku: 'گەڕانەوە'},
  'viewAll': {
    Lang.ar: 'عرض الكل',
    Lang.en: 'View all',
    Lang.ku: 'هەمووی ببینە',
  },
  'or': {Lang.ar: 'أو', Lang.en: 'or', Lang.ku: 'یان'},
  'free': {Lang.ar: 'مجاناً', Lang.en: 'Free', Lang.ku: 'بەخۆڕایی'},
  'freeConsultation': {
    Lang.ar: 'استشارة مجانية',
    Lang.en: 'Free consultation',
    Lang.ku: 'ڕاوێژی بەخۆڕایی',
  },
  'cancel': {Lang.ar: 'إلغاء', Lang.en: 'Cancel', Lang.ku: 'هەڵوەشاندنەوە'},
  'save': {Lang.ar: 'حفظ', Lang.en: 'Save', Lang.ku: 'پاشەکەوتکردن'},
  'confirm': {Lang.ar: 'تأكيد', Lang.en: 'Confirm', Lang.ku: 'پشتڕاستکردنەوە'},
  'delete': {Lang.ar: 'حذف', Lang.en: 'Delete', Lang.ku: 'سڕینەوە'},
  'edit': {Lang.ar: 'تعديل', Lang.en: 'Edit', Lang.ku: 'دەستکاری'},
  'close': {Lang.ar: 'إغلاق', Lang.en: 'Close', Lang.ku: 'داخستن'},
  'search': {Lang.ar: 'بحث', Lang.en: 'Search', Lang.ku: 'گەڕان'},
  'loading': {
    Lang.ar: 'جارٍ التحميل…',
    Lang.en: 'Loading…',
    Lang.ku: 'بارکردن…',
  },
  'retry': {Lang.ar: 'إعادة المحاولة', Lang.en: 'Retry', Lang.ku: 'هەوڵدانەوە'},
  'all': {Lang.ar: 'الكل', Lang.en: 'All', Lang.ku: 'هەموو'},
  'readMore': {
    Lang.ar: 'اقرأ المزيد',
    Lang.en: 'Read more',
    Lang.ku: 'زیاتر بخوێنەوە',
  },

  // ─── language switcher ───
  'language': {Lang.ar: 'اللغة', Lang.en: 'Language', Lang.ku: 'زمان'},
  'chooseLanguage': {
    Lang.ar: 'اختر اللغة',
    Lang.en: 'Choose language',
    Lang.ku: 'زمان هەڵبژێرە',
  },
};
