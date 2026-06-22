import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/notifications.ts.
/// UI strings for the notifications screen: t('notifications.KEY').
const Map<String, Map<Lang, String>> notifications = {
  'screenTitle': {
    Lang.ar: 'الإشعارات',
    Lang.en: 'Notifications',
    Lang.ku: 'ئاگادارکردنەوەکان',
  },
  'screenSub': {
    Lang.ar: 'آخر التحديثات والتنبيهات',
    Lang.en: 'Your latest updates and alerts',
    Lang.ku: 'دوایین نوێکارییەکان و ئاگادارکردنەوەکان',
  },
  'empty': {
    Lang.ar: 'لا توجد إشعارات حالياً',
    Lang.en: 'No notifications right now',
    Lang.ku: 'هیچ ئاگادارکردنەوەیەک نییە ئێستا',
  },
};
