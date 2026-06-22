# Backend-wired Services/News/Team + Team redesign + Contact update

**Date:** 2026-06-11
**Branch:** i18n-foundation
**Reference:** `/home/frappe/Frappe/polling/apps/law-firm-app/` (Expo/RN, backend-wired)
**Backend:** `law_firm.api.mobile.{get_services,get_news,get_team}` at `https://justice-iq.org`

## Goal

Make the Flutter app render Legal Service, Legal News, and Legal Team Member data
**from the backend only** (no bundled fallback), localize that content (`{ar,en,ku}`),
bring the Team list card + Lawyer detail to **visual parity with the PWA**, and apply
the PWA's Contact-screen updates.

Scope is limited to these three feeds + Contact. AI, Cases, Login/OTP, Laws, and Profile
are explicitly out of scope.

## Backend contracts (already live)

- `get_services` → `[{ id, title:Loc, description:Loc, details:Loc, bullets:[Loc], icon:string, color:string }]`
  - `icon` = Feather name (`shield, heart, briefcase, home, users, flag, award, git-merge`); `color` = `#RRGGBB`.
- `get_news` → `[{ id, category:string, categoryLabel:Loc, title:Loc, summary:Loc, content:Loc, date:string, imageUrl:string }]`
  - `category` is a stable Arabic key used only for accent-color lookup; `categoryLabel` is displayed.
- `get_team` → `[{ id, name:Loc, title:Loc, specialty:Loc, experience:int, cases:int, bio:Loc, education:Loc, phone, email, available:bool, nextAvailable:Loc, photoUrl:string }]`

`Loc` = `{ar, en, ku}`. The existing `lib/i18n/localized.dart` `Localized` class already
parses this via `Localized.fromJson`.

## Changes

### Models (`lib/models/`)
- **`Lawyer`** — `name/title/specialty/bio/education/nextAvailable` → `Localized`; add `photoUrl:String`; keep `experience/cases/phone/email/available`. Add `Lawyer.fromJson`.
- **`LegalService`** — `title/description/details` → `Localized`; `bullets` → `List<Localized>`; `icon` → `String`; `color` → `String`. Drop the `IconData`/`Color` fields. Add `LegalService.fromJson`.
- **`NewsItem`** — `title/summary/content` → `Localized`; add `categoryLabel:Localized`; `category` stays `String`; keep `date/imageUrl`. Add `NewsItem.fromJson`.
- Delete static `lib/data/services.dart`, `lib/data/news.dart`, `lib/data/lawyers.dart`.

### Helpers
- `lib/widgets/feather_icons.dart` — `IconData featherIcon(String)` mapping the 8 Feather names to the Material icons the app already used (shield→`shield_outlined`, heart→`favorite_border`, briefcase→`work_outline`, home→`home_outlined`, users→`people_outline`, flag→`flag_outlined`, award→`workspace_premium_outlined`, git-merge→`call_merge`), default `Icons.gavel`. Plus `Color parseHexColor(String)`.
- `tr(Localized)` convenience resolving against `LanguageService.instance.lang` (co-located with `Localized` or a small `lib/i18n/tr.dart`).
- `Icon3D.icon` stays `IconData`; service callers pass `featherIcon(service.icon)` and `parseHexColor(service.color)`.
- Lawyer card/detail avatar color: existing `lawyerAvatarColor` keyed by `int.parse(id) % 5`.

### Remote content store (`lib/services/content_service.dart`)
- Singleton with **memoized futures** `services()/news()/team()` (one fetch per session, shared by home + list + detail) and `retryServices()/retryNews()/retryTeam()` that null the cache.
- `ApiService.getServices/getNews/getTeam` change return type from `List<dynamic>` to parsed `List<LegalService>/List<NewsItem>/List<Lawyer>`.
- **`RemoteBuilder<T>`** widget (`lib/widgets/remote_builder.dart`) wraps a memoized future: spinner while loading, error + Retry button (`components.error.retry`) on failure, empty-text slot, else `builder(data)`. Detail screens reuse the same future and `firstWhere(id)` (→ `notFound` text when absent).

