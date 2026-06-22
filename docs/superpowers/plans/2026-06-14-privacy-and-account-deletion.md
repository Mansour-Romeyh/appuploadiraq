# Privacy Policy page + store-compliant account options — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a Privacy Policy page in the ERP, link it from the Flutter app, and add an in-app Delete Account flow so the app satisfies Apple 5.1.1(v) and Google Play account/privacy requirements.

**Architecture:** Two codebases. The Frappe `law_firm` app gets a static `/privacy` web page and a `delete_account` mobile API endpoint that disables + anonymizes the calling user. The Flutter app's Profile screen gets a "Legal & account" card with a Privacy Policy link (opens `/privacy` in the browser) and a Delete Account flow (two-step confirm → calls the endpoint → logs out).

**Tech Stack:** Frappe (Python, `www/` pages, `@frappe.whitelist`), Flutter/Dart (`url_launcher`, `http`, existing `ApiService`/`AuthService` singletons), trilingual i18n (ar/en/ku).

**Spec:** `docs/superpowers/specs/2026-06-14-privacy-and-account-deletion-design.md`

## Key paths & commands

- Frappe app root: `/home/frappe/Frappe/polling/apps/law_firm/law_firm`
- Frappe bench: `/home/frappe/Frappe/polling` — site `law.site`
- Run backend tests:
  `cd /home/frappe/Frappe/polling && bench --site law.site run-tests --module law_firm.tests.test_mobile_api`
- Flutter app root: `/home/frappe/Flutter/dill_adala`
- Flutter SDK (not on PATH): `export PATH="$PATH:/home/frappe/.flutter-sdk/bin"`
- Run a Flutter test: `cd /home/frappe/Flutter/dill_adala && flutter test test/<file>.dart`
- Flutter static analysis: `cd /home/frappe/Flutter/dill_adala && flutter analyze`

## File structure

**Backend (`law_firm`):**
- Modify: `law_firm/api/mobile.py` — add `delete_account` endpoint
- Create: `law_firm/www/privacy.py` — page context
- Create: `law_firm/www/privacy.html` — trilingual privacy policy page
- Modify: `law_firm/tests/test_mobile_api.py` — add `TestDeleteAccount`, `TestPrivacyPage`

**Flutter (`dill_adala`):**
- Modify: `lib/services/api_service.dart` — add `deleteAccount`
- Modify: `lib/i18n/sections/profile.dart` — add 7 keys (ar/en/ku)
- Modify: `lib/screens/profile_screen.dart` — add "Legal & account" section + delete flow
- Create: `test/profile_legal_section_test.dart` — widget test for row visibility

---

## Task 1: Backend — `delete_account` endpoint

**Files:**
- Modify: `/home/frappe/Frappe/polling/apps/law_firm/law_firm/api/mobile.py`
- Test: `/home/frappe/Frappe/polling/apps/law_firm/law_firm/tests/test_mobile_api.py`

- [ ] **Step 1: Write the failing test**

Append this class to the end of `tests/test_mobile_api.py`:

