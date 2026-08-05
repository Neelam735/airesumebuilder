# Backend Deployment

The Spring Boot backend is a single executable JAR with no database. The
recommended target is **Render** — it has a free tier, auto-HTTPS, secret-file
support for the Google Play service-account JSON, and one-click GitHub
auto-deploys.

This guide gets you from a fresh GitHub repo to a publicly reachable
`https://your-service.onrender.com/api/v1/health` returning `200`.

---

## 0. Prerequisites

You will need:

| Item                                | Where to get it                                   |
| ----------------------------------- | ------------------------------------------------- |
| GitHub repo with this code pushed   | this repo                                         |
| Google Gemini API key               | https://aistudio.google.com/apikey                |
| Google Play package name            | Play Console → your app → App information         |
| Google Play in-app product id       | Play Console → Monetize → Products (Consumable)   |
| Google Cloud service-account JSON   | Play Console → Setup → API access (see below)    |
| 32-byte random string               | `openssl rand -hex 32`                            |

### Service account for Play Developer API

1. In **Play Console → Setup → API access**, link a Google Cloud project.
2. Click **Create new service account** → it opens GCP IAM.
3. Give it a name (e.g. `play-billing-verifier`), no roles needed in GCP.
4. After creation, in Play Console click **Grant access** for that account.
   The only permission required is **View financial data, orders, and
   cancellation survey responses** for this app.
5. Back in GCP IAM, open the service account → **Keys → Add key → Create new
   key → JSON**. Save the downloaded JSON — you'll upload it as a Render
   secret file in step 3.

---

## 1. Push the repo to GitHub

If you already have a GitHub remote, skip. Otherwise:

```bash
git remote add origin git@github.com:<you>/airesumebuilder.git
git push -u origin main
```

The Dockerfile lives at `backend/Dockerfile` and the Render blueprint at
`render.yaml` — both are required for what follows.

---

## 2. Create the Render Web Service

You have two paths. **Blueprint** (recommended) reads `render.yaml` and
creates everything in one shot. **Manual** clicks through the dashboard.

### Path A — Blueprint (one-click)

1. Sign in to https://dashboard.render.com.
2. **New + → Blueprint**.
3. Connect the GitHub repo. Render will detect `render.yaml`.
4. Click **Apply**. Render creates the service named `resume-builder-backend`
   and asks you to set the values for any vars marked `sync: false`:
   - `GOOGLE_PLAY_PACKAGE_NAME` — e.g. `com.neelam.resumebuilder`
   - `GEMINI_API_KEY` — your AI Studio key
   - `CORS_ORIGINS` — leave blank for now; we'll fill it in step 5
5. The service starts building from `backend/Dockerfile`. The first build
   takes ~3–5 min.

### Path B — Manual

1. **New + → Web Service**, select your repo.
2. Set:
   - **Root directory**: `backend`
   - **Runtime**: `Docker`
   - **Dockerfile path**: `backend/Dockerfile`
   - **Plan**: `Free` (or `Starter` if you want no cold-starts)
   - **Region**: closest to your users
   - **Health Check Path**: `/api/v1/health`
