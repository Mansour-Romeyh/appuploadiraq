import '../i18n/localized.dart';
import '../models/app_notification.dart';

/* Static placeholder notifications, ported from law-firm-app/data/notifications.ts.
   Shaped so a real Frappe fetch can replace this list later behind the same
   `AppNotification` type. */
const List<AppNotification> notifications = [
  AppNotification(
    id: '1',
    type: NotificationType.caseUpdate,
    title: Localized(
      ar: 'تحديث في قضيتك',
      en: 'Update on your case',
      ku: 'نوێکردنەوە لە کەیسەکەت',
    ),
    body: Localized(
      ar: 'تم تحديد موعد جلسة جديدة لقضيتك رقم ١٢٤٥ يوم الأحد القادم.',
      en: 'A new hearing has been scheduled for your case No. 1245 next Sunday.',
      ku: 'دانیشتنێکی نوێ بۆ کەیسەکەت ژمارە ١٢٤٥ بۆ یەکشەممەی داهاتوو دیاری کرا.',
    ),
    date: 'اليوم 09:30',
    read: false,
  ),
  AppNotification(
    id: '2',
    type: NotificationType.appointment,
    title: Localized(
      ar: 'تذكير بموعد',
      en: 'Appointment reminder',
      ku: 'بیرخستنەوەی ژوانێک',
    ),
    body: Localized(
      ar: 'لديك استشارة قانونية غداً الساعة ١١:٠٠ صباحاً مع المحامي.',
      en: 'You have a legal consultation tomorrow at 11:00 AM with your lawyer.',
      ku: 'بەیانی کاتژمێر ١١:٠٠ ی بەیانی ڕاوێژکارییەکی یاساییت هەیە لەگەڵ پارێزەرەکەت.',
    ),
    date: 'أمس 18:10',
    read: false,
  ),
  AppNotification(
    id: '3',
    type: NotificationType.news,
    title: Localized(
      ar: 'خبر قانوني جديد',
      en: 'New legal news',
      ku: 'هەواڵی یاسایی نوێ',
    ),
    body: Localized(
      ar: 'تعديلات جديدة على قانون العقوبات العراقي — اطّلع على التفاصيل.',
      en: 'New amendments to the Iraqi Penal Code — read the details.',
      ku: 'گۆڕانکاری نوێ لە یاسای تاوانی عێراق — وردەکارییەکان ببینە.',
    ),
    date: '15 نوفمبر',
    read: true,
  ),
  AppNotification(
    id: '4',
    type: NotificationType.system,
    title: Localized(ar: 'مرحباً بك', en: 'Welcome', ku: 'بەخێربێیت'),
    body: Localized(
      ar: 'شكراً لاستخدامك تطبيق ظل العدالة. نحن هنا لخدمتك.',
      en: 'Thank you for using the Shadow of Justice app. We are here to help.',
      ku: 'سوپاس بۆ بەکارهێنانی ئەپی سێبەری دادپەروەری. ئێمە لێرەین بۆ خزمەتت.',
    ),
    date: '10 نوفمبر',
    read: true,
  ),
];

/// Number of unread notifications — drives the home-header bell badge.
final int unreadCount = notifications.where((n) => !n.read).length;