```python
class TestDeleteAccount(FrappeTestCase):
	DEL_EMAIL = "delete-test-user@example.com"

	@classmethod
	def setUpClass(cls):
		super().setUpClass()
		if not frappe.db.exists("User", cls.DEL_EMAIL):
			frappe.get_doc(
				{
					"doctype": "User",
					"email": cls.DEL_EMAIL,
					"first_name": "Delete Me",
					"mobile_no": "0770 999 0009",
					"send_welcome_email": 0,
				}
			).insert(ignore_permissions=True)

	def setUp(self):
		# reset to a known live state before each test
		user = frappe.get_doc("User", self.DEL_EMAIL)
		user.enabled = 1
		user.mobile_no = "0770 999 0009"
		user.first_name = "Delete Me"
		user.last_name = ""
		user.full_name = "Delete Me"
		user.save(ignore_permissions=True)

	def tearDown(self):
		frappe.set_user("Administrator")

	def test_delete_account_disables_and_anonymizes(self):
		mobile._issue_credentials(self.DEL_EMAIL)
		frappe.set_user(self.DEL_EMAIL)
		result = mobile.delete_account()
		frappe.set_user("Administrator")
		self.assertTrue(result["deleted"])
		user = frappe.get_doc("User", self.DEL_EMAIL)
		self.assertEqual(user.enabled, 0)
		self.assertFalse(user.mobile_no)
		self.assertFalse(user.phone)
		self.assertEqual(user.full_name, "Deleted User")
		self.assertFalse(user.api_key)
		self.assertFalse(user.api_secret)

	def test_deleted_user_no_longer_found_by_phone(self):
		mobile._issue_credentials(self.DEL_EMAIL)
		frappe.set_user(self.DEL_EMAIL)
		mobile.delete_account()
		frappe.set_user("Administrator")
		found = mobile._find_user_by_phone("+9647709990009", "964")
		self.assertNotEqual(found, self.DEL_EMAIL)

	def test_guest_cannot_delete(self):
		frappe.set_user("Guest")
		with self.assertRaises(frappe.exceptions.ValidationError):
			mobile.delete_account()

	def test_administrator_cannot_delete(self):
		frappe.set_user("Administrator")
		with self.assertRaises(frappe.exceptions.ValidationError):
			mobile.delete_account()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/frappe/Frappe/polling && bench --site law.site run-tests --module law_firm.tests.test_mobile_api`
Expected: FAIL — `AttributeError: module 'law_firm.api.mobile' has no attribute 'delete_account'`.

- [ ] **Step 3: Write minimal implementation**

Append this function to `api/mobile.py` (end of file is fine; it uses `frappe`, already imported):

```python
@frappe.whitelist(methods=["POST"])
def delete_account():
	"""Disable and anonymize the calling user's account.

	Satisfies Apple 5.1.1(v) / Google Play in-app account deletion. Linked
	case/booking records are retained for legal/audit reasons; only the User's
	PII and credentials are scrubbed. Disabling + clearing mobile_no removes the
	number from _find_user_by_phone (which filters enabled=1), so it can never be
	re-found or re-logged-into.
	"""
	user_name = frappe.session.user
	if user_name in ("Guest", "Administrator"):
		frappe.throw(frappe._("This account cannot be deleted."))

	user = frappe.get_doc("User", user_name)
	user.enabled = 0
	user.mobile_no = None
	user.phone = None
	user.first_name = "Deleted User"
	user.last_name = ""
	user.full_name = "Deleted User"
	user.api_key = None
	user.api_secret = None
	user.save(ignore_permissions=True)
	frappe.db.commit()
	return {"deleted": True}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/frappe/Frappe/polling && bench --site law.site run-tests --module law_firm.tests.test_mobile_api`
Expected: PASS (all `TestDeleteAccount` tests green, existing tests still green).

- [ ] **Step 5: Commit**

```bash
cd /home/frappe/Frappe/polling/apps/law_firm
git add law_firm/api/mobile.py law_firm/tests/test_mobile_api.py
git commit -m "feat(mobile): delete_account endpoint — disable + anonymize user

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Backend — Privacy Policy page at `/privacy`

**Files:**
- Create: `/home/frappe/Frappe/polling/apps/law_firm/law_firm/www/privacy.py`
- Create: `/home/frappe/Frappe/polling/apps/law_firm/law_firm/www/privacy.html`
- Test: `/home/frappe/Frappe/polling/apps/law_firm/law_firm/tests/test_mobile_api.py`

- [ ] **Step 1: Write the failing test**

Append this class to the end of `tests/test_mobile_api.py`:

```python
class TestPrivacyPage(FrappeTestCase):
	def test_get_context_sets_no_cache(self):
		from law_firm.www import privacy

		ctx = frappe._dict()
		privacy.get_context(ctx)
		self.assertEqual(ctx.no_cache, 1)

	def test_privacy_html_has_required_compliance_sections(self):
		import os

		import law_firm

		path = os.path.join(
			os.path.dirname(law_firm.__file__), "www", "privacy.html"
		)
		with open(path, encoding="utf-8") as f:
			html = f.read().lower()
		# store-compliance markers that must always be present
		for marker in (
			'id="account-deletion"',
			'id="contact"',
			'id="data-collected"',
			"delete_account",
		):
			self.assertIn(marker, html)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/frappe/Frappe/polling && bench --site law.site run-tests --module law_firm.tests.test_mobile_api`
Expected: FAIL — `ModuleNotFoundError`/`ImportError` for `law_firm.www.privacy` (file does not exist yet).

- [ ] **Step 3a: Create `www/privacy.py`**

Create `/home/frappe/Frappe/polling/apps/law_firm/law_firm/www/privacy.py`:

```python
import frappe


