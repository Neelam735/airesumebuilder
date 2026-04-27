# BuildifyAi ⚡

> **Building Powerful Mobile Apps & Websites That Drive Growth.**
>
> A modern, professional, responsive marketing site for a tech studio that ships mobile apps, websites, UI/UX, and ongoing maintenance.

---

## ✨ What's inside

- **Frontend** – Hand-crafted HTML, CSS, and vanilla JS (no frameworks). Tech-focused **blue + purple** palette, gradient accents, soft shadows, scroll-in animations, fully responsive.
- **Backend (choose one)**
  - **Node.js + Express** (`backend-node/`) – simple and fast.
  - **Java Spring Boot** (`backend-java/`) – enterprise alternative.
- **5 pages** – Home, Services, Portfolio, About, Contact.
- **Contact API** – validates and stores project enquiries (name, email, company, service, message).
- **Google Analytics** + **integration-ready** structure (chat widgets, pixels, etc.).

---

## 🎨 Color palette

| Token         | Hex       | Usage                             |
| ------------- | --------- | --------------------------------- |
| Primary       | `#2563EB` | Blue – buttons, links, accents    |
| Primary Dark  | `#1D4ED8` | Hover states                      |
| Accent        | `#8B5CF6` | Violet – gradient pair            |
| Dark          | `#0B1120` | Footer, headings, dark sections   |
| Text          | `#1E293B` | Body copy                         |
| Muted         | `#64748B` | Secondary text                    |
| Soft          | `#F8FAFC` | Alternating section background    |
| Background    | `#FFFFFF` | Page background                   |

Signature gradient: `linear-gradient(135deg, #2563EB, #8B5CF6)`

Font: **Inter** (Google Fonts).

---

## 📁 Folder structure

```
airesumebuilder/
├── frontend/
│   ├── index.html          # Home (hero, services overview, process, testimonials, CTA)
│   ├── services.html       # Services + benefits
│   ├── portfolio.html      # 9 sample projects
│   ├── about.html          # Mission, vision, team, stats
│   ├── contact.html        # Contact form (calls /api/contact)
│   ├── css/styles.css
│   ├── js/main.js          # shared nav/footer + form + scroll reveal
│   └── assets/             # screenshots
│
├── backend-node/           # Option A: Node + Express
│   ├── server.js
│   ├── package.json
│   ├── .env.example
│   └── routes/
│       ├── contact.js
│       └── auth.js         # (kept as a stub - safe to ignore for the agency site)
│
├── backend-java/           # Option B: Spring Boot
│   ├── pom.xml
│   └── src/main/java/com/buildifyai/api/...
│
└── README.md
```

---

## 🚀 Quick start (local)

### 1. Frontend (static)

```bash
cd frontend
python3 -m http.server 3000
# or
npx serve -l 3000 .
```

Open <http://localhost:3000>.

By default the frontend talks to `http://localhost:5000`. Override per page by adding before `js/main.js`:

```html
<script>window.API_BASE = 'https://your-api.com';</script>
```

### 2. Backend — Option A (Node.js)

```bash
cd backend-node
cp .env.example .env
npm install
npm start              # or: npm run dev (nodemon)
```

API runs on <http://localhost:5000>.

| Method | Path           | Body                                                 |
| ------ | -------------- | ---------------------------------------------------- |
| POST   | `/api/contact` | `{ name, email, company?, service?, message }`       |
| GET    | `/api/contact` | list submissions                                     |
| GET    | `/health`      | health check                                         |

### 3. Backend — Option B (Java Spring Boot)

Requires JDK 17+ and Maven 3.9+.

```bash
cd backend-java
mvn spring-boot:run
```

Same endpoints on <http://localhost:5000>.

---

## 🧪 Test the contact API

```bash
curl -X POST http://localhost:5000/api/contact \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane","email":"jane@acme.com","company":"Acme","service":"mobile","message":"We need an iOS MVP in 8 weeks."}'
```

---

## ☁️ Deployment

### Frontend → Netlify

1. Push to GitHub → <https://app.netlify.com> → **Add new site → Import existing project**.
2. **Base directory:** `frontend` · **Build command:** *(empty)* · **Publish directory:** `frontend`.
3. Deploy. Add a custom domain in **Site settings → Domain management**.

### Frontend → Vercel

1. <https://vercel.com> → **New Project** → import the repo.
2. **Root directory:** `frontend`. Framework preset: **Other**. Deploy.
3. Add a custom domain in **Project → Settings → Domains**.

> Before deploying, set `window.API_BASE` to your deployed backend URL.

### Backend → Render

1. <https://render.com> → **New → Web Service** → connect repo.
2. For Node: **Root** `backend-node` · **Build** `npm install` · **Start** `npm start`.
3. For Java: **Root** `backend-java` · **Build** `mvn -DskipTests package` · **Start** `java -jar target/buildifyai-api-1.0.0.jar`.
4. Env var: `CORS_ORIGIN=https://your-frontend.netlify.app`.

### Backend → Railway

1. <https://railway.app> → **New Project → Deploy from GitHub** → pick the backend folder.
2. Set env vars in **Variables**. Public URL is generated — paste into the frontend.

### Custom domain

1. Buy a domain (Namecheap, Cloudflare, Google Domains, etc.).
2. **Frontend:** add the domain in Netlify/Vercel → set the displayed DNS records at your registrar.
3. **Backend:** in Render/Railway, **Settings → Custom Domains** → use a subdomain like `api.yourdomain.com`. Update `CORS_ORIGIN` and `window.API_BASE`.
4. HTTPS is automatic on all three platforms.

---

## 📊 Integrations

- **Google Analytics** — replace `G-XXXXXXXXXX` in every HTML page's `<head>`.
- **Live chat** (Intercom / Crisp / Tawk.to) — paste the snippet right before `</body>` in each HTML file.
- **Conversion pixels / Google Ads** — add to the `<head>` of `index.html` and `contact.html`.

---

## 🔐 Notes

- Contact submissions are stored in `backend-node/data/contacts.json` (Node) or in-memory (Java) — swap for Postgres / Mongo before launch.
- Rate limiting on the Node API: 60 req / 15 min per IP.
- All forms validate on the client *and* on the server.

---

## 📜 License

MIT — go build something great.
