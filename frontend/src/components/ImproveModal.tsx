import { useEffect, useRef, useState } from 'react';
import { useRazorpay } from '../hooks/useRazorpay';
import { extractTextFromPdf } from '../utils/pdfExtract';
import { api } from '../utils/api';
import { mergeAiResume } from '../utils/applyAiResume';
import { useResumeStore } from '../store/resumeStore';

interface Props {
  open: boolean;
  onClose: () => void;
}

type Stage =
  | 'idle'
  | 'paying'
  | 'paid'
  | 'extracting'
  | 'improving'
  | 'filling'
  | 'done'
  | 'error';

const stages: { key: Stage; label: string }[] = [
  { key: 'extracting', label: 'Extracting resume' },
  { key: 'improving', label: 'Improving with AI' },
  { key: 'filling', label: 'Auto-filling form' },
];

export default function ImproveModal({ open, onClose }: Props) {
  const [stage, setStage] = useState<Stage>('idle');
  const [paymentToken, setPaymentToken] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [statusText, setStatusText] = useState<string>('');
  const fileInputRef = useRef<HTMLInputElement>(null);
  const resume = useResumeStore((s) => s.resume);
  const setResume = useResumeStore((s) => s.setResume);
  const { openCheckout } = useRazorpay();

  useEffect(() => {
    if (!open) {
      setStage('idle');
      setPaymentToken(null);
      setError(null);
      setStatusText('');
    }
  }, [open]);

  if (!open) return null;

  const startPayment = () => {
    setError(null);
    setStage('paying');
    openCheckout({
      prefill: { name: resume.name, email: resume.email, contact: resume.phone },
      onStatus: (s) => setStatusText(s),
      onSuccess: ({ paymentToken }) => {
        setPaymentToken(paymentToken);
        setStage('paid');
        setStatusText('Payment verified. Upload your PDF resume.');
      },
      onFailure: (err) => {
        setError(err.message);
        setStage('error');
      },
      onDismiss: () => {
        if (!paymentToken) {
          setStage('idle');
          setStatusText('');
        }
      },
    });
  };

  const onPickFile = () => fileInputRef.current?.click();

  const onFile = async (file: File | undefined) => {
    if (!file || !paymentToken) return;
    setError(null);
    try {
      setStage('extracting');
      const text = await extractTextFromPdf(file);

      setStage('improving');
      const result = await api.parseResume(paymentToken, text);

      setStage('filling');
      const next = mergeAiResume(resume, result.resume);
      setResume(next);

      setStage('done');
    } catch (e) {
      const err = e as Error;
      setError(err.message || 'Something went wrong');
      setStage('error');
    }
  };

  const stepIndex = stages.findIndex((s) => s.key === stage);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
      <div className="card w-full max-w-md p-6 relative animate-in fade-in zoom-in-95">
        <button
          type="button"
          onClick={onClose}
          className="absolute top-3 right-3 text-ink-muted hover:text-ink"
          aria-label="Close"
        >
          ×
        </button>

        <div className="flex items-center gap-2 mb-1">
          <span className="inline-block w-1.5 h-1.5 rounded-full bg-brand pulse-dot" />
          <h3 className="text-lg font-semibold">Import & Improve Resume</h3>
        </div>
        <p className="text-sm text-ink-muted mb-5">
          Upload your existing PDF and let AI rewrite it using strong, professional language.
        </p>

        {(stage === 'idle' || stage === 'paying') && (
          <div className="space-y-4">
            <div className="rounded-lg border border-brand/30 bg-brand/5 p-4 flex items-center justify-between">
              <div>
                <div className="text-sm font-medium">Unlock AI improvement</div>
                <div className="text-[12px] text-ink-muted">One-time fee per use</div>
              </div>
              <div className="text-2xl font-bold text-brand">₹29</div>
            </div>

            <button
              type="button"
              onClick={startPayment}
              className="btn-primary w-full"
              disabled={stage === 'paying'}
            >
              {stage === 'paying' ? statusText || 'Processing…' : 'Pay ₹29 with Razorpay'}
            </button>

            <p className="text-[11px] text-ink-muted text-center">
              Secure payment via Razorpay. You'll be able to upload your PDF after the payment is verified.
            </p>
          </div>
        )}

        {stage === 'paid' && (
          <div className="space-y-3">
            <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 p-3 text-sm text-emerald-200">
              ✓ Payment verified. Upload your resume PDF below.
            </div>
            <input
              ref={fileInputRef}
              type="file"
              accept="application/pdf"
              hidden
              onChange={(e) => onFile(e.target.files?.[0])}
            />
            <button
              type="button"
              onClick={onPickFile}
              className="w-full border-2 border-dashed border-bg-border hover:border-brand/50 rounded-xl py-8 flex flex-col items-center justify-center transition"
            >
              <span className="text-2xl mb-1">⬆</span>
              <span className="text-sm font-medium">Click to upload a PDF</span>
              <span className="text-[11px] text-ink-muted">
                Max ~5 MB · Standard resumes work best
              </span>
            </button>
          </div>
        )}

        {(stage === 'extracting' || stage === 'improving' || stage === 'filling') && (
          <div className="space-y-3">
            {stages.map((s, i) => {
              const active = i === stepIndex;
              const done = i < stepIndex;
              return (
                <div
                  key={s.key}
                  className={`flex items-center gap-3 px-3 py-2 rounded-md border ${
                    active
                      ? 'border-brand/50 bg-brand/10'
                      : done
                      ? 'border-emerald-500/30 bg-emerald-500/5'
                      : 'border-bg-border'
                  }`}
                >
                  <span
                    className={`w-2.5 h-2.5 rounded-full ${
                      done
                        ? 'bg-emerald-400'
                        : active
                        ? 'bg-brand pulse-dot'
                        : 'bg-bg-border'
                    }`}
                  />
                  <span
                    className={`text-sm ${
                      active ? 'text-ink' : done ? 'text-emerald-200' : 'text-ink-muted'
                    }`}
                  >
                    {s.label}
                  </span>
                </div>
              );
            })}
          </div>
        )}

        {stage === 'done' && (
          <div className="space-y-3">
            <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 p-3 text-sm text-emerald-200">
              ✓ Your resume has been improved and the form is filled.
            </div>
            <button type="button" onClick={onClose} className="btn-primary w-full">
              View improved resume
            </button>
          </div>
        )}

        {stage === 'error' && (
          <div className="space-y-3">
            <div className="rounded-lg border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-300">
              {error || 'Something went wrong.'}
            </div>
            <button
              type="button"
              onClick={() => {
                setError(null);
                setStage(paymentToken ? 'paid' : 'idle');
              }}
              className="btn-secondary w-full"
            >
              Try again
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
