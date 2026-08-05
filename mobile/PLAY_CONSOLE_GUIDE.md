# Play Console — Step‑by‑Step Publishing Guide

A complete, click‑by‑click walkthrough to publish **Resume Forge AI** on Google
Play and get the **Pay with Google Play** flow working.

**Fixed identity for this app (use these everywhere):**

| Thing | Value |
|------|-------|
| Application ID / package name | `com.neelam.resumebuilder` |
| App name | `Resume Forge AI` |
| In‑app product ID | `ai_resume_improvement` |
| Backend URL | `https://<your-app>.up.railway.app` |

> **Why "Pay with Google Play" fails on a debug build:** Google Play Billing
> only works when the in‑app product is **Active**, the app is **signed** and
> uploaded to a **testing track**, installed **from Play**, and your account is
> a **licensed tester**. Sections C, E, F, G below make that true.

---

## A. Set the package name to `com.neelam.resumebuilder`

Do this **before your first upload** — the applicationId is permanent on Play.
Your app was generated as `com.resumeforge.resume_builder`; change it now.

### Option 1 — automated (recommended)

```powershell
cd C:\Users\sarab\IdeaProjects\12-07\airesumebuilder\mobile
flutter pub add --dev change_app_package_name
dart run change_app_package_name:main com.neelam.resumebuilder
```

### Option 2 — manual (PowerShell, run from `mobile`)

```powershell
cd C:\Users\sarab\IdeaProjects\12-07\airesumebuilder\mobile

# Move MainActivity into the new package folder
$new = "android\app\src\main\kotlin\com\neelam\resumebuilder"
New-Item -ItemType Directory -Force -Path $new | Out-Null
Move-Item "android\app\src\main\kotlin\com\resumeforge\resume_builder\MainActivity.kt" "$new\MainActivity.kt" -Force

# Fix its package line
(Get-Content "$new\MainActivity.kt") -replace '^package .*', 'package com.neelam.resumebuilder' | Set-Content "$new\MainActivity.kt"

# Delete the old folders
Remove-Item -Recurse -Force "android\app\src\main\kotlin\com\resumeforge"

# Update namespace + applicationId (handles .gradle or .gradle.kts)
$gradle = if (Test-Path "android\app\build.gradle.kts") { "android\app\build.gradle.kts" } else { "android\app\build.gradle" }
(Get-Content $gradle) -replace 'com\.resumeforge\.resume_builder', 'com.neelam.resumebuilder' | Set-Content $gradle
```

### Verify

```powershell
Select-String -Path $gradle -Pattern "applicationId|namespace"
Get-Content "$new\MainActivity.kt" | Select-Object -First 1
```

Expected:
```
applicationId = "com.neelam.resumebuilder"
namespace = "com.neelam.resumebuilder"
package com.neelam.resumebuilder
```

Then rebuild fresh (the package changed, so remove the old install):

```powershell
adb uninstall com.resumeforge.resume_builder   # ok if it errors
flutter clean ; flutter pub get
flutter run --dart-define=API_BASE=http://172.20.10.2:8080
```

---

## B. Deploy the backend over HTTPS (do before release)

The app needs a reachable HTTPS backend. Deploy `backend/` to Railway:

1. Railway → New Project → Deploy from GitHub → this repo → root dir `backend/`
   (or the `backend` branch). It auto‑detects the `Dockerfile`.
2. Env vars:
   - `GEMINI_API_KEY=<your key>`
   - `GEMINI_MODEL=gemini-2.5-flash`
   - `PAYMENT_TOKEN_SIGNING_KEY=<long random string>`
   - `GOOGLE_PLAY_PACKAGE_NAME=com.neelam.resumebuilder`
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=<from Section F>`
3. Settings → Networking → **Generate Domain**.
4. Verify `https://<your-app>.up.railway.app/api/v1/health` → `{"status":"UP"}`.

---

## C. Create your signing key and build the AAB

```powershell
cd C:\Users\sarab\IdeaProjects\12-07\airesumebuilder\mobile
bash scripts/setup-keystore.sh          # creates android/keystore + key.properties
```

Merge the signing block from `android/signing.gradle.example` into your local
`android/app/build.gradle` (see `PLAY_STORE_RELEASE.md` §2 for the exact block).
**Back up `upload-keystore.jks` offline** — losing it means you can never update
the app again.

For production, disable cleartext HTTP (backend is HTTPS): remove
`android:usesCleartextTraffic="true"` from `AndroidManifest.xml`, or move it to
a debug‑only manifest (`PLAY_STORE_RELEASE.md` §3).

Build the release bundle pointed at production:

```powershell
flutter clean ; flutter pub get
flutter build appbundle --release `
  --dart-define=API_BASE=https://<your-app>.up.railway.app `
  --dart-define=GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
