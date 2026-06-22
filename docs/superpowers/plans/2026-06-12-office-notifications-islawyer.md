# Office Workspace + Notifications + isLawyer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the Flutter app (`dill_adala`) to feature parity with the reference PWA (`law-firm-app`) for the three missing areas: the lawyer-only Office workspace (intake + offer management), the Notifications screen with home-header bell, and the `isLawyer` auth flag that gates the Office tab.

**Architecture:** Port the reference Expo/React-Native implementation 1:1 into the app's existing conventions: singleton services (`ApiService`, `AuthService`), section-based i18n (`t('office.key')`), `AppColors` tokens, `Navigator.push(MaterialPageRoute(...))` full-screen routes, and `StatefulWidget` screens that load in `initState` and reload after returning from pushed children. New office data models live in `lib/models/office.dart`; the 10 lawyer API endpoints extend `ApiService`. The Office tab is the 7th tab in `TabsShell`, visible only when `AuthService.instance.isLawyer`.

**Tech Stack:** Flutter (no new dependencies). Tests with `flutter test` (pure-Dart + widget tests, same style as existing `test/` files). The Flutter SDK binary lives at `/home/frappe/.flutter-sdk/bin/flutter`.

**Reference sources (read-only, for fidelity checks):**
- Spec: `/home/frappe/Frappe/polling/apps/law-firm-app/docs/FEATURES.md` (sections 5, 6, API catalog)
- Screens: `/home/frappe/Frappe/polling/apps/law-firm-app/app/(tabs)/office.tsx`, `app/office/intake/{index,new,[id]}.tsx`, `app/office/offer/{index,new,[id]}.tsx`, `app/notifications.tsx`
- Components: `components/office/EntityPickerModal.tsx`, `components/NotificationCard.tsx`
- Data/i18n: `data/notifications.ts`, `i18n/sections/office.ts`, `i18n/sections/notifications.ts`

**Conventions you must follow (from the existing codebase):**
- Colors via `AppColors.*` (`lib/theme/app_colors.dart`): `background #0D0D0D`, `card #1A1A1A`, `gold #C9A84C`, `navy #0D0D0D`, `mutedForeground #888888`, `border #2A2A2A`, `destructive #C0392B`, `goldLight #2A2210`, `muted #242424`, `foreground/cream #F5F0E8`.
- Translations via `t('section.key', vars: {...})` from `lib/i18n/strings.dart`. Content via `tr(Localized)` from `lib/i18n/tr.dart`.
- All test commands: `/home/frappe/.flutter-sdk/bin/flutter test <file>` and analyzer: `/home/frappe/.flutter-sdk/bin/flutter analyze`.
- Commit after every task. Commit messages follow the repo style (`i18n(...)`, `feat(...)`, `test(...)`).

**Known design decisions (do not re-litigate):**
1. **Focus reload:** Flutter's `IndexedStack` tabs have no "focus" event. The office hub and list screens load in `initState` AND reload after any pushed child route pops (`await Navigator.push(...); _load();`). This covers the create→back and submit→back flows. This matches how the rest of the app handles it (`cases_screen.dart` does the same).
2. **EntityPicker cache:** the reference caches per mounted component via `useRef`. In Flutter each `showModalBottomSheet` creates a fresh state, so the cache is a `static` map on the picker state class, keyed `'$cacheScope $cacheKey ${q.trim()}'` — same session-lifetime semantics as the reference.
3. **Feather icons:** the app maps feather names to Material icons (`lib/widgets/feather_icons.dart`). Office uses `Icons.description_outlined` (file-text), `Icons.work_outline` (briefcase). Notifications type icons map: case→`Icons.work_outline`, appointment→`Icons.calendar_today_outlined`, news→`Icons.description_outlined`, system→`Icons.notifications_none`.
4. **`toLocaleString()`** number grouping: implement a tiny `groupThousands()` helper in `lib/models/office.dart` (no `intl` dependency).
5. **Network screens are not widget-tested** (existing convention — `cases_screen` has no test). Test pure logic: models, i18n keys, static data, gating predicate, and widgets that take data via constructor (NotificationCard, NotificationsScreen with injected list).

---

### Task 1: `isLawyer` on the auth model

**Files:**
- Modify: `lib/services/auth_service.dart` (AuthUser class, lines 10-56; AuthService getters around line 72)
- Modify: `lib/services/api_service.dart` (`VerifyOtpResult`, lines 223-265; `verifyOtp`, lines 161-180)
- Modify: `lib/screens/otp_screen.dart` (the `AuthService.instance.login(` call at line ~85)
- Test: `test/auth_user_test.dart` (create)

- [x] **Step 1: Write the failing test**

Create `test/auth_user_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/services/auth_service.dart';

void main() {
  test('AuthUser round-trips isLawyer through JSON', () {
    const user = AuthUser(
      name: 'Test Lawyer',
      phone: '+9647700000000',
      method: AuthMethod.phone,
      isLawyer: true,
      apiKey: 'k',
      apiSecret: 's',
    );
    final decoded = AuthUser.fromJson(
      jsonDecode(jsonEncode(user.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.isLawyer, isTrue);
    expect(decoded.name, 'Test Lawyer');
  });

  test('AuthUser defaults isLawyer to false (old persisted sessions)', () {
    final decoded = AuthUser.fromJson({
      'name': 'Old User',
      'method': 'phone',
    });
    expect(decoded.isLawyer, isFalse);
  });
}
```

Note: confirm the package name in `pubspec.yaml` (`name:` field) — if it is not `dill_adala`, fix the import accordingly.

- [x] **Step 2: Run test to verify it fails**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/auth_user_test.dart`
Expected: FAIL — compile error, `isLawyer` is not a parameter of `AuthUser`.

- [x] **Step 3: Implement**

In `lib/services/auth_service.dart`, change `AuthUser`:

```dart
class AuthUser {
  final String name;
  final String? phone;
  final String? email;
  final AuthMethod method;

  /// True when the backend flagged this account as a lawyer
  /// (`verify_otp` → `user.is_lawyer`). Gates the Office tab.
  final bool isLawyer;

  /// Frappe API credentials returned by verify_otp; sent as
  /// `Authorization: token apiKey:apiSecret` on authenticated calls.
  final String? apiKey;
  final String? apiSecret;

  const AuthUser({
    required this.name,
    this.phone,
    this.email,
    required this.method,
    this.isLawyer = false,
    this.apiKey,
    this.apiSecret,
  });

  /// A usable auth token only when both credentials are present (i.e. a real
  /// phone/OTP login, not a mock social login).
  AuthToken? get token => (apiKey != null && apiSecret != null)
      ? AuthToken(apiKey: apiKey!, apiSecret: apiSecret!)
      : null;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'method': method.name,
    'isLawyer': isLawyer,
    'apiKey': apiKey,
    'apiSecret': apiSecret,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    method: AuthMethod.values.firstWhere(
      (m) => m.name == json['method'],
      orElse: () => AuthMethod.phone,
    ),
    isLawyer: json['isLawyer'] as bool? ?? false,
    apiKey: json['apiKey'] as String?,
    apiSecret: json['apiSecret'] as String?,
  );
}
```

In `AuthService` (same file), add a convenience getter next to `hasAuth` (line ~75):

```dart
  bool get isLawyer => _user?.isLawyer ?? false;
```

In `lib/services/api_service.dart`, extend `VerifyOtpResult` with an `isLawyer` field. Replace the class:

```dart
class VerifyOtpResult {
  final bool ok;
  final String? apiKey;
  final String? apiSecret;
  final String? name;
  final String? fullName;
  final String? email;
  final String? mobileNo;
  final bool isLawyer;

  /// One of: expired | invalid | too_many_attempts
  final String? error;

  const VerifyOtpResult._({
    required this.ok,
    this.apiKey,
    this.apiSecret,
    this.name,
    this.fullName,
    this.email,
    this.mobileNo,
    this.isLawyer = false,
    this.error,
  });

  factory VerifyOtpResult.ok({
    required String apiKey,
    required String apiSecret,
    required String name,
    required String fullName,
    String? email,
    String? mobileNo,
    bool isLawyer = false,
  }) => VerifyOtpResult._(
    ok: true,
    apiKey: apiKey,
    apiSecret: apiSecret,
    name: name,
    fullName: fullName,
    email: email,
    mobileNo: mobileNo,
    isLawyer: isLawyer,
  );

