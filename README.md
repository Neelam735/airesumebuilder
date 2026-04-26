# AI Resume Builder

A production-ready resume builder with three templates, live preview, PDF export, and an
AI-powered "Import & Improve Resume" flow gated behind a ₹29 Razorpay payment.

- **Frontend** — Vite + React 18 + TypeScript + Tailwind + Zustand + react-hook-form
- **Backend** — Java 17 + Spring Boot 3 (REST + WebClient)
- **Payments** — Razorpay (server-side order creation + HMAC-SHA256 signature verification)
- **AI** — OpenAI Chat Completions (JSON mode)
- **PDF** — `pdfjs-dist` for parsing, `html2pdf.js` for export

No database is required — everything is auto-saved to `localStorage`, and verified
payment tokens live in an in-memory map on the backend.

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
│       ├── service/               # PaymentService, ResumeService
│       ├── client/                # RazorpayClient, OpenAIClient
│       ├── dto/
│       └── exception/
│   └── src/main/resources/application.yml
│
└── frontend/                      # React + Vite app
    ├── index.html
    └── src/
        ├── components/            # UI building blocks + ImproveModal
        ├── pages/BuilderPage.tsx  # 3-pane layout
        ├── templates/             # Classic / Modern / Minimal
        ├── hooks/useRazorpay.ts
        ├── store/resumeStore.ts   # Zustand + persist
        ├── utils/                 # api, pdf parse, pdf export, score
        └── types/resume.ts
```

---

## How the payment-gated AI flow works

1. User clicks **✨ Import & Improve Resume**.
2. Modal opens showing **₹29** unlock; clicking **Pay** calls `POST /api/v1/payment/create-order`.
3. Razorpay Checkout opens with the returned `order_id` and `key_id`.
4. After the user pays, Razorpay invokes the handler with `razorpay_payment_id`,
   `razorpay_order_id`, and `razorpay_signature`.
5. Frontend calls `POST /api/v1/payment/verify`. The backend computes
   `HMAC_SHA256(order_id + "|" + payment_id, key_secret)` and compares it to the signature
   in **constant time**. On success it issues a short-lived signed payment token.
6. The PDF upload step only unlocks once a valid token is held.
7. Frontend extracts text with `pdfjs-dist` and posts it together with the token to
   `POST /api/v1/resume/parse`. The backend rejects the request unless the token validates.
8. OpenAI returns improved structured JSON, the backend forwards it, and the frontend merges it
   into the form. The token is consumed (single-use) after a successful parse.

---

## Backend setup

### Prerequisites

- Java 17+
- Maven 3.9+
- Razorpay test account → `KEY_ID` + `KEY_SECRET`
- OpenAI API key

### Run locally

```bash
cd backend

export RAZORPAY_KEY_ID=rzp_test_xxxxx
export RAZORPAY_KEY_SECRET=your_test_secret
export OPENAI_API_KEY=sk-xxxxx
# optional overrides
export RAZORPAY_AMOUNT=2900            # paise = ₹29.00
export OPENAI_MODEL=gpt-4o-mini

mvn spring-boot:run
```

Server boots at `http://localhost:8080`.

Health check:

```bash
curl http://localhost:8080/api/v1/health
```

### REST API

| Method | Path                              | Purpose                                  |
| ------ | --------------------------------- | ---------------------------------------- |
| `POST` | `/api/v1/payment/create-order`    | Creates a Razorpay order (₹29 default)   |
| `POST` | `/api/v1/payment/verify`          | Verifies signature, returns payment token|
| `POST` | `/api/v1/resume/parse`            | AI-improves resume; requires token       |
| `GET`  | `/api/v1/health`                  | Liveness                                 |

`POST /api/v1/payment/verify` body:

```json
{
  "razorpayOrderId": "order_...",
  "razorpayPaymentId": "pay_...",
  "razorpaySignature": "<hex>"
}
```

Response:

```json
{ "verified": true, "paymentToken": "<token>", "message": "Payment verified successfully" }
```

`POST /api/v1/resume/parse` body:

```json
{ "paymentToken": "<token>", "resumeText": "..." }
```

A `402 Payment Required` is returned if the token is missing/expired/invalid.

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
- **AI model / prompt** — edit `OPENAI_MODEL` and `ResumeService.SYSTEM_PROMPT`.
