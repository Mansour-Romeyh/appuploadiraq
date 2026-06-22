import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/contact.ts.
const Map<String, Map<Lang, String>> contact = {
  'headerTitle': {
    Lang.ar: 'تواصل معنا',
    Lang.en: 'Contact us',
    Lang.ku: 'پەیوەندیمان پێوە بکە',
  },
  'headerSub': {
    Lang.ar: 'نحن هنا لخدمتك على مدار الساعة',
    Lang.en: 'We are here to serve you around the clock',
    Lang.ku: 'ئێمە لێرەین بۆ خزمەتکردنت لە هەموو کاتژمێرەکانی شەوانەڕۆژ',
  },

  // quick actions
  'call': {Lang.ar: 'اتصل', Lang.en: 'Call', Lang.ku: 'پەیوەندی'},
  'whatsapp': {Lang.ar: 'واتساب', Lang.en: 'WhatsApp', Lang.ku: 'واتساب'},
  'emailAction': {Lang.ar: 'إيميل', Lang.en: 'Email', Lang.ku: 'ئیمەیڵ'},

  // info card
  'phoneLabel': {Lang.ar: 'الهاتف', Lang.en: 'Phone', Lang.ku: 'تەلەفۆن'},
  'emailLabel': {Lang.ar: 'البريد', Lang.en: 'Email', Lang.ku: 'ئیمەیڵ'},
  'addressLabel': {Lang.ar: 'العنوان', Lang.en: 'Address', Lang.ku: 'ناونیشان'},
  'address': {
    Lang.ar: 'محلة 602، زقاق 23، دار 16، بغداد، العراق',
    Lang.en: 'Mahalla 602, Alley 23, House 16, Baghdad, Iraq',
    Lang.ku: 'مەحەللە 602، کۆڵانی 23، ماڵی 16، بەغدا، عێراق',
  },
  'openInWaze': {
    Lang.ar: 'الاتجاهات عبر Waze',
    Lang.en: 'Directions via Waze',
    Lang.ku: 'ئاراستە بە Waze',
  },

  // working hours
  'workingHours': {
    Lang.ar: 'أوقات العمل',
    Lang.en: 'Working hours',
    Lang.ku: 'کاتەکانی کار',
  },
  'daysSatThu': {
    Lang.ar: 'السبت - الخميس',
    Lang.en: 'Saturday – Thursday',
    Lang.ku: 'شەممە - پێنجشەممە',
  },
  'timeMorning': {
    Lang.ar: '9:00 ص - 5:00 م',
    Lang.en: '9:00 AM – 5:00 PM',
    Lang.ku: '٩:٠٠ بەیانی - ٥:٠٠ ئێوارە',
  },
  'friday': {Lang.ar: 'الجمعة', Lang.en: 'Friday', Lang.ku: 'هەینی'},
  'closed': {Lang.ar: 'مغلق', Lang.en: 'Closed', Lang.ku: 'داخراوە'},
  'emergency': {
    Lang.ar: 'الطوارئ القانونية',
    Lang.en: 'Legal emergency',
    Lang.ku: 'فریاگوزاری یاسایی',
  },

  // appointment form
  'formTitle': {
    Lang.ar: 'حجز استشارة',
    Lang.en: 'Book a consultation',
    Lang.ku: 'حجزکردنی ڕاوێژ',
  },
  'formSubtitle': {
    Lang.ar: 'أرسل طلبك وسنتواصل معك في أقرب وقت',
    Lang.en: 'Send your request and we will contact you shortly',
    Lang.ku: 'داواکارییەکەت بنێرە و بەم زووانە پەیوەندیت پێوە دەکەین',
  },
  'successMessage': {
    Lang.ar: 'تم إرسال طلبك بنجاح! سنتواصل معك قريباً.',
    Lang.en: 'Your request was sent successfully! We will contact you soon.',
    Lang.ku:
        'داواکارییەکەت بە سەرکەوتوویی نێردرا! بەم زووانە پەیوەندیت پێوە دەکەین.',
  },
  'namePlaceholder': {
    Lang.ar: 'الاسم الكامل *',
    Lang.en: 'Full name *',
    Lang.ku: 'ناوی تەواو *',
  },
  'phonePlaceholder': {
    Lang.ar: 'رقم الهاتف *',
    Lang.en: 'Phone number *',
    Lang.ku: 'ژمارەی تەلەفۆن *',
  },
  'subjectPlaceholder': {
    Lang.ar: 'موضوع الاستشارة *',
    Lang.en: 'Consultation subject *',
    Lang.ku: 'بابەتی ڕاوێژ *',
  },
  'messagePlaceholder': {
    Lang.ar: 'تفاصيل إضافية (اختياري)',
    Lang.en: 'Additional details (optional)',
    Lang.ku: 'وردەکاری زیاتر (ئیختیاری)',
  },
  'submit': {
    Lang.ar: 'إرسال الطلب',
    Lang.en: 'Send request',
    Lang.ku: 'ناردنی داواکاری',
  },
  'errorTitle': {Lang.ar: 'خطأ', Lang.en: 'Error', Lang.ku: 'هەڵە'},
  'errorRequired': {
    Lang.ar: 'يرجى تعبئة جميع الحقول الإلزامية',
    Lang.en: 'Please fill in all required fields',
    Lang.ku: 'تکایە هەموو خانە پێویستەکان پڕبکەرەوە',
  },
  'authAction': {
    Lang.ar: 'خدمة حجز الاستشارة',
    Lang.en: 'the consultation booking service',
    Lang.ku: 'خزمەتگوزاری حجزکردنی ڕاوێژ',
  },
  'submitFailed': {
    Lang.ar: 'تعذّر إرسال الطلب. حاول مرة أخرى.',
    Lang.en: 'Could not send the request. Please try again.',
    Lang.ku: 'نەتوانرا داواکارییەکە بنێردرێت. دووبارە هەوڵبدەوە.',
  },
  'submitThrottled': {
    Lang.ar: 'طلبات كثيرة. يرجى المحاولة لاحقاً.',
    Lang.en: 'Too many requests. Please try again later.',
    Lang.ku: 'داواکاری زۆر. تکایە دواتر هەوڵبدەوە.',
  },
  'sessionExpired': {
    Lang.ar: 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
    Lang.en: 'Session expired. Please sign in again.',
    Lang.ku: 'دانیشتنەکە بەسەرچوو. تکایە دووبارە بچۆ ژوورەوە.',
  },
  'withLawyer': {
    Lang.ar: 'الاستشارة مع: {name}',
    Lang.en: 'Consultation with: {name}',
    Lang.ku: 'ڕاوێژ لەگەڵ: {name}',
  },

  // join-as-lawyer form
  'joinTitle': {
    Lang.ar: 'انضم الى فريقنا كمحامي',
    Lang.en: 'Join our team as a lawyer',
    Lang.ku: 'وەک پارێزەرێک بەشداری تیمەکەمان بکە',
  },
  'joinSubtitle': {
    Lang.ar: 'قدّم طلبك وسنراجعه ونتواصل معك',
    Lang.en: 'Submit your application and we will review it and contact you',
    Lang.ku:
        'داواکارییەکەت پێشکەش بکە، پێداچوونەوەی بۆ دەکەین و پەیوەندیت پێوە دەکەین',
  },
  'joinGradYearPlaceholder': {
    Lang.ar: 'سنة التخرج',
    Lang.en: 'Graduation year',
    Lang.ku: 'ساڵی دەرچوون',
  },
  'joinUniversityPlaceholder': {
    Lang.ar: 'الجامعة التي تخرجت منها',
    Lang.en: 'University you graduated from',
    Lang.ku: 'ئەو زانکۆیەی لێی دەرچوویت',
  },
  'joinJobPlaceholder': {
    Lang.ar: 'العمل الحالي',
    Lang.en: 'Current job',
    Lang.ku: 'کاری ئێستا',
  },
  'joinAttachId': {
    Lang.ar: 'إرفاق هوية المحامي (اختياري)',
    Lang.en: 'Attach lawyer ID (optional)',
    Lang.ku: 'هاوپێچکردنی ناسنامەی پارێزەر (ئیختیاری)',
  },
  'joinFileInvalid': {
    Lang.ar: 'يرجى اختيار صورة بصيغة JPG أو PNG أو WEBP أو HEIC (بحجم أقصى 5 ميغابايت)',
    Lang.en: 'Please choose a JPG, PNG, WEBP or HEIC image (max 5 MB)',
    Lang.ku:
        'تکایە وێنەیەک بە فۆرماتی JPG، PNG، WEBP یان HEIC هەڵبژێرە (زۆرترین قەبارە ٥ مێگابایت)',
  },
  'joinPhoneInvalid': {
    Lang.ar: 'يرجى إدخال رقم هاتف عراقي صحيح (11 رقماً يبدأ بـ 07)',
    Lang.en: 'Please enter a valid Iraqi phone number (11 digits starting with 07)',
    Lang.ku: 'تکایە ژمارەیەکی تەلەفۆنی عێراقی دروست بنووسە (١١ ژمارە کە بە 07 دەست پێدەکات)',
  },
  'joinYearInvalid': {
    Lang.ar: 'يرجى إدخال سنة تخرج صحيحة',
    Lang.en: 'Please enter a valid graduation year',
    Lang.ku: 'تکایە ساڵێکی دەرچوونی دروست بنووسە',
  },
  'joinAuthAction': {
    Lang.ar: 'خدمة طلب الانضمام كمحامي',
    Lang.en: 'the lawyer application service',
    Lang.ku: 'خزمەتگوزاری داواکاری بەشداربوون وەک پارێزەر',
  },

  // settings / language
  'settings': {
    Lang.ar: 'الإعدادات',
    Lang.en: 'Settings',
    Lang.ku: 'ڕێکخستنەکان',
  },
};
