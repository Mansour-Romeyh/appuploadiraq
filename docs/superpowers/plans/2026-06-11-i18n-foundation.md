# i18n Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Flutter app `dill_adala` fully multilingual (Arabic / English / Sorani Kurdish) with runtime switching, correct RTL/LTR direction, and per-language fonts — faithfully mirroring the `law-firm-app` (Expo/RN) i18n system.

**Architecture:** A custom lightweight i18n layer built on the app's existing bare-`ChangeNotifier`-singleton + `ListenableBuilder` pattern. A `Lang` enum, a `Localized` data model, a translation catalog ported 1:1 from the RN `i18n/sections/*`, and a `LanguageService` singleton exposing `t()`, direction, and font. The top of the widget tree listens to the service so a language change rebuilds the whole app. Every hardcoded Arabic string in screens/widgets is migrated to `t('section.key')`.

**Tech Stack:** Flutter / Dart, `shared_preferences` (already a dependency), `flutter_test`. No new packages.

**Reference sources (read-only, authoritative for ported content):**
- RN i18n catalog: `/home/frappe/Frappe/polling/apps/law-firm-app/i18n/sections/*.ts`
- RN i18n machinery: `/home/frappe/Frappe/polling/apps/law-firm-app/i18n/index.ts`, `i18n/types.ts`
- RN language context: `/home/frappe/Frappe/polling/apps/law-firm-app/context/LanguageContext.tsx`
- RN screens (for per-screen key mapping): `/home/frappe/Frappe/polling/apps/law-firm-app/app/**`, `components/**`
- Kurdish font: `/home/frappe/Frappe/polling/apps/law-firm-app/public/fonts/NRT-Bd.ttf`

