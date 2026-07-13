# Google Play purchase verification — service account setup

How to connect the backend to the Google Play Developer API so it can verify
in‑app purchases of `ai_resume_improvement`. This is what fixes the runtime
errors:

- **"Google Play verification is not configured on the server."**
  → the service‑account JSON isn't set on the backend (Part C).
- **"Purchase verification failed: The current user has insufficient
  permissions…"**
  → the service account isn't authorized for the app yet, or permissions are
  still propagating (Part D / Troubleshooting).

Fixed values for this app:

| Thing | Value |
|------|-------|
| Package name | `com.neelam.resumebuilder` |
| Product ID | `ai_resume_improvement` |
| Backend env (JSON) | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` |
| Backend env (package) | `GOOGLE_PLAY_PACKAGE_NAME` |

---

## Part A — Create the service account + JSON key (Google Cloud)

Do this at **https://console.cloud.google.com**.

1. **Select/create a project.** Top‑left project dropdown → **New Project**
   (e.g. `resume-billing`) → **Create** → then reopen the dropdown and
   **select** it so it's active. (The "Service Accounts" menu only appears once
   a project is selected.)
2. **Enable the API.** Top search bar → **"Google Play Android Developer API"**
   → open it → **Enable**. It must live in the **same project** as the service
   account.
3. **Open Service Accounts.** Top search bar → **"Service accounts"** → click
   *Service Accounts — IAM & Admin* (or ☰ menu → IAM & Admin → Service
   Accounts).
4. **Create service account** → name `play-billing-verify` →
   **Create and continue** → skip optional roles → **Done**.
5. **Create the key.** Click the new account → **Keys** tab →
   **Add key → Create new key → JSON → Create**. A `.json` file downloads —
   keep it safe; it's the credential the backend uses.
6. **Copy the email.** In the `.json`, the `"client_email"` field looks like
   `play-billing-verify@<project>.iam.gserviceaccount.com`. You'll need it in
   Part B.

---

## Part B — Grant the service account access (Play Console)

You can grant access directly by the service‑account email (no need for the
sometimes‑hidden "API access" page).

1. Play Console → **Users and permissions** → **Invite new users**.
2. Paste the service account **email** from Part A.
3. Under **Account permissions**, enable **both**:
   - **View financial data, orders, and cancellation survey responses**
   - **Manage orders and subscriptions**
4. **Invite user / Save.**

> If you can open **Setup → API access** (top search bar → "API access"), you
> can alternatively link the Cloud project and grant the account there. Either
> path works; the email‑grant above is the reliable one.

---

## Part C — Configure the backend (Railway)

1. Open the downloaded `.json` in a text editor → **select all → copy** the
   entire contents (from `{` to `}`).
2. Railway → your backend service → **Variables**:
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` = *paste the whole JSON* (multiline is
     fine; the backend auto‑detects inline JSON because it starts with `{`).
   - `GOOGLE_PLAY_PACKAGE_NAME` = `com.neelam.resumebuilder`
3. Save → Railway redeploys automatically.

### Verify it loaded
In the Railway deploy logs after restart you should see:
```
Google Play Billing config: packageName=com.neelam.resumebuilder productId=ai_resume_improvement serviceAccount=<provided>
```
and **no** `service-account-json is not set` warning.

> Security: the JSON is a secret. Keep it only in Railway variables — never
> commit it to git.

---

## Part D — Test

On a phone signed in as a **license tester**, installed from the Play internal
testing track:

1. Open the app → **Enhance Resume using AI** → auto‑jumps to **Preview** →
   **Download** → **Pay with Google Play**.
2. Complete the **test** purchase (testers aren't charged).
3. The app posts the purchase token to `/api/v1/payment/verify`; the backend
   calls Google Play, verifies it, and unlocks the download.

---

## Troubleshooting

### "The current user has insufficient permissions…"
Auth worked, but the account isn't authorized for the app yet.

1. **Propagation delay (most common).** New service‑account permissions can take
   **a few hours, up to ~24–48h** to activate. If you just granted access,
   simply wait and retry — often no other change is needed.
2. **Check the two permissions** (Part B) are actually ticked on the service
   account under **Users and permissions**.
3. **Same project.** The enabled *Google Play Android Developer API* and the
   service account must be in the **same** Cloud project.
4. **Package name** matches `com.neelam.resumebuilder` exactly.

### "Google Play verification is not configured on the server."
`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` isn't set (or failed to parse). Re‑paste the
full JSON into Railway (Part C) and confirm the log shows
`serviceAccount=<provided>`.

### 404 / "product not found" when purchasing
That's a device‑side Play issue, not verification: the product isn't Active, the
ID doesn't match `ai_resume_improvement`, the build isn't installed from a Play
track, or it's still propagating.

---

## How it works (reference)

- App (`in_app_purchase`) buys the consumable → gets a `purchaseToken`.
- App → `POST /api/v1/payment/verify` `{ productId, purchaseToken }`.
- Backend (`GooglePlayBillingClient`) calls
  `GET androidpublisher/v3/applications/{package}/purchases/products/{productId}/tokens/{token}`
  using the service‑account credentials, then consumes the token so it can't be
  reused, and returns a signed single‑use payment token that unlocks the
  AI‑enhanced PDF download.
