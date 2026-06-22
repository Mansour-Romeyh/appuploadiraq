# Privacy Policy page + store-compliant account options — Design

**Date:** 2026-06-14
**Status:** Approved (pending spec review)

## Goal

Make the app compliant with Apple App Store and Google Play account/privacy
requirements by:

1. Publishing a Privacy Policy web page in the ERP, reachable at a stable URL.
2. Linking that page from the Flutter app's Profile screen.
3. Adding an in-app **Delete Account** flow (required by Apple guideline
   5.1.1(v) for any app with account creation; also required by Google Play),
   backed by a real backend endpoint.

## Store compliance mapping

| Requirement | Satisfied by |
| --- | --- |
| Apple 5.1.1(v): in-app account deletion | Profile → Delete Account → `delete_account` endpoint |
| Google Play: in-app deletion **and** web-accessible deletion request path | In-app flow + "Account deletion" section on `/privacy` with contact info |
| Both stores: published privacy policy URL | `https://justice-iq.org/privacy` (also added to store listings) |

The store *listing* fields (App Store Connect / Play Console) must be updated to
point at `https://justice-iq.org/privacy`. That is a console task outside this
codebase and is called out here as a reminder, not implemented in code.

## Part A — ERP backend (`law_firm` Frappe app)

App path: `/home/frappe/Frappe/polling/apps/law_firm/law_firm`
Served origin: `https://justice-iq.org`
Mobile API namespace: `law_firm.api.mobile`

### A1. Privacy page at `/privacy`

New files:

- `law_firm/www/privacy.html`
- `law_firm/www/privacy.py`

**`privacy.py`** — minimal context provider:

```python
import frappe

def get_context(context):
    context.no_cache = 1
```

The page is guest-accessible by default (standard for `www/` pages) and needs no
DB reads — content is static in the template.

**`privacy.html`** — styled to match the existing `www/index.html` landing page:

- Gold/dark theme, Noto Kufi Arabic font, Tailwind CDN config copied from index.
- Default `lang="ar" dir="rtl"`, with the same client-side **ar / en / ku**
  language switcher pattern index uses (text swapped in-page, no round-trip).
- Sections (all three languages), with a visible "Last updated: 2026-06-14":
  1. Intro / who we are
  2. **Data we collect** — name, phone number, email, OTP delivery logs
  3. **How we use it** — OTP login/authentication, consultation & case
     handling, AI legal-chat assistance
  4. **Third parties** — WhatsApp/SMS provider (OTP delivery), AI provider
     (chat). No selling of personal data.
  5. **Data retention & your rights** — access, correction, deletion
  6. **Account deletion** — explains the in-app path (Profile → Delete
     Account) and provides a contact email + phone for users who want to
     request deletion without the app. This is the Google Play web-accessible
     deletion path.
  7. **Contact us** — office contact details (reuse the contact info already
     used elsewhere in the app/site).

Content is drafted as a reasonable template; the user reviews and refines the
legal specifics.

### A2. New endpoint `delete_account` in `api/mobile.py`

```python
@frappe.whitelist(methods=["POST"])
def delete_account():
    """Disable and anonymize the calling user's account.

    Satisfies Apple 5.1.1(v) / Google Play in-app account deletion. Linked
    case/booking records are retained for legal/audit reasons; only the User's
    PII and credentials are scrubbed.
    """
    user_name = frappe.session.user
    if user_name in ("Guest", "Administrator"):
        frappe.throw(_("Cannot delete this account."))

    user = frappe.get_doc("User", user_name)
    user.enabled = 0            # drops from _find_user_by_phone (filters enabled=1); blocks login
    user.mobile_no = None       # remove the OTP-lookup key
    user.phone = None
    user.first_name = "Deleted User"
    user.last_name = ""
    user.full_name = "Deleted User"
    user.api_key = None         # revoke the current token immediately
    user.api_secret = None
    user.save(ignore_permissions=True)
    frappe.db.commit()
    return {"deleted": True}
```

