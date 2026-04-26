# BuildifyAi ⚡

> **Build Smarter. Launch Faster.**
>
> Got an idea? We help you bring it to life. Using AI, we make building apps and websites simple, fast, and stress-free.

A complete, modern, responsive startup website with two interchangeable backend options.

---

## ✨ What's inside

- **Frontend** – Hand-crafted HTML, CSS, and vanilla JS (no frameworks). Fully responsive, SEO-friendly, lightning fast.
- **Backend (choose one)**
  - **Node.js + Express** (`backend-node/`) – simple and quick.
  - **Java Spring Boot** (`backend-java/`) – enterprise-ready alternative.
- **Pages** – Landing (Hero / Features / Pricing / About / CTA), Contact, Login, Signup.
- **Contact API** – validates and stores submissions.
- **Auth UI stubs** – validated forms wired to API stubs (ready to plug into real auth).
- **Google Analytics** + **Google Ads placeholder** baked in.

---

## 🎨 Color palette

| Token         | Hex       | Usage                       |
| ------------- | --------- | --------------------------- |
| Primary       | `#6366F1` | Indigo - buttons, accents   |
| Primary Dark  | `#4F46E5` | Hover states                |
| Accent        | `#06B6D4` | Cyan - gradients, highlights|
| Dark          | `#0F172A` | Headings, footer background |
| Text          | `#1E293B` | Body copy                   |
| Muted         | `#64748B` | Secondary text              |
| Background    | `#F8FAFC` | Page background             |
| Success       | `#10B981` | Status messages             |
| Danger        | `#EF4444` | Errors                      |

Font: **Inter** (Google Fonts).

---

## 📁 Folder structure

```
airesumebuilder/
├── frontend/
│   ├── index.html          # Landing (Hero + Features + Pricing + About + CTA)
│   ├── contact.html        # Contact form (calls /api/contact)
│   ├── login.html          # Login UI
│   ├── signup.html         # Signup UI
│   ├── css/
│   │   └── styles.css
│   ├── js/
│   │   └── main.js
│   └── assets/
│
├── backend-node/           # Option A: Node + Express
│   ├── server.js
│   ├── package.json
│   ├── .env.example
│   └── routes/
│       ├── contact.js
│       └── auth.js
│
├── backend-java/           # Option B: Spring Boot
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/buildifyai/api/
│       │   ├── BuildifyAiApplication.java
│       │   ├── config/CorsConfig.java
│       │   ├── controller/
│       │   │   ├── ContactController.java
│       │   │   ├── AuthController.java
│       │   │   └── HealthController.java
│       │   ├── model/ContactMessage.java
│       │   └── service/ContactService.java
│       └── resources/application.properties
│
└── README.md
```

---

## 🚀 Quick start (local)

### 1. Frontend

The frontend is static — no build step.

```bash
cd frontend
# any static server works:
python3 -m http.server 3000
# or
npx serve -l 3000 .
```

Open <http://localhost:3000>.

By default it talks to `http://localhost:5000`. To override, set in the browser console **before loading the page** or in an inline tag in HTML:

```html
<script>window.API_BASE = 'https://your-api.com';</script>
```

### 2. Backend — Option A (Node.js)

```bash
cd backend-node
cp .env.example .env       # edit if needed
npm install
npm run dev                # nodemon, hot reload
# or
npm start
```

API runs on <http://localhost:5000>.

Endpoints:

| Method | Path              | Body                              | Notes                  |
| ------ | ----------------- | --------------------------------- | ---------------------- |
| GET    | `/`               | -                                 | service info           |
| GET    | `/health`         | -                                 | health check           |
| POST   | `/api/contact`    | `{ name, email, message }`        | stores to `data/contacts.json` |
| GET    | `/api/contact`    | -                                 | list all (admin) |
| POST   | `/api/auth/signup`| `{ name, email, password }`       | stub — returns demo token |
| POST   | `/api/auth/login` | `{ email, password }`             | stub — returns demo token |

### 3. Backend — Option B (Java Spring Boot)

Requires JDK 17+ and Maven 3.9+.

