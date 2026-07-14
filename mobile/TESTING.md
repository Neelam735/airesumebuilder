# Testing guide — sample resumes & test cases

How to exercise the app end‑to‑end: **Enhance with AI** (PDF/Word upload) →
**Preview** (3 templates, pagination) → **Download** (PDF / Word) → **Pay** gate.

## How to make the test files
The uploader accepts **PDF** and **Word (.docx)**. To create them from the
samples below:
1. Copy a sample into **Microsoft Word** or **Google Docs**.
2. Save/Export as **PDF** (`File → Save As → PDF`) and/or **.docx**.
3. Upload each in the app: **Enhance Resume using AI**.

Use each sample to test a specific behavior (short, long/2‑page, special
characters, sparse).

---

## Sample 1 — Short, clean (1 page) — baseline happy path

```
Rahul Verma
Backend Engineer
rahul.verma@example.com | +91 98765 43210 | Bengaluru, India | linkedin.com/in/rahulverma

Summary
Backend engineer with 4 years building REST APIs and cloud services. Focused on reliability and clean design.

Experience
Backend Engineer, PayFlow (2022 - Present)
Built and scaled a payments API handling 1M+ daily transactions. Cut p99 latency by 40%.

Software Engineer, DataNest (2020 - 2022)
Developed microservices in Java and Spring Boot. Led migration from monolith to services.

Skills
Java, Spring Boot, REST APIs, PostgreSQL, Docker, AWS, Kafka

Education
B.Tech, Computer Science, VIT Vellore (2016 - 2020)

Projects
OpenAPI Linter — CLI that flags API spec issues. 1.2k GitHub stars. github.com/rahul/oas-lint

Languages
English, Hindi
```

**Expect:** enhances quickly, fits on **one page** in all 3 templates.

---

## Sample 2 — Long, multi‑role (2 pages) — pagination test

```
Ananya Iyer
Senior Product Designer
ananya.iyer@example.com | +91 90000 11111 | Mumbai, India | linkedin.com/in/ananyaiyer

Summary
Senior product designer with 9 years across fintech, health, and e-commerce. I lead design systems, run research, and ship end-to-end. I care about accessibility and measurable outcomes.

Experience
Senior Product Designer, HealthFirst (2021 - Present)
Owned the patient onboarding redesign that lifted activation by 27 percent. Built a 60-component design system adopted by 5 squads. Mentored 3 junior designers and ran weekly critique.

Product Designer, ShopStack (2018 - 2021)
Led checkout redesign reducing cart abandonment by 18 percent. Ran 40+ usability sessions. Partnered with engineering to ship a reusable component library.

UX Designer, FinPath (2016 - 2018)
Designed the first mobile app from scratch; 4.6 star rating at launch. Established the research practice and interview cadence.

Junior Designer, Brightside Agency (2014 - 2016)
Delivered brand and web work for 20+ clients. Built wireframe-to-prototype workflows.

Skills
Figma, Design Systems, User Research, Prototyping, Accessibility (WCAG), Usability Testing, Design Tokens, HTML, CSS, Interaction Design, Information Architecture, Workshop Facilitation

Education
M.Des, Interaction Design, IIT Bombay (2012 - 2014)
B.A., Visual Communication, Sophia College (2009 - 2012)

Projects
Design System "Aurora" — cross-platform tokens and components used org-wide.
Research Repository — searchable insights hub that cut duplicate studies by 30 percent.
Accessibility Audit Kit — checklist and templates adopted by the whole design org.

Languages
English, Hindi, Tamil, French
```

**Expect:** flows onto **2 pages**; section headings should stay with their
first entry (no orphaned "Experience" at a page bottom).

---

## Sample 3 — Special characters — font‑safety test

```
José Müñoz-Nguyễn
Full‑Stack Developer — “Cloud & AI”
jose.munoz@example.com | +34 600 123 456 | Madrid, España | linkedin.com/in/josemunoz

Summary
Developer specialising in résumé‑grade UIs and back‑ends. Salary target: ₹18,00,000 / €55k. Comfortable with “ambiguity” and rapid iteration — I ship.

Experience
Full‑Stack Developer, Ñandú Labs (2021 – Present)
Built a data‑viz platform (React + D3) → 3× faster dashboards. Reduced costs ~35 %.

Skills
JavaScript, TypeScript, React, Node.js, GraphQL, Python, café‑level SQL, CI/CD

Education
B.Sc. Informática, Universidad Politécnica (2015 – 2019)

Languages
Español, English, Tiếng Việt
```

**Expect:** curly quotes, em/en dashes, ₹, €, accents, and non‑Latin names
render (or gracefully simplify) in the PDF **without crashing** the preview.

---

## Sample 4 — Sparse / minimal — empty‑section test

```
Sam Lee
sam.lee@example.com

Skills
Excel, Communication
```

**Expect:** no name/title fallback issues; sections that are empty simply don't
appear; preview and download still work.

---

## Test‑case matrix

| # | Area | Steps | Expected |
|---|------|-------|----------|
| 1 | Upload PDF | Enhance → pick Sample 1 (PDF) | Progress bar runs to 100%, auto‑opens Preview |
| 2 | Upload Word | Enhance → pick Sample 1 (.docx) | Same as #1 |
| 3 | Progress UI | Watch the enhance dialog | Bar + % advance; "Enhancing with AI" is the long step |
| 4 | Old .doc rejected | Save Sample 1 as legacy **.doc** → upload | Clear message to use .docx or PDF |
| 5 | Template: Classic | Preview → set Classic | Centered header, clean sections |
| 6 | Template: Modern | Preview → set Modern | Colored sidebar band on left, no color bleed |
| 7 | Template: Minimal | Preview → set Minimal | Timeline layout, aligned dates |
| 8 | Pagination | Sample 2, each template | 2 pages; headers stay with first entry |
| 9 | Special chars | Sample 3, each template | No crash; symbols render or simplify |
| 10 | Sparse | Sample 4 | Only present sections show; no errors |
| 11 | Download PDF | Preview → Download → PDF | Share sheet opens a .pdf matching preview |
| 12 | Download Word | Preview → Download → Word | Share sheet opens a .docx that opens in Word |
| 13 | Pay gate (enhanced) | After AI enhance, tap Download | Payment dialog appears first |
| 14 | Pay once, both formats | Pay, then download PDF and Word | Both download without paying again |
| 15 | Reset | App bar → Reset | Back to sample; AI unlock cleared |
| 16 | Accent color | Edit → change accent | Preview + exports use new accent |
| 17 | Backend down | Stop backend → Enhance | Friendly error, "Try again" works |
| 18 | Offline | Airplane mode → Enhance | Network error surfaced, no crash |

---

## Quick backend smoke test (no app needed)
```powershell
$body = @{ paymentToken=""; resumeText="Rahul Verma, backend engineer skilled in Java, Spring Boot, REST APIs" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "https://<your-railway-url>/api/v1/resume/parse" -ContentType "application/json" -Body $body
```
Returns enhanced JSON → backend + Gemini healthy.

---

## What to watch for
- **Preview never shows a hard error** — if a template can't lay out, it falls
  back to a plain document (by design).
- **Download filename** is derived from the name (e.g. `rahul-verma.pdf` /
  `.docx`).
- **Word file opens** in Microsoft Word / Google Docs / WPS without a repair
  prompt.
