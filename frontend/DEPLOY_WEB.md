# Deploy the web app (AI Resume Builder)

The `frontend/` folder is a React + Vite + TypeScript + Tailwind web version of
the resume builder. It talks to the **same backend** you deployed on Railway.

On the web, AI enhancement is **free** (no payment) and PDF download is
client-side, so no billing setup is needed — only the API URL + CORS.

---

## 1. Point the web app at your backend
Set the build-time env var `VITE_API_BASE` to your Railway API base (note the
`/api/v1` suffix):
```
VITE_API_BASE=https://airesumebuilder-production-648a.up.railway.app/api/v1
```
Locally you can copy `.env.production.example` → `.env.production`.
On a host (Vercel/Netlify), set it as an environment variable instead.

## 2. Allow the web origin on the backend (CORS)
The backend now applies CORS from the `CORS_ORIGINS` env var (comma-separated,
wildcards allowed). After you know your web URL, set on Railway:
```
CORS_ORIGINS=http://localhost:5173,https://<your-web-domain>,https://*.vercel.app
```
Then redeploy the backend. (Without this, the browser blocks API calls.)

## 3a. Deploy to Vercel (easiest)
1. Go to vercel.com → New Project → import the GitHub repo.
2. **Root Directory:** `frontend`
3. Framework preset: **Vite** (auto-detected). Build: `npm run build`, Output: `dist`.
4. Add env var **`VITE_API_BASE`** = your Railway API base (step 1).
5. Deploy → you get `https://<project>.vercel.app`.
6. Add that URL to `CORS_ORIGINS` on Railway (step 2) and redeploy the backend.

## 3b. Deploy to Netlify (alternative)
1. netlify.com → Add new site → import the repo.
2. **Base directory:** `frontend`, Build: `npm run build`, Publish: `frontend/dist`.
3. Add env var `VITE_API_BASE`.
4. Deploy → add the Netlify URL to `CORS_ORIGINS` and redeploy the backend.

## 3c. Cloudflare Pages / GitHub Pages
Also work (static site). For GitHub Pages set `base` in `vite.config.ts` to the
repo subpath. Vercel/Netlify are simpler because they support env vars + SPA
rewrites out of the box (see `vercel.json` / `netlify.toml`).

---

## 4. Test locally first (optional)
```bash
cd frontend
npm install
# talk to the deployed backend:
VITE_API_BASE=https://airesumebuilder-production-648a.up.railway.app/api/v1 npm run dev
# open http://localhost:5173
```

## Verify
- Open the deployed site → build a resume → **Improve/Enhance with AI** →
  it should call `/api/v1/resume/parse` and fill the form.
- Export PDF works entirely in the browser.
- If the browser console shows a CORS error, the web origin isn't in
  `CORS_ORIGINS` yet (step 2).
