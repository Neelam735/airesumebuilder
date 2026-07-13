# Deploy the backend to Railway

Step‑by‑step guide to host the Spring Boot backend on Railway with a free HTTPS
subdomain (no custom domain required).

The backend already reads the platform‑assigned `PORT` (see `application.yml`:
`server.port: ${PORT:${SERVER_PORT:8080}}`) and ships a multi‑stage
`Dockerfile`, so Railway builds and runs it as‑is.

---

## 1. Prerequisites

- A GitHub account with this repo (`Neelam735/airesumebuilder`).
- A Railway account → sign up at **https://railway.app** (sign in with GitHub).
- Your `GEMINI_API_KEY` (from Google AI Studio).

---

## 2. Create the project from GitHub

1. Railway dashboard → **New Project**.
2. **Deploy from GitHub repo** → authorize Railway → pick
   `Neelam735/airesumebuilder`.
3. Railway creates a service and starts an initial build.

---

## 3. Point Railway at the backend folder

The Spring Boot app lives in `backend/`, so tell Railway where it is:

1. Open the service → **Settings**.
2. **Source → Root Directory** → set to `backend`.
3. **Build**: Railway auto‑detects `backend/Dockerfile` and uses it. (If it
   doesn't, set **Builder = Dockerfile**, Dockerfile path `Dockerfile`.)
4. Save. This triggers a rebuild.

> Alternatively you can deploy the `backend` branch (which has the files at the
> repo root) and leave Root Directory empty — but using `main` + Root Directory
> `backend` is simplest.

---

## 4. Set environment variables

Service → **Variables** → add:

| Variable | Value | Required |
|---|---|---|
| `GEMINI_API_KEY` | your Gemini key | ✅ |
| `GEMINI_MODEL` | `gemini-2.5-flash` | recommended |
| `PAYMENT_TOKEN_SIGNING_KEY` | a long random string (32+ chars) | ✅ |
| `GOOGLE_PLAY_PACKAGE_NAME` | `com.neelam.resumebuilder` | for billing |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | service‑account JSON (inline) | for billing verification |

Notes:
- **Do NOT set `PORT`** — Railway injects it automatically and the app reads it.
- `GOOGLE_PLAY_*` are only needed once you wire up real purchase verification
  (see the Play Console guide). The app runs without them; only
  `/payment/verify` needs them.
- Generate a signing key quickly: any 40+ random characters works.

After adding variables, Railway redeploys.

---

## 5. Generate the public HTTPS domain

1. Service → **Settings → Networking**.
2. **Generate Domain** (Railway may ask for the port — enter `8080`, which the
   app also honours as the default, or leave it to auto‑detect).
3. You get a URL like `https://airesumebuilder-production.up.railway.app` with
   HTTPS already enabled — no domain purchase needed.

---

## 6. Verify it's live

Open in a browser or curl:

```
https://<your-app>.up.railway.app/api/v1/health
```

Expected: `{"status":"UP"}`.

Quick end‑to‑end check of the AI path (PowerShell):

```powershell
$body = @{ paymentToken=""; resumeText="John Doe, Java and Spring engineer" } | ConvertTo-Json
Invoke-RestMethod -Method Post `
  -Uri "https://<your-app>.up.railway.app/api/v1/resume/parse" `
  -ContentType "application/json" -Body $body
```

- Returns enhanced JSON → backend + Gemini are working.
- Returns a Gemini error → check `GEMINI_API_KEY` / `GEMINI_MODEL`.

---

## 7. Point the app at the deployed backend

Run or build the Flutter app with the Railway URL:

```powershell
# dev run on a device
flutter run --dart-define=API_BASE=https://<your-app>.up.railway.app

# release AAB
flutter build appbundle --release `
  --dart-define=API_BASE=https://<your-app>.up.railway.app `
  --dart-define=GOOGLE_PLAY_PRODUCT_ID=ai_resume_improvement
```

The app appends `/api/v1` automatically, so pass only the host.

---

## 8. Redeploys & logs

- **Auto‑deploy:** every push to the deployed branch triggers a rebuild.
- **Logs:** service → **Deployments → View Logs** (look for
  `Started ResumeBuilderApplication` and `Tomcat started on port …`).
- **Rollback:** Deployments tab → pick a previous successful deploy → Redeploy.

---

## 9. Notes & gotchas

- **In‑memory state:** payment tokens live in memory, so a restart/redeploy
  clears them. Fine for now (the app also stores the unlock on‑device); add
  Postgres later if you want server‑side persistence.
- **Cold starts / sleeping:** on the free tier the service may sleep; the first
  request after idle can be slow. Upgrade the plan if you need it always‑on.
- **Health check:** the Dockerfile health check now targets the platform `PORT`
  (`${PORT:-${SERVER_PORT:-8080}}`), so Railway reports the service healthy.
- **CORS:** only needed for the web frontend, not the mobile app. Set
  `CORS_ORIGINS` if you also host the web UI.
