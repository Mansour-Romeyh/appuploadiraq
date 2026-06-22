import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/laws.ts.
const Map<String, Map<Lang, String>> laws = {
  /* ── Screen header ── */
  'screenTitle': {
    Lang.ar: 'ظل العدالة',
    Lang.en: 'Shadow of Justice',
    Lang.ku: 'سێبەری دادوەری',
  },

  /* ── Summary banner ── */
  'libraryTitle': {
    Lang.ar: 'المكتبة القانونية العراقية',
    Lang.en: 'Iraqi Legal Library',
    Lang.ku: 'کتێبخانەی یاساییی عێراقی',
  },
  'librarySummary': {
    Lang.ar: '{count} قانون • {articles} مادة قانونية',
    Lang.en: '{count} laws • {articles} legal articles',
    Lang.ku: '{count} یاسا • {articles} مادەی یاسایی',
  },

  /* ── Header subtitle (law list view) ── */
  'headerSubList': {
    Lang.ar: '{count} قانون • {articles} مادة',
    Lang.en: '{count} laws • {articles} articles',
    Lang.ku: '{count} یاسا • {articles} مادە',
  },

  /* ── Meta badges on each law card ── */
  'chapters': {Lang.ar: 'فصل', Lang.en: 'ch.', Lang.ku: 'بەش'},
  'articles': {Lang.ar: 'مادة', Lang.en: 'art.', Lang.ku: 'مادە'},

  /* ── Search bar ── */
  'searchPlaceholder': {
    Lang.ar: 'ابحث في جميع القوانين...',
    Lang.en: 'Search all laws...',
    Lang.ku: 'لە هەموو یاساکاندا بگەڕێ...',
  },

  /* ── Search results header ── */
  'resultsCount': {
    Lang.ar: '{count} نتيجة في جميع القوانين',
    Lang.en: '{count} result(s) across all laws',
    Lang.ku: '{count} ئەنجام لە هەموو یاساکاندا',
  },

  /* ── Empty state ── */
  'noResults': {
    Lang.ar: 'لم نجد نتائج لـ "{query}"',
    Lang.en: 'No results for "{query}"',
    Lang.ku: 'هیچ ئەنجامێک نەدۆزرایەوە بۆ "{query}"',
  },

  /* ── Disclaimer banner (non-Arabic) ── */
  'disclaimer': {
    Lang.ar: '',
    Lang.en:
        'Unofficial translation — the Arabic text is the authoritative legal version.',
    Lang.ku: 'وەرگێڕانی نافەرمی — دەقی عەرەبی سەرچاوەی فەرمی یاساییە.',
  },
};
