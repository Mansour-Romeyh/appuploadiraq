import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/office.ts.
/// Strings for the lawyer-only "My Office" section: t('office.KEY').
const Map<String, Map<Lang, String>> office = {
  'hubTitle': {Lang.ar: 'مكتبي', Lang.en: 'My Office', Lang.ku: 'نووسینگەکەم'},
  'hubSubtitle': {
    Lang.ar: 'أدوات المحامي: الاستقبال القانوني وعروض الخدمات',
    Lang.en: 'Lawyer tools: legal intakes and service offers',
    Lang.ku: 'ئامرازی پارێزەر: تۆمارە یاساییەکان و پێشکەشکراوەکان',
  },
  // Shown to non-lawyer users, who only see the Legal Cases entry here.
  'hubSubtitleUser': {
    Lang.ar: 'متابعة قضاياك',
    Lang.en: 'Track your legal cases',
    Lang.ku: 'شوێنکەوتنی دەعواکانت',
  },
  'intakeCard': {
    Lang.ar: 'الاستقبال القانوني',
    Lang.en: 'Legal Intake',
    Lang.ku: 'تۆماری یاسایی',
  },
  'offerCard': {
    Lang.ar: 'عروض الخدمات القانونية',
    Lang.en: 'Legal Service Offers',
    Lang.ku: 'پێشکەشی خزمەتگوزاری',
  },
  'countOfMine': {
    Lang.ar: '{n} من مستنداتي',
    Lang.en: '{n} of mine',
    Lang.ku: '{n} هی من',
  },

  /* ── lists ── */
  'emptyIntakes': {
    Lang.ar: 'لا يوجد استقبال بعد',
    Lang.en: 'No intakes yet',
    Lang.ku: 'هێشتا هیچ تۆمارێک نییە',
  },
  'emptyOffers': {
    Lang.ar: 'لا توجد عروض بعد',
    Lang.en: 'No offers yet',
    Lang.ku: 'هێشتا هیچ پێشکەشێک نییە',
  },
  'newIntake': {
    Lang.ar: 'استقبال جديد',
    Lang.en: 'New intake',
    Lang.ku: 'تۆماری نوێ',
  },
  'newOffer': {
    Lang.ar: 'عرض جديد',
    Lang.en: 'New offer',
    Lang.ku: 'پێشکەشی نوێ',
  },
  'draft': {Lang.ar: 'مسودة', Lang.en: 'Draft', Lang.ku: 'ڕەشنووس'},
  'submitted': {Lang.ar: 'مُقدّم', Lang.en: 'Submitted', Lang.ku: 'نێردراو'},

  /* ── intake form ── */
  'date': {Lang.ar: 'التاريخ', Lang.en: 'Date', Lang.ku: 'بەروار'},
  'itemGroup': {
    Lang.ar: 'الدائرة',
    Lang.en: 'Item Group',
    Lang.ku: 'گرووپی خزمەت',
  },
  'item': {Lang.ar: 'القضية', Lang.en: 'Item', Lang.ku: 'خزمەت'},
  'clients': {Lang.ar: 'الموكلون', Lang.en: 'Clients', Lang.ku: 'موکڵەکان'},
  'defendants': {
    Lang.ar: 'المدّعى عليهم',
    Lang.en: 'Defendants',
    Lang.ku: 'تاوانباران',
  },
  'fullName': {
    Lang.ar: 'الاسم الكامل',
    Lang.en: 'Full name',
    Lang.ku: 'ناوی تەواو',
  },
  'nationalId': {
    Lang.ar: 'رقم الهوية',
    Lang.en: 'National ID',
    Lang.ku: 'ژمارەی ناسنامە',
  },
  'pickCustomer': {
    Lang.ar: 'اختر موكلاً (اختياري)',
    Lang.en: 'Pick a customer (optional)',
    Lang.ku: 'موکڵ هەڵبژێرە (ئیختیاری)',
  },
  'chooseFromList': {
    Lang.ar: 'اختيار من قائمة الموكلين',
    Lang.en: 'Choose from clients',
    Lang.ku: 'هەڵبژاردن لە لیست',
  },
  'intakeDescription': {
    Lang.ar: 'وصف الطلب',
    Lang.en: 'Intake description',
    Lang.ku: 'وەسفی تۆمار',
  },
  'managementDescription': {
    Lang.ar: 'وصف الإدارة',
    Lang.en: 'Management description',
    Lang.ku: 'وەسفی بەڕێوەبردن',
  },
  'addRow': {Lang.ar: 'إضافة', Lang.en: 'Add', Lang.ku: 'زیادکردن'},
  'remove': {Lang.ar: 'حذف', Lang.en: 'Remove', Lang.ku: 'سڕینەوە'},

  /* ── offer form ── */
  'customer': {Lang.ar: 'الموكل', Lang.en: 'Customer', Lang.ku: 'موکڵ'},
  'title': {Lang.ar: 'العنوان', Lang.en: 'Title', Lang.ku: 'ناونیشان'},
  'deliveryDate': {
    Lang.ar: 'تاريخ التسليم',
    Lang.en: 'Delivery date',
    Lang.ku: 'بەرواری گەیاندن',
  },
  'legalCase': {Lang.ar: 'القضية', Lang.en: 'Legal case', Lang.ku: 'دۆسیە'},
  'items': {Lang.ar: 'البنود', Lang.en: 'Items', Lang.ku: 'بڕگەکان'},
  'qty': {Lang.ar: 'الكمية', Lang.en: 'Qty', Lang.ku: 'بڕ'},
  'rate': {Lang.ar: 'السعر', Lang.en: 'Rate', Lang.ku: 'نرخ'},
  'total': {Lang.ar: 'الإجمالي', Lang.en: 'Total', Lang.ku: 'کۆ'},

  /* ── actions / states ── */
  'save': {
    Lang.ar: 'حفظ كمسودة',
    Lang.en: 'Save draft',
    Lang.ku: 'پاشەکەوتی ڕەشنووس',
  },
  'submit': {Lang.ar: 'تقديم', Lang.en: 'Submit', Lang.ku: 'ناردن'},
  'saving': {
    Lang.ar: 'جارٍ الحفظ...',
    Lang.en: 'Saving...',
    Lang.ku: 'پاشەکەوت دەکرێت...',
  },
  'loadFailed': {
    Lang.ar: 'تعذّر التحميل',
    Lang.en: 'Could not load',
    Lang.ku: 'نەتوانرا باربکرێت',
  },
  'saveFailed': {
    Lang.ar: 'تعذّر الحفظ. حاول مرة أخرى.',
    Lang.en: 'Could not save. Please try again.',
    Lang.ku: 'نەتوانرا پاشەکەوت بکرێت. دووبارە هەوڵبدەوە.',
  },
  'clientRequired': {
    Lang.ar: 'أضف موكلاً واحداً على الأقل',
    Lang.en: 'Add at least one client',
    Lang.ku: 'لانیکەم یەک موکڵ زیادبکە',
  },
  'itemRequired': {
    Lang.ar: 'أضف بنداً واحداً على الأقل',
    Lang.en: 'Add at least one item',
    Lang.ku: 'لانیکەم یەک بڕگە زیادبکە',
  },
  'customerRequired': {
    Lang.ar: 'اختر موكلاً',
    Lang.en: 'Pick a customer',
    Lang.ku: 'موکڵێک هەڵبژێرە',
  },
  'search': {Lang.ar: 'بحث...', Lang.en: 'Search...', Lang.ku: 'گەڕان...'},
  'noResults': {
    Lang.ar: 'لا توجد نتائج',
    Lang.en: 'No results',
    Lang.ku: 'هیچ ئەنجامێک نییە',
  },
  'confirmSubmit': {
    Lang.ar: 'تقديم هذا المدخل؟ لا يمكن التراجع.',
    Lang.en: 'Submit this intake? This cannot be undone.',
    Lang.ku: 'ئەم تۆمارە بنێرە؟ ناگەڕێتەوە.',
  },
};