### Screen rewiring
- **Home** — wrap the Services strip and News list in the loading/empty pattern (inline gold spinner, then `home.noServices`/`home.noNews`, else content), matching the PWA. Uses `ContentService` futures.
- **Services list / Service detail** — `RemoteBuilder`; resolve `Localized` via `tr`; icon via `featherIcon`/`parseHexColor`.
- **News list / News detail** — `RemoteBuilder`; `categoryLabel` for the badge text, `category` key for color; related list from the same future.
- **Team list / Lawyer detail** — see below.
- **Cards** (`ServiceCard`, `NewsCard`, `LawyerCard`) take the localized models and resolve with `tr`.
- Language switches already rebuild the whole tree (MaterialApp under `ListenableBuilder(LanguageService)`), so content re-resolves with no per-screen wiring.

### Team list card → PWA parity (`LawyerCard`)
Rounded card, `overflow: clip`. Top row: photo `Image.network` (or colored initials box) 96px wide, `borderRadius 12`, stretched to row height, at the start edge; info column (name bold, title muted, green experience badge = calendar icon + `"{experience} {experienceUnit}"`); favorite heart (local `setState` toggle, outline↔filled) pinned top-end. Footer bar: `muted` bg + top border, "Next available" label (clock icon + `team.nextAvailable`) at start, gold `tr(nextAvailable)` at end. Initials = words[1..3] of resolved name. Drop the old chevron/specialty/available-pill row.

### Lawyer detail → PWA parity (4-tab)
- Navy hero: circular back button; row of [info column (specialty muted, name bold, gold title) + 96px photo/avatar `borderRadius 18`]; two stat chips on translucent white (users icon + `+cases` + `casesCompleted`; briefcase + `"{experience} {experienceUnit}"` + `tabExperience`).
- Tab bar: About / Availability / Experience / Education, gold underline on active.
- **About**: bio paragraph + 2-col info-card grid — specialty (`infoSpecialty`), completed cases (`infoCompletedCases`, `"+{cases} {casesUnit}"`), next available (`infoNextAvailable`), status (`infoStatus` → `availableNow`/`notAvailable`). Each card: gold-tint round icon, muted label, foreground value.
- **Availability**: section card, clock icon, `infoNextAvailable` title, gold `nextAvailable` value, available/not badge (green/red dot + text).
- **Experience**: section card, briefcase, title, `"{experience} {experienceDescription}"` prose.
- **Education**: section card, book icon, `educationTitle`, `tr(education)`.
- Solid **gold** "Book appointment" (`team.bookAppointment`) → switch to Contact tab via `TabSwitcher`. **Removes** the current phone/email buttons.

### Contact (تواصل معنا) update
- New `lib/widgets/language_switcher.dart` — 3-segment control (العربية/English/کوردی from `langOrder`/`langMeta`), gold active pill, calls `LanguageService.setLang`. Rendered in a card at the top of the Contact form list (before quick actions).
- Update default contact constants to the PWA's: `_phone = '+964 786 900 8003'`, `_email = 'info@justice-iq.org'`, `_whatsapp = '9647869008003'`. (Inline error text + submit spinner already present.)

## Verification
- `flutter analyze` clean.
- `flutter test` (existing `test/i18n_keys_resolve_test.dart` green; update if it referenced deleted static data).
- Manual smoke: each rewired screen loads from backend; language toggle re-localizes service/news/lawyer content; Team card + detail match the PWA; Contact shows the switcher and new contact info.

## Risks / notes
- All i18n keys required already exist in `team`, `contact`, `common`, `home`, `components` sections (verified).
- No static fallback by design — a failed fetch shows retry (list/detail) or empty text (home), per PWA.
- `feather_icons.dart` is a fixed map, not a font dependency — keeps the build lean and reuses the app's existing Material icon choices.
