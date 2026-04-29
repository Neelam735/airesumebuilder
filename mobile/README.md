# Resume Forge AI — Flutter Android app

The Android client that talks to the same Spring Boot backend as the web app.
Adds Google Play in-app billing for the AI resume rewrite, and a smart-apply
flow on the go.

- **Editor** — Material 3 dark UI with section cards for Personal, Skills,
  Experience, Education, Projects, Languages.
- **Live Preview** — uses the exact PDF that gets exported (rendered via
  `printing`'s `PdfPreview`), so what you see is what you share.
- **Three templates** — Classic, Modern (sidebar), Minimal (timeline).
- **PDF Export** — `pdf` + `printing` for system Share / Save to Files.
- **AI Improve** — pick a PDF, extract text with `syncfusion_flutter_pdf`,
  send to backend, auto-fill the form. Gated behind a Google Play one-time
  purchase verified server-side via the Android Publisher API.
- **Auto-apply by skills** — calls the backend's `/jobs/match` (Remotive
  source), drafts a tailored cover letter via Gemini, downloads a tailored
  resume PDF, and opens the listing in the browser.

---

## Project layout

```
mobile/
├── pubspec.yaml
├── android/
│   └── app/
│       ├── proguard-rules.pro
│       └── src/main/AndroidManifest.xml
└── lib/
    ├── main.dart
    ├── app.dart
    ├── theme.dart
    ├── models/
    │   ├── resume.dart
    │   └── job.dart
    ├── state/resume_provider.dart
    ├── services/
    │   ├── api.dart            # HTTP client to Spring Boot backend
    │   ├── billing.dart        # in_app_purchase wrapper
    │   ├── storage.dart        # shared_preferences persistence
    │   ├── pdf_extract.dart    # syncfusion text extraction
    │   └── pdf_export.dart     # share / save / preview
    ├── pdf/templates.dart      # Classic / Modern / Minimal pdf widgets
    ├── widgets/
    │   ├── forms.dart          # all section forms + customisation card
    │   ├── preview_widget.dart # live preview
    │   ├── improve_dialog.dart # Pay → Upload → Extract → Improve → Fill
    │   ├── jobs_panel.dart     # search + ranked match cards
    │   └── apply_dialog.dart   # cover letter + share + open listing
    └── screens/builder_screen.dart
```

---

## Prerequisites

- Flutter 3.19+ (Dart 3.3+)
- Android SDK 34, minSdk 21 or higher (required by Google Play Billing)
- A Google Play Console listing for this app (any track, even internal testing)
- A reachable backend (`../backend`) configured per `../backend/.env.example`

---

## First-time setup

The repo only ships the Flutter source. Generate the platform scaffolding once,
then replace the placeholder files with the ones in this folder.

```bash
cd mobile
flutter create --org com.resumebuilder --project-name resume_builder --platforms=android .
flutter pub get
```

Then copy the AndroidManifest patch over `android/app/src/main/AndroidManifest.xml`
(or merge the `<queries>` block into the file Flutter generated). Bump
`android/app/build.gradle` to:

```groovy
defaultConfig {
    applicationId "com.resumebuilder.app"   // must match Play Console listing
    minSdkVersion 21
    targetSdkVersion 34
}
```

Add the proguard rules to `android/app/build.gradle`:

```groovy
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
}
```

---

## Backend connection

`lib/services/api.dart` defaults to `http://10.0.2.2:8080/api/v1`, which is the
Android emulator's loopback alias for the host machine. To target a real
device or deployed backend, build with `--dart-define`:

```bash
flutter run --dart-define=API_BASE=https://api.example.com/api/v1
```

> When testing AI improve on a real device, your backend must be reachable
> over HTTPS — Android blocks plaintext traffic by default.

---

## Google Play Billing setup

1. **Create the in-app product** in Play Console → Monetize → Products → In-app products:
   - Product ID: `ai_resume_improvement`
   - Type: **Consumable**
   - Price: ₹29 (or your preferred amount)
   - Status: Active

2. **Upload at least one signed build** to an internal testing track. Billing
   will not work in plain `flutter run` on debug — the package name **and**
   signing key must match what's in Play Console. Run:

   ```bash
   flutter build appbundle --dart-define=API_BASE=...
   ```

3. **Add yourself as a license tester** (Play Console → Setup → License testing).
   This lets your purchases complete without actually being charged.

4. **Override the product id** if you used a different SKU:

   ```bash
   flutter run \
     --dart-define=API_BASE=https://api.example.com/api/v1 \
     --dart-define=GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
   ```

### Backend service-account (for verification)

The backend verifies each purchase server-side via the Android Publisher API:

1. In Play Console → Setup → API access, link a Google Cloud project and
   create a service account with the **"View financial data"** permission
   for this app.
2. Download the service-account JSON key file.
3. Set the env var on the backend:

   ```bash
   export GOOGLE_PLAY_PACKAGE_NAME=com.resumebuilder.app
   export GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
   export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=/etc/secrets/play-service-account.json
   export PAYMENT_TOKEN_SIGNING_KEY=<32+ random bytes>
   ```

Either a file path or the JSON content directly is accepted.

---

## Running

```bash
# 1. Backend
cd ../backend
mvn spring-boot:run        # localhost:8080

# 2. Flutter (in another shell, with an emulator running)
cd ../mobile
flutter run --dart-define=API_BASE=http://10.0.2.2:8080/api/v1
```

The first build compiles native dependencies (pdfjs, syncfusion); subsequent
runs are fast.

---

## End-to-end flow

1. Build / edit the resume in the **Edit** tab. Changes are auto-saved to
   `shared_preferences`.
2. Switch to **Preview** to see the rendered PDF (matches the export pixel
   for pixel since both go through `lib/pdf/templates.dart`).
3. Tap the **Improve** FAB →
   1. Google Play checkout opens (₹29 consumable).
   2. On success, the app posts the `purchaseToken` to
      `POST /api/v1/payment/verify`.
   3. The backend verifies the purchase via the Android Publisher API,
      consumes it, and returns a single-use HMAC-signed payment token.
   4. The user picks a PDF; we extract its text, send it (with the token) to
      `POST /api/v1/resume/parse`, merge the AI-improved JSON back into the
      form, and switch to Preview.
4. On the **Jobs** tab, tap **Find matching jobs** to fetch ranked listings
   from Remotive, then **Apply with AI** to:
   - Draft a tailored cover letter via Gemini.
   - Share/save a tailored PDF named `<you>-<company>.pdf`.
   - Open the job listing in the browser so you can finalise the application.

---

## Why not auto-fill the actual application form?

True bot-applying on LinkedIn / Indeed / Wellfound violates platform terms
and gets accounts banned. This app does the 95%-value, low-risk version:
match → tailor → 1-click open. The human spends 30 seconds finalising on the
real job site.
