# Sub-project 1 — i18n Foundation (Flutter, dill_adala)

**Date:** 2026-06-11
**Status:** Approved design, pending implementation plan
**Part of:** Porting the `law-firm-app` (Expo/React Native) backend + multilingual updates into the Flutter app `dill_adala`.

## Context

`dill_adala` is the Flutter implementation of the same product as the React Native
`law-firm-app`. It currently mirrors the RN app screen-for-screen but is **Arabic-only**
with hardcoded Arabic string literals, static bundled data, and no network layer.

The RN app supports three languages — Arabic (`ar`), English (`en`), and Sorani Kurdish
(`ku`) — via a custom i18n system (`i18n/sections/*.ts`, ~1,120 lines) and a
`LanguageContext` that manages the active language, RTL direction, and a Kurdish font
swap. The RN app is also now backend-connected (Frappe/ERPNext mobile API at
`https://justice-iq.org`, methods `law_firm.api.mobile.*`).

The overall port is decomposed into three sub-projects, built in dependency order:

1. **i18n foundation** *(this spec)* — multilingual infrastructure + full screen-string migration. Prerequisite for everything localized.
2. **Backend client + remote content** — Dart API client, localized models, remote stores replacing static services/news/team. Depends on `Localized` from #1.
3. **Auth + cases + bookings + AI** — token auth, `get_my_cases`, `create_booking`, `ai_chat`. Depends on #2.

This document specifies **only sub-project 1**.

## Goal

Make the Flutter app fully multilingual (ar/en/ku) with runtime language switching,
correct RTL/LTR direction, and the correct font per language — faithfully mirroring the
RN app's i18n behavior — while fitting the Flutter app's existing architecture (bare
`ChangeNotifier` singletons consumed via `ListenableBuilder`; no state-management
package).

### In scope

- A `Lang` enum, a `Localized` data model, and a translation catalog ported 1:1 from the RN `i18n/sections/*`.
- A `LanguageService extends ChangeNotifier` singleton: active language, persistence, `t()` translator, `Localized` resolution, RTL/direction, font family.
- App wiring so language/direction/font are applied app-wide and update at runtime.
- Migration of **every** hardcoded Arabic string in `lib/screens/*` and `lib/widgets/*` to `t('section.key')` calls, using the same keys as the corresponding RN screens.
- Kurdish NRT font bundling.
- A language-switcher UI (bottom sheet) reachable from a globe icon in the home-screen header.
- Unit + widget tests.

### Out of scope (YAGNI / later sub-projects)

