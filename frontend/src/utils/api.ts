const BASE = (import.meta.env.VITE_API_BASE as string | undefined) ?? '/api/v1';

export interface CreateOrderResponse {
  orderId: string;
  amount: number;
  currency: string;
  keyId: string;
  receipt: string;
  status: string;
}

export interface VerifyResponse {
  verified: boolean;
  paymentToken: string;
  message: string;
}

async function postJSON<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : '{}',
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    let message = `Request failed (${res.status})`;
    try {
      const parsed = JSON.parse(text);
      if (parsed?.error) message = parsed.error;
    } catch {
      if (text) message = text;
    }
    throw new Error(message);
  }
  return res.json() as Promise<T>;
}

export const api = {
  createOrder: () => postJSON<CreateOrderResponse>('/payment/create-order', {}),

  verifyPayment: (payload: {
    razorpayOrderId: string;
    razorpayPaymentId: string;
    razorpaySignature: string;
  }) => postJSON<VerifyResponse>('/payment/verify', payload),

  parseResume: (paymentToken: string, resumeText: string) =>
    postJSON<{ resume: any; message: string }>('/resume/parse', {
      paymentToken,
      resumeText,
    }),
};
