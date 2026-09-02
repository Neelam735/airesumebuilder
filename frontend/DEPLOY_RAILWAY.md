# Deploy the web app to Railway

The frontend is a static Vite/React build served by nginx. `Dockerfile` builds
it and `railway.json` tells Railway to use that Dockerfile (not Railpack).

You end up with **two Railway services in one project**:

| Service | Root directory | Purpose |
|---|---|---|
| backend | `backend` | Spring Boot API |
| web | `frontend` | this site |

## 1. Create the service

1. Railway → your project → **New → GitHub Repo** → pick `airesumebuilder`.
2. Open the new service → **Settings → Source**:
   - **Branch**: `main`
   - **Root Directory**: `frontend`  ← essential, or Railway builds the repo root and fails
3. **Settings → Build** should show the **Dockerfile** builder. If it shows
   Railpack/Nixpacks, the root directory is wrong — `frontend/railway.json`
   isn't being found.

## 2. Set the API base

**Variables → New Variable:**

```
VITE_API_BASE = https://airesumebuilder-production-648a.up.railway.app
```

> Vite inlines env vars at **build** time, so this must exist *before* the build
> runs. The Dockerfile declares `ARG VITE_API_BASE` and Railway passes the
> service variable in as a build arg. Changing it later requires a **redeploy**,
> not just a restart — a restart reuses the already-built bundle.

Do **not** point it at `/api/v1`; the API is on a different host, so it needs
the full URL.

## 3. Deploy

Railway builds and starts nginx on its injected `$PORT`. Then
**Settings → Networking → Generate Domain** gives you a
`*.up.railway.app` URL to test.

## 4. Allow the site through CORS

The browser calls the API from a different origin, so the backend must permit
it. On the **backend** service add/extend:

```
CORS_ORIGINS = https://airesumebuilder.bizwisetech.com,https://<your-web>.up.railway.app
```

Comma-separated, no spaces, **no trailing slash**, and include the scheme.

> Use exact origins — **not `*`**. The backend sends
> `allowCredentials(true)`, and browsers reject a wildcard origin combined with
> credentials, so `*` silently breaks every request.

Redeploy the backend after changing this.

## 5. Custom domain — `airesumebuilder.bizwisetech.com`

1. Web service → **Settings → Networking → Custom Domain → + Custom Domain**.
2. Enter `airesumebuilder.bizwisetech.com`.
3. Railway shows a **CNAME target** like `abc123.up.railway.app`. Copy it.
4. At the DNS provider for `bizwisetech.com`, add:

   | Field | Value |
   |---|---|
   | Type | `CNAME` |
   | Name / Host | `airesumebuilder` (just the subdomain, not the full name) |
   | Value / Target | the `…up.railway.app` target Railway gave you |
   | TTL | Automatic (or 300) |
   | Proxy | **DNS only** — see the Cloudflare note below |

5. Wait for DNS to propagate. Railway verifies the record and issues a TLS
   certificate automatically — no certificate work on your side.
6. The Railway dashboard shows the domain as **Active** when it's done.

Check it from your machine:

```bash
dig +short CNAME airesumebuilder.bizwisetech.com
curl -I https://airesumebuilder.bizwisetech.com
```

### Notes and gotchas

- **CNAME, not A.** Railway's IPs change; an A record will break.
- **Subdomain only.** A root domain (`bizwisetech.com`) can't take a CNAME under
  standard DNS. A subdomain like this one is fine.
- **Cloudflare users:** set the record to **DNS only** (grey cloud) at first.
  The orange-cloud proxy can block Railway's certificate issuance. Once the
  domain is Active you may enable the proxy, but then set SSL/TLS mode to
  **Full (strict)** — "Flexible" causes a redirect loop.
- **Don't forget step 4.** Adding the domain without adding it to
  `CORS_ORIGINS` gives a site that loads but whose API calls all fail in the
  browser console.

## 6. Verify end to end

1. Open `https://airesumebuilder.bizwisetech.com` — the app loads.
2. Refresh on a deep link — still loads (nginx falls back to `index.html`).
3. Perform an action that calls the API; confirm no CORS error in the console.
4. Check the backend logs for the matching `USER_EVENT ... action=…` line.

## Local check

```bash
cd frontend
docker build --build-arg VITE_API_BASE=https://your-api.up.railway.app -t rb-web .
docker run --rm -e PORT=8080 -p 8080:8080 rb-web
# open http://localhost:8080
```
