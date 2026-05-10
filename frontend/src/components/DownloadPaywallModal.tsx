import { useState } from 'react';
import { api } from '../utils/api';

interface Props {
  open: boolean;
  onClose: () => void;
  onVerified: () => void;
}

type Phase = 'idle' | 'verifying' | 'error';

export default function DownloadPaywallModal({ open, onClose, onVerified }: Props) {
  const [token, setToken] = useState('');
  const [phase, setPhase] = useState<Phase>('idle');
  const [error, setError] = useState('');

  if (!open) return null;

  const handleClose = () => {
    setToken('');
    setPhase('idle');
    setError('');
    onClose();
  };

  const handleVerify = async () => {
    if (!token.trim()) {
      setError('Please enter your purchase token.');
      return;
    }
    setPhase('verifying');
    setError('');
    try {
      await api.verifyPayment(token.trim());
      handleClose();
      onVerified();
    } catch (e: any) {
      setError(e?.message || 'Verification failed. Please check your token and try again.');
      setPhase('error');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
      <div className="card w-full max-w-md p-6 relative">
        <button
          type="button"
          onClick={handleClose}
          className="absolute top-3 right-3 text-ink-muted hover:text-ink"
          aria-label="Close"
        >
          ×
        </button>

        <div className="flex items-center gap-2 mb-1">
          <span className="text-xl">⬇</span>
          <h3 className="text-lg font-semibold">Download Resume PDF</h3>
        </div>
        <p className="text-sm text-ink-muted mb-4">
          PDF download requires a one-time unlock. Purchase on the Android app, then paste your
          Google Play purchase token below.
        </p>

        <div className="rounded-lg border border-bg-border bg-bg-soft p-4 mb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-md bg-brand/20 flex items-center justify-center text-brand text-lg">
              📱
            </div>
            <div className="text-sm">
              <div className="font-medium">Resume Forge AI on Android</div>
              <div className="text-[12px] text-ink-muted">One-time ₹29 unlock via Google Play Billing</div>
            </div>
          </div>
        </div>

        <label className="label-base">Purchase Token</label>
        <input
          type="text"
          className="input-base mb-1"
          placeholder="Paste your Google Play purchase token…"
          value={token}
          onChange={(e) => setToken(e.target.value)}
          disabled={phase === 'verifying'}
        />

        {phase === 'error' && (
          <p className="text-sm text-red-400 mt-2 mb-1">{error}</p>
        )}

        <p className="text-[11px] text-ink-dim mb-4 mt-2">
          Open the Android app → purchase complete → copy the token shown there.
        </p>

        <button
          type="button"
          onClick={handleVerify}
          disabled={phase === 'verifying' || !token.trim()}
          className="btn-primary w-full"
        >
          {phase === 'verifying' ? 'Verifying…' : 'Verify & Download'}
        </button>
        <button type="button" onClick={handleClose} className="btn-ghost w-full mt-2">
          Cancel
        </button>
      </div>
    </div>
  );
}