3. Add the env vars from the [Environment variables](#4-environment-variables)
   table below.

---

## 3. Upload the Google Play service-account JSON as a secret file

This is the crucial bit — never paste the JSON into a normal env var, it's
huge and Render's UI truncates large values awkwardly.

1. Open the service → **Environment** tab.
2. Scroll to **Secret Files** → **Add Secret File**.
3. **Filename**: `play-service-account.json`
4. **Contents**: paste the entire JSON you downloaded from GCP.
5. **Save changes** — Render will mount it at `/etc/secrets/play-service-account.json`.

The env var `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=/etc/secrets/play-service-account.json`
(set automatically by `render.yaml`) tells the backend to read the file from
that path.

---

## 4. Environment variables

Already set by `render.yaml`. Cross-check on the **Environment** tab:

| Variable                              | Required | Notes                                                        |
| ------------------------------------- | :------: | ------------------------------------------------------------ |
| `GOOGLE_PLAY_PACKAGE_NAME`            | yes      | matches the listing in Play Console                          |
| `GOOGLE_PLAY_PRODUCT_ID`              | yes      | `ai_resume_improvement` unless you renamed the SKU          |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`    | yes      | path to the secret file                                      |
| `PAYMENT_TOKEN_SIGNING_KEY`           | yes      | Render auto-generates 32 random bytes                        |
| `GEMINI_API_KEY`                      | yes      | from https://aistudio.google.com/apikey                      |
| `GEMINI_MODEL`                        | no       | default `gemini-2.5-flash`                                   |
| `GEMINI_BASE_URL`                     | no       | default `https://generativelanguage.googleapis.com/v1beta`   |
| `GEMINI_JSON_MODE`                    | no       | default `true`                                               |
| `CORS_ORIGINS`                        | yes      | comma-separated frontend origins                             |
| `PORT`                                | auto     | injected by Render — the app honours it                      |

After editing env vars, click **Save changes** — Render will redeploy.

---

## 5. Configure CORS for the frontend

If you'll host the React frontend on Vercel / Netlify / Render Static, you
must allow that origin server-side. After deploying the frontend, set:

```
CORS_ORIGINS=https://your-frontend.onrender.com,https://your-domain.com
```

For local dev against the deployed backend, also add `http://localhost:5173`.

---

## 6. Verify the deployment

Once the deploy completes (Logs tab shows `Started ResumeBuilderApplication`):

```bash
curl https://your-service.onrender.com/api/v1/health
# → {"service":"resume-builder-backend","status":"UP"}
```

Try the AI-blocked resume parse — it should return 402 because no payment
token is provided:

```bash
curl -s -X POST https://your-service.onrender.com/api/v1/resume/parse \
  -H 'Content-Type: application/json' \
  -d '{"paymentToken":"forged","resumeText":"hello"}'
# → {"error":"Payment required ...","status":402}
```

Then try job matching, which is unauthenticated:

```bash
curl -s -X POST https://your-service.onrender.com/api/v1/jobs/match \
  -H 'Content-Type: application/json' \
  -d '{"skills":["python","aws"],"limit":3}' | jq '.matches | length'
```

---

## 7. Point the frontend and Android app at the deployed URL

### Web frontend

Build with the API base set to your Render URL:

```bash
cd frontend
echo "VITE_API_BASE=https://your-service.onrender.com/api/v1" > .env.production
npm run build
```

Deploy `frontend/dist` to your static host of choice. Once the URL is known,
update `CORS_ORIGINS` on the backend.

### Flutter Android app

Pass the URL via `--dart-define` when building:

```bash
cd mobile
flutter build appbundle \
  --dart-define=API_BASE=https://your-service.onrender.com/api/v1 \
  --dart-define=GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
```

Upload the AAB to Play Console's internal testing track to test the full
purchase flow with a license-tester account.

---

## 8. Notes on Render's free tier

- **Cold starts**: free web services sleep after 15 minutes of inactivity and
  take ~30 s to wake up. The first AI improve after a cold start will hit
  this latency. Upgrade to **Starter** (~$7/mo) for always-on instances.
- **Build times**: counted against your monthly free build minutes. The
  Dockerfile is multi-stage with cached deps so re-deploys are fast.
- **HTTPS**: automatic. You don't manage certs.
- **Logs**: Render keeps 7 days of logs on free tier; longer on paid.

---

## Alternative targets

The same Dockerfile works on:

- **Google Cloud Run** — `gcloud run deploy --source backend/`. Free tier is
  generous (2M requests/month). Use **Secret Manager** to mount the SA JSON.
- **Fly.io** — `fly launch` from `backend/`. Use `fly secrets set` for
  the env vars and `fly volumes`/`fly secrets set <(cat sa.json)` for the
  service account.
- **Railway** — connect GitHub repo, set root directory to `backend/`,
  Railway detects the Dockerfile. Use the **Volumes** feature for the SA JSON.
- **Self-hosted VPS** — `docker compose up -d` with a small Compose file
  pointing to the same Dockerfile, then a Caddy/Nginx reverse proxy in front
  for HTTPS.

In all of them the env-var contract is identical to the Render setup above.

---

## Troubleshooting

| Symptom                                                 | Cause / fix                                                                                                                     |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `Connection refused: ::1:80` from Gemini                | `GEMINI_BASE_URL` resolved to empty. The client now falls back to the default — make sure you didn't override it to a blank.   |
| `Gemini API returned 404 ... is not found`              | `GEMINI_MODEL` is a deprecated id (e.g. `gemini-1.5-flash`). Use `gemini-2.5-flash`, `gemini-2.5-pro`, or `gemini-2.0-flash`.   |
| `Purchase verification failed: ... not found`           | Wrong `GOOGLE_PLAY_PACKAGE_NAME` or service account lacks app permission. Re-grant access in Play Console → Setup → API access. |
| `google-play.token-signing-key is not configured`       | `PAYMENT_TOKEN_SIGNING_KEY` env var is missing. Re-run blueprint or set it manually.                                            |
| 5xx with `Could not obtain Google service-account token`| Secret file isn't mounted at the path in `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, or the JSON is malformed. Re-upload it.            |
| Frontend gets `403 / CORS error`                        | Add the frontend origin to `CORS_ORIGINS` and save (triggers redeploy).                                                         |
