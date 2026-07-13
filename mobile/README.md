# Resume Forge AI — Flutter Android app

The Android client that talks to the same Spring Boot backend as the web app.
**AI enhancement is free** — a one-time Google Play purchase only unlocks the
download of the polished, AI-rewritten PDF. Manually-edited resumes can be
downloaded for free.

- **Editor** — Material 3 dark UI with section cards for Personal, Skills,
  Experience, Education, Projects, Languages.
- **Live Preview** — uses the exact PDF that gets exported (rendered via
  `printing`'s `PdfPreview`), so what you see is what you share.
- **Three templates** — Classic, Modern (sidebar), Minimal (timeline).
- **Enhance Resume using AI** — pick a PDF, extract text with
  `syncfusion_flutter_pdf`, send to backend, auto-fill the form. Free.
- **Pay-on-download** — when downloading an AI-enhanced resume, Google Play
  Billing unlocks the PDF (verified server-side via Android Publisher API).
  The unlock persists for that resume; reset to clear it.
- **Auto-apply by skills** — calls the backend's `/jobs/match` (Remotive
  source), drafts a tailored cover letter via Gemini, downloads a tailored
  resume PDF, and opens the listing in the browser.

---

## Project layout

```
mobile/
├── pubspec.yaml
├── scripts/
│   └── setup-keystore.sh        # generate release keystore + key.properties
├── android/
│   ├── key.properties.example   # template; copy to key.properties (gitignored)
│   ├── signing.gradle.example   # snippet to merge into app/build.gradle
│   └── app/
│       ├── proguard-rules.pro
│       └── src/main/AndroidManifest.xml
└── lib/
    ├── main.dart, app.dart, theme.dart
    ├── models/                  # ResumeData, JobMatch
    ├── state/resume_provider.dart  # + aiEnhanced + aiPaymentToken
    ├── services/
    │   ├── api.dart             # HTTP client
    │   ├── billing.dart         # in_app_purchase wrapper
    │   ├── storage.dart         # shared_preferences (persists AI flags)
    │   ├── pdf_extract.dart     # syncfusion text extraction
    │   └── pdf_export.dart      # share / save / preview
    ├── pdf/templates.dart       # Classic / Modern / Minimal PDF widgets
    ├── widgets/
    │   ├── forms.dart           # all section forms + customisation card
    │   ├── preview_widget.dart  # live preview with download bar
    │   ├── enhance_dialog.dart  # free: Upload → Extract → Enhance → Fill
    │   ├── payment_dialog.dart  # paid: Google Play unlock at download time
    │   ├── jobs_panel.dart      # search + ranked match cards
    │   └── apply_dialog.dart    # cover letter + share + open listing
    └── screens/builder_screen.dart
```

---

## End-to-end flow

1. Build / edit the resume in the **Edit** tab. Auto-saved to
   `shared_preferences`.
2. Tap the **Enhance Resume using AI** FAB → pick a PDF → AI rewrites it →
   form is filled. Free, no payment needed yet.
3. Switch to **Preview**. There's a **Download Resume** button at the bottom.
4. On tap:
   - If the resume hasn't been AI-enhanced → system Share/Save sheet opens
     immediately.
   - If it **has** been AI-enhanced and not yet paid → the payment dialog
     opens. Google Play purchase → backend verifies → on success the PDF
     downloads and the unlock is stored so re-downloads of the same resume
     skip the paywall.
5. **Reset** clears the unlock so editing a fresh resume requires a new
   payment when AI is used again.

---

## Prerequisites

- Flutter 3.19+ (Dart 3.3+)
- Android SDK 34, minSdk 21+ (Google Play Billing requirement)
- A Google Play Console listing with a consumable in-app product
- A reachable backend (`../backend`) configured per `../backend/.env.example`

---

## First-time setup

```bash
cd mobile
flutter create --org com.resumebuilder --project-name resume_builder --platforms=android .
flutter pub get
```

Replace `android/app/src/main/AndroidManifest.xml` with the one shipped here
(or merge in the `<queries>` block needed by `url_launcher`).

In `android/app/build.gradle` set:

```groovy
defaultConfig {
    applicationId "com.neelam.resumebuilder"   // must match Play Console listing
    minSdkVersion 21
    targetSdkVersion 34
}
```

---

## Backend connection