Notes:

- Anonymizing `mobile_no` + `enabled=0` is the key privacy action: phone lookup
  in `_find_user_by_phone` filters on `enabled=1` and matches `mobile_no`, so a
  deleted user's number can never be re-found or re-logged-into.
- The User record `name` (login id / email) is preserved so existing document
  links don't break — but it carries no usable PII after scrubbing.
- Clearing `api_key`/`api_secret` invalidates the token the app is currently
  holding, so subsequent authed calls fail with 401 (the app logs out anyway).

## Part B — Flutter app

### B1. `ApiService.deleteAccount`

In `lib/services/api_service.dart`, mirroring the existing authed-call style
(e.g. `getMyCases`):

```dart
Future<void> deleteAccount(AuthToken auth) async {
  await _call('delete_account', method: 'POST', auth: auth);
}
```

### B2. `profile_screen.dart` — "Legal & account" section

Add a new card section below the account info, shown to everyone:

- **Privacy Policy** row (always visible, incl. guests) → opens the policy:
  `launchUrl(Uri.parse('$apiBaseUrl/privacy'), mode: LaunchMode.externalApplication)`
  (`url_launcher` is already a dependency; pattern matches `contact_screen.dart`).
- **Delete Account** row (logged-in users only; destructive/red styling) →
  two-step in-app confirmation reusing the existing `_confirming`-style card
  pattern, with an explicit warning that deletion is permanent and PII will be
  removed. On confirm:
  1. Call `ApiService.instance.deleteAccount(user.token!)`.
  2. On success: `AuthService.instance.logout()` then
     `Navigator.popUntil((r) => r.isFirst)` (same as sign-out).
  3. On failure: show an error (SnackBar) using `deleteError` string; stay
     signed in.

Rows are presented as tappable list rows with leading icon, label, and a
trailing chevron (`chevron_left` to match the RTL convention already adopted in
the office screens).

Guard: the Delete Account row only appears when `user != null && user.token != null`
(a real OTP session). Mock social logins without a token don't show it.

### B3. i18n

Add to `lib/i18n/sections/profile.dart` (ar / en / ku) — keys:

- `legalSection` — "Legal & account" section header
- `privacyPolicy` — "Privacy Policy"
- `deleteAccount` — "Delete account"
- `deleteConfirm` — confirmation question
- `deleteWarning` — permanence/PII-removal warning line
- `deleting` — in-progress label
- `deleteError` — failure message

## Components & boundaries

- **`privacy.html`/`privacy.py`** — self-contained static page; depends only on
  Frappe's www rendering. Testable by loading `/privacy`.
- **`delete_account`** — single endpoint; depends on the `User` doctype.
  Testable in isolation (call it, assert user disabled/scrubbed/token cleared).
- **`ApiService.deleteAccount`** — thin wrapper over `_call`; no new state.
- **`profile_screen` Legal section** — UI only; depends on `ApiService`,
  `AuthService`, `url_launcher`, and the new i18n keys.

## Error handling

- Endpoint refuses Guest/Administrator via `frappe.throw`.
- App surfaces `ApiException` from `deleteAccount` as a SnackBar; the user stays
  logged in so they can retry.
- Privacy link uses `externalApplication` mode; if no browser handles it,
  `url_launcher` throws — caught and surfaced as a SnackBar (same as contact).

## Testing

- Backend: a test that calls `delete_account` as a normal user and asserts
  `enabled == 0`, `mobile_no is None`, names anonymized, `api_key`/`api_secret`
  cleared; and that Guest/Administrator are refused.
- Flutter: widget-level check that the Privacy Policy row is always present and
  the Delete Account row only renders with an authenticated token; a unit check
  that `deleteAccount` issues a POST to `delete_account` with the auth header.

## Out of scope

- Terms of Service page (only Privacy Policy is store-required here).
- Hard deletion of the User record and cascading link cleanup.
- Updating the App Store Connect / Play Console listing fields (manual console
  task; noted above).
