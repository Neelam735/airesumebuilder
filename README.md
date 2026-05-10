# AI Resume Builder

A production-ready resume builder with three templates, live preview, PDF export, and an
AI-powered "Import & Improve Resume" flow gated behind a ₹29 Google Play in-app purchase
(in the Android app) and a smart-apply flow that ranks remote jobs by skill overlap.

- **Web frontend** — Vite + React 18 + TypeScript + Tailwind + Zustand
- **Android app** — Flutter 3.19+ (Dart 3.3+) with Material 3 dark UI
- **Backend** — Java 17 + Spring Boot 3 (REST + WebClient)
- **Payments** — Google Play Billing (consumable in-app product), verified
  server-side via the Android Publisher API
- **AI** — Google Gemini (`generateContent`) with JSON response mode
- **Job matching** — [Remotive](https://remotive.com/api-documentation) public API,
  ranked by weighted skill overlap
- **PDF** — `pdfjs-dist` (web) / `syncfusion_flutter_pdf` (mobile) for parsing;
  `html2pdf.js` (web) / `pdf` + `printing` (mobile) for export

No database is required — everything is auto-saved to local storage, and verified
payment tokens live in an in-memory map on the backend.

> AI improvement is paid only in the Android app (Google Play in-app purchase).
> The web frontend's "Improve" button shows a "Get on Android" notice — all other
> features (build, edit, export PDF, job match, cover letter draft) remain free
> on the web.

---

## Project layout

```
airesumebuilder/
├── backend/                       # Spring Boot 3 service
│   ├── pom.xml
│   └── src/main/java/com/resumebuilder
│       ├── ResumeBuilderApplication.java
│       ├── config/                # CORS + @ConfigurationProperties
│       ├── controller/            # REST endpoints
│       ├── service/               # PaymentService, ResumeService, JobsService
│       ├── client/                # GooglePlayBillingClient, GeminiClient, RemotiveClient
│       ├── dto/
│       └── exception/
│   └── src/main/resources/application.yml
│
├── frontend/                      # React + Vite web app
│   ├── index.html
│   └── src/
│       ├── components/            # UI building blocks
│       ├── pages/BuilderPage.tsx  # 3-pane layout
│       ├── templates/             # Classic / Modern / Minimal
│       ├── store/resumeStore.ts   # Zustand + persist
│       ├── utils/                 # api, pdf parse, pdf export, score
│       └── types/resume.ts
│
└── mobile/                        # Flutter Android app
    ├── pubspec.yaml
    ├── android/                   # AndroidManifest patch + proguard
    └── lib/
        ├── main.dart, app.dart, theme.dart
        ├── models/                # ResumeData, JobMatch
        ├── state/                 # Provider + persistence
        ├── services/              # api, billing, storage, pdf_extract, pdf_export
        ├── pdf/templates.dart     # 3 templates rendered via `pdf` package
        ├── widgets/               # forms, preview, improve_dialog, jobs, apply
        └── screens/builder_screen.dart
```

---

## How the payment-gated AI flow works (Android app)

1. User taps **Improve** in the Flutter app.
2. The app shows a paywall card with the price returned by Google Play.
3. Tapping **Pay with Google Play** invokes `InAppPurchase.buyConsumable`,
   which opens Play's native checkout for the `ai_resume_improvement` SKU.
4. On success, the app posts `{productId, purchaseToken}` to
   `POST /api/v1/payment/verify`.
5. The backend calls the **Android Publisher API** at
   `purchases/products/{productId}/tokens/{purchaseToken}` using a
   service-account access token, checks `purchaseState == 0` and
   `consumptionState != 1`, then **consumes** the purchase server-side.
6. On success it issues a short-lived HMAC-signed payment token.
7. The PDF upload step only unlocks once a valid token is held.
8. App extracts text with `syncfusion_flutter_pdf` and posts it with the
   token to `POST /api/v1/resume/parse`. The backend rejects the request
   unless the token validates.
9. Gemini returns improved structured JSON; the app merges it into the form
   and switches to the Preview tab. The token is consumed (single-use)
   after a successful parse.

The web app's Improve button shows a "Get on Android" notice — Google Play
Billing only works inside the Android app, so AI improve is mobile-only.

---

## Backend setup

### Prerequisites

- Java 17+
- Maven 3.9+
- Google Play Console access for the Android listing (any track)
- Service-account JSON with "View financial data" permission for the app
- Google Gemini API key — get one from https://aistudio.google.com/apikey

### Run locally

```bash
cd backend

export GOOGLE_PLAY_PACKAGE_NAME=com.resumebuilder.app
export GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=/etc/secrets/play-service-account.json
export PAYMENT_TOKEN_SIGNING_KEY=replace_with_at_least_32_random_bytes
export GEMINI_API_KEY=your_gemini_api_key
# optional overrides
export GEMINI_MODEL=gemini-2.5-flash   # or gemini-2.5-pro, gemini-2.0-flash. (1.5 family is deprecated.)
export GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
export GEMINI_JSON_MODE=true

mvn spring-boot:run
```

Server boots at `http://localhost:8080`.

Health check:

```bash
curl http://localhost:8080/api/v1/health
```

### REST API

| Method | Path                              | Purpose                                       |
| ------ | --------------------------------- | --------------------------------------------- |
| `POST` | `/api/v1/payment/verify`          | Verifies a Google Play purchase, returns token|
| `POST` | `/api/v1/resume/parse`            | AI-improves resume; requires token            |
| `POST` | `/api/v1/jobs/match`              | Ranks remote jobs by resume skills            |
| `POST` | `/api/v1/jobs/cover-letter`       | Drafts a tailored cover letter via AI         |
| `GET`  | `/api/v1/health`                  | Liveness                                      |

`POST /api/v1/payment/verify` body:

```json
{
  "productId": "ai_resume_improvement",
  "purchaseToken": "<token returned by Google Play Billing>"
}
```

Response:

```json
{ "verified": true, "paymentToken": "<server token>", "message": "Purchase verified successfully" }
```

`POST /api/v1/resume/parse` body:

```json
{ "paymentToken": "<token>", "resumeText": "..." }
```

A `402 Payment Required` is returned if the token is missing/expired/invalid.

### Job matching & "Apply with AI"

`POST /api/v1/jobs/match` body:

```json
{ "skills": ["typescript","aws","spring boot"], "title": "Senior Engineer", "location": "remote", "limit": 12 }
```

Jobs are sourced from [Remotive's public API](https://remotive.com/api-documentation)
(no auth required, free) and ranked by skill overlap with weighted scoring:
`tag match × 3 + title match × 2 + description match × 1`, normalised to 0–100.

`POST /api/v1/jobs/cover-letter` produces a 200-word, three-paragraph cover letter
via Gemini using the candidate's name/title/summary/skills and the target
job's title/company/description. This endpoint is **not** payment-gated —
the ₹29 fee covers the AI resume rewrite only.

> ⚠️ **Important:** "Apply with AI" is a smart-assist flow, not a bot. Truly
> hands-off applying on LinkedIn / Indeed violates platform ToS. The frontend
> uses these endpoints to (1) match jobs, (2) draft a cover letter, and
> (3) download the resume PDF + open the listing in a new tab so the user can
> finalise the application themselves.

---

## Deployment

See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for a full walk-through of
deploying the backend to Render in ~5 minutes (free tier, auto-HTTPS,
Google Play service-account mounted as a secret file). The same Dockerfile
also works on Cloud Run, Fly.io, Railway, or any VPS.

---

## Android app

See [`mobile/README.md`](mobile/README.md) for full Flutter + Google Play setup.
Quick start:

```bash
cd mobile
flutter create --org com.resumebuilder --project-name resume_builder --platforms=android .
flutter pub get
flutter run --dart-define=API_BASE=http://10.0.2.2:8080/api/v1
```

The first run only needs Play Services to be present; the actual purchase flow
requires a signed build uploaded to an internal testing track in Play Console
with a license-tester account.

---

## Frontend setup

### Prerequisites

- Node.js 18+

### Run locally

```bash
cd frontend
npm install
npm run dev
```

Vite dev server boots at `http://localhost:5173` and proxies `/api` to
`http://localhost:8080`.

To override the API base, copy `.env.example` to `.env` and edit `VITE_API_BASE`.

### Production build

```bash
cd frontend
npm run build
npm run preview
```

The built static assets in `frontend/dist` can be served from any static host
(Vercel, Netlify, S3 + CloudFront, Nginx, etc.). Point them at your backend
either via a reverse proxy on `/api` or by setting `VITE_API_BASE`
to the full backend URL at build time.

---

## Security notes

- **Razorpay key secret is never exposed to the browser.** Only `key_id` is
  returned to the client at order-creation time.
- **Signature verification is constant-time.**
- **AI calls are blocked unless the payment token validates** — the token is
  HMAC-signed with the key secret and is single-use (consumed after a successful parse).
- All API keys come from environment variables. `.env` files are git-ignored.

---

## Customisation

- **Templates** — drop another `<TemplateId>Template.tsx` into `frontend/src/templates/`,
  add it to the list in `CustomizationPanel.tsx`, and update the `TemplateId` union
  in `frontend/src/types/resume.ts`.
- **Accent color & zoom** — handled in `CustomizationPanel.tsx`.
- **Price** — set `RAZORPAY_AMOUNT` (paise) on the backend. The server overrides any
  client-supplied amount.
- **AI model / prompt** — edit `GEMINI_MODEL` and `ResumeService.SYSTEM_PROMPT`.
  `gemini-2.5-flash` is the cheapest fast model; switch to `gemini-2.5-pro`
  for higher-quality output at higher latency and cost.