`lib/services/api.dart` defaults to `http://10.0.2.2:8080/api/v1` (Android
emulator's loopback alias for the host). Override via `--dart-define`:

```bash
flutter run --dart-define=API_BASE=https://your-backend.example.com/api/v1
```

> Real devices need an HTTPS backend — Android blocks plaintext by default.

---

## Google Play Billing setup

1. **In Play Console → Monetize → Products → In-app products**:
   - Product ID: `ai_resume_improvement`
   - Type: **Consumable**
   - Price: ₹29 (or whatever you want)
   - Status: Active

2. **Add license testers** (Play Console → Setup → License testing) so
   purchases complete without actually being charged.

3. **Override the product id** if you used a different SKU:

   ```bash
   flutter run \
     --dart-define=API_BASE=... \
     --dart-define=GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
   ```

### Backend service-account (for verification)

The backend verifies each purchase server-side via the Android Publisher API:

1. **Play Console → Setup → API access** → link a Google Cloud project →
   create a service account.
2. Grant the service account **"View financial data"** for this app.
3. Download the service-account JSON.
4. Set on the backend:

   ```bash
   export GOOGLE_PLAY_PACKAGE_NAME=com.neelam.resumebuilder
   export GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
   export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=/etc/secrets/play-service-account.json
   export PAYMENT_TOKEN_SIGNING_KEY=$(openssl rand -hex 32)
   ```

---

## 🔐 Signing & uploading to the Play Store

Play requires every release to be signed with a stable key. Lose this key
and you can never publish updates on the same listing — back it up.

### 1. Generate the upload keystore (one time per project)

```bash
cd mobile
./scripts/setup-keystore.sh
```

The script:
- prompts for alias, distinguished name, and passwords
- generates `android/keystore/upload-keystore.jks` (RSA 2048, 27-year validity)
- writes `android/key.properties` with the credentials
- chmods both files to 600

Both files are **gitignored** (`mobile/.gitignore` excludes `*.jks`,
`key.properties`, and `android/keystore/`).

### 2. Wire the signing config into `android/app/build.gradle`

Open `mobile/android/signing.gradle.example` and copy the two marked sections
into `android/app/build.gradle`:

- **Top of file** — loads `key.properties` into `keystoreProperties`.
- **Inside `android { … }`** — declares `signingConfigs.release` (reads from
  the loaded properties), and overrides `buildTypes.release` to use it
  with `minifyEnabled` + ProGuard.

The block is defensive: if `key.properties` is missing it falls back to
the debug signing config so `flutter run` still works on developer machines
without the keystore.

### 3. Build a release bundle

```bash
flutter build appbundle --release \
  --dart-define=API_BASE=https://your-backend.example.com/api/v1 \
  --dart-define=GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

### 4. Upload to Play Console

1. Play Console → your app → **Testing → Internal testing → Create new release**.
2. Upload `app-release.aab`.
3. Add release notes.
4. Save → Review release → **Start rollout to Internal testing**.
5. Add test users via the **Testers** tab. They get an opt-in URL.

### 5. Verifying billing in the testing build

- Real purchases complete only when:
  - The AAB is uploaded to **at least Internal testing**.
  - The signing key matches what Play Console has on file.
  - Your Google account is a **license tester** AND opted into the testing
    track.
  - The `applicationId` matches the Play Console listing exactly.

If `BillingService.load()` keeps failing in production with
*"product not available"*, one of those four boxes is unchecked.

### Long-term: Play App Signing

Modern Play Console **requires** Play App Signing. You upload an AAB signed
with your **upload key** (the keystore you just made), and Google re-signs
it with their managed app-signing key for distribution. Both keys are
managed transparently — your only job is to never lose the upload key. If
you ever do, Play Console offers a "request key reset" flow that takes a
few days and Google's review.

---

## Backups (don't skip this)

```bash
# After running setup-keystore.sh, archive the keystore + properties
# somewhere safe (1Password / Bitwarden / encrypted USB).
cd mobile
tar -czf "$HOME/resumeforge-keystore-$(date +%Y%m%d).tar.gz" \
  android/keystore/ android/key.properties
```

If the laptop dies and you don't have this archive, the Play Store listing
is permanently locked unless you go through Google's key-reset process.

---

## Why pay only at download?

UX-wise this is the strongest funnel:

- The user can **try AI enhancement risk-free** — they see the rewritten
  resume in the preview before deciding to pay.
- Payment is anchored to the **deliverable** (the polished PDF), not the
  process (the AI call). Conversion is naturally higher.
- The free path (manually-edited resumes) stays free, so the app remains
  useful even for users who don't want AI.

The mobile FAB is intentionally renamed to **"Enhance Resume using AI"** to
match this — it's positioned as a free quality-of-life feature, with the
unlock happening only at the share/download moment.

---

## Why not auto-fill the actual application form?

True bot-applying on LinkedIn / Indeed / Wellfound violates platform terms
and gets accounts banned. This app does the 95%-value, low-risk version:
match → tailor → 1-click open. The human spends 30 seconds finalising on
the real job site.