- Any backend/network work — that is sub-project 2. (`Localized` is *defined* here but only *consumed* in #2.)
- Device-locale auto-detection — default language stays `ar`, matching RN.
- Digit/numeral localization — strings are rendered as authored, matching RN.
- The RN `pwa` i18n section — web-install prompts, irrelevant to Flutter.
- A full profile screen — not ported; only the language switcher entry point is added.

## Approach

**Approach A — Custom lightweight i18n mirroring the RN system.** Chosen over the official
`flutter_localizations` + `.arb` + `intl` stack because: (a) it is a near-mechanical,
faithful port of the existing 1,120-line dotted-section catalog with identical fallback
and interpolation semantics; (b) Sorani Kurdish is not a well-supported Material locale and
would need a custom delegate under the official stack; (c) runtime language switching needs
a notifier regardless; (d) it matches the app's existing `ChangeNotifier`/`ListenableBuilder`
convention with no codegen; and (e) the `Localized` data resolver that sub-project 2 needs
drops out for free. A provider/riverpod-based approach was rejected to preserve the app's
deliberate use of bare singletons.

## Components

### File layout

```
lib/i18n/
  lang.dart            # enum Lang { ar, en, ku } + metadata/helpers
  localized.dart       # Localized data model
  sections/
    common.dart auth.dart home.dart team.dart cases.dart laws.dart
    ai.dart contact.dart services.dart news.dart components.dart profile.dart
  strings.dart         # flatten sections -> dict; bare top-level t()
lib/services/
  language_service.dart
lib/widgets/
  language_picker.dart # bottom-sheet switcher
assets/fonts/
  NRT-Bd.ttf           # copied from law-firm-app/public/fonts/NRT-Bd.ttf
test/
  language_service_test.dart
  localized_test.dart
  i18n_widget_test.dart
```

### `lib/i18n/lang.dart`

```dart
enum Lang { ar, en, ku }
```

- `code` → `'ar' | 'en' | 'ku'`; `Lang.fromCode(String)` with `ar` default for unknown.
- `isRtl` → `true` for `ar` and `ku`, `false` for `en`.
- `langMeta` → `Map<Lang, ({String label, String native})>`:
  - `ar`: label `Arabic`, native `العربية`
  - `en`: label `English`, native `English`
  - `ku`: label `Kurdish`, native `کوردی`
- Iteration order for the switcher: `[ar, en, ku]` (matches RN `LANGS`).

### `lib/i18n/localized.dart`

A piece of localized **content** (data), Arabic authoritative — mirrors RN `Localized`.

```dart
class Localized {
  final String ar;        // required, authoritative fallback
  final String? en;
  final String? ku;
  const Localized({required this.ar, this.en, this.ku});

  String resolve(Lang lang) => switch (lang) {
        Lang.ar => ar,
        Lang.en => en ?? ar,
        Lang.ku => ku ?? ar,
      };

  factory Localized.fromJson(Object? json); // {ar,en,ku} map -> Localized;
                                            // a bare String -> Localized(ar: s)
}
```

`fromJson` accepts either a `{ar,en,ku}` map (as the backend returns) or a plain string
(treated as Arabic-only), matching the RN `trField` tolerance.

### Translation catalog — `lib/i18n/sections/*.dart`

One file per RN section (excluding `pwa`). Each exports a const map:

```dart
const Map<String, Map<Lang, String>> common = {
  'firmName': {Lang.ar: 'شركة ظل العدالة', Lang.en: 'Shadow of Justice Law Firm', Lang.ku: 'کۆمپانیای سێبەری دادپەروەری'},
  'tab.home': {Lang.ar: 'الرئيسية', Lang.en: 'Home', Lang.ku: 'سەرەکی'},
  // ...
};
```

Keys, values, and the three translations are copied verbatim from the corresponding RN
section file. Sections to port: `common, auth, home, team, cases, laws, ai, contact,
services, news, components, profile`.

### `lib/i18n/strings.dart`

- At first use, flattens all sections into one `Map<String, Map<Lang,String>>` keyed
  `"section.key"`. `common.*` keys are additionally registered **unprefixed** (matching RN).
- Exposes a bare top-level convenience function:

  ```dart
  String t(String key, {Map<String, Object>? vars}) =>
      LanguageService.instance.t(key, vars: vars);
  ```

  so screen call-sites read like the RN `t("auth.welcome")`.

### `lib/services/language_service.dart`

```dart
class LanguageService extends ChangeNotifier {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const _langKey = 'law_firm_lang_v1';
  static const Lang _defaultLang = Lang.ar;

  Lang get lang;
  bool get isRTL;                 // lang.isRtl
  TextDirection get dir;          // isRTL ? rtl : ltr
  String get fontFamily;          // lang == ku ? 'NRT' : 'Cairo'
  bool get isReady;

  String t(String key, {Map<String, Object>? vars});
  Future<void> init();            // load persisted lang from SharedPreferences
  Future<void> setLang(Lang next);// set + persist + notifyListeners
}
```

`t()` semantics (identical to RN `makeT`):
1. Look up `dict[key]`.
2. Result = `entry?[lang] ?? entry?[Lang.ar] ?? key`.
3. If `vars` provided, replace every `{name}` occurrence with its stringified value.

`init()` reads `_langKey`; on missing/invalid value uses `_defaultLang`. `setLang()` updates
the field, persists, and calls `notifyListeners()`.

### App wiring — `lib/main.dart`

- `main()` calls `LanguageService.instance.init()` alongside `AuthService.instance.init()`.
- `MaterialApp` is wrapped in `ListenableBuilder(listenable: LanguageService.instance, …)`
  so a language change rebuilds the whole tree.
- `theme.fontFamily` = `LanguageService.instance.fontFamily` (was hardcoded `'Cairo'`).
- `builder:` returns `Directionality(textDirection: LanguageService.instance.dir, child: child)`
  (was hardcoded `TextDirection.rtl`).
- `MaterialApp.title` = `t('common.firmShort')`.
- `AuthGate` shows the splash spinner until **both** `LanguageService.instance.isReady` and
  `AuthService.instance.isReady` are true, so direction/lang/font are settled before first
  content paint. (`AuthGate` already listens to `AuthService`; it will also listen to
  `LanguageService`, or be nested inside the top-level `ListenableBuilder`.)

### Screen-string migration

For each file in `lib/screens/*` and `lib/widgets/*`:
1. Identify every hardcoded Arabic string literal.
2. Map it to the key used by the **corresponding RN screen** (read the RN screen's `t(...)`
   calls to get exact keys — keys are not invented).
3. Replace with `t('section.key')` (or `t('section.key', vars: {...})` where the RN string
   interpolates).
4. Apply RTL-sensitive layout fixes only where Flutter does not auto-mirror under
   `Directionality`: explicit `TextAlign`, directional chevrons/back icons, and any
   `EdgeInsets.only(left/right)` that should be direction-relative (`EdgeInsetsDirectional`).

Screen ↔ RN route map (for key cross-reference):

| Flutter | RN |
|---|---|
| `home_screen.dart` | `app/(tabs)/index.tsx` (`home`) |
| `team_screen.dart` | `app/(tabs)/team.tsx` (`team`) |
| `cases_screen.dart` | `app/(tabs)/cases.tsx` (`cases`) |
| `laws_screen.dart` | `app/(tabs)/laws.tsx` (`laws`) |
| `ai_screen.dart` | `app/(tabs)/ai.tsx` (`ai`) |
| `contact_screen.dart` | `app/(tabs)/contact.tsx` (`contact`) |
| `services_screen.dart` | `app/(tabs)/services.tsx` (`services`) |
| `news_screen.dart` | `app/(tabs)/news.tsx` (`news`) |
| `service_detail_screen.dart` | `app/service/[id].tsx` (`services`) |
| `news_detail_screen.dart` | `app/news/[id].tsx` (`news`) |
| `lawyer_detail_screen.dart` | `app/lawyer/[id].tsx` (`team`) |
| `login_screen.dart` | `app/(auth)/login.tsx` (`auth`) |
| `otp_screen.dart` | `app/(auth)/otp.tsx` (`auth`) |
| `tabs_shell.dart` | `app/(tabs)/_layout.tsx` (`common.tab.*`) |
| widgets (`auth_sheet`, cards, badges, headers) | `components/*` (`components`) |

> Note: the `laws` **content** (`lib/data/laws/*.dart`) is large static legal text and is
> **not** translated in this sub-project — only the laws *screen UI chrome* (titles, labels,
> buttons) is migrated to `t()`. Translating legal corpora is out of scope for the whole
> port (the RN app also keeps law bodies as-is).

### Fonts & direction

- Copy `law-firm-app/public/fonts/NRT-Bd.ttf` → `assets/fonts/NRT-Bd.ttf`.
- Register an `NRT` font family in `pubspec.yaml` (single asset `NRT-Bd.ttf`).
- `fontFamily` resolves to `'NRT'` when `lang == ku`, else `'Cairo'` (existing 4 weights).
- Direction is purely a function of `lang.isRtl`.

### Language switcher UI — `lib/widgets/language_picker.dart`

- A `showModalBottomSheet` listing the three languages by `langMeta[...].native`
  (العربية / English / کوردی), with the active one marked (check/highlight).
- Selecting one calls `LanguageService.instance.setLang(...)` and closes the sheet; the
  top-level `ListenableBuilder` rebuilds the app in the new language/direction/font.
- Entry point: a globe (`Icons.language` / `Icons.translate`) icon button in the
  **home-screen header**. (Approved placement.)

## Data flow

```
SharedPreferences ──init()──> LanguageService.lang
                                      │
        setLang(next) ──persist──────┤ notifyListeners()
                                      ▼
        top-level ListenableBuilder rebuilds MaterialApp
            ├─ theme.fontFamily  (Cairo | NRT)
            ├─ Directionality    (rtl | ltr)
            └─ every screen: t('key') re-reads dict[key][lang]
```

`Localized.resolve(lang)` is the data-side analogue, consumed by sub-project 2's models.

## Error handling / edge cases

- **Missing translation key:** `t()` returns the key string itself (visible, debuggable) rather than throwing.
- **Missing language in an entry:** falls back to Arabic. (Catalog entries always provide all three, so this mainly guards typos.)
- **Missing language in a `Localized`:** falls back to `ar`.
- **Corrupt/invalid persisted lang code:** `Lang.fromCode` returns `ar`.
- **Runtime switch:** widget types are unchanged across the rebuild, so `State` objects (text input, scroll offset) are preserved.
- **Kurdish font:** NRT is bundled, so `ku` renders correctly; no tofu/fallback.

## Testing

- `test/language_service_test.dart`
  - `t()` returns the active-language value.
  - Missing language in an entry falls back to Arabic.
  - Unknown key returns the key.
  - `{var}` interpolation replaces all occurrences.
  - `setLang()` persists to `SharedPreferences` (`setMockInitialValues`) and notifies listeners.
  - `init()` loads a persisted value; defaults to `ar` when absent/invalid.
- `test/localized_test.dart`
  - `resolve()` returns the requested language; falls back to `ar` when missing.
  - `fromJson` handles both a `{ar,en,ku}` map and a bare string.
- `test/i18n_widget_test.dart`
  - Pump the app; assert a known label is Arabic; call `setLang(Lang.en)`; assert the label
    becomes English and `Directionality` is LTR; `setLang(Lang.ku)` flips back to RTL and
    uses the `NRT` font family.

## Acceptance criteria

1. App launches in Arabic (RTL, Cairo) exactly as today — no visual regression in `ar`.
2. The home-header globe opens a 3-language picker; choosing English switches the entire app
   to English LTR; choosing Kurdish switches to Sorani RTL with the NRT font.
3. The chosen language persists across app restarts.
4. No hardcoded Arabic string literals remain in `lib/screens/*` or `lib/widgets/*`;
   all UI text (including brand strings) is read via `t()`. The only exception is static
   law-body content in `lib/data/laws/*.dart`, which is intentionally not translated.
5. All keys used by migrated screens exist in the catalog and match the RN keys.
6. `flutter analyze` is clean and all tests pass.

## Dependencies / pubspec changes

- No new package dependencies (uses existing `shared_preferences`).
- `pubspec.yaml`: add the `NRT` font family and the `assets/fonts/NRT-Bd.ttf` asset.
