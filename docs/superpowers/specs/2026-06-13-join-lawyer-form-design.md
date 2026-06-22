# Join-as-lawyer form (Flutter port)

**Date:** 2026-06-13
**Branch:** i18n-foundation

## Goal

The PWA (`law-firm-app`) contact tab shows a second form below the consultation
form: **"انضم الى فريقنا كمحامي" / "Join our team as a lawyer"**
(`components/JoinLawyerForm.tsx`). The Flutter app
(`lib/screens/contact_screen.dart`) currently has only the consultation form.
Port the join-as-lawyer form 1:1 into the Flutter app.

## Reference

- PWA widget: `apps/law-firm-app/components/JoinLawyerForm.tsx`
- PWA API: `apps/law-firm-app/lib/api.ts` → `createJoinRequest` →
  `create_join_request` (authenticated POST)
- PWA strings: `apps/law-firm-app/i18n/sections/contact.ts` (`join*` keys)

## Changes

### 1. API layer — `lib/services/api_service.dart`

Add a `JoinRequestPayload` class and a `createJoinRequest` method, mirroring the
existing `BookingPayload` / `createBooking` pair.

```dart
class JoinRequestPayload {
  final String fullName;
  final String phone;
  final int? graduationYear;
  final String? university;
  final String? currentJob;
  final String? idFileBase64;
  final String? idFilename;
  // toJson(): full_name, phone, graduation_year, university,
  //           current_job, id_file_base64, id_filename (omit nulls)
}

Future<String> createJoinRequest(JoinRequestPayload payload, AuthToken auth);
// POST create_join_request, authenticated, returns message['id'] ?? ''
```

### 2. i18n — `lib/i18n/sections/contact.dart`

Add, verbatim from the PWA (ar/en/ku): `joinTitle`, `joinSubtitle`,
`joinGradYearPlaceholder`, `joinUniversityPlaceholder`, `joinJobPlaceholder`,
`joinAttachId`, `joinFileInvalid`, `joinPhoneInvalid`, `joinYearInvalid`,
`joinAuthAction`. (`successMessage`, `errorRequired`, `submit`, `submitFailed`,
`submitThrottled`, `sessionExpired`, `namePlaceholder`, `phonePlaceholder`
already exist and are reused.)

### 3. Widget — new `lib/widgets/join_lawyer_form.dart`

`JoinLawyerForm` (StatefulWidget), self-contained (own input-field helper).

Fields: name*, phone*, graduation year (numeric, max 4), university,
current job, optional ID-image attach.

Constants (mirror PWA):
- `IRAQI_PHONE_RE = ^07\d{9}$`
- `MIN_GRADUATION_YEAR = 1950`
- allowed ID extensions: jpg, jpeg, png, webp, heic
- max ID file: 5 MB

Image picking: `image_picker` → `readAsBytes()` → `base64Encode`. Validate
extension + 5 MB byte cap before keeping; on failure set `joinFileInvalid`.
Show a thumbnail (from picked bytes via `Image.memory`) with a remove button.

Submit flow (mirror `contact_screen.dart` `_handleSubmit`):
- guest / no token → `showAuthSheet(context, actionLabel: t('contact.joinAuthAction'))`
- required: name + phone; `errorRequired` if missing
- phone must match Iraqi regex → `joinPhoneInvalid`
- if grad year present, must be int in `1950..DateTime.now().year` →
  `joinYearInvalid`
- call `createJoinRequest`; on success: haptic, success banner, 3s `Timer`
  then clear all fields. Errors mapped: `unauthorized`→`sessionExpired`+sheet,
  `throttled`→`submitThrottled`, else `submitFailed`.
- guard all `setState` after await with `mounted`; cancel `Timer` in `dispose`.

Styling matches the existing consultation card: `AppColors`, same rounded
input decoration, navy submit button with send icon / spinner.

### 4. Wire-up — `lib/screens/contact_screen.dart`

Append `const JoinLawyerForm()` as the last child of the contact `ListView`,
below the consultation form (matching the PWA's placement).

## Out of scope

- Backend changes (the `create_join_request` endpoint already exists, used by
  the PWA).
- Any change to the consultation form.

## Verification

- `flutter analyze` clean.
- Manual: form renders below consultation form; guest tap opens auth sheet;
  invalid phone / year / file show correct messages; success banner clears.
