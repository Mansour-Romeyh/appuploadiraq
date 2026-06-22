import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/news.ts.
const Map<String, Map<Lang, String>> news = {
  // ─── screen header ───
  'screenTitle': {
    Lang.ar: 'الأخبار والمستجدات',
    Lang.en: 'News & Updates',
    Lang.ku: 'هەواڵ و نوێکارییەکان',
  },
  'screenSub': {
    Lang.ar: 'آخر التطورات القانونية في العراق',
    Lang.en: 'Latest legal developments in Iraq',
    Lang.ku: 'دوایین گەشەسەندنەکانی یاسایی لە عێراق',
  },

  // ─── detail screen ───
  'navTitle': {
    Lang.ar: 'الأخبار القانونية',
    Lang.en: 'Legal News',
    Lang.ku: 'هەواڵی یاسایی',
  },
  'articleDetails': {
    Lang.ar: 'تفاصيل الخبر',
    Lang.en: 'Article Details',
    Lang.ku: 'وردەکاری هەواڵەکە',
  },
  'relatedNews': {
    Lang.ar: 'أخبار ذات صلة',
    Lang.en: 'Related News',
    Lang.ku: 'هەواڵی پەیوەندیدار',
  },

  // ─── not-found ───
  'notFound': {
    Lang.ar: 'الخبر غير موجود',
    Lang.en: 'Article not found',
    Lang.ku: 'هەواڵەکە نەدۆزرایەوە',
  },

  // ─── category display labels ───
  'cat.تشريعات': {
    Lang.ar: 'تشريعات',
    Lang.en: 'Legislation',
    Lang.ku: 'یاساسازی',
  },
  'cat.أخبار قانونية': {
    Lang.ar: 'أخبار قانونية',
    Lang.en: 'Legal News',
    Lang.ku: 'هەواڵی یاسایی',
  },
  'cat.توعية': {
    Lang.ar: 'توعية',
    Lang.en: 'Awareness',
    Lang.ku: 'ئاگادارکردنەوە',
  },
  'cat.استثمار': {
    Lang.ar: 'استثمار',
    Lang.en: 'Investment',
    Lang.ku: 'وەبەرهێنان',
  },
};
