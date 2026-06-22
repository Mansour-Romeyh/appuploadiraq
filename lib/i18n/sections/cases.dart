import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/cases.ts.
const Map<String, Map<Lang, String>> cases = {
  /* ── Screen header ── */
  'screenTitle': {
    Lang.ar: 'متابعة القضايا',
    Lang.en: 'Case Tracking',
    Lang.ku: 'شوێنکەوتنی دەعوا',
  },
  // Subtitle for the Cases entry button on the Office hub.
  'hubCardSubtitle': {
    Lang.ar: 'عرض قضاياك المسجلة',
    Lang.en: 'View your registered cases',
    Lang.ku: 'بینینی دەعوا تۆمارکراوەکانت',
  },
  'casesCount': {
    Lang.ar: '{n} قضية مسجلة',
    Lang.en: '{n} registered cases',
    Lang.ku: '{n} دەعوای تۆمارکراو',
  },
  'loading': {
    Lang.ar: 'جارٍ تحميل القضايا...',
    Lang.en: 'Loading cases...',
    Lang.ku: 'دەعواکان بار دەکرێن...',
  },
  'openedLabel': {
    Lang.ar: 'تاريخ الفتح: {date}',
    Lang.en: 'Opened: {date}',
    Lang.ku: 'کرانەوە: {date}',
  },

  /* ── Filter bar ── */
  'filterAll': {Lang.ar: 'الكل', Lang.en: 'All', Lang.ku: 'هەموو'},

  /* ── Status display labels (keyed by CaseStatus value) ── */
  'status.جارية': {Lang.ar: 'جارية', Lang.en: 'Active', Lang.ku: 'چالاک'},
  'status.معلّقة': {Lang.ar: 'معلّقة', Lang.en: 'Pending', Lang.ku: 'لەوەستان'},
  'status.مغلقة': {Lang.ar: 'مغلقة', Lang.en: 'Closed', Lang.ku: 'داخراو'},
  'status.فائزة': {Lang.ar: 'فائزة', Lang.en: 'Won', Lang.ku: 'بردراو'},
  'status.خاسرة': {Lang.ar: 'خاسرة', Lang.en: 'Lost', Lang.ku: 'باختراو'},

  /* ── Case type labels ── */
  'type.جنائية': {Lang.ar: 'جنائية', Lang.en: 'Criminal', Lang.ku: 'تاوانکاری'},
  'type.مدنية': {Lang.ar: 'مدنية', Lang.en: 'Civil', Lang.ku: 'مەدەنی'},
  'type.تجارية': {
    Lang.ar: 'تجارية',
    Lang.en: 'Commercial',
    Lang.ku: 'بازرگانی',
  },
  'type.عمالية': {Lang.ar: 'عمالية', Lang.en: 'Labour', Lang.ku: 'کرێکاری'},
  'type.أسرة': {Lang.ar: 'أسرة', Lang.en: 'Family', Lang.ku: 'خێزانی'},
  'type.عقارية': {
    Lang.ar: 'عقارية',
    Lang.en: 'Real Estate',
    Lang.ku: 'خانووبەرە',
  },
  'type.إدارية': {
    Lang.ar: 'إدارية',
    Lang.en: 'Administrative',
    Lang.ku: 'ئیداری',
  },
  'type.أخرى': {Lang.ar: 'أخرى', Lang.en: 'Other', Lang.ku: 'تر'},

  /* ── Court labels ── */
  'court.محكمة الجنايات': {
    Lang.ar: 'محكمة الجنايات',
    Lang.en: 'Criminal Court',
    Lang.ku: 'دادگای تاوانکاری',
  },
  'court.محكمة الأحوال الشخصية': {
    Lang.ar: 'محكمة الأحوال الشخصية',
    Lang.en: 'Personal Status Court',
    Lang.ku: 'دادگای حاڵی کەسی',
  },
  'court.المحكمة التجارية': {
    Lang.ar: 'المحكمة التجارية',
    Lang.en: 'Commercial Court',
    Lang.ku: 'دادگای بازرگانی',
  },
  'court.محكمة العمل': {
    Lang.ar: 'محكمة العمل',
    Lang.en: 'Labour Court',
    Lang.ku: 'دادگای کار',
  },
  'court.المحكمة المدنية': {
    Lang.ar: 'المحكمة المدنية',
    Lang.en: 'Civil Court',
    Lang.ku: 'دادگای مەدەنی',
  },
  'court.محكمة الاستئناف': {
    Lang.ar: 'محكمة الاستئناف',
    Lang.en: 'Court of Appeal',
    Lang.ku: 'دادگای ئاپیل',
  },
  'court.هيئة التمييز': {
    Lang.ar: 'هيئة التمييز',
    Lang.en: 'Court of Cassation',
    Lang.ku: 'دیوانی تمییز',
  },
  'court.أخرى': {Lang.ar: 'أخرى', Lang.en: 'Other', Lang.ku: 'تر'},

  /* ── Empty state ── */
  'emptyTitle': {
    Lang.ar: 'لا توجد قضايا',
    Lang.en: 'No cases found',
    Lang.ku: 'هیچ دەعوایەک نەدۆزرایەوە',
  },
  'emptyText': {
    Lang.ar: 'اضغط + لإضافة قضية جديدة',
    Lang.en: 'Tap + to add a new case',
    Lang.ku: '+ دابگرە بۆ زیادکردنی دەعوایەکی نوێ',
  },

  /* ── Case card ── */
  'nextHearingLabel': {
    Lang.ar: 'الجلسة القادمة: {date}',
    Lang.en: 'Next hearing: {date}',
    Lang.ku: 'دانیشتنی داهاتوو: {date}',
  },
  'lawyerLabel': {
    Lang.ar: 'المحامي: {name}',
    Lang.en: 'Lawyer: {name}',
    Lang.ku: 'پارێزەر: {name}',
  },

  /* ── Modal ── */
  'modalTitle': {
    Lang.ar: 'إضافة قضية جديدة',
    Lang.en: 'Add New Case',
    Lang.ku: 'زیادکردنی دەعوایەکی نوێ',
  },
  'labelCaseNumber': {
    Lang.ar: 'رقم القضية *',
    Lang.en: 'Case Number *',
    Lang.ku: 'ژمارەی دەعوا *',
  },
  'placeholderCaseNumber': {
    Lang.ar: 'مثال: 1234/2024',
    Lang.en: 'e.g. 1234/2024',
    Lang.ku: 'نموونە: 1234/2024',
  },
  'labelTitle': {
    Lang.ar: 'عنوان القضية *',
    Lang.en: 'Case Title *',
    Lang.ku: 'ناونیشانی دەعوا *',
  },
  'placeholderTitle': {
    Lang.ar: 'وصف مختصر للقضية',
    Lang.en: 'Brief case description',
    Lang.ku: 'کورتە وەسفی دەعوا',
  },
  'labelType': {
    Lang.ar: 'نوع القضية',
    Lang.en: 'Case Type',
    Lang.ku: 'جۆری دەعوا',
  },
  'labelCourt': {Lang.ar: 'المحكمة', Lang.en: 'Court', Lang.ku: 'دادگا'},
  'labelStatus': {Lang.ar: 'الحالة', Lang.en: 'Status', Lang.ku: 'دۆخ'},
  'labelNextHearing': {
    Lang.ar: 'موعد الجلسة القادمة',
    Lang.en: 'Next Hearing Date',
    Lang.ku: 'بەرواری دانیشتنی داهاتوو',
  },
  'placeholderNextHearing': {
    Lang.ar: 'مثال: 25 يناير 2025',
    Lang.en: 'e.g. 25 January 2025',
    Lang.ku: 'نموونە: ٢٥ی کانوونی دووەم ٢٠٢٥',
  },
  'labelLawyer': {
    Lang.ar: 'اسم المحامي',
    Lang.en: 'Lawyer Name',
    Lang.ku: 'ناوی پارێزەر',
  },
  'placeholderLawyer': {
    Lang.ar: 'اختياري',
    Lang.en: 'Optional',
    Lang.ku: 'ئارەزوومەندانە',
  },
  'btnCancel': {Lang.ar: 'إلغاء', Lang.en: 'Cancel', Lang.ku: 'هەڵوەشاندنەوە'},
  'btnSave': {
    Lang.ar: 'حفظ القضية',
    Lang.en: 'Save Case',
    Lang.ku: 'پاشەکەوتکردنی دەعوا',
  },

  /* ── Alerts ── */
  'errorTitle': {Lang.ar: 'خطأ', Lang.en: 'Error', Lang.ku: 'هەڵە'},
  'errorRequiredFields': {
    Lang.ar: 'يرجى إدخال رقم القضية والعنوان',
    Lang.en: 'Please enter the case number and title',
    Lang.ku: 'تکایە ژمارە و ناونیشانی دەعوا بنووسە',
  },
  'deleteTitle': {
    Lang.ar: 'حذف القضية',
    Lang.en: 'Delete Case',
    Lang.ku: 'سڕینەوەی دەعوا',
  },
  'deleteMessage': {
    Lang.ar: 'هل تريد حذف هذه القضية؟',
    Lang.en: 'Do you want to delete this case?',
    Lang.ku: 'دەتەوێت ئەم دەعوایە بسڕیتەوە؟',
  },
  'deleteBtnConfirm': {Lang.ar: 'حذف', Lang.en: 'Delete', Lang.ku: 'سڕینەوە'},
  'deleteBtnCancel': {
    Lang.ar: 'إلغاء',
    Lang.en: 'Cancel',
    Lang.ku: 'هەڵوەشاندنەوە',
  },

  /* ── AuthSheet action label ── */
  'authAction': {
    Lang.ar: 'إضافة القضايا ومتابعتها',
    Lang.en: 'Add and track cases',
    Lang.ku: 'زیادکردن و شوێنکەوتنی دەعواکان',
  },
};
