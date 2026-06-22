import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/ai.ts.
const Map<String, Map<Lang, String>> ai = {
  // ─── header ───
  'headerTitle': {
    Lang.ar: 'المستشار القانوني',
    Lang.en: 'AI Legal Advisor',
    Lang.ku: 'ڕاوێژکاری زیرەکی دەستکرد',
  },
  'headerSub': {
    Lang.ar: 'المستشار القانوني • القانون العراقي',
    Lang.en: 'Artificial intelligence • Iraqi Law',
    Lang.ku: 'زیرەکی دەستکرد • یاسای عێراقی',
  },

  // ─── welcome / empty-state message ───
  'welcomeMessage': {
    Lang.ar:
        'هلا! أنا المستشار القانوني، متخصص بالقانون العراقي 🏛️\n\nاسألني عن أي موضوع قانوني — طلاق، ميراث، عقارات، عمل، جنائي، تجاري — وأحلل موقفك وأبين الخطوات المطلوبة على وفق القانون العراقي.\n\nتقدر تكتب سؤالك أو ترفق صورة وثيقة للتحليل 📎',
    Lang.en:
        'Hello! I am the AI Legal Advisor, specialising in Iraqi law 🏛️\n\nAsk me about any legal topic — divorce, inheritance, real estate, employment, criminal, commercial — and I will analyse your situation and explain the required steps under Iraqi law.\n\nYou can type your question or attach a document image for analysis 📎',
    Lang.ku:
        'مرحەبا! من ڕاوێژکاری یاساییی زیرەکی دەستکردم، پسپۆڕی یاسای عێراقی 🏛️\n\nلەبارەی هەر بابەتێکی یاساییەوە بمپرسە — جیابوونەوە، میراث، خانووبەرە، کار، تاوانی، بازرگانی — دەوضعی تۆ شی دەکەمەوە و هەنگاوە پێویستەکان لەژێر یاسای عێراقدا ڕوون دەکەمەوە.\n\nدەتوانیت پرسیارەکەت بنووسیت یان وێنەی بەڵگەنامەیەک هاوپێچ بکەیت بۆ شیکارکردن 📎',
  },

  // ─── input placeholder ───
  'inputPlaceholder': {
    Lang.ar: 'اسأل عن أي موضوع قانوني...',
    Lang.en: 'Ask about any legal topic...',
    Lang.ku: 'لەبارەی هەر بابەتێکی یاساییەوە بپرسە...',
  },

  // ─── send button (accessibility) ───
  'sendButton': {Lang.ar: 'إرسال', Lang.en: 'Send', Lang.ku: 'ناردن'},

  // ─── image / attachment ───
  'attachImage': {
    Lang.ar: 'إرفاق صورة',
    Lang.en: 'Attach image',
    Lang.ku: 'وێنە هاوپێچ بکە',
  },
  'imageAttached': {
    Lang.ar: 'صورة مرفقة',
    Lang.en: 'Image attached',
    Lang.ku: 'وێنە هاوپێچکراوە',
  },
  'imageSentCaption': {
    Lang.ar: '📎 أرسلت صورة للتحليل',
    Lang.en: '📎 Sent an image for analysis',
    Lang.ku: '📎 وێنەیەک بۆ شیکارکردن نارد',
  },

  // ─── error messages ───
  'errorNotConfigured': {
    Lang.ar:
        '⚠️ خدمة المستشار القانوني غير مفعّلة حالياً. يرجى التواصل مع الدعم الفني.',
    Lang.en:
        '⚠️ The AI service is not currently active. Please contact technical support.',
    Lang.ku:
        '⚠️ خزمەتگوزاری زیرەکی دەستکرد ئێستا چالاک نییە. تکایە پەیوەندی بە پشتیوانی تەکنیکی بکە.',
  },
  'errorNetwork': {
    Lang.ar: 'تعذّر الاتصال بالخادم، يرجى التحقق من الإنترنت والمحاولة مجدداً.',
    Lang.en:
        'Could not connect to the server. Please check your internet connection and try again.',
    Lang.ku:
        'پەیوەندی بە ڕاژەکە نەدەکرا. تکایە پەیوەندی ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵ بدەرەوە.',
  },
};
