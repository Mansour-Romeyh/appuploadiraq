# Flutter ↔ Reference App Parity Audit

**Date:** 2026-06-11
**Reference:** `/home/frappe/Frappe/polling/apps/law-firm-app/` (Expo / React Native, backend-wired)
**Flutter:** `/home/frappe/Flutter/dill_adala/` (this app)

Every screen pair was compared file-by-file. Screen inventory matches 1:1 **except the Flutter app has no Profile screen** (reference `app/profile.tsx`).

---

## TL;DR — Two root causes explain most differences

1. **Flutter is a port of an OLDER version of the reference app.** The reference has since become a real backend-wired product (live OTP via `send_otp`/`verify_otp`, real cases via `get_my_cases`, live `ai_chat`, real `createBooking`). The Flutter app mocks all of these. Login accepts any 6 digits; AI only ever replies "service not configured"; cases are local-only CRUD; contact/booking forms fake success.

2. **Content data is Arabic-only in Flutter.** The reference stores `{ar, en, ku}` for all services, lawyers, news, and law titles/chapters and renders via `tr(..., lang)`. Flutter's models hold plain Arabic `String`s. **Result:** switching to English or Kurdish leaves all real content (service titles, lawyer names/bios, article text, law titles) in Arabic — only the UI chrome translates. This affects Services, Team, News, and Laws identically.

---

## Cross-cutting gaps (affect many screens)

| Gap | Detail |
|---|---|
| **No Profile screen** | Reference `app/profile.tsx` (avatar+initials, account-info card with name/phone/email/sign-in method, two-step sign-out confirm, guest sign-in CTA) is entirely absent. `lib/i18n/sections/profile.dart` exists but every key is dead. Flutter's only analog is a greeting+logout block in the home header. |
| **No content localization** | Services/Lawyers/News/Laws content is Arabic-only; EN/KU show Arabic. Models need `Localized` (ar/en/ku) fields. |
| **No backend wiring** | Auth, Cases, AI, Contact/Booking are all mocked. No `lib/api` client exists. |
| **Cases tab not guest-gated** | Reference hides the Cases tab for guests; Flutter always shows it and lets guests open it. |
| **No ErrorBoundary / ErrorFallback** | Reference wraps the tree; `components.dart` error keys are dead in Flutter. |
| **No PWA install prompt** | Reference-only (`pwa` i18n section not even ported). N/A if Flutter is native-only — confirm intent. |
| **`AuthUser` missing `apiKey`/`apiSecret`** | Reference stores Frappe credentials; Flutter drops them, so no authenticated API call is even possible yet. |
| **RTL-aware icons/text** | Reference flips chevrons/arrows/send-icon and sets per-text `writingDirection` by `isRTL`. Flutter hardcodes RTL-correct values (fine for Arabic, wrong if EN/KU LTR). |

---

## Login / OTP (the example you gave)

**Login screen — concrete differences:**
- **Social button is the wrong provider.** Reference shows an **Apple** button (iOS-only). Flutter shows a **Google** button (all platforms) with a mock 3-account picker sheet. They are opposite providers.
- **No country-code picker.** Reference has a searchable 52-country dial-code picker (`CountryCodePicker`); Flutter has none — just a bare phone field. No dial code is ever prepended.
- **No phone validation.** Reference enforces Iraqi rules (10 digits starting `7`, or 11 starting `0`, strips leading zero) with an inline `phoneInvalidIraq` hint. Flutter only checks `length >= 10`.
- **No WhatsApp note, no send spinner, no error states** (`phoneNotRegistered`, `otpThrottled`, `otpSendFailed` all dead in Flutter).
- **Firm name localizes in Flutter but is hardcoded Arabic in reference** (reference intentionally keeps the brand Arabic in every language).
- **Layout:** reference = country pill + field on one row, full-width submit below + WhatsApp note. Flutter = inline 52×52 arrow button beside the field.

**OTP screen:**
- Reference calls real `verifyOtp` with a full error matrix (invalid/expired/too-many → red boxes, clears, refocuses). Flutter accepts **any 6 digits** after a 1.8s fake delay; no error states; resend doesn't call a backend.
- ~10 auth i18n keys are defined in Flutter but never rendered.

---

## Home

- **Missing:** profile/avatar button in header (initials → profile), services/news loading + empty states (`home.noServices`/`home.noNews` dead), ServiceCard press *rotation* animation, NewsCard localized category label + conditional image.
- **Different:** firm name localizes (reference hardcodes Arabic); "free consultation" uses `TabSwitcher.switchTo(5)` vs router push (same target).
- **Extra in Flutter:** language `IconButton` in header (reference has no language control on home — it lives in Contact), news image error placeholder.
- Section order matches: Header → Services (6 compact cards) → News (2) → quick-contact banner → user/logout.

## Services + Service detail

- **Data:** 8 services, ids 1–8, all Arabic text byte-identical. ✅ counts match. ❌ Flutter has no en/ku translations.
- **Detail CTA is broken:** reference "Book consultation" → Contact tab; Flutter just `pop()`s (goes nowhere useful). Also button color gold (Flutter) vs navy (reference).
- **Extra back button** on the Flutter services list header (reference is a tab root, no back button).
- Grid uses fixed `childAspectRatio: 0.95` vs reference intrinsic height; no card rotation; chevron not RTL-aware.