def get_context(context):
	# Public, always-fresh legal page. Logged-in users may also view it.
	context.no_cache = 1
```

- [ ] **Step 3b: Create `www/privacy.html`**

Create `/home/frappe/Frappe/polling/apps/law_firm/law_firm/www/privacy.html`. This is a self-contained trilingual page (default Arabic/RTL) with a client-side ar/en/ku switcher mirroring `www/index.html`'s theme. The English `delete_account` reference and the section `id`s are required by the test above.

```html
{% raw %}
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>سياسة الخصوصية | ظل العدالة</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@300;400;500;600;700;800&family=Noto+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: { extend: {
                colors: {
                    gold: { 400: '#D4AF37', 500: '#C5A028', 700: '#8A6E1A' },
                    dark: { 200: '#1E1E1E', 400: '#141414', 500: '#101010', 900: '#030303' }
                },
                fontFamily: { kufi: ['Noto Kufi Arabic','sans-serif'], sans: ['Noto Sans','sans-serif'] }
            } }
        }
    </script>
    <style>
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:'Noto Kufi Arabic',sans-serif; background:#050505; color:#e9e9e9; line-height:1.9; }
        html[lang="en"] body { font-family:'Noto Sans',sans-serif; }
        a { color:#D4AF37; }
        h1,h2 { color:#fff; }
        .wrap { max-width:820px; margin:0 auto; padding:48px 20px 96px; }
        h1 { font-size:30px; font-weight:800; margin-bottom:8px; }
        h2 { font-size:20px; font-weight:700; margin:32px 0 10px; }
        p, li { color:#cfcfcf; font-size:15px; margin-bottom:10px; }
        ul { padding-inline-start:22px; }
        .meta { color:#8a8a8a; font-size:13px; margin-bottom:24px; }
        .card { background:#101010; border:1px solid #1f1f1f; border-radius:14px; padding:18px 20px; margin-top:14px; }
        .switch { position:fixed; top:14px; inset-inline-end:14px; display:flex; gap:6px; z-index:10; }
        .switch button { background:#1E1E1E; color:#cfcfcf; border:1px solid #2a2a2a; border-radius:8px; padding:6px 12px; font-size:13px; cursor:pointer; }
        .switch button.active { background:#D4AF37; color:#101010; border-color:#D4AF37; font-weight:700; }
        [data-lang] { display:none; }
    </style>
</head>
<body>
    <div class="switch">
        <button data-set="ar" class="active" onclick="setLang('ar')">عربي</button>
        <button data-set="en" onclick="setLang('en')">EN</button>
        <button data-set="ku" onclick="setLang('ku')">کوردی</button>
    </div>

    <div class="wrap">
        <!-- ARABIC -->
        <div data-lang="ar" style="display:block">
            <h1>سياسة الخصوصية</h1>
            <p class="meta">آخر تحديث: 14 حزيران 2026 — تطبيق وموقع «ظل العدالة»</p>
            <p>تحترم شركة ظل العدالة للمحاماة خصوصيتك. توضّح هذه السياسة البيانات التي نجمعها وكيفية استخدامها وحقوقك تجاهها.</p>

            <h2 id="data-collected-ar">البيانات التي نجمعها</h2>
            <ul>
                <li>الاسم الكامل.</li>
                <li>رقم الهاتف (يُستخدم لتسجيل الدخول عبر رمز التحقق OTP).</li>
                <li>البريد الإلكتروني (إن وُجد).</li>
                <li>سجلّات إرسال رموز التحقق (الوقت وحالة الإرسال).</li>
            </ul>

            <h2>كيف نستخدم بياناتك</h2>
            <ul>
                <li>تسجيل الدخول والتحقق من الهوية عبر رمز OTP.</li>
                <li>إدارة الاستشارات والقضايا والطلبات القانونية.</li>
                <li>تشغيل المساعد القانوني الذكي للإجابة على استفساراتك.</li>
            </ul>

            <h2>مشاركة البيانات مع أطراف ثالثة</h2>
            <p>نشارك الحد الأدنى من البيانات مع مزوّدي الخدمة الضروريين فقط: مزوّد رسائل واتساب/الرسائل النصية لإرسال رمز التحقق، ومزوّد خدمة الذكاء الاصطناعي لتشغيل المساعد القانوني. لا نبيع بياناتك الشخصية لأي جهة.</p>

            <h2>الاحتفاظ بالبيانات وحقوقك</h2>
            <p>نحتفظ ببياناتك طالما كان حسابك فعّالاً أو وفق ما يقتضيه الالتزام القانوني. يحق لك الوصول إلى بياناتك أو تصحيحها أو حذف حسابك.</p>

            <div class="card" id="account-deletion-ar">
                <h2>حذف الحساب</h2>
                <p>يمكنك حذف حسابك مباشرةً من داخل التطبيق عبر: <strong>الملف الشخصي ← حذف الحساب</strong>. عند الحذف يتم تعطيل الحساب وإزالة بياناتك الشخصية (الاسم ورقم الهاتف والبريد الإلكتروني).</p>
                <p>وإن رغبت في طلب الحذف دون استخدام التطبيق، راسلنا على البريد أدناه وسننفّذ الطلب.</p>
            </div>

            <h2 id="contact-ar">تواصل معنا</h2>
            <p>البريد الإلكتروني: <a href="mailto:info@justice-iq.org">info@justice-iq.org</a><br>الهاتف: <a href="tel:+9647700000000">+964 770 000 0000</a></p>
        </div>

        <!-- ENGLISH -->
        <div data-lang="en">
            <h1>Privacy Policy</h1>
            <p class="meta">Last updated: 14 June 2026 — “Dill Adala” (Justice Shadow) app &amp; website</p>
            <p>Dill Adala Law Firm respects your privacy. This policy explains what data we collect, how we use it, and your rights.</p>

            <h2 id="data-collected">Data we collect</h2>
            <ul>
                <li>Full name.</li>
                <li>Phone number (used to sign in via a one-time code, OTP).</li>
                <li>Email address (if provided).</li>
                <li>OTP delivery logs (time and delivery status).</li>
            </ul>

            <h2>How we use your data</h2>
            <ul>
                <li>Sign-in and identity verification via OTP.</li>
                <li>Handling consultations, cases, and legal requests.</li>
                <li>Powering the AI legal assistant to answer your questions.</li>
            </ul>

            <h2>Third parties</h2>
            <p>We share the minimum necessary data only with essential service providers: a WhatsApp/SMS provider to deliver your OTP, and an AI provider to power the legal assistant. We do not sell your personal data.</p>

            <h2>Retention &amp; your rights</h2>
            <p>We retain your data while your account is active or as required by law. You may access or correct your data, or delete your account.</p>

            <div class="card" id="account-deletion">
                <h2>Account deletion</h2>
                <p>You can delete your account directly in the app: <strong>Profile → Delete account</strong>. This calls our <code>delete_account</code> service, which disables the account and removes your personal data (name, phone, email).</p>
                <p>If you prefer to request deletion without the app, email us at the address below and we will process your request.</p>
            </div>

            <h2 id="contact">Contact us</h2>
            <p>Email: <a href="mailto:info@justice-iq.org">info@justice-iq.org</a><br>Phone: <a href="tel:+9647700000000">+964 770 000 0000</a></p>
        </div>

        <!-- KURDISH -->
        <div data-lang="ku">
            <h1>سیاسەتی تایبەتمەندی</h1>
            <p class="meta">دوایین نوێکردنەوە: ١٤ی حوزەیرانی ٢٠٢٦ — ئەپ و ماڵپەڕی «سێبەری دادپەروەری»</p>
            <p>کۆمپانیای یاسایی سێبەری دادپەروەری ڕێز لە تایبەتمەندیت دەگرێت. ئەم سیاسەتە ڕوونی دەکاتەوە چ زانیارییەک کۆدەکەینەوە و چۆن بەکاری دەهێنین و مافەکانت چین.</p>

            <h2 id="data-collected-ku">ئەو زانیاریانەی کۆیان دەکەینەوە</h2>
            <ul>
                <li>ناوی تەواو.</li>
                <li>ژمارەی تەلەفۆن (بۆ چوونەژوورەوە بە کۆدی OTP بەکاردێت).</li>
                <li>ئیمەیڵ (ئەگەر هەبێت).</li>
                <li>تۆماری ناردنی کۆدەکان (کات و دۆخی ناردن).</li>
            </ul>

            <h2>چۆن زانیارییەکانت بەکاردەهێنین</h2>
            <ul>
                <li>چوونەژوورەوە و پشتڕاستکردنەوەی ناسنامە بە OTP.</li>
                <li>بەڕێوەبردنی ڕاوێژکاری و کەیس و داواکاری یاسایی.</li>
                <li>کارپێکردنی یاریدەدەری یاسایی زیرەک بۆ وەڵامی پرسیارەکانت.</li>
            </ul>

            <h2>لایەنی سێیەم</h2>
            <p>تەنها کەمترین زانیاری پێویست لەگەڵ دابینکەرانی پێویست هاوبەش دەکەین: دابینکەری واتساب/SMS بۆ ناردنی کۆد، و دابینکەری AI بۆ یاریدەدەری یاسایی. زانیاری کەسیت نافرۆشین.</p>

            <h2>هەڵگرتن و مافەکانت</h2>
            <p>زانیارییەکانت هەڵدەگرین تا کاتێک هەژمارەکەت چالاکە یان بەپێی پێویستی یاسایی. مافی ئەوەت هەیە بگەیتە زانیارییەکانت، ڕاستیان بکەیتەوە، یان هەژمارەکەت بسڕیتەوە.</p>

            <div class="card" id="account-deletion-ku">
                <h2>سڕینەوەی هەژمار</h2>
                <p>دەتوانیت هەژمارەکەت ڕاستەوخۆ لە ئەپەکەدا بسڕیتەوە بە: <strong>پرۆفایل ← سڕینەوەی هەژمار</strong>. لە سڕینەوەدا هەژمارەکە ناچالاک دەکرێت و زانیاری کەسیت (ناو، ژمارە، ئیمەیڵ) لادەبرێت.</p>
                <p>ئەگەر دەتەوێت بەبێ ئەپ داوای سڕینەوە بکەیت، لە ئیمەیڵی خوارەوە پەیوەندیمان پێوە بکە.</p>
            </div>

            <h2 id="contact-ku">پەیوەندیمان پێوە بکە</h2>
            <p>ئیمەیڵ: <a href="mailto:info@justice-iq.org">info@justice-iq.org</a><br>تەلەفۆن: <a href="tel:+9647700000000">+964 770 000 0000</a></p>
        </div>
    </div>

    <script>
        function setLang(lang) {
            var dir = (lang === 'en') ? 'ltr' : 'rtl';
            document.documentElement.lang = lang;
            document.documentElement.dir = dir;
            document.querySelectorAll('[data-lang]').forEach(function (el) {
                el.style.display = (el.getAttribute('data-lang') === lang) ? 'block' : 'none';
            });
            document.querySelectorAll('.switch button').forEach(function (b) {
                b.classList.toggle('active', b.getAttribute('data-set') === lang);
            });
        }
    </script>
</body>
</html>
{% endraw %}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/frappe/Frappe/polling && bench --site law.site run-tests --module law_firm.tests.test_mobile_api`
Expected: PASS (`TestPrivacyPage` green).

- [ ] **Step 5: Manual visual verification**

Run: `cd /home/frappe/Frappe/polling && bench --site law.site clear-cache`
Then open `https://justice-iq.org/privacy` (or the local site URL) in a browser. Confirm: Arabic shows by default (RTL), the EN/کوردی buttons switch language and direction, and the Account deletion + Contact sections render.

- [ ] **Step 6: Commit**

```bash
cd /home/frappe/Frappe/polling/apps/law_firm
git add law_firm/www/privacy.py law_firm/www/privacy.html law_firm/tests/test_mobile_api.py
git commit -m "feat(www): trilingual privacy policy page at /privacy

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Flutter — `ApiService.deleteAccount`

**Files:**
- Modify: `/home/frappe/Flutter/dill_adala/lib/services/api_service.dart`

> Note: `ApiService` constructs its `http.Client` internally (no dependency
> injection) and the codebase has no ApiService HTTP-level tests. We follow that
> convention — `deleteAccount` is a thin wrapper verified by compilation
> (`flutter analyze`) and exercised through the Profile screen. No brittle
> network unit test is added.

- [ ] **Step 1: Add the method**

In `lib/services/api_service.dart`, find the "Lawyer workspace" authed section (e.g. `lawyerListIntakes`). Add this method just above it (after `getMyCases`):

```dart
  /// Deletes (disables + anonymizes) the authenticated user's account.
  /// Backend: law_firm.api.mobile.delete_account.
  Future<void> deleteAccount(AuthToken auth) async {
    await _call('delete_account', method: 'POST', auth: auth);
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /home/frappe/Flutter/dill_adala && export PATH="$PATH:/home/frappe/.flutter-sdk/bin" && flutter analyze lib/services/api_service.dart`
Expected: No issues found (or only pre-existing unrelated infos).

- [ ] **Step 3: Commit**

```bash
cd /home/frappe/Flutter/dill_adala
git add lib/services/api_service.dart
git commit -m "feat(api): deleteAccount wrapper for delete_account endpoint

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Flutter — i18n keys for the Legal & account section

**Files:**
- Modify: `/home/frappe/Flutter/dill_adala/lib/i18n/sections/profile.dart`

The existing `test/i18n_keys_resolve_test.dart` scans `lib/` for every `t('...')`
key and fails if one is missing from the catalog, so adding these keys is what
unblocks Task 5. The `profile` section is already registered in `strings.dart`.

- [ ] **Step 1: Add the keys**

In `lib/i18n/sections/profile.dart`, insert these entries into the `profile`
map, just before the closing `};` (after the `signIn` entry):

```dart
  // legal & account section (store compliance)
  'legalSection': {
    Lang.ar: 'الخصوصية والحساب',
    Lang.en: 'Privacy & account',
    Lang.ku: 'تایبەتمەندی و هەژمار',
  },
  'privacyPolicy': {
    Lang.ar: 'سياسة الخصوصية',
    Lang.en: 'Privacy Policy',
    Lang.ku: 'سیاسەتی تایبەتمەندی',
  },
  'deleteAccount': {
    Lang.ar: 'حذف الحساب',
    Lang.en: 'Delete account',
    Lang.ku: 'سڕینەوەی هەژمار',
  },
  'deleteConfirm': {
    Lang.ar: 'هل أنت متأكد من حذف حسابك؟',
    Lang.en: 'Are you sure you want to delete your account?',
    Lang.ku: 'دڵنیایت دەتەوێت هەژمارەکەت بسڕیتەوە؟',
  },
  'deleteWarning': {
    Lang.ar: 'سيتم تعطيل حسابك وإزالة بياناتك الشخصية نهائيًا. لا يمكن التراجع عن هذا الإجراء.',
    Lang.en: 'Your account will be disabled and your personal data permanently removed. This cannot be undone.',
    Lang.ku: 'هەژمارەکەت ناچالاک دەکرێت و زانیاری کەسیت بۆ هەمیشە لادەبرێت. ناگەڕێتەوە.',
  },
  'deleting': {
    Lang.ar: 'جارٍ الحذف…',
    Lang.en: 'Deleting…',
    Lang.ku: 'سڕینەوە…',
  },
  'deleteError': {
    Lang.ar: 'تعذّر حذف الحساب. حاول مرة أخرى.',
    Lang.en: 'Could not delete the account. Please try again.',
    Lang.ku: 'سڕینەوەی هەژمار سەرکەوتوو نەبوو. دووبارە هەوڵ بدە.',
  },
```

- [ ] **Step 2: Verify keys resolve**

Run: `cd /home/frappe/Flutter/dill_adala && export PATH="$PATH:/home/frappe/.flutter-sdk/bin" && flutter test test/i18n_keys_resolve_test.dart test/catalog_test.dart`
Expected: PASS (no unresolved keys; the section still resolves across all langs).

- [ ] **Step 3: Commit**

```bash
cd /home/frappe/Flutter/dill_adala
git add lib/i18n/sections/profile.dart
git commit -m "i18n(profile): keys for privacy policy + delete account

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Flutter — Profile screen "Privacy & account" section + delete flow

**Files:**
- Modify: `/home/frappe/Flutter/dill_adala/lib/screens/profile_screen.dart`
- Test: `/home/frappe/Flutter/dill_adala/test/profile_legal_section_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/profile_legal_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dill_adala/i18n/strings.dart';
import 'package:dill_adala/screens/profile_screen.dart';
import 'package:dill_adala/services/auth_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('guest sees Privacy Policy but not Delete account',
      (tester) async {
    await AuthService.instance.logout();
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text(t('profile.privacyPolicy')), findsOneWidget);
    expect(find.text(t('profile.deleteAccount')), findsNothing);
  });

  testWidgets('authenticated user sees both Privacy Policy and Delete account',
      (tester) async {
    await AuthService.instance.login(const AuthUser(
      name: 'Test User',
      phone: '+9647700000000',
      method: AuthMethod.phone,
      apiKey: 'k',
      apiSecret: 's',
    ));
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text(t('profile.privacyPolicy')), findsOneWidget);
    expect(find.text(t('profile.deleteAccount')), findsOneWidget);

    await AuthService.instance.logout();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/frappe/Flutter/dill_adala && export PATH="$PATH:/home/frappe/.flutter-sdk/bin" && flutter test test/profile_legal_section_test.dart`
Expected: FAIL — `Privacy Policy` text not found (section not built yet).

- [ ] **Step 3a: Add imports**

At the top of `lib/screens/profile_screen.dart`, add these imports alongside the
existing ones:

```dart
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
```

- [ ] **Step 3b: Add delete-flow state**

In `_ProfileScreenState`, replace the existing field line:

```dart
  bool _confirming = false;
```

with:

```dart
  bool _confirming = false;
  bool _deleteConfirming = false;
  bool _deleting = false;
```

- [ ] **Step 3c: Render the section + the delete-confirm card**

In `build`, inside the authenticated branch, the current code is:

```dart
                      if (user != null) ...[
                        _accountSection(user),
                        const SizedBox(height: 16),
                        if (_confirming) _confirmCard() else _signOutButton(),
                      ] else
                        _signInButton(),
```

Replace it with:

```dart
                      if (user != null) ...[
                        _accountSection(user),
                        const SizedBox(height: 16),
                        if (_confirming) _confirmCard() else _signOutButton(),
                        const SizedBox(height: 16),
                        _legalSection(showDelete: user.token != null),
                        if (_deleteConfirming) ...[
                          const SizedBox(height: 12),
                          _deleteConfirmCard(),
                        ],
                      ] else ...[
                        _signInButton(),
                        const SizedBox(height: 16),
                        _legalSection(showDelete: false),
                      ],
```

- [ ] **Step 3d: Add the handler + widget methods**

Add these methods inside `_ProfileScreenState` (e.g. just after `_handleSignOut`):

```dart
  Future<void> _openPrivacy() async {
    HapticFeedback.selectionClick();
    await launchUrl(
      Uri.parse('$apiBaseUrl/privacy'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _handleDelete() async {
    final token = AuthService.instance.user?.token;
    if (token == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _deleting = true);
    try {
      await ApiService.instance.deleteAccount(token);
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _deleteConfirming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('profile.deleteError'))),
      );
    }
  }

  Widget _legalSection({required bool showDelete}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('profile.legalSection'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: cardShadow,
          ),
          child: Column(
            children: [
              _LinkRow(
                icon: Icons.privacy_tip_outlined,
                label: t('profile.privacyPolicy'),
                onTap: _openPrivacy,
              ),
              if (showDelete) ...[
                const _Divider(),
                _LinkRow(
                  icon: Icons.delete_outline,
                  label: t('profile.deleteAccount'),
                  destructive: true,
                  onTap: () => setState(() => _deleteConfirming = true),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _deleteConfirmCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.destructive.withAlpha(0x55)),
        boxShadow: cardShadow,
      ),
      child: Column(
        children: [
          Text(
            t('profile.deleteConfirm'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('profile.deleteWarning'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
              height: 20 / 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.muted,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _deleting
                      ? null
                      : () => setState(() => _deleteConfirming = false),
                  child: Text(
                    t('cancel'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _deleting ? null : _handleDelete,
                  child: Text(
                    _deleting
                        ? t('profile.deleting')
                        : t('profile.deleteAccount'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 3e: Add the `_LinkRow` widget**

Add this class at the bottom of the file, next to the other private widgets
(e.g. after `_InfoRow`):

```dart
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.destructive : AppColors.foreground;
    final tint = destructive ? AppColors.destructive : AppColors.gold;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withAlpha(0x18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            // chevron_left as the trailing affordance matches the RTL
            // convention adopted across the office screens.
            Icon(Icons.chevron_left, size: 22, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the widget test to verify it passes**

Run: `cd /home/frappe/Flutter/dill_adala && export PATH="$PATH:/home/frappe/.flutter-sdk/bin" && flutter test test/profile_legal_section_test.dart`
Expected: PASS (both tests green).

- [ ] **Step 5: Run analyze + full test suite**

Run: `cd /home/frappe/Flutter/dill_adala && export PATH="$PATH:/home/frappe/.flutter-sdk/bin" && flutter analyze && flutter test`
Expected: No analyzer issues introduced; full suite green (including `i18n_keys_resolve_test`).

- [ ] **Step 6: Commit**

```bash
cd /home/frappe/Flutter/dill_adala
git add lib/screens/profile_screen.dart test/profile_legal_section_test.dart
git commit -m "feat(profile): privacy policy link + in-app delete account flow

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Manual end-to-end verification

- [ ] **Step 1: Run the app against the backend**

Run: `cd /home/frappe/Flutter/dill_adala && export PATH="$PATH:/home/frappe/.flutter-sdk/bin" && flutter run`
(Default `API_URL` is `https://justice-iq.org`; the privacy page must be deployed there — Task 2.)

- [ ] **Step 2: Verify the flows**

- Profile (signed out): "Privacy Policy" row opens `/privacy` in the browser; no "Delete account" row.
- Sign in with a real OTP test account.
- Profile (signed in): both rows present; tapping "Delete account" shows the confirm card with the warning.
- Confirm deletion → app returns to the login screen.
- Confirm in the ERP desk (`law.site` → User list) that the account is disabled and its name/phone are anonymized.

> Note (out of code scope): update App Store Connect and Google Play Console
> listing fields to point the privacy-policy URL at `https://justice-iq.org/privacy`.

---

## Self-review notes

- **Spec coverage:** A1 privacy page → Task 2; A2 `delete_account` → Task 1;
  B1 `deleteAccount` → Task 3; B2 profile section + delete flow → Task 5; B3
  i18n → Task 4; store-listing reminder → Tasks 2/6 notes.
- **Deviation from spec:** the spec mentioned a unit test asserting
  `deleteAccount` issues a POST. `ApiService` has no DI for its `http.Client`
  and the codebase has zero ApiService network tests; forcing one would require
  unrelated refactoring. Coverage is instead via `flutter analyze` + the Profile
  widget test + Task 6 manual E2E. Documented in Task 3.
- **Type/name consistency:** `delete_account` (backend) ↔ `deleteAccount`
  (Dart); i18n keys used in Task 5 (`profile.legalSection`, `privacyPolicy`,
  `deleteAccount`, `deleteConfirm`, `deleteWarning`, `deleting`, `deleteError`)
  all defined in Task 4; `_LinkRow`, `_legalSection`, `_deleteConfirmCard`,
  `_handleDelete`, `_openPrivacy`, `_deleteConfirming`, `_deleting` all defined
  in Task 5; `t('cancel')` is an existing top-level key already used by
  `_confirmCard`.
