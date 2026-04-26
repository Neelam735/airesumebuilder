import { useCallback } from 'react';
import { api } from '../utils/api';

declare global {
  interface Window {
    Razorpay: any;
  }
}

export interface RazorpayHandlerArgs {
  paymentToken: string;
}

export interface OpenCheckoutOptions {
  onSuccess: (args: RazorpayHandlerArgs) => void;
  onFailure: (err: Error) => void;
  onDismiss?: () => void;
  prefill?: { name?: string; email?: string; contact?: string };
  onStatus?: (status: string) => void;
}

export function useRazorpay() {
  const openCheckout = useCallback(async (opts: OpenCheckoutOptions) => {
    if (!window.Razorpay) {
      opts.onFailure(new Error('Razorpay SDK not loaded. Check your network.'));
      return;
    }

    try {
      opts.onStatus?.('Creating order…');
      const order = await api.createOrder();

      const options = {
        key: order.keyId,
        amount: order.amount,
        currency: order.currency,
        order_id: order.orderId,
        name: 'AI Resume Builder',
        description: 'Unlock AI Resume Improvement',
        image: '/favicon.svg',
        prefill: opts.prefill ?? {},
        theme: { color: '#7c5cff' },
        modal: {
          ondismiss: () => opts.onDismiss?.(),
        },
        handler: async (response: {
          razorpay_payment_id: string;
          razorpay_order_id: string;
          razorpay_signature: string;
        }) => {
          try {
            opts.onStatus?.('Verifying payment…');
            const verify = await api.verifyPayment({
              razorpayOrderId: response.razorpay_order_id,
              razorpayPaymentId: response.razorpay_payment_id,
              razorpaySignature: response.razorpay_signature,
            });
            if (!verify.verified || !verify.paymentToken) {
              opts.onFailure(new Error('Payment verification failed'));
              return;
            }
            opts.onSuccess({ paymentToken: verify.paymentToken });
          } catch (e) {
            opts.onFailure(e as Error);
          }
        },
      };

      const rz = new window.Razorpay(options);
      rz.on('payment.failed', (resp: any) => {
        opts.onFailure(new Error(resp?.error?.description ?? 'Payment failed'));
      });
      rz.open();
    } catch (e) {
      opts.onFailure(e as Error);
    }
  }, []);

  return { openCheckout };
}