## Team + Lawyer detail

- **Data:** 5 lawyers, ids 1–5, all Arabic fields match. ❌ Missing `nextAvailable` field entirely, ❌ no `photoUrl`, ❌ no en/ku.
- **Detail screen is much simpler in Flutter:** reference has a **4-tab** detail (About / Availability / Experience / Education) with stat chips (cases, years), 4 info cards, availability badge, experience prose. Flutter is a flat single-scroll with specialty/education/bio cards only.
- **Booking CTA broken** (same as services: reference → Contact, Flutter → `pop()`); reference solid gold button vs Flutter outlined.
- **Card differs:** reference = large photo + next-available footer + heart favorite; Flutter = small circle avatar + "available" pill + cases/experience row + chevron, no photo/favorite/footer.
- **Extra in Flutter:** call (`tel:`) + email (`mailto:`) buttons on detail (reference has none here), inline "available" pill.

## News + News detail

- **Data:** 4 articles, ids 1–4, Arabic text/dates/images identical. ❌ Missing all en/ku + localized `categoryLabel` (badge stays Arabic; `cat.*` keys dead).
- **Different:** Flutter news list has a back button (reference tab root has none); related-article tap uses `pushReplacement` (Back skips visited) vs reference `push`.
- **Missing:** focus-replay stagger animation, animated header entrance, scroll-linked navbar fade on detail.
- **Extra in Flutter:** image-failure placeholder icon.

## Cases

- **Central divergence:** reference is a **read-only remote viewer** (`getMyCases`, login-gated, loading spinner, pull-to-refresh, dynamic filter chips, localized status labels). Flutter is **local SharedPreferences CRUD** (add/edit/delete sheet) — a user's real firm cases never appear.
- Status badge/filter labels render raw Arabic enum strings in Flutter (`cases.status.*` keys dead); unknown backend statuses would mislabel as "active".
- Card shows court/type (Flutter) vs opened-date/lawyer (reference).
- **Extra in Flutter:** `+` add button, add-case bottom sheet, per-card delete + confirm.

## AI Assistant

- **Non-functional in Flutter:** reference calls real `aiChat(history)` (multi-turn, sends base64 image for analysis, real reply / `errorNotConfigured` / `errorNetwork`). Flutter **never contacts a server** — `_sendMessage` always fake-streams the "service not configured" message 12 chars at a time. Attached images are shown but never encoded/sent.

## Contact

- **Missing:** the `LanguageSwitcher` card (reference's primary in-app language control lives here — Flutter moved language to a home-header modal), real `createBooking` submission, apiKey gate, submitting spinner, network error messages (`submitFailed`/`submitThrottled`/`sessionExpired` dead).
- **Different:** required-field error is a SnackBar (Flutter) vs inline red text; submit button gold (Flutter) vs navy.
- **Parity OK:** call/WhatsApp/email quick actions, office info, working hours, form fields, auth-gate.

## Laws

- **Data:** same 7 laws, same ids/order. ✅ Constitution, Civil, Personal Status, Labor, Criminal Procedure, Commerce match exactly. ⚠️ **Penal Code differs:** Flutter has 9 chapters / 139 articles vs reference 6 / 96 (Flutter adds chapters p7–p9). Library totals diverge (Flutter 767 vs reference 724 articles).
- **Missing:** law/chapter title localization (EN/KU stay Arabic), the "unofficial translation" **disclaimer banner** (shown in reference when lang≠ar, 3 places; never shown in Flutter). Search is Arabic-only so EN/KU title search never matches.
- Article body text is Arabic-only on **both** sides (not a divergence).

## Navigation / Shell / i18n

- Tab bar: both have the 6 visible tabs in same order. Reference additionally **hides Cases for guests** (Flutter doesn't) and uses a native Liquid-Glass tab bar on iOS 26 (cosmetic).
- Languages identical: Arabic (default, RTL), English (LTR), Sorani Kurdish (RTL). Same persistence key `law_firm_lang_v1`, same fallback-to-Arabic engine.
- **Switcher UX differs:** reference = inline 3-segment control in Contact tab; Flutter = modal bottom sheet from a home-header globe icon.
- Theme/colors/fonts are a faithful dark-only port (gold `#C9A84C`, bg `#0D0D0D`, Cairo + NRT). ✅

---

## Suggested fix priority

**P0 — correctness / broken flows**
1. Service & Lawyer detail "Book consultation" CTAs go nowhere → route to Contact.
2. Add Profile screen (account info + sign-out + guest CTA).
3. Guest-gate the Cases tab.

**P1 — localization (large but mechanical)**
4. Convert Services/Lawyers/News/Laws models to `Localized {ar,en,ku}` and translate content, OR confirm Arabic-only is acceptable.
5. Localize status badges, news category labels, laws disclaimer.

**P2 — backend wiring (only if a backend is in scope for the Flutter build)**
6. Real OTP, cases fetch, AI chat, booking submission + `apiKey/apiSecret` on `AuthUser`.

**P3 — auth/login polish**
7. Country-code picker, Iraqi phone validation + error states, Apple-vs-Google decision, WhatsApp note.

**P4 — UI fidelity**
8. Lawyer 4-tab detail, `nextAvailable`/photos, card animations (rotation), RTL-aware icons, loading/empty states, services list back-button removal, Penal Code chapter reconciliation.