```bash
cd backend-java
mvn spring-boot:run
```

Same endpoints as the Node version, on <http://localhost:5000>.

---

## 🧪 Test the contact API

```bash
curl -X POST http://localhost:5000/api/contact \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane","email":"jane@test.com","message":"Hello BuildifyAi!"}'
```

Then submit the form on `contact.html`.

---

## ☁️ Deployment

### Frontend → Netlify

1. Push this repo to GitHub.
2. Sign in to <https://app.netlify.com> → **Add new site → Import existing project**.
3. Pick the repo, set:
   - **Base directory:** `frontend`
   - **Build command:** *(leave empty)*
   - **Publish directory:** `frontend`
4. Deploy. Netlify gives you a `*.netlify.app` URL.
5. **Custom domain:** Site settings → Domain management → Add custom domain → follow the DNS instructions (CNAME or Netlify nameservers).

### Frontend → Vercel

1. Sign in to <https://vercel.com> → **New Project** → import your repo.
2. **Root directory:** `frontend`. Framework preset: **Other**.
3. Deploy. You get a `*.vercel.app` URL.
4. **Custom domain:** Project → Settings → Domains → Add → follow DNS instructions.

> Before deploying, edit `frontend/js/main.js` and set `API_BASE` to your deployed backend URL, **or** add a small inline script in each HTML page:
> `<script>window.API_BASE = 'https://your-api.onrender.com';</script>`

### Backend → Render (Node)

1. Push this repo to GitHub.
2. <https://render.com> → **New → Web Service** → connect repo.
3. Settings:
   - **Root Directory:** `backend-node`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Environment:** Node
   - Add env var `CORS_ORIGIN=https://your-frontend.netlify.app`
4. Deploy. Copy the URL into the frontend `API_BASE`.

### Backend → Render (Java)

1. **New → Web Service** → connect repo.
2. Settings:
   - **Root Directory:** `backend-java`
   - **Build Command:** `mvn -DskipTests package`
   - **Start Command:** `java -jar target/buildifyai-api-1.0.0.jar`
   - Env var `CORS_ORIGIN=https://your-frontend.netlify.app`

### Backend → Railway

1. <https://railway.app> → **New Project → Deploy from GitHub**.
2. Pick `backend-node` (or `backend-java`) as the service root.
3. Railway auto-detects Node / Maven. Set env vars in the **Variables** tab.
4. Public URL is generated — paste it into the frontend.

### Connecting your custom domain

1. **Buy** a domain (Namecheap, Google Domains, Cloudflare, etc.).
2. **Frontend (Netlify/Vercel):** add the domain in dashboard → Netlify/Vercel shows the DNS records you need.
3. **At your registrar:** add the records (usually one `A` to the platform's IP and one `CNAME www`).
4. Wait for DNS to propagate (a few minutes to a few hours). HTTPS is automatic.
5. **Backend:** in Render/Railway, go to **Settings → Custom Domains** and follow the same flow with `api.yourdomain.com`. Update `CORS_ORIGIN` and the frontend `API_BASE` to match.

---

## 📊 Google Analytics

Open every HTML page and replace **both** instances of `G-XXXXXXXXXX` in the `<head>` with your real GA4 measurement ID (from <https://analytics.google.com>).

## 📢 Google Ads

A placeholder ad slot is already on the landing page (`<div class="ad-slot">`).

To activate **AdSense**:

1. Sign up at <https://www.google.com/adsense>.
2. Add the AdSense site verification snippet to the `<head>` of `index.html`.
3. Replace the placeholder block with the real `<ins class="adsbygoogle">` tag and load `adsbygoogle.js`.

---

## 🔐 Notes & next steps

- The contact endpoint stores data **in-memory / JSON file** — fine for a starter, swap for Postgres / Mongo for production.
- Auth endpoints are **UI-only stubs** that validate input and return a demo token. Wire them to JWT + a hashed-password store before launch.
- All forms have client-side validation; the backends also validate independently.
- Rate limiting is enabled on the Node API (60 req / 15 min per IP).

---

## 📜 License

MIT — go build something great.
