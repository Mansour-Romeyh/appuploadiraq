import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/team.ts.
const Map<String, Map<Lang, String>> team = {
  // ─── screen header ───
  'screenTitle': {
    Lang.ar: 'فريقنا القانوني',
    Lang.en: 'Our Legal Team',
    Lang.ku: 'تیمی یاسایی ئێمە',
  },
  'screenSubtitle': {
    Lang.ar: 'محامون متخصصون بخبرة واسعة في القانون العراقي',
    Lang.en: 'Specialized lawyers with extensive expertise in Iraqi law',
    Lang.ku: 'پارێزەرانی پسپۆڕ کە زۆر ئەزمووندارن لە یاسای عێراقی',
  },

  // ─── lawyer card / list ───
  'nextAvailable': {
    Lang.ar: 'أقرب موعد متاح',
    Lang.en: 'Next available',
    Lang.ku: 'نزیکترین کات',
  },
  'experienceUnit': {
    Lang.ar: 'سنة خبرة',
    Lang.en: 'yrs exp',
    Lang.ku: 'ساڵ ئەزموون',
  },
  'casesUnit': {Lang.ar: 'قضية', Lang.en: 'cases', Lang.ku: 'دۆسیە'},
  'casesCompleted': {
    Lang.ar: 'موكّل وقضية',
    Lang.en: 'clients & cases',
    Lang.ku: 'مەکتوب و دۆسیە',
  },

  // ─── profile screen ───
  'tabAbout': {Lang.ar: 'نبذة', Lang.en: 'About', Lang.ku: 'دەربارە'},
  'tabAvailability': {
    Lang.ar: 'المواعيد',
    Lang.en: 'Availability',
    Lang.ku: 'خستنەڕووی کات',
  },
  'tabExperience': {
    Lang.ar: 'الخبرة',
    Lang.en: 'Experience',
    Lang.ku: 'ئەزموون',
  },
  'tabEducation': {Lang.ar: 'التعليم', Lang.en: 'Education', Lang.ku: 'خوێندن'},

  // ─── info card labels ───
  'infoSpecialty': {Lang.ar: 'التخصص', Lang.en: 'Specialty', Lang.ku: 'پسپۆڕی'},
  'infoCompletedCases': {
    Lang.ar: 'القضايا المنجزة',
    Lang.en: 'Completed cases',
    Lang.ku: 'دۆسیە تەواوبووەکان',
  },
  'infoNextAvailable': {
    Lang.ar: 'أقرب موعد متاح',
    Lang.en: 'Next available slot',
    Lang.ku: 'نزیکترین کاتی بەردەست',
  },
  'infoStatus': {Lang.ar: 'الحالة', Lang.en: 'Status', Lang.ku: 'دۆخ'},

  // ─── availability tab ───
  'available': {Lang.ar: 'متاح', Lang.en: 'Available', Lang.ku: 'بەردەستە'},
  'availableNow': {
    Lang.ar: 'متاح للاستشارة',
    Lang.en: 'Available for consultation',
    Lang.ku: 'بەردەستە بۆ ڕاوێژ',
  },
  'notAvailable': {
    Lang.ar: 'غير متاح حالياً',
    Lang.en: 'Not available now',
    Lang.ku: 'ئێستا بەردەست نییە',
  },

  // ─── experience tab ───
  'experienceDescription': {
    Lang.ar:
        'سنة من الخبرة في {specialty}، أنجز خلالها أكثر من {cases} قضية أمام المحاكم العراقية بمختلف درجاتها.',
    Lang.en:
        'years of experience in {specialty}, with over {cases} cases handled before Iraqi courts at all levels.',
    Lang.ku:
        'ساڵ ئەزموون لە {specialty}، زیاتر لە {cases} دۆسیە ئەنجامداوە لەبەردەم دادگاکانی عێراقی.',
  },

  // ─── education tab ───
  'educationTitle': {
    Lang.ar: 'المؤهل العلمي',
    Lang.en: 'Academic qualification',
    Lang.ku: 'بڕوانامەی زانستی',
  },

  // ─── not-found ───
  'notFound': {
    Lang.ar: 'المحامي غير موجود',
    Lang.en: 'Lawyer not found',
    Lang.ku: 'پارێزەر نەدۆزرایەوە',
  },

  // ─── appointment CTA ───
  'bookAppointment': {
    Lang.ar: 'احجز موعداً',
    Lang.en: 'Book an appointment',
    Lang.ku: 'کاتژمێر دابین بکە',
  },
};