  factory VerifyOtpResult.fail(String error) =>
      VerifyOtpResult._(ok: false, error: error);
}
```

In `verifyOtp` (same file, line ~170), add the field to the `.ok(` call:

```dart
      return VerifyOtpResult.ok(
        apiKey: map['api_key'] as String,
        apiSecret: map['api_secret'] as String,
        name: user['name'] as String? ?? '',
        fullName: user['full_name'] as String? ?? '',
        email: user['email'] as String?,
        mobileNo: user['mobile_no'] as String?,
        isLawyer: user['is_lawyer'] == true || user['is_lawyer'] == 1,
      );
```

(Frappe booleans arrive as `0`/`1` ints — accept both.)

In `lib/screens/otp_screen.dart`, the `login(` call (~line 85) gains:

```dart
        await AuthService.instance.login(
          AuthUser(
            name: (result.fullName?.isNotEmpty ?? false)
                ? result.fullName!
                : (result.name ?? ''),
            phone: result.mobileNo ?? widget.phone,
            email: result.email,
            method: AuthMethod.phone,
            isLawyer: result.isLawyer,
            apiKey: result.apiKey,
            apiSecret: result.apiSecret,
          ),
        );
```

- [x] **Step 4: Run tests to verify they pass**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/auth_user_test.dart`
Expected: PASS (2 tests).
Also run: `/home/frappe/.flutter-sdk/bin/flutter analyze` — expect no new issues.

- [x] **Step 5: Commit**

```bash
git add lib/services/auth_service.dart lib/services/api_service.dart lib/screens/otp_screen.dart test/auth_user_test.dart
git commit -m "feat(auth): persist isLawyer flag from verify_otp"
```

---

### Task 2: i18n sections — `office`, `notifications`, `tab.office`

**Files:**
- Create: `lib/i18n/sections/office.dart`
- Create: `lib/i18n/sections/notifications.dart`
- Modify: `lib/i18n/strings.dart` (imports + `_sections` map)
- Modify: `lib/i18n/sections/common.dart` (add `tab.office` after `tab.contact`, line ~25)
- Test: `test/i18n_office_notifications_test.dart` (create)

- [x] **Step 1: Write the failing test**

Create `test/i18n_office_notifications_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/i18n/strings.dart';

void main() {
  test('office keys resolve in all three languages', () {
    expect(translate('office.hubTitle', Lang.ar), 'مكتبي');
    expect(translate('office.hubTitle', Lang.en), 'My Office');
    expect(translate('office.hubTitle', Lang.ku), 'نووسینگەکەم');
    expect(translate('office.countOfMine', Lang.en, vars: {'n': 3}),
        '3 of mine');
    expect(translate('office.draft', Lang.en), 'Draft');
    expect(translate('office.submitted', Lang.en), 'Submitted');
    expect(translate('office.confirmSubmit', Lang.en),
        'Submit this intake? This cannot be undone.');
  });

  test('notifications keys resolve', () {
    expect(translate('notifications.screenTitle', Lang.ar), 'الإشعارات');
    expect(translate('notifications.screenTitle', Lang.en), 'Notifications');
    expect(translate('notifications.empty', Lang.ku),
        'هیچ ئاگادارکردنەوەیەک نییە ئێستا');
  });

  test('office tab label registered in common', () {
    expect(translate('common.tab.office', Lang.ar), 'مكتبي');
    expect(translate('common.tab.office', Lang.en), 'Office');
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/i18n_office_notifications_test.dart`
Expected: FAIL — keys fall through and return the key string itself.

- [x] **Step 3: Create the office section**

Create `lib/i18n/sections/office.dart` — a 1:1 port of `law-firm-app/i18n/sections/office.ts`:

```dart
import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/office.ts.
/// Strings for the lawyer-only "My Office" section: t('office.<key>').
const Map<String, Map<Lang, String>> office = {
  'hubTitle': {Lang.ar: 'مكتبي', Lang.en: 'My Office', Lang.ku: 'نووسینگەکەم'},
  'hubSubtitle': {
    Lang.ar: 'أدوات المحامي: الاستقبال القانوني وعروض الخدمات',
    Lang.en: 'Lawyer tools: legal intakes and service offers',
    Lang.ku: 'ئامرازی پارێزەر: تۆمارە یاساییەکان و پێشکەشکراوەکان',
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
```

- [x] **Step 4: Create the notifications section**

Create `lib/i18n/sections/notifications.dart`:

```dart
import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/notifications.ts.
/// UI strings for the notifications screen: t('notifications.<key>').
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
```

- [x] **Step 5: Register both sections and the tab label**

In `lib/i18n/strings.dart` add imports after the existing section imports (line ~13):

```dart
import 'sections/office.dart';
import 'sections/notifications.dart';
```

And in the `_sections` map (after `'profile': profile,`):

```dart
  'office': office,
  'notifications': notifications,
```

Note: `notifications` collides with nothing — but `office`/`notifications` are top-level consts; if the analyzer flags a name clash with another import, use `import 'sections/notifications.dart' as n;` and register `n.notifications`. Check first; only alias if needed.

In `lib/i18n/sections/common.dart`, after the `'tab.contact'` entry (line ~25), add:

```dart
  'tab.office': {Lang.ar: 'مكتبي', Lang.en: 'Office', Lang.ku: 'نووسینگە'},
```

- [x] **Step 6: Run tests to verify they pass**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/i18n_office_notifications_test.dart test/i18n_keys_resolve_test.dart`
Expected: PASS (all). The existing `i18n_keys_resolve_test.dart` must stay green.

- [x] **Step 7: Commit**

```bash
git add lib/i18n/sections/office.dart lib/i18n/sections/notifications.dart lib/i18n/strings.dart lib/i18n/sections/common.dart test/i18n_office_notifications_test.dart
git commit -m "i18n(office,notifications): port office + notifications sections and office tab label"
```

---

### Task 3: Office data models

**Files:**
- Create: `lib/models/office.dart`
- Test: `test/office_models_test.dart` (create)

- [x] **Step 1: Write the failing test**

Create `test/office_models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/models/office.dart';

void main() {
  test('IntakeListItem parses', () {
    final it = IntakeListItem.fromJson({
      'name': 'INT-001',
      'posting_date': '2026-06-01',
      'item_name': 'قضية مدنية',
      'client_names': 'أحمد، سارة',
      'docstatus': 1,
    });
    expect(it.name, 'INT-001');
    expect(it.docstatus, 1);
    expect(it.clientNames, 'أحمد، سارة');
  });

  test('IntakeDoc parses with party rows', () {
    final doc = IntakeDoc.fromJson({
      'name': 'INT-002',
      'posting_date': '2026-06-02',
      'docstatus': 0,
      'item': 'ITEM-1',
      'clients': [
        {'client': 'CUST-1', 'customer_full_name': 'أحمد'},
        {'customer_full_name': 'سارة', 'national_id': '123'},
      ],
      'defendants': [],
    });
    expect(doc.clients, hasLength(2));
    expect(doc.clients[0].client, 'CUST-1');
    expect(doc.clients[1].nationalId, '123');
    expect(doc.defendants, isEmpty);
  });

  test('IntakeCreatePayload serializes only set fields', () {
    const payload = IntakeCreatePayload(
      itemGroup: 'G1',
      clients: [IntakeParty(customerFullName: 'أحمد')],
    );
    final json = payload.toJson();
    expect(json['item_group'], 'G1');
    expect(json.containsKey('item'), isFalse);
    expect((json['clients'] as List).first['customer_full_name'], 'أحمد');
  });

  test('IntakeParty serializes explicit null client (unlink)', () {
    const row = IntakeParty(client: null, customerFullName: 'typed name');
    expect(row.toJson(), {'customer_full_name': 'typed name'});
  });

  test('OfferDoc parses items and totals', () {
    final doc = OfferDoc.fromJson({
      'name': 'QTN-001',
      'customer': 'CUST-1',
      'customer_name': 'أحمد',
      'transaction_date': '2026-06-03',
      'grand_total': 1500000,
      'status': 'Draft',
      'items': [
        {'item_code': 'SRV-1', 'item_name': 'استشارة', 'qty': 2, 'rate': 750000, 'amount': 1500000},
      ],
    });
    expect(doc.items, hasLength(1));
    expect(doc.items.first.qty, 2);
    expect(doc.grandTotal, 1500000);
  });

  test('OfferCreatePayload serializes', () {
    const payload = OfferCreatePayload(
      customer: 'CUST-1',
      items: [OfferItem(itemCode: 'SRV-1', itemName: 'استشارة', qty: 1, rate: 100)],
    );
    final json = payload.toJson();
    expect(json['customer'], 'CUST-1');
    expect(json.containsKey('title'), isFalse);
    expect((json['items'] as List).first['item_code'], 'SRV-1');
  });

  test('groupThousands formats like toLocaleString', () {
    expect(groupThousands(0), '0');
    expect(groupThousands(1500000), '1,500,000');
    expect(groupThousands(999), '999');
    expect(groupThousands(1234.5), '1,234.5');
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/office_models_test.dart`
Expected: FAIL — `lib/models/office.dart` does not exist.

- [x] **Step 3: Implement the models**

Create `lib/models/office.dart` (field names mirror `law-firm-app/lib/api.ts`):

```dart
/// Office (lawyer workspace) data models.
/// Ported from law-firm-app/lib/api.ts: IntakeParty, IntakeListItem,
/// IntakeDoc, IntakeCreatePayload, OfferItem, OfferListItem, OfferDoc,
/// OfferCreatePayload, CustomerHit, ItemHit, ItemGroupHit.

/// Format an amount with thousands separators — the Dart stand-in for the
/// reference app's `Number.toLocaleString()`. Keeps any decimal part as-is.
String groupThousands(num n) {
  final s = n.toString();
  final dot = s.indexOf('.');
  final intPart = dot == -1 ? s : s.substring(0, dot);
  final decPart = dot == -1 ? '' : s.substring(dot);
  final negative = intPart.startsWith('-');
  final digits = negative ? intPart.substring(1) : intPart;
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buf$decPart';
}

/// One client/defendant row. `client` is the linked Customer id when picked
/// from the list, and null when the lawyer typed a free-form name (unlinked).
class IntakeParty {
  final String? client;
  final String? customerFullName;
  final String? nationalId;

  const IntakeParty({this.client, this.customerFullName, this.nationalId});

  factory IntakeParty.fromJson(Map<String, dynamic> j) => IntakeParty(
    client: j['client'] as String?,
    customerFullName: j['customer_full_name'] as String?,
    nationalId: j['national_id'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (client != null) 'client': client,
    if (customerFullName != null) 'customer_full_name': customerFullName,
    if (nationalId != null && nationalId!.isNotEmpty) 'national_id': nationalId,
  };

  IntakeParty copyWith({
    String? client,
    bool clearClient = false,
    String? customerFullName,
    String? nationalId,
  }) => IntakeParty(
    client: clearClient ? null : (client ?? this.client),
    customerFullName: customerFullName ?? this.customerFullName,
    nationalId: nationalId ?? this.nationalId,
  );
}

class IntakeListItem {
  final String name;
  final String postingDate;
  final String? itemName;
  final String? clientNames;

  /// 0 = draft, 1 = submitted.
  final int docstatus;

  const IntakeListItem({
    required this.name,
    required this.postingDate,
    this.itemName,
    this.clientNames,
    required this.docstatus,
  });

  factory IntakeListItem.fromJson(Map<String, dynamic> j) => IntakeListItem(
    name: j['name'] as String? ?? '',
    postingDate: j['posting_date']?.toString() ?? '',
    itemName: j['item_name'] as String?,
    clientNames: j['client_names'] as String?,
    docstatus: (j['docstatus'] as num?)?.toInt() ?? 0,
  );
}

class IntakeDoc {
  final String name;
  final String postingDate;
  final int docstatus;
  final String? itemGroup;
  final String? item;
  final String? itemName;
  final String? intakeDescription;
  final String? managementDescription;
  final List<IntakeParty> clients;
  final List<IntakeParty> defendants;

  const IntakeDoc({
    required this.name,
    required this.postingDate,
    required this.docstatus,
    this.itemGroup,
    this.item,
    this.itemName,
    this.intakeDescription,
    this.managementDescription,
    required this.clients,
    required this.defendants,
  });

  factory IntakeDoc.fromJson(Map<String, dynamic> j) => IntakeDoc(
    name: j['name'] as String? ?? '',
    postingDate: j['posting_date']?.toString() ?? '',
    docstatus: (j['docstatus'] as num?)?.toInt() ?? 0,
    itemGroup: j['item_group'] as String?,
    item: j['item'] as String?,
    itemName: j['item_name'] as String?,
    intakeDescription: j['intake_description'] as String?,
    managementDescription: j['management_description'] as String?,
    clients: _parties(j['clients']),
    defendants: _parties(j['defendants']),
  );

  static List<IntakeParty> _parties(Object? raw) => ((raw as List?) ?? const [])
      .whereType<Map>()
      .map((e) => IntakeParty.fromJson(e.cast<String, dynamic>()))
      .toList();
}

class IntakeCreatePayload {
  final String? itemGroup;
  final String? item;
  final String? itemName;
  final List<IntakeParty> clients;
  final List<IntakeParty> defendants;
  final String? intakeDescription;

  const IntakeCreatePayload({
    this.itemGroup,
    this.item,
    this.itemName,
    required this.clients,
    this.defendants = const [],
    this.intakeDescription,
  });

  Map<String, dynamic> toJson() => {
    if (itemGroup != null && itemGroup!.isNotEmpty) 'item_group': itemGroup,
    if (item != null && item!.isNotEmpty) 'item': item,
    if (itemName != null && itemName!.isNotEmpty) 'item_name': itemName,
    'clients': clients.map((c) => c.toJson()).toList(),
    'defendants': defendants.map((d) => d.toJson()).toList(),
    if (intakeDescription != null && intakeDescription!.isNotEmpty)
      'intake_description': intakeDescription,
  };
}

class OfferItem {
  final String itemCode;
  final String? itemName;
  final num qty;
  final num rate;

  /// Server-computed; present on fetched docs, omitted on create.
  final num? amount;

  const OfferItem({
    required this.itemCode,
    this.itemName,
    required this.qty,
    required this.rate,
    this.amount,
  });

  factory OfferItem.fromJson(Map<String, dynamic> j) => OfferItem(
    itemCode: j['item_code'] as String? ?? '',
    itemName: j['item_name'] as String?,
    qty: (j['qty'] as num?) ?? 0,
    rate: (j['rate'] as num?) ?? 0,
    amount: j['amount'] as num?,
  );

  Map<String, dynamic> toJson() => {
    'item_code': itemCode,
    if (itemName != null) 'item_name': itemName,
    'qty': qty,
    'rate': rate,
  };

  OfferItem copyWith({num? qty, num? rate}) => OfferItem(
    itemCode: itemCode,
    itemName: itemName,
    qty: qty ?? this.qty,
    rate: rate ?? this.rate,
    amount: amount,
  );
}

class OfferListItem {
  final String name;
  final String customer;
  final String? customerName;
  final String transactionDate;
  final num grandTotal;
  final String status;

  const OfferListItem({
    required this.name,
    required this.customer,
    this.customerName,
    required this.transactionDate,
    required this.grandTotal,
    required this.status,
  });

  factory OfferListItem.fromJson(Map<String, dynamic> j) => OfferListItem(
    name: j['name'] as String? ?? '',
    customer: j['customer'] as String? ?? '',
    customerName: j['customer_name'] as String?,
    transactionDate: j['transaction_date']?.toString() ?? '',
    grandTotal: (j['grand_total'] as num?) ?? 0,
    status: j['status'] as String? ?? '',
  );
}

class OfferDoc extends OfferListItem {
  final String? title;
  final String? deliveryDate;
  final String? project;
  final List<OfferItem> items;

  const OfferDoc({
    required super.name,
    required super.customer,
    super.customerName,
    required super.transactionDate,
    required super.grandTotal,
    required super.status,
    this.title,
    this.deliveryDate,
    this.project,
    required this.items,
  });

  factory OfferDoc.fromJson(Map<String, dynamic> j) {
    final base = OfferListItem.fromJson(j);
    return OfferDoc(
      name: base.name,
      customer: base.customer,
      customerName: base.customerName,
      transactionDate: base.transactionDate,
      grandTotal: base.grandTotal,
      status: base.status,
      title: j['title'] as String?,
      deliveryDate: j['delivery_date']?.toString(),
      project: j['project'] as String?,
      items: ((j['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => OfferItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class OfferCreatePayload {
  final String customer;
  final String? title;
  final List<OfferItem> items;

  const OfferCreatePayload({
    required this.customer,
    this.title,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'customer': customer,
    if (title != null && title!.isNotEmpty) 'title': title,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

class CustomerHit {
  final String name;
  final String? customerName;
  const CustomerHit({required this.name, this.customerName});

  factory CustomerHit.fromJson(Map<String, dynamic> j) => CustomerHit(
    name: j['name'] as String? ?? '',
    customerName: j['customer_name'] as String?,
  );
}

class ItemHit {
  final String itemCode;
  final String? itemName;
  final num? standardRate;
  const ItemHit({required this.itemCode, this.itemName, this.standardRate});

  factory ItemHit.fromJson(Map<String, dynamic> j) => ItemHit(
    itemCode: j['item_code'] as String? ?? '',
    itemName: j['item_name'] as String?,
    standardRate: j['standard_rate'] as num?,
  );
}

class ItemGroupHit {
  final String name;
  const ItemGroupHit({required this.name});

  factory ItemGroupHit.fromJson(Map<String, dynamic> j) =>
      ItemGroupHit(name: j['name'] as String? ?? '');
}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/office_models_test.dart`
Expected: PASS (7 tests).

- [x] **Step 5: Commit**

```bash
git add lib/models/office.dart test/office_models_test.dart
git commit -m "feat(office): add intake/offer/search data models"
```

---

### Task 4: Lawyer API endpoints

**Files:**
- Modify: `lib/services/api_service.dart` (add import + 10 methods after `aiChat`, line ~212)
- Test: covered by Task 3 model tests + analyzer (the methods are thin `_call` wrappers; `ApiService` has no injectable HTTP client and the codebase convention is not to mock it)

- [x] **Step 1: Add the import**

At the top of `lib/services/api_service.dart` (with the other model imports):

```dart
import '../models/office.dart';
```

- [x] **Step 2: Add the endpoint methods**

Inside `class ApiService`, after `aiChat` (before the closing brace):

```dart
  // ─── Lawyer workspace (all token-authenticated) ───
  Future<List<IntakeListItem>> lawyerListIntakes(AuthToken auth) async =>
      _parseList(await _call('lawyer_list_intakes', auth: auth),
          IntakeListItem.fromJson);

  Future<IntakeDoc> lawyerGetIntake(String name, AuthToken auth) async =>
      IntakeDoc.fromJson(((await _call(
        'lawyer_get_intake',
        method: 'POST',
        body: {'name': name},
        auth: auth,
      )) as Map)
          .cast<String, dynamic>());

  /// Creates a draft intake; returns the new document name.
  Future<String> lawyerCreateIntake(
    IntakeCreatePayload payload,
    AuthToken auth,
  ) async {
    final m = await _call(
      'lawyer_create_intake',
      method: 'POST',
      body: payload.toJson(),
      auth: auth,
    );
    return ((m as Map)['name'] as String?) ?? '';
  }

  Future<void> lawyerSubmitIntake(String name, AuthToken auth) async =>
      _call(
        'lawyer_submit_intake',
        method: 'POST',
        body: {'name': name},
        auth: auth,
      );

  Future<List<OfferListItem>> lawyerListOffers(AuthToken auth) async =>
      _parseList(await _call('lawyer_list_offers', auth: auth),
          OfferListItem.fromJson);

  Future<OfferDoc> lawyerGetOffer(String name, AuthToken auth) async =>
      OfferDoc.fromJson(((await _call(
        'lawyer_get_offer',
        method: 'POST',
        body: {'name': name},
        auth: auth,
      )) as Map)
          .cast<String, dynamic>());

  /// Creates a draft offer (Quotation); returns the new document name.
  Future<String> lawyerCreateOffer(
    OfferCreatePayload payload,
    AuthToken auth,
  ) async {
    final m = await _call(
      'lawyer_create_offer',
      method: 'POST',
      body: payload.toJson(),
      auth: auth,
    );
    return ((m as Map)['name'] as String?) ?? '';
  }

  Future<List<CustomerHit>> lawyerSearchCustomers(
    String q,
    AuthToken auth,
  ) async => _parseList(
        await _call(
          'lawyer_search_customers',
          method: 'POST',
          body: {'q': q},
          auth: auth,
        ),
        CustomerHit.fromJson,
      );

  Future<List<ItemHit>> lawyerSearchItems(
    String q,
    AuthToken auth, {
    String? itemGroup,
  }) async => _parseList(
        await _call(
          'lawyer_search_items',
          method: 'POST',
          body: {
            'q': q,
            if (itemGroup != null && itemGroup.isNotEmpty)
              'item_group': itemGroup,
          },
          auth: auth,
        ),
        ItemHit.fromJson,
      );

  Future<List<ItemGroupHit>> lawyerSearchItemGroups(
    String q,
    AuthToken auth,
  ) async => _parseList(
        await _call(
          'lawyer_search_item_groups',
          method: 'POST',
          body: {'q': q},
          auth: auth,
        ),
        ItemGroupHit.fromJson,
      );
```

- [x] **Step 3: Analyze + run full test suite**

Run: `/home/frappe/.flutter-sdk/bin/flutter analyze && /home/frappe/.flutter-sdk/bin/flutter test`
Expected: analyzer clean, all tests pass.

- [x] **Step 4: Commit**

```bash
git add lib/services/api_service.dart
git commit -m "feat(api): add 10 lawyer workspace endpoints"
```

---

### Task 5: Notifications model + static data

**Files:**
- Create: `lib/models/app_notification.dart`
- Create: `lib/data/notifications.dart`
- Test: `test/notifications_data_test.dart` (create)

- [x] **Step 1: Write the failing test**

Create `test/notifications_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/data/notifications.dart';
import 'package:dill_adala/models/app_notification.dart';

void main() {
  test('seed data: 4 items, 2 unread, all types localized', () {
    expect(notifications, hasLength(4));
    expect(notifications.where((n) => !n.read), hasLength(2));
    expect(unreadCount, 2);
    expect(notifications.map((n) => n.type).toSet(), {
      NotificationType.caseUpdate,
      NotificationType.appointment,
      NotificationType.news,
      NotificationType.system,
    });
    for (final n in notifications) {
      expect(n.title.ar, isNotEmpty);
      expect(n.body.ar, isNotEmpty);
      expect(n.date, isNotEmpty);
    }
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/notifications_data_test.dart`
Expected: FAIL — files do not exist.

- [x] **Step 3: Create the model**

Create `lib/models/app_notification.dart` (note: `case` is a Dart keyword, so the enum value is `caseUpdate`; the icon/color mapping lives with the enum so card + tests share it):

```dart
import 'package:flutter/material.dart';

import '../i18n/localized.dart';

/// Ported from law-firm-app/data/notifications.ts.
/// `case` is a reserved word in Dart — `caseUpdate` is the stable stand-in.
enum NotificationType { caseUpdate, appointment, news, system }

/// Stable type key → icon + accent color. Never changes with locale.
/// (Reference: NotificationCard.tsx typeMeta.)
({IconData icon, Color color}) notificationTypeMeta(NotificationType type) =>
    switch (type) {
      NotificationType.caseUpdate => (
        icon: Icons.work_outline,
        color: const Color(0xFF1565C0),
      ),
      NotificationType.appointment => (
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFF2E7D32),
      ),
      NotificationType.news => (
        icon: Icons.description_outlined,
        color: const Color(0xFFF57F17),
      ),
      NotificationType.system => (
        icon: Icons.notifications_none,
        color: const Color(0xFF6A1B9A),
      ),
    };

class AppNotification {
  final String id;
  final NotificationType type;
  final Localized title;
  final Localized body;

  /// Display-as-is string, like news.date. Not localized.
  final String date;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    required this.read,
  });
}
```

- [x] **Step 4: Create the static data**

Create `lib/data/notifications.dart` (1:1 port of `data/notifications.ts`):

```dart
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
```

- [x] **Step 5: Run tests to verify they pass**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/notifications_data_test.dart`
Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add lib/models/app_notification.dart lib/data/notifications.dart test/notifications_data_test.dart
git commit -m "feat(notifications): add model and static seed data"
```

---

### Task 6: NotificationCard widget + Notifications screen + home bell

**Files:**
- Create: `lib/widgets/notification_card.dart`
- Create: `lib/screens/notifications_screen.dart`
- Modify: `lib/screens/home_screen.dart` (header right-side `Row`, line ~122-144)
- Test: `test/notifications_screen_test.dart` (create)

- [x] **Step 1: Write the failing widget test**

Create `test/notifications_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/data/notifications.dart';
import 'package:dill_adala/screens/notifications_screen.dart';
import 'package:dill_adala/widgets/notification_card.dart';

void main() {
  testWidgets('notifications screen renders all seed cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    expect(find.byType(NotificationCard), findsNWidgets(notifications.length));
    // Unread cards show the gold dot; read ones don't (2 unread in seed data).
    expect(
      find.byKey(const ValueKey('unread-dot')),
      findsNWidgets(2),
    );
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/notifications_screen_test.dart`
Expected: FAIL — files do not exist.

- [x] **Step 3: Create NotificationCard**

Create `lib/widgets/notification_card.dart` (port of `components/NotificationCard.tsx`):

```dart
import 'package:flutter/material.dart';

import '../i18n/tr.dart';
import '../models/app_notification.dart';
import '../theme/app_colors.dart';

/// One notification row: tinted type icon, title (bold when unread + gold
/// dot), 2-line body, date with clock icon.
/// Ported from components/NotificationCard.tsx.
class NotificationCard extends StatelessWidget {
  final AppNotification item;

  const NotificationCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = notificationTypeMeta(item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: meta.color.withAlpha(0x18),
              shape: BoxShape.circle,
            ),
            child: Icon(meta.icon, size: 20, color: meta.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(item.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 22 / 15,
                          color: AppColors.foreground,
                          fontWeight:
                              item.read ? FontWeight.w600 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!item.read) ...[
                      const SizedBox(width: 8),
                      Container(
                        key: const ValueKey('unread-dot'),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr(item.body),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 4: Create NotificationsScreen**

Create `lib/screens/notifications_screen.dart` (port of `app/notifications.tsx` — navy header with back button + title/sub, scrollable card list, empty state):

```dart
import 'package:flutter/material.dart';

import '../data/notifications.dart' as data;
import '../i18n/strings.dart';
import '../theme/app_colors.dart';
import '../widgets/notification_card.dart';

/// Notifications screen (ported from app/notifications.tsx). Static bundled
/// data for now — shaped so a real Frappe fetch can slot in later.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.navy,
            padding: EdgeInsets.only(
              top: topPadding + 16,
              left: 20,
              right: 20,
              bottom: 22,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('notifications.screenTitle'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('notifications.screenSub'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xA6FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: data.notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        t('notifications.empty'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      for (final item in data.notifications)
                        NotificationCard(item: item),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
```

The back arrow: the screen sits inside the app's `Directionality` (RTL for ar/ku), so `Icons.arrow_back` auto-mirrors via `MatchTextDirection`? It does not — use `Icon(Icons.arrow_back)` wrapped: simplest faithful approach used elsewhere in this app is the inline direction-aware back button; reuse the same pattern as `lawyer_detail_screen.dart:99-112` if it differs. Check that file and copy its back-button idiom verbatim.

- [x] **Step 5: Add the home-header bell**

In `lib/screens/home_screen.dart`: add imports at the top:

```dart
import '../data/notifications.dart' as notif;
import 'notifications_screen.dart';
```

In the header's right-side `Row` (line ~122, currently `[language IconButton, SizedBox, logo]`), insert the bell **before** the language button:

```dart
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              ),
                              tooltip: t('notifications.screenTitle'),
                            ),
                            if (notif.unreadCount > 0)
                              PositionedDirectional(
                                top: 10,
                                end: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
```

- [x] **Step 6: Run tests to verify they pass**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/notifications_screen_test.dart && /home/frappe/.flutter-sdk/bin/flutter analyze`
Expected: PASS, analyzer clean.

- [x] **Step 7: Commit**

```bash
git add lib/widgets/notification_card.dart lib/screens/notifications_screen.dart lib/screens/home_screen.dart test/notifications_screen_test.dart
git commit -m "feat(notifications): screen, card widget, and home bell with unread badge"
```

---

### Task 7: EntityPicker bottom sheet

**Files:**
- Create: `lib/widgets/entity_picker_sheet.dart`
- Test: `test/entity_picker_test.dart` (create)

- [x] **Step 1: Write the failing widget test**

Create `test/entity_picker_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dill_adala/widgets/entity_picker_sheet.dart';

void main() {
  setUp(EntityPickerSheet.clearCacheForTest);

  Future<void> open(
    WidgetTester tester,
    Future<List<PickerOption>> Function(String q) search, {
    void Function(PickerOption)? onPick,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showEntityPicker(
              context,
              title: 'Test',
              cacheScope: 'test',
              search: search,
              onPick: onPick ?? (_) {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty query loads default list immediately', (tester) async {
    var calls = <String>[];
    await open(tester, (q) async {
      calls.add(q);
      return [const PickerOption(id: '1', label: 'Alpha')];
    });
    expect(calls, ['']);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('typing debounces 250ms then searches', (tester) async {
    var calls = <String>[];
    await open(tester, (q) async {
      calls.add(q);
      return q.isEmpty
          ? [const PickerOption(id: '1', label: 'Alpha')]
          : [const PickerOption(id: '2', label: 'Beta')];
    });
    await tester.enterText(find.byType(TextField), 'b');
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, ['']); // not yet — still inside debounce window
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(calls, ['', 'b']);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('cache hit skips the search call', (tester) async {
    var calls = 0;
    Future<List<PickerOption>> search(String q) async {
      calls++;
      return [const PickerOption(id: '1', label: 'Alpha')];
    }

    await open(tester, search);
    expect(calls, 1);
    // Close and reopen — same cacheScope → served from cache.
    await tester.tapAt(const Offset(10, 10)); // backdrop dismiss
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('pick returns the option and closes', (tester) async {
    PickerOption? picked;
    await open(
      tester,
      (q) async => [const PickerOption(id: '7', label: 'Gamma', meta: 99)],
      onPick: (o) => picked = o,
    );
    await tester.tap(find.text('Gamma'));
    await tester.pumpAndSettle();
    expect(picked?.id, '7');
    expect(picked?.meta, 99);
    expect(find.text('Gamma'), findsNothing); // sheet closed
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/entity_picker_test.dart`
Expected: FAIL — file does not exist.

- [x] **Step 3: Implement the picker**

Create `lib/widgets/entity_picker_sheet.dart` (port of `components/office/EntityPickerModal.tsx`):

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../theme/app_colors.dart';

/// One selectable row in the picker.
class PickerOption {
  final String id;
  final String label;
  final String? sublabel;
  final num? meta;

  const PickerOption({
    required this.id,
    required this.label,
    this.sublabel,
    this.meta,
  });
}

/// Opens the generic typeahead bottom sheet.
/// Ported from components/office/EntityPickerModal.tsx:
///  - results cached per query for the session (instant on reopen/re-type),
///  - the default (empty-query) list loads immediately; typing debounces 250ms,
///  - previous rows stay on screen while the next query loads.
/// [cacheScope] namespaces the cache per picker use-site; append [cacheKey]
/// when the same picker can return different sets (items scoped by group).
Future<void> showEntityPicker(
  BuildContext context, {
  required String title,
  required Future<List<PickerOption>> Function(String q) search,
  required void Function(PickerOption option) onPick,
  String cacheScope = '',
  String cacheKey = '',
  String? emptyText,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (sheetContext) => EntityPickerSheet(
    title: title,
    search: search,
    onPick: (o) {
      onPick(o);
      Navigator.of(sheetContext).pop();
    },
    cacheScope: cacheScope,
    cacheKey: cacheKey,
    emptyText: emptyText,
  ),
);

class EntityPickerSheet extends StatefulWidget {
  final String title;
  final Future<List<PickerOption>> Function(String q) search;
  final void Function(PickerOption option) onPick;
  final String cacheScope;
  final String cacheKey;
  final String? emptyText;

  const EntityPickerSheet({
    super.key,
    required this.title,
    required this.search,
    required this.onPick,
    this.cacheScope = '',
    this.cacheKey = '',
    this.emptyText,
  });

  /// Session-scoped result cache shared across opens (the reference keeps it
  /// in a useRef on a component that stays mounted; a sheet remounts per open,
  /// so the cache must be static to survive).
  static final Map<String, List<PickerOption>> _cache = {};

  static void clearCacheForTest() => _cache.clear();

  @override
  State<EntityPickerSheet> createState() => _EntityPickerSheetState();
}

class _EntityPickerSheetState extends State<EntityPickerSheet> {
  final TextEditingController _query = TextEditingController();
  List<PickerOption> _rows = const [];
  bool _loading = false;
  Timer? _debounce;
  int _generation = 0;

  String get _cacheKeyFor =>
      '${widget.cacheScope} ${widget.cacheKey} ${_query.text.trim()}';

  @override
  void initState() {
    super.initState();
    _run(immediate: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) => _run();

  void _run({bool immediate = false}) {
    _debounce?.cancel();

    final cached = EntityPickerSheet._cache[_cacheKeyFor];
    if (cached != null) {
      setState(() {
        _rows = cached;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    final gen = ++_generation;
    // Default (empty) list loads at once; typing is debounced.
    final delay = (immediate || _query.text.trim().isEmpty)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    _debounce = Timer(delay, () async {
      final key = _cacheKeyFor;
      List<PickerOption> result;
      try {
        result = await widget.search(_query.text);
      } catch (_) {
        result = const [];
      }
      if (!mounted || gen != _generation) return;
      EntityPickerSheet._cache[key] = result;
      setState(() {
        _rows = result;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight, minHeight: 300),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  style: IconButton.styleFrom(backgroundColor: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      onChanged: _onChanged,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: t('office.search'),
                        hintStyle:
                            const TextStyle(color: AppColors.mutedForeground),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: _loading && _rows.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 28),
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _rows.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: Text(
                            widget.emptyText ?? t('office.noResults'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _rows.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, i) {
                            final option = _rows[i];
                            return InkWell(
                              onTap: () => widget.onPick(option),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.foreground,
                                            ),
                                          ),
                                          if (option.sublabel != null &&
                                              option.sublabel!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 2),
                                              child: Text(
                                                option.sublabel!,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: AppColors
                                                      .mutedForeground,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: AppColors.gold,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 4: Run tests to verify they pass**

Run: `/home/frappe/.flutter-sdk/bin/flutter test test/entity_picker_test.dart`
Expected: PASS (4 tests). If the cache-hit test's backdrop dismiss is flaky, replace the `tapAt` with `Navigator.of(tester.element(find.byType(EntityPickerSheet))).pop()` via `tester.state`.

- [x] **Step 5: Commit**

```bash
git add lib/widgets/entity_picker_sheet.dart test/entity_picker_test.dart
git commit -m "feat(office): generic typeahead entity picker bottom sheet"
```

---

### Task 8: Office hub screen + 7th tab

**Files:**
- Create: `lib/screens/office_hub_screen.dart`
- Modify: `lib/screens/tabs_shell.dart` (`_allTabDefs`, line ~33-65)
- Note: `office_intake_list_screen.dart` / `office_offer_list_screen.dart` do not exist yet — the hub navigates to them; create the hub with the imports commented out is NOT allowed. Instead Task 8 creates the hub with navigation wired to the list screens created in Tasks 9 and 12 — so implement Tasks 8, 9, 12 in this order **but compile only at the end of Task 8 using placeholder-free ordering**: create the two list screens first if you prefer compile-green commits. Recommended order: do Task 9 and Task 12 list screens FIRST, then this task. (Tasks are written in spec order; execution order: 9 → 12 → 8 → 10 → 11 → 13 → 14.)

- [x] **Step 1: Create the hub screen**

Create `lib/screens/office_hub_screen.dart` (port of `app/(tabs)/office.tsx`):

```dart
import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'office_intake_list_screen.dart';
import 'office_offer_list_screen.dart';

/// Lawyer workspace landing — two cards with live counts of the lawyer's own
/// documents (ported from app/(tabs)/office.tsx). Counts load on mount and
/// reload after returning from either child list (covers create/submit flows).
class OfficeHubScreen extends StatefulWidget {
  const OfficeHubScreen({super.key});

  @override
  State<OfficeHubScreen> createState() => _OfficeHubScreenState();
}

class _OfficeHubScreenState extends State<OfficeHubScreen> {
  int? _intakes;
  int? _offers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) return;
    try {
      final results = await Future.wait([
        ApiService.instance.lawyerListIntakes(auth),
        ApiService.instance.lawyerListOffers(auth),
      ]);
      if (!mounted) return;
      setState(() {
        _intakes = (results[0] as List).length;
        _offers = (results[1] as List).length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _intakes = 0;
        _offers = 0;
      });
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: topPadding + 24,
        left: 18,
        right: 18,
        bottom: 140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('office.hubTitle'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t('office.hubSubtitle'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 18),
          _HubCard(
            icon: Icons.description_outlined,
            title: t('office.intakeCard'),
            count: _intakes,
            onTap: () => _open(const OfficeIntakeListScreen()),
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.work_outline,
            title: t('office.offerCard'),
            count: _offers,
            onTap: () => _open(const OfficeOfferListScreen()),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: AppColors.gold),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == null
                        ? '…'
                        : t('office.countOfMine', vars: {'n': count!}),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: AppColors.foreground,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Register the 7th tab**

In `lib/screens/tabs_shell.dart`:

Add import:

```dart
import 'office_hub_screen.dart';
```

Add a lawyer predicate next to `_isLoggedIn()` (line ~31):

```dart
/// Office is only shown to lawyer accounts — mirrors the reference
/// `_layout.tsx` `isLawyer` filter.
bool _isLawyer() => AuthService.instance.isLawyer;
```

Append the office tab def at the end of `_allTabDefs` (after the contact entry):

```dart
  _TabDef(
    Icons.work_outline,
    t('common.tab.office'),
    const OfficeHubScreen(),
    _isLawyer,
  ),
```

- [x] **Step 3: Analyze + full test suite**

Run: `/home/frappe/.flutter-sdk/bin/flutter analyze && /home/frappe/.flutter-sdk/bin/flutter test`
Expected: clean + all pass. (This step requires Tasks 9 and 12 to be done first — see ordering note above.)

- [x] **Step 4: Commit**

```bash
git add lib/screens/office_hub_screen.dart lib/screens/tabs_shell.dart
git commit -m "feat(office): hub screen and lawyer-gated office tab"
```

---

### Task 9: Intake list screen

**Files:**
- Create: `lib/screens/office_intake_list_screen.dart`
- Depends on: Task 10 (`office_intake_detail_screen.dart`) and Task 11 (`office_intake_new_screen.dart`) for navigation targets. **Execution order within the office screens: create all six screen files in one pass (Tasks 9-14), then run analyzer/tests once and commit per logical unit.** Each task below still lists its own commit.

- [x] **Step 1: Create the screen**

Create `lib/screens/office_intake_list_screen.dart` (port of `app/office/intake/index.tsx`):

```dart
import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'office_intake_detail_screen.dart';
import 'office_intake_new_screen.dart';

/// Lawyer's intake list (ported from app/office/intake/index.tsx).
class OfficeIntakeListScreen extends StatefulWidget {
  const OfficeIntakeListScreen({super.key});

  @override
  State<OfficeIntakeListScreen> createState() => _OfficeIntakeListScreenState();
}

class _OfficeIntakeListScreenState extends State<OfficeIntakeListScreen> {
  List<IntakeListItem> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) {
      setState(() {
        _rows = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final rows = await ApiService.instance.lawyerListIntakes(auth);
      if (mounted) setState(() => _rows = rows);
    } catch (_) {
      if (mounted) setState(() => _rows = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.only(top: topPadding + 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.foreground,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t('office.intakeCard'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _push(const OfficeIntakeNewScreen()),
                    icon: const Icon(Icons.add, color: AppColors.gold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _rows.isEmpty
                      ? Center(
                          child: Text(
                            t('office.emptyIntakes'),
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                          itemCount: _rows.length,
                          itemBuilder: (context, i) {
                            final item = _rows[i];
                            return _IntakeRow(
                              item: item,
                              onTap: () => _push(
                                OfficeIntakeDetailScreen(name: item.name),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntakeRow extends StatelessWidget {
  final IntakeListItem item;
  final VoidCallback onTap;

  const _IntakeRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final submitted = item.docstatus == 1;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item.clientNames?.isNotEmpty ?? false)
                        ? item.clientNames!
                        : item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.itemName ?? ''} · ${item.postingDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: submitted ? AppColors.gold : const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                submitted ? t('office.submitted') : t('office.draft'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: submitted ? AppColors.navy : AppColors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Commit** (after the screens compile together — see Task 14 step ordering)

```bash
git add lib/screens/office_intake_list_screen.dart
git commit -m "feat(office): intake list screen"
```

---

### Task 10: Intake detail screen

**Files:**
- Create: `lib/screens/office_intake_detail_screen.dart`

- [x] **Step 1: Create the screen**

Port of `app/office/intake/[id].tsx`. Fields render only when non-empty; clients/defendants joined with `"، "`; Submit button only on drafts, with a confirm dialog; reload in place after submit.

```dart
import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Intake detail + draft submission (ported from app/office/intake/[id].tsx).
class OfficeIntakeDetailScreen extends StatefulWidget {
  final String name;

  const OfficeIntakeDetailScreen({super.key, required this.name});

  @override
  State<OfficeIntakeDetailScreen> createState() =>
      _OfficeIntakeDetailScreenState();
}

class _OfficeIntakeDetailScreenState extends State<OfficeIntakeDetailScreen> {
  IntakeDoc? _doc;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await ApiService.instance.lawyerGetIntake(widget.name, auth);
      if (mounted) setState(() => _doc = doc);
    } catch (_) {
      if (mounted) setState(() => _doc = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmSubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        content: Text(
          t('office.confirmSubmit'),
          style: const TextStyle(color: AppColors.foreground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              '×',
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              t('office.submit'),
              style: const TextStyle(color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _submit();
  }

  Future<void> _submit() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) return;
    setState(() => _submitting = true);
    try {
      await ApiService.instance.lawyerSubmitIntake(widget.name, auth);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('office.saveFailed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final doc = _doc;
    if (doc == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: EdgeInsets.only(top: topPadding + 40),
          child: Center(
            child: Text(
              t('office.loadFailed'),
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ),
      );
    }

    final submitted = doc.docstatus == 1;
    final clientNames = doc.clients
        .map((c) => c.customerFullName ?? c.client ?? '')
        .where((s) => s.isNotEmpty)
        .join('، ');
    final defendantNames = doc.defendants
        .map((d) => d.customerFullName ?? d.client ?? '')
        .where((s) => s.isNotEmpty)
        .join('، ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 16,
          left: 18,
          right: 18,
          bottom: 140,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.foreground,
                  ),
                ),
                Expanded(
                  child: Text(
                    doc.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        submitted ? AppColors.gold : const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    submitted ? t('office.submitted') : t('office.draft'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          submitted ? AppColors.navy : AppColors.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Field(label: t('office.date'), value: doc.postingDate),
            _Field(label: t('office.item'), value: doc.itemName ?? doc.item),
            _Field(label: t('office.clients'), value: clientNames),
            _Field(label: t('office.defendants'), value: defendantNames),
            if (doc.docstatus == 0)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: FilledButton(
                  onPressed: _submitting ? null : _confirmSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _submitting ? t('office.saving') : t('office.submit'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Label + value pair; renders nothing when the value is empty
/// (mirrors the reference `Field` helper).
class _Field extends StatelessWidget {
  final String label;
  final String? value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 2: Commit**

```bash
git add lib/screens/office_intake_detail_screen.dart
git commit -m "feat(office): intake detail screen with draft submission"
```

---

### Task 11: Intake create form

**Files:**
- Create: `lib/screens/office_intake_new_screen.dart`

- [x] **Step 1: Create the screen**

Port of `app/office/intake/new.tsx`. Item-group picker resets the item on change; item picker is scoped by group (`cacheKey: itemGroup`); dynamic client/defendant rows (picking a customer fills name + link; typing the name clears the link); ≥1 valid client required; success replaces to detail.

```dart
import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/entity_picker_sheet.dart';
import 'office_intake_detail_screen.dart';

/// One editable party row's controllers — kept outside build so TextFields
/// hold focus across rebuilds (the reference has the same concern).
class _PartyRowState {
  final TextEditingController name = TextEditingController(text: '');
  final TextEditingController nationalId = TextEditingController(text: '');
  String? client;

  void dispose() {
    name.dispose();
    nationalId.dispose();
  }

  IntakeParty toParty() => IntakeParty(
    client: client,
    customerFullName: name.text,
    nationalId: nationalId.text,
  );

  bool get isValid => name.text.trim().isNotEmpty || client != null;
}

/// New intake draft form (ported from app/office/intake/new.tsx).
class OfficeIntakeNewScreen extends StatefulWidget {
  const OfficeIntakeNewScreen({super.key});

  @override
  State<OfficeIntakeNewScreen> createState() => _OfficeIntakeNewScreenState();
}

class _OfficeIntakeNewScreenState extends State<OfficeIntakeNewScreen> {
  String _itemGroup = '';
  String _item = '';
  String _itemName = '';
  final List<_PartyRowState> _clients = [_PartyRowState()];
  final List<_PartyRowState> _defendants = [];
  final TextEditingController _description = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final r in [..._clients, ..._defendants]) {
      r.dispose();
    }
    _description.dispose();
    super.dispose();
  }

  void _showError(String key) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t(key))));
  }

  Future<void> _save() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) return;
    final cleanClients =
        _clients.where((r) => r.isValid).map((r) => r.toParty()).toList();
    if (cleanClients.isEmpty) {
      _showError('office.clientRequired');
      return;
    }
    setState(() => _saving = true);
    try {
      final name = await ApiService.instance.lawyerCreateIntake(
        IntakeCreatePayload(
          itemGroup: _itemGroup,
          item: _item,
          itemName: _itemName,
          clients: cleanClients,
          defendants: _defendants
              .where((r) => r.isValid)
              .map((r) => r.toParty())
              .toList(),
          intakeDescription: _description.text,
        ),
        auth,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OfficeIntakeDetailScreen(name: name),
        ),
      );
    } catch (_) {
      if (mounted) _showError('office.saveFailed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openGroupPicker() => showEntityPicker(
    context,
    title: t('office.itemGroup'),
    cacheScope: 'item-groups',
    search: (q) async {
      final auth = AuthService.instance.user?.token;
      if (auth == null) return const [];
      final hits = await ApiService.instance.lawyerSearchItemGroups(q, auth);
      return [for (final g in hits) PickerOption(id: g.name, label: g.name)];
    },
    onPick: (o) => setState(() {
      // A case belongs to a circuit — reset it when the circuit changes.
      if (o.id != _itemGroup) {
        _item = '';
        _itemName = '';
      }
      _itemGroup = o.id;
    }),
  );

  void _openItemPicker() => showEntityPicker(
    context,
    title: t('office.item'),
    cacheScope: 'items',
    cacheKey: _itemGroup,
    search: (q) async {
      final auth = AuthService.instance.user?.token;
      if (auth == null) return const [];
      final hits = await ApiService.instance.lawyerSearchItems(
        q,
        auth,
        itemGroup: _itemGroup.isEmpty ? null : _itemGroup,
      );
      return [
        for (final it in hits)
          PickerOption(
            id: it.itemCode,
            label: it.itemName ?? it.itemCode,
            sublabel: it.itemCode,
          ),
      ];
    },
    onPick: (o) => setState(() {
      _item = o.id;
      _itemName = o.label;
    }),
  );

  void _openPartyPicker(_PartyRowState row, String titleKey) =>
      showEntityPicker(
        context,
        title: t(titleKey),
        cacheScope: 'customers',
        search: (q) async {
          final auth = AuthService.instance.user?.token;
          if (auth == null) return const [];
          final hits =
              await ApiService.instance.lawyerSearchCustomers(q, auth);
          return [
            for (final c in hits)
              PickerOption(
                id: c.name,
                label: c.customerName ?? c.name,
                sublabel: c.name,
              ),
          ];
        },
        onPick: (o) => setState(() {
          row.client = o.id;
          row.name.text = o.label;
        }),
      );

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 16,
          left: 18,
          right: 18,
          bottom: 160 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.foreground,
                  ),
                ),
                Expanded(
                  child: Text(
                    t('office.newIntake'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 14),
            _PickerField(
              value: _itemGroup,
              placeholder: t('office.itemGroup'),
              onTap: _openGroupPicker,
            ),
            const SizedBox(height: 10),
            _PickerField(
              value: _itemName.isNotEmpty ? _itemName : _item,
              placeholder: t('office.item'),
              onTap: _openItemPicker,
            ),
            _partySection(
              label: t('office.clients'),
              rows: _clients,
              titleKey: 'office.clients',
            ),
            _partySection(
              label: t('office.defendants'),
              rows: _defendants,
              titleKey: 'office.defendants',
            ),
            const SizedBox(height: 18),
            Text(
              t('office.intakeDescription'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 4,
              decoration: _inputDecoration(t('office.intakeDescription')),
              style: const TextStyle(color: AppColors.foreground),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _saving ? t('office.saving') : t('office.save'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _partySection({
    required String label,
    required List<_PartyRowState> rows,
    required String titleKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => rows.add(_PartyRowState())),
                child: Text(
                  '+ ${t('office.addRow')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          for (var i = 0; i < rows.length; i++)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openPartyPicker(rows[i], titleKey),
                    icon: const Icon(
                      Icons.people_outline,
                      size: 15,
                      color: AppColors.gold,
                    ),
                    label: Text(
                      t('office.chooseFromList'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.goldLight,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: rows[i].name,
                    // Typing a name unlinks the picked customer.
                    onChanged: (_) => rows[i].client = null,
                    decoration: _inputDecoration(t('office.fullName')),
                    style: const TextStyle(color: AppColors.foreground),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: rows[i].nationalId,
                    decoration: _inputDecoration(t('office.nationalId')),
                    style: const TextStyle(color: AppColors.foreground),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      rows.removeAt(i).dispose();
                    }),
                    child: Text(
                      t('office.remove'),
                      style: const TextStyle(color: AppColors.destructive),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.mutedForeground),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.gold),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
  ),
  contentPadding: const EdgeInsets.all(12),
);

/// Tap-to-pick pseudo-input showing the current selection or its placeholder.
class _PickerField extends StatelessWidget {
  final String value;
  final String placeholder;
  final VoidCallback onTap;

  const _PickerField({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value.isNotEmpty ? value : placeholder,
          style: TextStyle(
            color: value.isNotEmpty
                ? AppColors.foreground
                : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Commit**

```bash
git add lib/screens/office_intake_new_screen.dart
git commit -m "feat(office): intake create form with pickers and party rows"
```

---

### Task 12: Offer list screen

**Files:**
- Create: `lib/screens/office_offer_list_screen.dart`

- [x] **Step 1: Create the screen**

Port of `app/office/offer/index.tsx` — same skeleton as the intake list but rows show `customerName || customer`, `name · transactionDate`, and a gold `groupThousands(grandTotal)` amount; **no status badge**.

```dart
import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'office_offer_detail_screen.dart';
import 'office_offer_new_screen.dart';

/// Lawyer's service offer list (ported from app/office/offer/index.tsx).
class OfficeOfferListScreen extends StatefulWidget {
  const OfficeOfferListScreen({super.key});

  @override
  State<OfficeOfferListScreen> createState() => _OfficeOfferListScreenState();
}

class _OfficeOfferListScreenState extends State<OfficeOfferListScreen> {
  List<OfferListItem> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) {
      setState(() {
        _rows = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final rows = await ApiService.instance.lawyerListOffers(auth);
      if (mounted) setState(() => _rows = rows);
    } catch (_) {
      if (mounted) setState(() => _rows = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.only(top: topPadding + 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.foreground,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t('office.offerCard'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _push(const OfficeOfferNewScreen()),
                    icon: const Icon(Icons.add, color: AppColors.gold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  : _rows.isEmpty
                      ? Center(
                          child: Text(
                            t('office.emptyOffers'),
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                          itemCount: _rows.length,
                          itemBuilder: (context, i) {
                            final item = _rows[i];
                            return InkWell(
                              onTap: () => _push(
                                OfficeOfferDetailScreen(name: item.name),
                              ),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.gold),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.customerName ??
                                                item.customer,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.foreground,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.name} · ${item.transactionDate}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color:
                                                  AppColors.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      groupThousands(item.grandTotal),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Commit**

```bash
git add lib/screens/office_offer_list_screen.dart
git commit -m "feat(office): offer list screen"
```

---

### Task 13: Offer detail screen

**Files:**
- Create: `lib/screens/office_offer_detail_screen.dart`

- [x] **Step 1: Create the screen**

Port of `app/office/offer/[id].tsx` — customer, `transactionDate · status`, line items (`qty × rate = amount`), gold grand total. No submit/edit.

```dart
import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Offer (Quotation) read-only detail (ported from app/office/offer/[id].tsx).
class OfficeOfferDetailScreen extends StatefulWidget {
  final String name;

  const OfficeOfferDetailScreen({super.key, required this.name});

  @override
  State<OfficeOfferDetailScreen> createState() =>
      _OfficeOfferDetailScreenState();
}

class _OfficeOfferDetailScreenState extends State<OfficeOfferDetailScreen> {
  OfferDoc? _doc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await ApiService.instance.lawyerGetOffer(widget.name, auth);
      if (mounted) setState(() => _doc = doc);
    } catch (_) {
      if (mounted) setState(() => _doc = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final doc = _doc;
    if (doc == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: EdgeInsets.only(top: topPadding + 40),
          child: Center(
            child: Text(
              t('office.loadFailed'),
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 16,
          left: 18,
          right: 18,
          bottom: 140,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.foreground,
                  ),
                ),
                Expanded(
                  child: Text(
                    doc.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              doc.customerName ?? doc.customer,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${doc.transactionDate} · ${doc.status}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in doc.items)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName ?? item.itemCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.qty} × ${groupThousands(item.rate)} = ${groupThousands(item.amount ?? 0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('office.total'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Text(
                  groupThousands(doc.grandTotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Commit**

```bash
git add lib/screens/office_offer_detail_screen.dart
git commit -m "feat(office): offer detail screen"
```

---

### Task 14: Offer create form

**Files:**
- Create: `lib/screens/office_offer_new_screen.dart`

- [x] **Step 1: Create the screen**

Port of `app/office/offer/new.tsx`. Customer picker (required), optional title, add-item picker appends `{itemCode, itemName, qty:1, rate: standardRate}`, editable numeric qty/rate, live total, success replaces to detail.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/entity_picker_sheet.dart';
import 'office_offer_detail_screen.dart';

/// New offer (Quotation draft) form (ported from app/office/offer/new.tsx).
class OfficeOfferNewScreen extends StatefulWidget {
  const OfficeOfferNewScreen({super.key});

  @override
  State<OfficeOfferNewScreen> createState() => _OfficeOfferNewScreenState();
}

class _OfficeOfferNewScreenState extends State<OfficeOfferNewScreen> {
  ({String id, String name})? _customer;
  final TextEditingController _title = TextEditingController();
  final List<OfferItem> _items = [];
  bool _saving = false;

  num get _total =>
      _items.fold<num>(0, (sum, it) => sum + it.qty * it.rate);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _showError(String key) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t(key))));
  }

  Future<void> _save() async {
    final auth = AuthService.instance.user?.token;
    if (auth == null) return;
    final customer = _customer;
    if (customer == null) {
      _showError('office.customerRequired');
      return;
    }
    final clean = _items.where((it) => it.itemCode.isNotEmpty).toList();
    if (clean.isEmpty) {
      _showError('office.itemRequired');
      return;
    }
    setState(() => _saving = true);
    try {
      final name = await ApiService.instance.lawyerCreateOffer(
        OfferCreatePayload(
          customer: customer.id,
          title: _title.text,
          items: clean,
        ),
        auth,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OfficeOfferDetailScreen(name: name),
        ),
      );
    } catch (_) {
      if (mounted) _showError('office.saveFailed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openCustomerPicker() => showEntityPicker(
    context,
    title: t('office.customer'),
    cacheScope: 'customers',
    search: (q) async {
      final auth = AuthService.instance.user?.token;
      if (auth == null) return const [];
      final hits = await ApiService.instance.lawyerSearchCustomers(q, auth);
      return [
        for (final c in hits)
          PickerOption(
            id: c.name,
            label: c.customerName ?? c.name,
            sublabel: c.name,
          ),
      ];
    },
    onPick: (o) => setState(() => _customer = (id: o.id, name: o.label)),
  );

  void _openItemPicker() => showEntityPicker(
    context,
    title: t('office.item'),
    cacheScope: 'offer-items',
    search: (q) async {
      final auth = AuthService.instance.user?.token;
      if (auth == null) return const [];
      final hits = await ApiService.instance.lawyerSearchItems(q, auth);
      return [
        for (final it in hits)
          PickerOption(
            id: it.itemCode,
            label: it.itemName ?? it.itemCode,
            sublabel: it.itemCode,
            meta: it.standardRate,
          ),
      ];
    },
    onPick: (o) => setState(
      () => _items.add(
        OfferItem(
          itemCode: o.id,
          itemName: o.label,
          qty: 1,
          rate: o.meta ?? 0,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 16,
          left: 18,
          right: 18,
          bottom: 160 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.foreground,
                  ),
                ),
                Expanded(
                  child: Text(
                    t('office.newOffer'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _openCustomerPicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _customer?.name ?? t('office.customer'),
                  style: TextStyle(
                    color: _customer != null
                        ? AppColors.foreground
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              decoration: _decoration(t('office.title')),
              style: const TextStyle(color: AppColors.foreground),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('office.items'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
                TextButton(
                  onPressed: _openItemPicker,
                  child: Text(
                    '+ ${t('office.addRow')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            for (var i = 0; i < _items.length; i++)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _items[i].itemName ?? _items[i].itemCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('qty-$i-${_items[i].itemCode}'),
                            initialValue: '${_items[i].qty}',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => _items[i] = _items[i]
                                  .copyWith(qty: num.tryParse(v) ?? 0),
                            ),
                            decoration: _decoration(t('office.qty')),
                            style: const TextStyle(
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('rate-$i-${_items[i].itemCode}'),
                            initialValue: '${_items[i].rate}',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            onChanged: (v) => setState(
                              () => _items[i] = _items[i]
                                  .copyWith(rate: num.tryParse(v) ?? 0),
                            ),
                            decoration: _decoration(t('office.rate')),
                            style: const TextStyle(
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => setState(() => _items.removeAt(i)),
                      child: Text(
                        t('office.remove'),
                        style: const TextStyle(color: AppColors.destructive),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('office.total'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedForeground,
                  ),
                ),
                Text(
                  groupThousands(_total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _saving ? t('office.saving') : t('office.save'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _decoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.mutedForeground),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.gold),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
  ),
  contentPadding: const EdgeInsets.all(12),
);
```

Note: the `_decoration` helper duplicates `_inputDecoration` from Task 11. After both compile, extract the shared helper into `lib/widgets/office_field_decoration.dart` as `InputDecoration officeFieldDecoration(String hint)` and use it from both screens (DRY).

- [x] **Step 2: Commit**

```bash
git add lib/screens/office_offer_new_screen.dart lib/widgets/office_field_decoration.dart lib/screens/office_intake_new_screen.dart
git commit -m "feat(office): offer create form with live total"
```

---

### Task 15: Final verification

- [x] **Step 1: Analyzer + full test suite**

Run: `/home/frappe/.flutter-sdk/bin/flutter analyze && /home/frappe/.flutter-sdk/bin/flutter test`
Expected: analyzer clean (or only pre-existing infos), ALL tests pass (existing 9 files + 6 new).

- [x] **Step 2: Spec cross-check**

Re-read FEATURES.md sections 5 and 6 and confirm each table row maps to implemented code:
- Office hub: lawyer gate (tab hidden, hub never reachable for non-lawyers), 2 cards, live counts, "…" loading, errors → 0 ✓
- Intake list/detail/new: rows, badges, joined names ("، "), truthy-only fields, submit confirm + reload, ≥1 client validation, group→item reset, typed-name unlink ✓
- Offer list/detail/new: customer fallback chain, gold amounts with grouping, qty × rate = amount, live total, customer/item validation ✓
- EntityPicker: immediate empty-query load, 250 ms debounce, session cache, stale rows during refetch, error → empty ✓
- Notifications: bell + gold dot (2 unread), screen, 4 seed cards, type icon/colors, bold unread titles, empty state present ✓
- isLawyer: persisted, parsed from `is_lawyer` (bool or 0/1), gates tab ✓

- [x] **Step 3: Commit any remaining fixes**

```bash
git add -A
git commit -m "fix(office): final analyzer/test fixes"
```

(Skip if nothing changed.)
