# Razorpay setup

Razorpay is offered alongside Google Play billing as a UPI / card / net-banking
option. The order is created and the payment signature verified **on the
server**, so the amount cannot be changed by the app and a forged payment
cannot unlock the download.

## 1. Get your API keys

Razorpay Dashboard → **Settings → API Keys → Generate Key**.

You get a **Key Id** (`rzp_test_…` / `rzp_live_…`) and a **Key Secret**.

> The **Key Secret is server-only**. It is never sent to the app — only the key
> id reaches the client. Never commit either value.

## 2. Set the environment variables

In Railway → your service → **Variables**:

| Variable | Required | Default | Notes |
|---|---|---|---|
| `RAZORPAY_KEY_ID` | yes | — | e.g. `rzp_test_abc123` |
| `RAZORPAY_KEY_SECRET` | yes | — | server-only secret |
| `RAZORPAY_AMOUNT_PAISE` | no | `2900` | charge in paise (2900 = ₹29.00) |
| `RAZORPAY_CURRENCY` | no | `INR` | |
| `RAZORPAY_COMPANY_NAME` | no | `AI Resume Builder` | shown on the checkout sheet |
| `RAZORPAY_DESCRIPTION` | no | `AI-enhanced resume download` | shown on the checkout sheet |

Without the two required variables the endpoints return `503` and the app's
Razorpay button fails cleanly — Google Play billing is unaffected.

At startup the log line confirms what was picked up (the secret is only ever
reported as present, never printed):

```
Razorpay config: keyId=rzp_test_abc123 secret=<provided> amount=2900 INR
```

## 3. Endpoints

### Create an order
```
POST /api/v1/payment/razorpay/order
```
Returns the order plus the public key id:
```json
{
  "orderId": "order_XXXXXXXX",
  "amount": 2900,
  "currency": "INR",
  "keyId": "rzp_test_abc123",
  "companyName": "AI Resume Builder",
  "description": "AI-enhanced resume download"
}
```
The amount comes from server config — the client never sends it.

### Verify a payment
```
POST /api/v1/payment/razorpay/verify
{
  "razorpayOrderId": "order_XXXXXXXX",
  "razorpayPaymentId": "pay_YYYYYYYY",
  "razorpaySignature": "<signature from checkout>"
}
```

The server recomputes `HMAC_SHA256(orderId + "|" + paymentId, keySecret)` and
compares it in constant time. On a match it issues the same signed payment
token a Google Play purchase yields, so the download-unlock path is identical
for both providers.

- valid signature → `200` with `paymentToken`
- forged signature → `400 Payment signature verification failed`
- missing fields → `400`

## 4. Testing

Use **test mode** keys (`rzp_test_…`). Razorpay's test cards:

| Card | Result |
|---|---|
| `4111 1111 1111 1111` | success (any future expiry, any CVV) |
| `5104 0600 0000 0008` | success (Mastercard) |

For UPI in test mode use `success@razorpay` / `failure@razorpay`.

You can verify the signature check without the app:

```bash
BASE="https://<your-app>.up.railway.app"
SECRET="<your key secret>"
ORDER="order_TEST"; PAY="pay_TEST"
SIG=$(printf '%s' "$ORDER|$PAY" | openssl dgst -sha256 -hmac "$SECRET" -hex | sed 's/.*= *//')

# valid -> 200 + paymentToken
curl -s -X POST "$BASE/api/v1/payment/razorpay/verify" -H 'Content-Type: application/json' \
  -d "{\"razorpayOrderId\":\"$ORDER\",\"razorpayPaymentId\":\"$PAY\",\"razorpaySignature\":\"$SIG\"}"

# forged -> 400
curl -s -X POST "$BASE/api/v1/payment/razorpay/verify" -H 'Content-Type: application/json' \
  -d "{\"razorpayOrderId\":\"$ORDER\",\"razorpayPaymentId\":\"$PAY\",\"razorpaySignature\":\"deadbeef\"}"
```

Both appear in the logs as `action=RAZORPAY_VERIFY`.

## 5. Android release builds

`android/app/proguard-rules.pro` keeps the Razorpay classes and the JavaScript
bridge it drives the checkout sheet through. Without those rules checkout
crashes in minified release builds.

## 6. Google Play policy — read before shipping

Google Play's Payments policy generally requires **Google Play Billing** for
digital goods bought inside an app distributed on Play. Shipping Razorpay as
the payment method for the AI download can put the listing at risk.

India is a special case: following the CCI ruling, Google permits alternative
and user-choice billing for apps served to Indian users, but the terms (and the
service-fee reduction) are specific, and the alternative option normally has to
be offered *alongside* Play billing rather than replacing it — which is how
this integration is wired.

Confirm your obligations for the markets you ship to before enabling Razorpay
in a production release. Keeping the Google Play button visible, as it is here,
is the safer configuration.