**Spec:** `docs/superpowers/specs/2026-06-11-i18n-foundation-design.md`

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/i18n/lang.dart` | `enum Lang { ar, en, ku }`; `isRtl`, `code`, `fromCode`, `langMeta`, `langOrder` |
| `lib/i18n/localized.dart` | `Localized` data model (`{ar, en?, ku?}`, `resolve(Lang)`, `fromJson`) |
| `lib/i18n/sections/<section>.dart` | One const `Map<String, Map<Lang,String>>` per RN section |
| `lib/i18n/strings.dart` | Flatten sections into one dict; pure `translate(key, lang, {vars})`; top-level `t()` |
| `lib/services/language_service.dart` | `LanguageService extends ChangeNotifier` singleton: lang state, persistence, `t()`, `dir`, `fontFamily` |
| `lib/widgets/language_picker.dart` | Language-switcher bottom sheet |
| `lib/main.dart` | Wire direction/font/locale + init gating (modify) |
| `lib/screens/*`, `lib/widgets/*` | Replace hardcoded Arabic with `t()` (modify) |
| `assets/fonts/NRT-Bd.ttf` | Kurdish font (new asset) |
| `pubspec.yaml` | Register NRT font family + asset (modify) |
| `test/*` | Unit + widget tests |

---

## Task 0: Initialize git for commit cadence

The `dill_adala` directory is **not** a git repository, so the per-task commit steps below need a repo first.

**Files:** none (repo init only)

- [ ] **Step 1: Initialize the repo**

Run:
```bash
cd /home/frappe/Flutter/dill_adala && git init
```
Expected: `Initialized empty Git repository in /home/frappe/Flutter/dill_adala/.git/`

- [ ] **Step 2: Make the baseline commit**

Run:
```bash
cd /home/frappe/Flutter/dill_adala && git add -A && git commit -m "chore: baseline before i18n foundation"
```
Expected: a commit is created listing the existing files. (A `.gitignore` already exists in the repo, so `build/`, `.dart_tool/`, etc. are excluded.)

---

## Task 1: `Lang` enum

**Files:**
- Create: `lib/i18n/lang.dart`
- Test: `test/lang_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/lang_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/i18n/lang.dart';

void main() {
  test('code round-trips through fromCode', () {
    for (final l in Lang.values) {
      expect(Lang.fromCode(l.code), l);
    }
  });

  test('fromCode falls back to ar for unknown input', () {
    expect(Lang.fromCode('xx'), Lang.ar);
    expect(Lang.fromCode(null), Lang.ar);
  });

  test('ar and ku are RTL, en is LTR', () {
    expect(Lang.ar.isRtl, isTrue);
    expect(Lang.ku.isRtl, isTrue);
    expect(Lang.en.isRtl, isFalse);
  });

  test('langOrder is ar, en, ku', () {
    expect(langOrder, [Lang.ar, Lang.en, Lang.ku]);
  });

  test('langMeta has native names', () {
    expect(langMeta[Lang.ar]!.native, 'العربية');
    expect(langMeta[Lang.en]!.native, 'English');
    expect(langMeta[Lang.ku]!.native, 'کوردی');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lang_test.dart`
Expected: FAIL — `lib/i18n/lang.dart` does not exist / `Lang` undefined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/i18n/lang.dart
/// Supported UI languages. `ku` = Sorani Kurdish (Arabic script, RTL).
enum Lang {
  ar('ar'),
  en('en'),
  ku('ku');

  const Lang(this.code);

  /// Two-letter language code persisted in storage and sent to the backend.
  final String code;

  /// `ar` and `ku` are right-to-left; English is the only LTR option.
  bool get isRtl => this == Lang.ar || this == Lang.ku;

  /// Parse a stored code; unknown/null falls back to Arabic (the default).
  static Lang fromCode(String? code) =>
      Lang.values.firstWhere((l) => l.code == code, orElse: () => Lang.ar);
}

/// Display order for the language switcher (matches the RN `LANGS` order).
const List<Lang> langOrder = [Lang.ar, Lang.en, Lang.ku];

/// Switcher labels: `label` is the English name, `native` the autonym.
typedef LangMeta = ({String label, String native});

const Map<Lang, LangMeta> langMeta = {
  Lang.ar: (label: 'Arabic', native: 'العربية'),
  Lang.en: (label: 'English', native: 'English'),
  Lang.ku: (label: 'Kurdish', native: 'کوردی'),
};
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/lang_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/i18n/lang.dart test/lang_test.dart
git commit -m "feat(i18n): add Lang enum with RTL + metadata"
```

---

## Task 2: `Localized` data model

**Files:**
- Create: `lib/i18n/localized.dart`
- Test: `test/localized_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/localized_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/i18n/localized.dart';

void main() {
  const full = Localized(ar: 'مرحبا', en: 'Hello', ku: 'سڵاو');

  test('resolve returns the requested language', () {
    expect(full.resolve(Lang.ar), 'مرحبا');
    expect(full.resolve(Lang.en), 'Hello');
    expect(full.resolve(Lang.ku), 'سڵاو');
  });

  test('resolve falls back to Arabic when a language is missing', () {
    const arOnly = Localized(ar: 'فقط');
    expect(arOnly.resolve(Lang.en), 'فقط');
    expect(arOnly.resolve(Lang.ku), 'فقط');
  });

  test('fromJson parses an {ar,en,ku} map', () {
    final l = Localized.fromJson({'ar': 'أ', 'en': 'a', 'ku': 'ا'});
    expect(l.resolve(Lang.en), 'a');
  });

  test('fromJson treats a bare string as Arabic-only', () {
    final l = Localized.fromJson('نص');
    expect(l.resolve(Lang.en), 'نص');
  });

  test('fromJson tolerates null/empty into empty Arabic', () {
    expect(Localized.fromJson(null).resolve(Lang.ar), '');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/localized_test.dart`
Expected: FAIL — `Localized` undefined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/i18n/localized.dart
import 'lang.dart';

/// A piece of localized *content* (data), e.g. a service title from the API.
/// Arabic is authoritative and always present; other languages fall back to it.
class Localized {
  final String ar;
  final String? en;
  final String? ku;

  const Localized({required this.ar, this.en, this.ku});

  String resolve(Lang lang) => switch (lang) {
        Lang.ar => ar,
        Lang.en => (en == null || en!.isEmpty) ? ar : en!,
        Lang.ku => (ku == null || ku!.isEmpty) ? ar : ku!,
      };

  /// Accepts either a `{ar,en,ku}` map (as the backend returns) or a bare
  /// string (treated as Arabic-only). Null/other becomes empty Arabic.
  factory Localized.fromJson(Object? json) {
    if (json is String) return Localized(ar: json);
    if (json is Map) {
      return Localized(
        ar: (json['ar'] as String?) ?? '',
        en: json['en'] as String?,
        ku: json['ku'] as String?,
      );
    }
    return const Localized(ar: '');
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/localized_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/i18n/localized.dart test/localized_test.dart
git commit -m "feat(i18n): add Localized data model with ar fallback"
```

---

## Task 3: Catalog scaffolding + `common` section + `translate()`

This task establishes the section-file format, ports the first section (`common`), and builds the flattening + pure translator that `LanguageService` will delegate to.

**Files:**
- Create: `lib/i18n/sections/common.dart`
- Create: `lib/i18n/strings.dart`
- Test: `test/translate_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/translate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/i18n/strings.dart';

void main() {
  test('resolves a namespaced key in the active language', () {
    expect(translate('common.tab.home', Lang.ar), 'الرئيسية');
    expect(translate('common.tab.home', Lang.en), 'Home');
    expect(translate('common.tab.home', Lang.ku), 'سەرەکی');
  });

  test('common.* keys are also reachable unprefixed', () {
    expect(translate('back', Lang.en), 'Back');
    expect(translate('common.back', Lang.en), 'Back');
  });

  test('unknown key returns the key itself', () {
    expect(translate('nope.missing', Lang.en), 'nope.missing');
  });

  test('interpolates {vars}', () {
    // Uses a synthetic entry via the public dict to avoid coupling to content.
    expect(
      interpolate('Hello {name} and {name}', {'name': 'Sam'}),
      'Hello Sam and Sam',
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/translate_test.dart`
Expected: FAIL — `strings.dart` / `translate` undefined.

- [ ] **Step 3: Port the `common` section**

Transcribe **verbatim** from `/home/frappe/Frappe/polling/apps/law-firm-app/i18n/sections/common.ts`, applying this mechanical transform per entry:

`key: { ar: "X", en: "Y", ku: "Z" }`  →  `'key': {Lang.ar: 'X', Lang.en: 'Y', Lang.ku: 'Z'}`

- Keep the exact key strings (including dotted keys like `'tab.home'`).
- Use single quotes; escape any embedded single quote with `\'`.
- Preserve all Unicode (Arabic/Kurdish) exactly.

```dart
// lib/i18n/sections/common.dart
import '../lang.dart';

/// Shared UI strings (tab bar, generic actions, brand, language switcher).
/// Ported 1:1 from law-firm-app/i18n/sections/common.ts.
const Map<String, Map<Lang, String>> common = {
  // ─── brand ───
  'firmName': {Lang.ar: 'شركة ظل العدالة', Lang.en: 'Shadow of Justice Law Firm', Lang.ku: 'کۆمپانیای سێبەری دادپەروەری'},
  'firmShort': {Lang.ar: 'ظل العدالة', Lang.en: 'Shadow of Justice', Lang.ku: 'سێبەری دادپەروەری'},
  'company': {Lang.ar: 'شركة', Lang.en: 'Company', Lang.ku: 'کۆمپانیا'},

  // ─── tab bar ───
  'tab.home': {Lang.ar: 'الرئيسية', Lang.en: 'Home', Lang.ku: 'سەرەکی'},
  'tab.team': {Lang.ar: 'الفريق', Lang.en: 'Team', Lang.ku: 'تیم'},
  'tab.cases': {Lang.ar: 'القضايا', Lang.en: 'Cases', Lang.ku: 'دۆسیەکان'},
  'tab.laws': {Lang.ar: 'القوانين', Lang.en: 'Laws', Lang.ku: 'یاساکان'},
  'tab.ai': {Lang.ar: 'المساعد', Lang.en: 'AI', Lang.ku: 'یاریدەدەر'},
  'tab.contact': {Lang.ar: 'تواصل', Lang.en: 'Contact', Lang.ku: 'پەیوەندی'},

  // ─── generic actions ───
  'back': {Lang.ar: 'رجوع', Lang.en: 'Back', Lang.ku: 'گەڕانەوە'},
  'viewAll': {Lang.ar: 'عرض الكل', Lang.en: 'View all', Lang.ku: 'هەمووی ببینە'},
  'or': {Lang.ar: 'أو', Lang.en: 'or', Lang.ku: 'یان'},
  'free': {Lang.ar: 'مجاناً', Lang.en: 'Free', Lang.ku: 'بەخۆڕایی'},
  'freeConsultation': {Lang.ar: 'استشارة مجانية', Lang.en: 'Free consultation', Lang.ku: 'ڕاوێژی بەخۆڕایی'},
  'cancel': {Lang.ar: 'إلغاء', Lang.en: 'Cancel', Lang.ku: 'هەڵوەشاندنەوە'},
  'save': {Lang.ar: 'حفظ', Lang.en: 'Save', Lang.ku: 'پاشەکەوتکردن'},
  'confirm': {Lang.ar: 'تأكيد', Lang.en: 'Confirm', Lang.ku: 'پشتڕاستکردنەوە'},
  'delete': {Lang.ar: 'حذف', Lang.en: 'Delete', Lang.ku: 'سڕینەوە'},
  'edit': {Lang.ar: 'تعديل', Lang.en: 'Edit', Lang.ku: 'دەستکاری'},
  'close': {Lang.ar: 'إغلاق', Lang.en: 'Close', Lang.ku: 'داخستن'},
  'search': {Lang.ar: 'بحث', Lang.en: 'Search', Lang.ku: 'گەڕان'},
  'loading': {Lang.ar: 'جارٍ التحميل…', Lang.en: 'Loading…', Lang.ku: 'بارکردن…'},
  'retry': {Lang.ar: 'إعادة المحاولة', Lang.en: 'Retry', Lang.ku: 'هەوڵدانەوە'},
  'all': {Lang.ar: 'الكل', Lang.en: 'All', Lang.ku: 'هەموو'},
  'readMore': {Lang.ar: 'اقرأ المزيد', Lang.en: 'Read more', Lang.ku: 'زیاتر بخوێنەوە'},

  // ─── language switcher ───
  'language': {Lang.ar: 'اللغة', Lang.en: 'Language', Lang.ku: 'زمان'},
  'chooseLanguage': {Lang.ar: 'اختر اللغة', Lang.en: 'Choose language', Lang.ku: 'زمان هەڵبژێرە'},
};
```

> Verify against the source: the Dart key count must equal the `.ts` entry count. If the source has more keys than shown above, port them too — the snippet reflects the file at authoring time.

- [ ] **Step 4: Write `strings.dart` (flatten + translator)**

```dart
// lib/i18n/strings.dart
import 'lang.dart';
import 'sections/common.dart';
import 'services/../services/language_service.dart' if (dart.library.io) 'sections/common.dart';
```

> NOTE: ignore the conditional-import line above — replace the import block with the real one below. (Kept the warning so the engineer does not copy the placeholder.)

Use exactly this file:

```dart
// lib/i18n/strings.dart
import 'lang.dart';
import 'sections/common.dart';
import '../services/language_service.dart';

/// Every ported section, registered by its namespace. Adding a section here is
/// the only wiring step needed for its keys to resolve.
const Map<String, Map<String, Map<Lang, String>>> _sections = {
  'common': common,
};

/// Flattened "section.key" → per-language entry, built once on first access.
/// `common.*` keys are also registered unprefixed (matches the RN behavior).
final Map<String, Map<Lang, String>> dict = _buildDict();

Map<String, Map<Lang, String>> _buildDict() {
  final out = <String, Map<Lang, String>>{};
  _sections.forEach((ns, section) {
    section.forEach((key, entry) {
      out['$ns.$key'] = entry;
      if (ns == 'common') out[key] = entry;
    });
  });
  return out;
}

/// Replace every `{name}` token with its stringified value.
String interpolate(String input, Map<String, Object> vars) {
  var out = input;
  vars.forEach((k, v) {
    out = out.replaceAll('{$k}', '$v');
  });
  return out;
}

/// Pure translator: entry[lang] ?? entry[ar] ?? key, then interpolate vars.
String translate(String key, Lang lang, {Map<String, Object>? vars}) {
  final entry = dict[key];
  var out = entry == null ? key : (entry[lang] ?? entry[Lang.ar] ?? key);
  if (vars != null) out = interpolate(out, vars);
  return out;
}

/// Convenience top-level translator bound to the live active language, so
/// call-sites read like the RN `t("auth.welcome")`.
String t(String key, {Map<String, Object>? vars}) =>
    translate(key, LanguageService.instance.lang, vars: vars);
```

> The `t()` top-level function imports `LanguageService`; that class is created in Task 4. Until then, `strings.dart` will not compile via `t()`, but `translate()` and `interpolate()` (which the Task 3 test uses) do not depend on it. To keep Task 3 green in isolation, **temporarily** comment out the `import '../services/language_service.dart';` line and the `t()` function, then restore both in Task 4 Step 6. (The Task 3 test only exercises `translate` and `interpolate`.)

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/translate_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/i18n/sections/common.dart lib/i18n/strings.dart test/translate_test.dart
git commit -m "feat(i18n): add common catalog section + pure translator"
```

---

## Task 4: `LanguageService`

**Files:**
- Create: `lib/services/language_service.dart`
- Modify: `lib/i18n/strings.dart` (restore `t()` + the LanguageService import from Task 3 Step 4)
- Test: `test/language_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/language_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/services/language_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageService.instance.resetForTest();
  });

  test('defaults to Arabic before init', () {
    expect(LanguageService.instance.lang, Lang.ar);
    expect(LanguageService.instance.isReady, isFalse);
  });

  test('init loads a persisted language', () async {
    SharedPreferences.setMockInitialValues({'law_firm_lang_v1': 'en'});
    await LanguageService.instance.init();
    expect(LanguageService.instance.lang, Lang.en);
    expect(LanguageService.instance.isReady, isTrue);
  });

  test('init defaults to ar when nothing is stored', () async {
    await LanguageService.instance.init();
    expect(LanguageService.instance.lang, Lang.ar);
  });

  test('setLang persists and notifies', () async {
    var notified = 0;
    LanguageService.instance.addListener(() => notified++);
    await LanguageService.instance.setLang(Lang.ku);
    expect(LanguageService.instance.lang, Lang.ku);
    expect(notified, greaterThan(0));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('law_firm_lang_v1'), 'ku');
  });

  test('direction and font follow the language', () async {
    await LanguageService.instance.setLang(Lang.ku);
    expect(LanguageService.instance.isRTL, isTrue);
    expect(LanguageService.instance.fontFamily, 'NRT');
    await LanguageService.instance.setLang(Lang.en);
    expect(LanguageService.instance.isRTL, isFalse);
    expect(LanguageService.instance.fontFamily, 'Cairo');
  });

  test('t delegates to the active language', () async {
    await LanguageService.instance.setLang(Lang.en);
    expect(LanguageService.instance.t('common.tab.home'), 'Home');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/language_service_test.dart`
Expected: FAIL — `LanguageService` undefined.

- [ ] **Step 3: Write the implementation**

```dart
// lib/services/language_service.dart
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/lang.dart';
import '../i18n/strings.dart' as strings;

/// App-wide language state persisted in SharedPreferences.
/// Mirrors law-firm-app/context/LanguageContext.tsx.
class LanguageService extends ChangeNotifier {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const _langKey = 'law_firm_lang_v1';
  static const Lang _defaultLang = Lang.ar;

  Lang _lang = _defaultLang;
  bool _isReady = false;

  Lang get lang => _lang;
  bool get isReady => _isReady;
  bool get isRTL => _lang.isRtl;
  TextDirection get dir => _lang.isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Kurdish ships with the NRT font; everything else uses Cairo.
  String get fontFamily => _lang == Lang.ku ? 'NRT' : 'Cairo';

  String t(String key, {Map<String, Object>? vars}) =>
      strings.translate(key, _lang, vars: vars);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lang = Lang.fromCode(prefs.getString(_langKey));
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

  Future<void> setLang(Lang next) async {
    _lang = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, next.code);
  }

  /// Test-only: restore the singleton to its pre-init state between tests.
  @visibleForTesting
  void resetForTest() {
    _lang = _defaultLang;
    _isReady = false;
  }
}
```

- [ ] **Step 4: Restore `t()` in `strings.dart`**

If the `import '../services/language_service.dart';` line and the top-level `t()` function were commented out in Task 3, **uncomment both now** so `t()` is live. Verify the file ends with:

```dart
String t(String key, {Map<String, Object>? vars}) =>
    translate(key, LanguageService.instance.lang, vars: vars);
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/language_service_test.dart test/translate_test.dart`
Expected: PASS (all).

- [ ] **Step 6: Commit**

```bash
git add lib/services/language_service.dart lib/i18n/strings.dart test/language_service_test.dart
git commit -m "feat(i18n): add LanguageService with persistence + direction/font"
```

---

## Task 5: Port the remaining catalog sections

Port each remaining RN section and register it in `strings.dart`. Sections: `auth, home, team, cases, laws, ai, contact, services, news, components, profile`. (Skip `pwa`.)

**Files:**
- Create: `lib/i18n/sections/{auth,home,team,cases,laws,ai,contact,services,news,components,profile}.dart`
- Modify: `lib/i18n/strings.dart` (register all sections)
- Test: `test/catalog_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/catalog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/i18n/strings.dart';

void main() {
  test('all sections are registered and resolve', () {
    // One representative key per section (must exist after porting).
    const probes = <String>[
      'auth.welcome',
      'home.heroTitle',
      'team.title',
      'cases.title',
      'laws.title',
      'ai.welcomeMessage',
      'contact.title',
      'services.title',
      'news.title',
      'components.sheetTitle',
      'profile.title',
    ];
    for (final key in probes) {
      // Resolves to a non-empty, non-key string in all three languages.
      for (final lang in Lang.values) {
        final v = translate(key, lang);
        expect(v, isNotEmpty, reason: '$key/$lang empty');
        expect(v, isNot(key), reason: '$key/$lang missing (returned the key)');
      }
    }
  });

  test('every entry defines all three languages', () {
    dict.forEach((key, entry) {
      for (final lang in Lang.values) {
        expect(entry[lang], isNotNull, reason: 'missing $lang for "$key"');
      }
    });
  });
}
```

> The probe keys must match real keys in the source sections. Before writing implementations, open each RN section file and pick the actual first key if any probe above does not exist; update the probe list to a key that genuinely exists in that section. Do **not** invent keys.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/catalog_test.dart`
Expected: FAIL — sections not yet registered (probe keys return the key).

- [ ] **Step 3: Port each section file**

For each section `<name>` in `auth, home, team, cases, laws, ai, contact, services, news, components, profile`:
- Read `/home/frappe/Frappe/polling/apps/law-firm-app/i18n/sections/<name>.ts`.
- Create `lib/i18n/sections/<name>.dart` applying the same transform as Task 3 Step 3:

```dart
// lib/i18n/sections/<name>.dart
import '../lang.dart';

/// Ported 1:1 from law-firm-app/i18n/sections/<name>.ts.
const Map<String, Map<Lang, String>> <name> = {
  'someKey': {Lang.ar: '…', Lang.en: '…', Lang.ku: '…'},
  // … every entry from the source, verbatim …
};
```

Rules (identical to Task 3):
- Exact key strings; single-quoted values; escape embedded `'` as `\'`.
- Preserve all Unicode exactly.
- If a source entry uses `{var}` interpolation tokens, keep them literally — `translate()` handles them at runtime.
- The Dart entry count per file must equal the source `.ts` entry count.

- [ ] **Step 4: Register all sections in `strings.dart`**

Replace the `_sections` map and imports so every section is wired:

```dart
// lib/i18n/strings.dart  (imports block)
import 'lang.dart';
import '../services/language_service.dart';
import 'sections/common.dart';
import 'sections/auth.dart';
import 'sections/home.dart';
import 'sections/team.dart';
import 'sections/cases.dart';
import 'sections/laws.dart';
import 'sections/ai.dart';
import 'sections/contact.dart';
import 'sections/services.dart';
import 'sections/news.dart';
import 'sections/components.dart';
import 'sections/profile.dart';

const Map<String, Map<String, Map<Lang, String>>> _sections = {
  'common': common,
  'auth': auth,
  'home': home,
  'team': team,
  'cases': cases,
  'laws': laws,
  'ai': ai,
  'contact': contact,
  'services': services,
  'news': news,
  'components': components,
  'profile': profile,
};
```

(Leave the rest of `strings.dart` — `dict`, `interpolate`, `translate`, `t` — unchanged.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/catalog_test.dart`
Expected: PASS. If "every entry defines all three languages" fails, the named source key is missing a translation — copy the missing language from the source (the RN entries always define all three).

- [ ] **Step 6: Commit**

```bash
git add lib/i18n/sections/ lib/i18n/strings.dart test/catalog_test.dart
git commit -m "feat(i18n): port full translation catalog (11 sections)"
```

---

## Task 6: Bundle the Kurdish NRT font

**Files:**
- Create: `assets/fonts/NRT-Bd.ttf` (copied)
- Modify: `pubspec.yaml`

- [ ] **Step 1: Copy the font**

Run:
```bash
cp /home/frappe/Frappe/polling/apps/law-firm-app/public/fonts/NRT-Bd.ttf \
   /home/frappe/Flutter/dill_adala/assets/fonts/NRT-Bd.ttf
ls -l /home/frappe/Flutter/dill_adala/assets/fonts/NRT-Bd.ttf
```
Expected: the file exists (~57 KB).

- [ ] **Step 2: Register the font family in `pubspec.yaml`**

Add a new `NRT` family under the existing `fonts:` list (after the `Cairo` family). The single NRT-Bd weight is mapped to all weights (matches the RN behavior of remapping every Cairo weight to NRT-Bd):

```yaml
    - family: NRT
      fonts:
        - asset: assets/fonts/NRT-Bd.ttf
```

- [ ] **Step 3: Fetch packages / validate pubspec**

Run: `flutter pub get`
Expected: completes with no error (validates the asset path and font block).

- [ ] **Step 4: Commit**

```bash
git add assets/fonts/NRT-Bd.ttf pubspec.yaml
git commit -m "feat(i18n): bundle Kurdish NRT font"
```

---

## Task 7: Wire direction, font, and init gating in `main.dart`

**Files:**
- Modify: `lib/main.dart`
- Test: `test/i18n_widget_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
// test/i18n_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/services/language_service.dart';
import 'package:dill_adala/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageService.instance.resetForTest();
  });

  testWidgets('app reflects language: direction + a known label', (tester) async {
    await LanguageService.instance.init();
    await tester.pumpWidget(const DillAdalaApp());
    await tester.pumpAndSettle();

    // Default Arabic → RTL.
    expect(Directionality.of(tester.element(find.byType(Scaffold).first)),
        TextDirection.rtl);

    // Switch to English → LTR, and the Home tab label becomes "Home".
    await LanguageService.instance.setLang(Lang.en);
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.byType(Scaffold).first)),
        TextDirection.ltr);
    expect(find.text('Home'), findsWidgets);

    // Switch to Kurdish → RTL again, NRT font selected on the theme.
    await LanguageService.instance.setLang(Lang.ku);
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.byType(Scaffold).first)),
        TextDirection.rtl);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.textTheme.bodyMedium?.fontFamily ?? app.theme!.fontFamily,
        anyOf('NRT', contains('NRT')));
  });
}
```

> This test assumes the app, when authed-out, shows the `LoginScreen` (a `Scaffold`) and that the bottom tabs (with the "Home" label) are reachable. If `find.text('Home')` is not present on the login screen, adjust the assertion to a label that IS visible on the first screen in English (e.g. a login button), using the real key/string from `login_screen.dart` after Task 16's migration. For the first pass, gate this test on `Directionality` only and add the label assertion after the tab shell is migrated (Task 8/9). Keep the direction assertions regardless.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/i18n_widget_test.dart`
Expected: FAIL — direction is still hardcoded RTL (LTR assertion fails) and/or font not wired.

- [ ] **Step 3: Modify `main.dart`**

Replace the current `DillAdalaApp.build` and `main()` with language-aware wiring:

```dart
// lib/main.dart
import 'package:flutter/material.dart';

import 'i18n/strings.dart';
import 'screens/login_screen.dart';
import 'screens/tabs_shell.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AuthService.instance.init();
  LanguageService.instance.init();
  runApp(const DillAdalaApp());
}

class DillAdalaApp extends StatelessWidget {
  const DillAdalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;
        return MaterialApp(
          title: t('common.firmShort'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: lang.fontFamily,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              secondary: AppColors.gold,
              surface: AppColors.card,
              error: AppColors.destructive,
            ),
            useMaterial3: true,
          ),
          builder: (context, child) => Directionality(
            textDirection: lang.dir,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Shows login or the main tab shell depending on auth state, after both the
/// language and auth singletons have finished loading.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [AuthService.instance, LanguageService.instance]),
      builder: (context, _) {
        final auth = AuthService.instance;
        final lang = LanguageService.instance;
        if (!auth.isReady || !lang.isReady) {
          return const Scaffold(
            backgroundColor: AppColors.navy,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }
        return auth.hasAuth ? const TabsShell() : const LoginScreen();
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/i18n_widget_test.dart`
Expected: PASS for the `Directionality` assertions. (Defer/adjust the label assertion per the note in Step 1 if the tab shell is not yet migrated.)

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/i18n_widget_test.dart
git commit -m "feat(i18n): drive direction, font, and title from active language"
```

---

## Task 8: Language picker + home-header entry point

**Files:**
- Create: `lib/widgets/language_picker.dart`
- Modify: `lib/screens/home_screen.dart` (add a globe icon button to the header)
- Test: `test/language_picker_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/language_picker_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dill_adala/i18n/lang.dart';
import 'package:dill_adala/services/language_service.dart';
import 'package:dill_adala/widgets/language_picker.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageService.instance.resetForTest();
  });

  testWidgets('selecting a language updates the service', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showLanguagePicker(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The three native names are listed.
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('کوردی'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(LanguageService.instance.lang, Lang.en);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/language_picker_test.dart`
Expected: FAIL — `showLanguagePicker` undefined.

- [ ] **Step 3: Implement the picker**

```dart
// lib/widgets/language_picker.dart
import 'package:flutter/material.dart';

import '../i18n/lang.dart';
import '../i18n/strings.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

/// Bottom-sheet language switcher. Lists the three languages by their native
/// names and applies the choice via LanguageService.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final active = LanguageService.instance.lang;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t('common.chooseLanguage'),
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
            for (final lang in langOrder)
              ListTile(
                title: Text(langMeta[lang]!.native,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                trailing: lang == active
                    ? const Icon(Icons.check, color: AppColors.gold)
                    : null,
                onTap: () async {
                  await LanguageService.instance.setLang(lang);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
```

- [ ] **Step 4: Add the globe button to the home header**

In `lib/screens/home_screen.dart`, add the import:

```dart
import '../widgets/language_picker.dart';
```

In the header `Container` (the navy block near the top of `build`), place a globe `IconButton` aligned to the trailing edge that opens the picker:

```dart
Align(
  alignment: AlignmentDirectional.topEnd,
  child: IconButton(
    icon: const Icon(Icons.language, color: AppColors.gold),
    onPressed: () => showLanguagePicker(context),
    tooltip: t('common.language'),
  ),
),
```

(Exact placement: inside the header column/stack so it sits in the top corner without overlapping the firm name. If the header is a `Column`, wrap the title row and this button in a `Row` with `MainAxisAlignment.spaceBetween`.)

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/language_picker_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/language_picker.dart lib/screens/home_screen.dart test/language_picker_test.dart
git commit -m "feat(i18n): add language picker + home-header switcher"
```

---

## Tasks 9–18: Screen & widget string migration

Each task migrates one screen/widget group from hardcoded Arabic to `t('section.key')`. **Procedure (identical for every task):**

1. Open the Flutter file(s) and the corresponding RN file(s) (see the screen↔route table in the spec).
2. For each hardcoded Arabic string literal in the Flutter file, find the matching `t("section.key")` call in the RN file and use the **same key**. For interpolated strings, use `t('key', vars: {'name': value})`.
3. Add `import '../i18n/strings.dart';` to the Flutter file (for the top-level `t()`); add `import '../services/language_service.dart';` only if the file needs `LanguageService.instance` directly (e.g. `isRTL`).
4. Replace any direction-hardcoded layout: `TextAlign.right`→ default/`TextAlign.start`; `EdgeInsets.only(left:/right:)` that should mirror → `EdgeInsetsDirectional.only(start:/end:)`; directional chevrons → flip with `LanguageService.instance.isRTL` or use `Icons.chevron_right`/`chevron_left` chosen by `isRTL`.
5. Run `flutter analyze` on the file and the relevant widget test (if any).
6. Verify no Arabic literals remain in that file (Step "verify" below).
7. Commit.

**Per-file verification command** (no Arabic-script literal should remain in code, excluding comments):
```bash
grep -nP '[\x{0600}-\x{06FF}]' <file> || echo "clean"
```
A `clean` result (or only matches inside `//` comments) is the gate. Brand/UI strings must come from `t()`.

> If executed via subagents, dispatch one subagent per task below; each reads both the Flutter and RN file, performs the mapping, and runs the verification grep + `flutter analyze`.

---

### Task 9: `tabs_shell.dart` (tab bar labels)

**Files:** Modify `lib/screens/tabs_shell.dart` · Reference `app/(tabs)/_layout.tsx`

- [ ] **Step 1:** Replace the 6 hardcoded tab labels with `t('common.tab.home')`, `t('common.tab.team')`, `t('common.tab.cases')`, `t('common.tab.laws')`, `t('common.tab.ai')`, `t('common.tab.contact')`. Add `import '../i18n/strings.dart';`.
- [ ] **Step 2:** Run `flutter analyze lib/screens/tabs_shell.dart` → no issues.
- [ ] **Step 3:** Verify: `grep -nP '[\x{0600}-\x{06FF}]' lib/screens/tabs_shell.dart` → `clean` (or comments only).
- [ ] **Step 4:** Commit: `git add lib/screens/tabs_shell.dart && git commit -m "i18n(tabs): localize tab bar labels"`

---

### Task 10: `home_screen.dart`

**Files:** Modify `lib/screens/home_screen.dart` · Reference `app/(tabs)/index.tsx` (`home`, `common`)

- [ ] **Step 1:** Replace `const String _firmName = 'ظل العدالة';` usage and every inline Arabic literal (hero text, section headers, button labels, greeting) with the matching `t('home.*')`/`t('common.*')` keys from `app/(tabs)/index.tsx`. Replace any `_firmName` references with `t('common.firmShort')`.
- [ ] **Step 2:** `flutter analyze lib/screens/home_screen.dart` → no issues.
- [ ] **Step 3:** Verify grep → `clean`.
- [ ] **Step 4:** Commit: `git commit -am "i18n(home): localize home screen"`

---

### Task 11: `services_screen.dart` + `service_detail_screen.dart`

**Files:** Modify both · Reference `app/(tabs)/services.tsx`, `app/service/[id].tsx` (`services`, `common`)

- [ ] **Step 1:** Migrate all UI chrome literals (titles, labels, "view all", CTA buttons) to `t('services.*')`/`t('common.*')`. (Service *content* — title/description/details — is still static Arabic data in `lib/data/services.dart` for now; it becomes localized in sub-project 2. Do **not** translate the data file here.)
- [ ] **Step 2:** `flutter analyze` on both files → no issues.
- [ ] **Step 3:** Verify grep on both → `clean` (data still references `services` from `lib/data` — that is allowed; only screen-chrome literals are migrated).
- [ ] **Step 4:** Commit: `git commit -am "i18n(services): localize services screens"`

---

### Task 12: `news_screen.dart` + `news_detail_screen.dart`

**Files:** Modify both · Reference `app/(tabs)/news.tsx`, `app/news/[id].tsx` (`news`, `common`)

- [ ] **Step 1:** Migrate chrome literals to `t('news.*')`/`t('common.*')`. (News data stays static for now.)
- [ ] **Step 2:** `flutter analyze` both → no issues.
- [ ] **Step 3:** Verify grep → `clean`.
- [ ] **Step 4:** Commit: `git commit -am "i18n(news): localize news screens"`

---

### Task 13: `team_screen.dart` + `lawyer_detail_screen.dart`

**Files:** Modify both · Reference `app/(tabs)/team.tsx`, `app/lawyer/[id].tsx` (`team`, `common`)

- [ ] **Step 1:** Migrate chrome literals (title, "experience" unit, availability labels, contact buttons) to `t('team.*')`/`t('common.*')`. Watch for interpolation (e.g. experience years) → use `vars`.
- [ ] **Step 2:** `flutter analyze` both → no issues.
- [ ] **Step 3:** Verify grep → `clean`.
- [ ] **Step 4:** Commit: `git commit -am "i18n(team): localize team screens"`

---

### Task 14: `cases_screen.dart`

**Files:** Modify `lib/screens/cases_screen.dart` · Reference `app/(tabs)/cases.tsx` (`cases`, `common`)

- [ ] **Step 1:** Migrate chrome literals (title, status filter labels, empty/login-required text). The `CaseStatus` enum Arabic labels in `lib/models/case_item.dart` are status *keys* — leave the enum as-is, but localize any **display** label shown in the UI via `t('cases.*')`. (Status display localization is finalized in sub-project 3; here, migrate only literal UI strings.)
- [ ] **Step 2:** `flutter analyze` → no issues.
- [ ] **Step 3:** Verify grep on `lib/screens/cases_screen.dart` → `clean`.
- [ ] **Step 4:** Commit: `git commit -am "i18n(cases): localize cases screen chrome"`

---

### Task 15: `laws_screen.dart` (chrome only)

**Files:** Modify `lib/screens/laws_screen.dart` · Reference `app/(tabs)/laws.tsx` (`laws`, `common`)

- [ ] **Step 1:** Migrate **only** screen chrome (title, search placeholder, category labels, "read more"). Do **not** touch `lib/data/laws/*.dart` — the legal corpus stays static Arabic (out of scope per spec).
- [ ] **Step 2:** `flutter analyze lib/screens/laws_screen.dart` → no issues.
- [ ] **Step 3:** Verify grep on `lib/screens/laws_screen.dart` → `clean` (references to law data are allowed).
- [ ] **Step 4:** Commit: `git commit -am "i18n(laws): localize laws screen chrome"`

---

### Task 16: `ai_screen.dart`

**Files:** Modify `lib/screens/ai_screen.dart` · Reference `app/(tabs)/ai.tsx` (`ai`, `common`)

- [ ] **Step 1:** Migrate welcome message, input placeholder, send/attach labels, and any error strings to `t('ai.*')`/`t('common.*')`.
- [ ] **Step 2:** `flutter analyze` → no issues.
- [ ] **Step 3:** Verify grep → `clean`.
- [ ] **Step 4:** Commit: `git commit -am "i18n(ai): localize AI screen"`

---

### Task 17: `contact_screen.dart`

**Files:** Modify `lib/screens/contact_screen.dart` · Reference `app/(tabs)/contact.tsx` (`contact`, `common`)

- [ ] **Step 1:** Migrate form field labels, placeholders, submit button, and contact-info labels to `t('contact.*')`/`t('common.*')`.
- [ ] **Step 2:** `flutter analyze` → no issues.
- [ ] **Step 3:** Verify grep → `clean`.
- [ ] **Step 4:** Commit: `git commit -am "i18n(contact): localize contact screen"`

---

### Task 18: `login_screen.dart` + `otp_screen.dart`

**Files:** Modify both · Reference `app/(auth)/login.tsx`, `app/(auth)/otp.tsx` (`auth`, `common`)

- [ ] **Step 1:** Migrate welcome/subtitle, the Google/Apple/phone buttons, phone placeholder, validation/error strings, OTP prompt, resend label/timer, and guest CTA to `t('auth.*')`/`t('common.*')`. Use `vars` for the resend countdown (e.g. `t('auth.resendIn', vars: {'seconds': resendTimer})` — use the exact RN key).
- [ ] **Step 2:** `flutter analyze` both → no issues.
- [ ] **Step 3:** Verify grep → `clean`.
- [ ] **Step 4:** Commit: `git commit -am "i18n(auth): localize login + otp screens"`

---

### Task 19: Shared widgets

**Files:** Modify `lib/widgets/auth_sheet.dart`, `lib/widgets/section_header.dart`, `lib/widgets/case_status_badge.dart`, `lib/widgets/lawyer_card.dart`, `lib/widgets/news_card.dart`, `lib/widgets/service_card.dart` · Reference `components/*` (`components`, `common`)

- [ ] **Step 1:** Migrate any hardcoded Arabic literals in these widgets to `t('components.*')`/`t('common.*')`. Cards that render *data* (lawyer name, service title) keep reading from their model fields — only fixed UI chrome (e.g. "Free consultation", badge text, "Read more") is migrated.
- [ ] **Step 2:** `flutter analyze lib/widgets/` → no issues.
- [ ] **Step 3:** Verify each file with the grep → `clean` (model-field references allowed).
- [ ] **Step 4:** Commit: `git commit -am "i18n(widgets): localize shared widget chrome"`

---

## Task 20: Full verification + i18n widget-test finalization

**Files:** Modify `test/i18n_widget_test.dart` (restore the deferred label assertion if it was gated in Task 7)

- [ ] **Step 1: Restore the label assertion**

Now that `login_screen.dart`/`tabs_shell.dart` are migrated, ensure `test/i18n_widget_test.dart` asserts a real English label visible on the first screen after switching to `en` (e.g. the login welcome or "Continue with phone" string — use the actual migrated key/text). Keep the direction + font assertions.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: all tests PASS.

- [ ] **Step 3: Static analysis**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Residual-literal sweep across migrated code**

Run:
```bash
grep -rnP '[\x{0600}-\x{06FF}]' lib/screens lib/widgets \
  | grep -v '//' || echo "NO RESIDUAL ARABIC LITERALS"
```
Expected: only allowed matches (none in screen/widget chrome). Investigate any hit that is a UI string and migrate it.

> Note: `lib/data/*` (services/news/lawyers/laws static content) and `lib/models/case_item.dart` (status enum keys) intentionally still contain Arabic — they are out of scope for this sub-project. The sweep targets `lib/screens` and `lib/widgets` only.

- [ ] **Step 5: Manual smoke check (optional but recommended)**

Run the app (`flutter run` or via the `/run` skill), open the home-header globe, switch to English then Kurdish, and confirm: layout direction flips, the Kurdish text uses the NRT font, and the choice persists across a restart.

- [ ] **Step 6: Commit**

```bash
git add test/i18n_widget_test.dart
git commit -m "test(i18n): finalize widget test; full suite green"
```

---

## Self-Review Notes (author)

- **Spec coverage:** Lang/Localized (T1–T2) · LanguageService + persistence + dir/font (T4) · catalog port incl. all sections, pwa excluded (T3, T5) · NRT font (T6) · main.dart direction/font/title + dual-readiness gate (T7) · switcher bottom sheet + home-header entry (T8) · full screen/widget migration incl. laws-chrome-only and data-stays-static caveats (T9–T19) · tests: language_service, localized, translate, catalog, widget, picker (T1–T8, T20) · acceptance-criteria verification incl. residual-literal sweep (T20). All spec sections map to a task.
- **Type consistency:** `Lang.code`/`fromCode`/`isRtl`, `langOrder`, `langMeta[...].native`, `Localized.resolve/fromJson`, `translate(key, lang, {vars})`, `interpolate`, `t(key, {vars})`, `LanguageService.instance.{lang,isRTL,dir,fontFamily,isReady,t,init,setLang,resetForTest}` are used consistently across tasks.
- **Known soft spots for the executor:** probe keys in T5 and exact RN keys in T9–T19 must be confirmed against the live source files (the plan instructs reading them and forbids inventing keys); the T7 widget-test label assertion is intentionally deferred to T20 because it depends on migrated screens.
