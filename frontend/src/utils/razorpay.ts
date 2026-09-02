import { api } from './api';

const CHECKOUT_SRC = 'https://checkout.razorpay.com/v1/checkout.js';

declare global {
  interface Window {
    Razorpay?: new (options: Record<string, unknown>) => {
      open: () => void;
      on: (event: string, handler: (response: any) => void) => void;
    };
  }
}

let loader: Promise<void> | null = null;

/**
 * Loads Razorpay's checkout script on demand. Kept out of index.html so the
 * third-party script is only fetched when someone actually chooses to pay.
 */
function loadCheckout(): Promise<void> {
  if (window.Razorpay) return Promise.resolve();
  if (loader) return loader;

  loader = new Promise<void>((resolve, reject) => {
    const script = document.createElement('script');
    script.src = CHECKOUT_SRC;
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => {
      // Allow a later retry rather than caching the failure forever.
      loader = null;
      reject(new Error('Could not load Razorpay checkout. Check your connection and retry.'));
    };
    document.head.appendChild(script);
  });
  return loader;
}

/**
 * Runs the full web payment flow and resolves with the server-issued payment
 * token:
 *   1. ask the server for an order (amount is server-side, so the price can't
 *      be tampered with from the browser),
 *   2. open Razorpay Checkout,
 *   3. send the result back for signature verification.
 *
 * Rejects with a readable message if the user closes the sheet or payment fails.
 */
export async function payWithRazorpay(
  onStatus: (status: string) => void,
): Promise<string> {
  onStatus('Creating order…');
  const order = await api.createRazorpayOrder();
  if (!order?.orderId || !order?.keyId) {
    throw new Error('Server did not return a valid Razorpay order.');
  }

  await loadCheckout();
  const Checkout = window.Razorpay;
  if (!Checkout) throw new Error('Razorpay checkout is unavailable.');

  return new Promise<string>((resolve, reject) => {
    let settled = false;
    const finish = (fn: () => void) => {
      if (settled) return;
      settled = true;
      fn();
    };

    const rzp = new Checkout({
      key: order.keyId,
      order_id: order.orderId,
      amount: order.amount,
      currency: order.currency,
      name: order.companyName,
      description: order.description,
      theme: { color: '#6d4bff' },

      handler: async (response: any) => {
        try {
          onStatus('Verifying payment…');
          const result = await api.verifyRazorpayPayment({
            razorpayOrderId: response?.razorpay_order_id,
            razorpayPaymentId: response?.razorpay_payment_id,
            razorpaySignature: response?.razorpay_signature,
          });
          if (!result?.paymentToken) {
            throw new Error('Server did not return a payment token.');
          }
          finish(() => resolve(result.paymentToken));
        } catch (e) {
          // Money may have been taken but verification failed — be explicit
          // rather than showing a generic failure.
          const detail = e instanceof Error ? e.message : String(e);
          finish(() =>
            reject(
              new Error(
                `Payment went through but could not be verified (${detail}). ` +
                  'If you were charged, contact support with your payment id.',
              ),
            ),
          );
        }
      },

      // Fires when the user closes the sheet without paying. Harmless after a
      // successful payment because the promise is already settled.
      modal: {
        ondismiss: () => finish(() => reject(new Error('Payment cancelled'))),
      },
    });

    rzp.on('payment.failed', (response: any) => {
      const message =
        response?.error?.description || response?.error?.reason || 'Payment failed';
      finish(() => reject(new Error(message)));
    });

    onStatus('Opening Razorpay…');
    rzp.open();
  });
}