```

Output: `build/app/outputs/bundle/release/app-release.aab`.
Bump `version:` in `pubspec.yaml` before every new upload.

---

## D. Create your Play Console account & app

### D0 — Developer account (one‑time)
1. Go to **https://play.google.com/console** and sign in.
2. Account type **Personal** (or Organization).
3. Pay the **one‑time $25** fee and complete **identity verification**
   (can take a few hours to a couple of days — you can't publish until verified).

### D1 — Create the app
1. Console home → **Create app**.
2. **App name:** `Resume Forge AI`
3. **Default language:** English · **App** · **Free**.
4. Accept declarations → **Create app**.

---

## E. Complete the Dashboard setup tasks

On the app **Dashboard**, work through the "Set up your app" checklist:

1. **App access** → "All functionality available without special access".
2. **Ads** → declare Yes/No (No unless you add ads).
3. **Content rating** → complete questionnaire → receive rating.
4. **Target audience** → choose age groups (e.g. 18+).
5. **Data safety** → declare that resume text is collected and sent to your
   server / Google Gemini for app functionality, plus Google Play billing.
6. **Privacy policy** → paste a hosted Privacy Policy URL (required).
7. **Store listing** (Grow → Store presence → Main store listing):
   - Short + full description, **app icon 512×512**, **feature graphic
     1024×500**, **≥2 phone screenshots**, category **Productivity/Business**,
     contact email → **Save**.

---

## F. Link the backend for purchase verification (service account)

1. Console → **Setup → API access** → link/create a **Google Cloud project**.
2. In Google Cloud, create a **service account** → create a **JSON key** →
   download it.
3. Back in **API access**, grant that service account access with at least
   **View financial data / Manage orders** for this app.
4. Put the JSON into the backend env var `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
   (inline JSON or a file path) and confirm
   `GOOGLE_PLAY_PACKAGE_NAME=com.neelam.resumebuilder`. Redeploy the backend.

---

## G. Upload to Internal testing + add testers

### G1 — Upload the build
1. Console → **Test and release → Testing → Internal testing** →
   **Create new release**.
2. Accept **Play App Signing** (Google manages the app key; your keystore is the
   upload key — this is normal).
3. Upload `app-release.aab` → add release notes → **Save → Review release →
   Start rollout to Internal testing**.

### G2 — Add license testers (so test purchases aren't charged)
1. **Internal testing → Testers** → create an email list → add your tester
   Google account(s) → **Save** → copy the **join link**.
2. Console (account level) → **Setup → License testing** → add the same emails →
   **License response = RESPOND_NORMALLY**.

### G3 — Install on the phone as a tester
1. On the phone, sign in with the **tester** Google account.
2. Open the **join link**, accept, then **install from the Play Store link**
   (or `flutter install --release` of the *same* signed build/version you
   uploaded — Play verifies the installed signature).

---

## H. Create + activate the in‑app product (fixes "not available")

1. Console → **Monetize → Products → In‑app products** → **Create product**.
2. **Product ID:** `ai_resume_improvement` — must match exactly
   (case‑sensitive, cannot be reused once created).
3. Add a name + description, **set price** (e.g. ₹29) for your countries.
4. Click **Activate** — it must show status **Active**.

> If "Create product" is greyed out, upload a build to a track first (Section G),
> then come back. New products can take a **few hours** to propagate to devices.

### Test the purchase
Open the installed app → **Enhance Resume using AI** → wait for the auto‑jump to
**Preview** → tap **Download** → **Pay with Google Play**. You should get a
**test purchase** dialog (testers are not charged).

**Still "not available"?** The app now shows the precise reason. Check:
- Product is **Active** and the ID matches exactly.
- The build is **signed** and uploaded; you installed *that* build (not a raw
  `flutter run` debug build).
- Your account is a **licensed tester** on the track.
- Give it a few hours for activation/propagation.

---

## I. Promote to production

Once internal testing works end‑to‑end:
1. Optionally widen via **Closed testing**.
2. **Test and release → Production → Create release** → upload the AAB →
   **Send for review**. First production review usually takes a **few days**.

---

## J. Final pre‑launch checklist

- [ ] Package name is `com.neelam.resumebuilder` everywhere (app, backend, Play).
- [ ] Backend live on HTTPS; `/api/v1/health` returns `UP`.
- [ ] Release build signed with your upload key; keystore backed up offline.
- [ ] `usesCleartextTraffic` removed (or debug‑only) for the release build.
- [ ] `--dart-define=API_BASE=<https prod url>` used for the release build.
- [ ] In‑app product `ai_resume_improvement` is **Active**.
- [ ] Service account wired to the backend; a test purchase verified end‑to‑end.
- [ ] Privacy Policy URL, Data safety, Content rating completed.
- [ ] Icon, feature graphic, screenshots uploaded.
- [ ] `version:` bumped in `pubspec.yaml`.
