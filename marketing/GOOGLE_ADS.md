# Google Ads — AI Resume Builder (web)

Paste-ready assets for a Responsive Search Ad pointing at
<https://airesumebuilder.bizwisetech.com/>.

Every asset below is within Google's character limits (headline 30,
description 90, path 15, sitelink 25 / description 35, callout 25), so none
should be rejected on length.

> **Unit economics, before you spend.** A download earns ₹19. Resume keywords
> in India typically cost ₹10–40 per click, and only a few percent of visitors
> will pay. A Search campaign will therefore lose money per conversion. Run it
> to learn which keywords and messages work, cap the budget, and expect the
> App campaign (cheaper installs) to be the better performer.

## Campaign settings

| Setting | Value |
|---|---|
| Campaign type | Search |
| Goal | Website traffic |
| Networks | Search only — **turn off** Search Partners and Display |
| Locations | India (or Bengaluru, Delhi, Mumbai, Hyderabad, Pune to start) |
| Languages | English, Hindi |
| Bidding | **Maximise clicks** with a max CPC cap of ₹15 |
| Budget | ₹300–500/day |
| Final URL | `https://airesumebuilder.bizwisetech.com/` |

Switch to **Expert Mode** when creating the account — the default "Smart"
flow hides most of these controls.

## Headlines (15, max 30 chars)

```
Free AI Resume Builder
AI Rewrites Your Resume
Resume Ready in 5 Minutes
Build Your Resume Free
Download PDF for Just Rs.19
No Subscription. Pay Once.
Upload PDF, AI Improves It
Professional Resume, Fast
Try Free, Pay to Download
Stronger Resume Wording
3 Clean Resume Templates
Make Your Resume Stand Out
Instant AI Resume Rewrite
Free Resume Maker Online
AI Resume Builder India
```

Pin **Free AI Resume Builder** to Headline 1 so the offer always shows.

## Descriptions (4, max 90 chars)

```
Build and preview your resume free. AI rewrites it in strong, professional language.
Upload your existing PDF or paste the text. See the improved version before you pay.
One-time Rs.19 to download as PDF. No subscription, no auto-renewal, no hidden fees.
Pay by UPI, card or net banking. Your polished resume downloads straight away.
```

## Display paths (max 15 each)

```
resume-builder / free-ai-resume
```

Shows as `airesumebuilder.bizwisetech.com/resume-builder/free-ai-resume`.

## Sitelink extensions

| Link text | Description line 1 | Description line 2 | URL |
|---|---|---|---|
| Pricing | What's free and what costs | Rs.19 one-time, no plans | `/pricing.html` |
| Refund Policy | When we refund and how | Request within 7 days | `/refund-policy.html` |
| Contact Us | Email and phone support | Reply within 2 days | `/contact-us.html` |
| Terms & Conditions | How the service works | Plain-English terms | `/terms-and-conditions.html` |

## Callout extensions

```
Free to try
No subscription
AI-powered rewriting
Instant PDF download
Pay by UPI or card
```

## Keywords

Start narrow. Broad terms like `resume` or `cv` will drain the budget in
hours against far better-funded competitors.

**Phrase match**
```
"ai resume builder"
"ai resume maker"
"free resume builder online"
"resume builder free download"
"ai resume writer"
"improve my resume"
"resume builder no subscription"
```

**Exact match**
```
[ai resume builder]
[free ai resume builder]
[ai resume builder india]
[resume builder free pdf]
```

## Negative keywords — add these before launching

```
-jobs            -vacancy         -naukri         -indeed
-template word   -format download -sample         -examples
-course          -writing service -writer job     -salary
-linkedin        -internship      -government     -pdf editor
-free download crack
```

`sample`, `format download` and `template word` matter most: they attract
people looking for a free file, not a tool, and they convert at ~0.

## Conversion tracking — set this up first

Without it Google cannot optimise and you cannot tell which keywords earned
money.

1. Google Ads → **Goals → Conversions → New conversion action → Website**
2. Enter `airesumebuilder.bizwisetech.com`
3. Create an action named **Resume download purchase**, category *Purchase*,
   value **19 INR**, count **Every**
4. Copy the **Google tag** (`AW-XXXXXXXXX`)

The tag goes in `frontend/index.html`, and the conversion event fires in
`PaymentModal` once payment is verified. Neither is wired up yet — the site
currently has no Google tag at all.

## First two weeks

- Leave bids and keywords alone for the first 7 days; edits restart learning.
- Check **Search terms** (not Keywords) every other day and add negatives for
  anything irrelevant. This is where most of the savings are.
- Pause any keyword with 50+ clicks and zero conversions.
- Judge the campaign on **cost per download**, not clicks or impressions.
