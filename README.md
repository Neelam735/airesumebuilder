# Resume Forge AI — Backend

Spring Boot 3 / Java 17 service that powers the
[web frontend](https://github.com/Neelam735/airesumebuilder/tree/claude/resume-builder-ai-payments-NBtxH/frontend)
and [Flutter Android app](https://github.com/Neelam735/airesumebuilder/tree/claude/resume-builder-ai-payments-NBtxH/mobile).

This branch contains **only the backend**, with all files at the repo root so it
can be deployed as-is to Render / Cloud Run / Fly.io / any Docker host.

- **AI** — Google Gemini (`generateContent`, JSON-mode)
- **Payments** — Google Play Billing, verified server-side via the Android Publisher API
- **Jobs** — [Remotive](https://remotive.com/api-documentation) for free remote-jobs search,
  ranked by skill overlap with weighted scoring
- **Cover letters** — Gemini-drafted, tailored to candidate + target job
- **No database** — payment tokens are in-memory and cryptographically signed

---

## Project layout

```
.
├── Dockerfile                # multi-stage: JDK 17 builder → JRE 17 runtime
├── .dockerignore
├── .env.example              # template for the env vars below
├── pom.xml                   # Maven, Spring Boot 3
├── render.yaml               # Render Blueprint
└── src/main/java/com/resumebuilder/
    ├── ResumeBuilderApplication.java
    ├── config/               # CORS + @ConfigurationProperties
    ├── controller/           # REST endpoints
    ├── service/              # PaymentService, ResumeService, JobsService
    ├── client/               # GooglePlayBillingClient, GeminiClient, RemotiveClient
    ├── dto/
    └── exception/
```

---

## REST API

| Method | Path                              | Purpose                                       |
| ------ | --------------------------------- | --------------------------------------------- |
| `POST` | `/api/v1/payment/verify`          | Verifies a Google Play purchase, returns token|
| `POST` | `/api/v1/resume/parse`            | AI-rewrites resume text (free)                |
| `POST` | `/api/v1/jobs/match`              | Ranks remote jobs by resume skills            |
| `POST` | `/api/v1/jobs/cover-letter`       | Drafts a tailored cover letter via AI         |
| `GET`  | `/api/v1/health`                  | Liveness                                      |

### `POST /api/v1/payment/verify`

Validates a Google Play in-app purchase token and returns a single-use HMAC-signed
payment token. The mobile app uses this token to unlock paid actions
(currently: download of an AI-enhanced PDF).

```json
// Request
{
  "productId": "ai_resume_improvement",
  "purchaseToken": "<token returned by Google Play Billing>"
}

// Response
{ "verified": true, "paymentToken": "<server token>", "message": "Purchase verified successfully" }
```

The server calls
`androidpublisher.googleapis.com/.../purchases/products/{productId}/tokens/{purchaseToken}`
using a service-account access token, checks `purchaseState == 0` and
`consumptionState != 1`, then **consumes** the purchase server-side.

### `POST /api/v1/resume/parse`

```json
{ "resumeText": "..." }
```

Returns improved structured JSON. No payment required — the mobile app gates the
download instead. The server caps input at 50 KB and strips markdown fences from
Gemini's output before parsing.

### `POST /api/v1/jobs/match`

```json
{ "skills": ["typescript","aws"], "title": "Senior Engineer", "location": "remote", "limit": 12 }
```

Ranking: `tag match × 3 + title match × 2 + description match × 1`,
normalised to 0–100.

### `POST /api/v1/jobs/cover-letter`

200-word, three-paragraph cover letter drafted by Gemini. Hard-rules in the
system prompt forbid fabricating experience.

---

## Local development

### Prerequisites

- Java 17+ and Maven 3.9+
- Google Gemini API key — https://aistudio.google.com/apikey
- (Optional) Google Play service-account JSON for testing payment verification

### Run

```bash
export GEMINI_API_KEY=your_gemini_api_key
export PAYMENT_TOKEN_SIGNING_KEY=$(openssl rand -hex 32)
# Only required for /payment/verify; the rest of the API runs fine without these:
export GOOGLE_PLAY_PACKAGE_NAME=com.resumebuilder.app
export GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
export GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=/path/to/play-service-account.json

mvn spring-boot:run
```

Server boots at `http://localhost:8080`. Health check:

```bash
curl http://localhost:8080/api/v1/health
# → {"service":"resume-builder-backend","status":"UP"}
```

---

## Environment variables

| Variable                              | Required | Default                                                  | Notes                                          |
| ------------------------------------- | :------: | -------------------------------------------------------- | ---------------------------------------------- |
| `GOOGLE_PLAY_PACKAGE_NAME`            |   yes    | —                                                        | Matches Play Console listing                   |
| `GOOGLE_PLAY_PRODUCT_ID`              |   yes    | `ai_resume_improvement`                                  | Consumable in-app product id                   |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`    |   yes    | —                                                        | File path or inline JSON                       |
| `PAYMENT_TOKEN_SIGNING_KEY`           |   yes    | —                                                        | 32+ random bytes for HMAC token signing        |
| `GEMINI_API_KEY`                      |   yes    | —                                                        | From https://aistudio.google.com/apikey        |
| `GEMINI_MODEL`                        |    no    | `gemini-2.5-flash`                                       | Use `gemini-2.5-pro` for higher quality        |
| `GEMINI_BASE_URL`                     |    no    | `https://generativelanguage.googleapis.com/v1beta`       |                                                |
| `GEMINI_JSON_MODE`                    |    no    | `true`                                                   | Set `false` if you bring your own model        |
| `CORS_ORIGINS`                        |   yes    | `http://localhost:5173,http://localhost:3000`            | Comma-separated frontend origins               |
| `PORT` / `SERVER_PORT`                |    no    | `8080`                                                   | Either is honoured (Render injects `PORT`)     |

---

## Deploying to Render

This repo's root contains everything Render needs. Two paths:

### Blueprint (one-click)

1. Sign in to https://dashboard.render.com.
2. **New + → Blueprint** → connect this repo, branch `backend`.
3. Render reads `render.yaml`, creates the service, asks you to fill in:
   - `GOOGLE_PLAY_PACKAGE_NAME`
   - `GEMINI_API_KEY`
   - `CORS_ORIGINS`
4. Open the service → **Environment** → **Secret Files** → upload the
   service-account JSON as `play-service-account.json`. Render mounts it at
   `/etc/secrets/play-service-account.json`, which is what
   `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` points at.
5. Wait ~3 min for the first build → done.

### Manual

1. **New + → Web Service** → connect this repo, branch `backend`.
2. Runtime: `Docker` (auto-detected from the root `Dockerfile`).
3. Health check path: `/api/v1/health`.
4. Add the env vars from the table above plus the secret file as in step 4 above.

---

## Other deployment targets

The same `Dockerfile` works on:

- **Google Cloud Run** — `gcloud run deploy --source .`. Use **Secret Manager**
  to mount the SA JSON. Set `--min-instances=1` to avoid cold starts (the
  in-memory token map currently does not survive instance restarts).
- **Fly.io** — `fly launch`. Use `fly secrets set` for env vars and
  `fly secrets set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON="$(cat sa.json)"` for the
  service account inline. Always-on free tier means no cold starts.
- **Railway** — connect the repo, branch `backend`, Railway detects the Dockerfile.
- **Self-hosted VPS** — `docker compose up -d` plus a Caddy / Nginx reverse
  proxy in front for HTTPS.

In all of them the env-var contract is identical to the Render setup above.

---

## Verifying the deployment

```bash
# 1. Liveness
curl https://your-service.example.com/api/v1/health

# 2. Job matching is unauthenticated
curl -s -X POST https://your-service.example.com/api/v1/jobs/match \
  -H 'Content-Type: application/json' \
  -d '{"skills":["python","aws"],"limit":3}' | jq '.matches | length'

# 3. AI improve is open (paywall has moved to the mobile download step)
curl -s -X POST https://your-service.example.com/api/v1/resume/parse \
  -H 'Content-Type: application/json' \
  -d '{"resumeText":"Jane Doe — Senior Engineer at Acme since 2020."}' \
  | jq '.resume'
```

---

## Troubleshooting

| Symptom                                                  | Fix                                                                                                                                |
| -------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `Gemini API returned 404 ... is not found`               | `GEMINI_MODEL` is deprecated. Use `gemini-2.5-flash`, `gemini-2.5-pro`, or `gemini-2.0-flash`.                                     |
| `Connection refused: ::1:80` from Gemini                 | `GEMINI_BASE_URL` is empty. The client falls back to the default — make sure you didn't set it to a blank string.                  |
| `Purchase verification failed: ... not found`            | Wrong `GOOGLE_PLAY_PACKAGE_NAME`, or the service account doesn't have "View financial data" permission for this app in Play Console.|
| `Could not obtain Google service-account token`          | Secret file isn't mounted at the path in `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, or the JSON is malformed.                              |
| `google-play.token-signing-key is not configured`        | Set `PAYMENT_TOKEN_SIGNING_KEY` to a 32+ byte random string.                                                                       |
| Frontend gets `403 / CORS error`                         | Add the frontend origin to `CORS_ORIGINS` and redeploy.                                                                            |

---

## Related branches

- **`claude/resume-builder-ai-payments-NBtxH`** — full mono-repo with backend +
  React web frontend + Flutter Android app. The two clients use the API
  documented above.
