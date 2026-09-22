import { useState } from 'react';
import { payWithRazorpay } from '../utils/razorpay';
import { useResumeStore } from '../store/resumeStore';

interface Props {
  open: boolean;
  onClose: () => void;
  /** Called once payment is verified, so the caller can start the download. */
  onPaid: () => void;
}

/**
 * Shown when the user downloads an AI-enhanced resume that hasn't been paid
 * for. AI enhancement itself is free — this is the only paid step.
 */
export default function PaymentModal({ open, onClose, onPaid }: Props) {
  const setPaymentToken = useResumeStore((s) => s.setPaymentToken);
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState('');
  const [error, setError] = useState<string | null>(null);

  if (!open) return null;

  const close = () => {
    if (busy) return;
    setError(null);
    setStatus('');
    onClose();
  };

  const pay = async () => {
    setBusy(true);
    setError(null);
    try {
      const token = await payWithRazorpay(setStatus);
      setPaymentToken(token);
      setBusy(false);
      setStatus('');
      onPaid();
    } catch (e) {
      setBusy(false);
      setStatus('');
      setError(e instanceof Error ? e.message : String(e));
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
      <div className="card w-full max-w-md p-6 relative">
        <button
          type="button"
          onClick={close}
          disabled={busy}
          className="absolute top-3 right-3 text-ink-muted hover:text-ink disabled:opacity-40"
          aria-label="Close"
        >
          ×
        </button>

        <div className="flex items-center gap-2 mb-1">
          <span className="inline-block w-1.5 h-1.5 rounded-full bg-brand pulse-dot" />
          <h3 className="text-lg font-semibold">Unlock your download</h3>
        </div>
        <p className="text-sm text-ink-muted">
          Your AI-enhanced resume is ready. Pay once to download it as a PDF —
          you can re-download it afterwards without paying again.
        </p>

        <div className="mt-4 rounded-lg border border-brand/30 bg-brand/10 p-4 flex items-center">
          <div className="flex-1">
            <div className="text-sm font-semibold">AI-enhanced PDF download</div>
            <div className="text-[11px] text-ink-muted">
              One-time payment · UPI, card or net banking
            </div>
          </div>
          <div className="text-2xl font-bold text-brand">₹19</div>
        </div>

        {error && (
          <div className="mt-3 rounded-lg border border-red-500/30 bg-red-500/10 p-3 text-[12px] text-red-400">
            {error}
          </div>
        )}

        {busy && (
          <div className="mt-3 flex items-center gap-2 text-[12px] text-ink-muted">
            <span className="inline-block w-3 h-3 rounded-full border-2 border-brand border-t-transparent animate-spin" />
            {status || 'Working…'}
          </div>
        )}

        <button
          type="button"
          onClick={pay}
          disabled={busy}
          className="btn-primary w-full mt-4 disabled:opacity-50"
        >
          {busy ? status || 'Processing…' : 'Pay ₹19 & download'}
        </button>

        <button
          type="button"
          onClick={close}
          disabled={busy}
          className="btn-ghost w-full mt-2 disabled:opacity-40"
        >
          Not now
        </button>

        <p className="mt-3 text-[11px] text-ink-muted">
          Payment is processed securely by Razorpay. See our{' '}
          <a
            href="/refund-policy.html"
            target="_blank"
            rel="noopener"
            className="underline hover:text-ink"
          >
            refund policy
          </a>
          .
        </p>
      </div>
    </div>
  );
}
