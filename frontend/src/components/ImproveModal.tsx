import { useEffect, useRef, useState } from 'react';
import { api } from '../utils/api';
import { mergeAiResume } from '../utils/applyAiResume';
import { extractTextFromPdf } from '../utils/pdfExtract';
import { useResumeStore } from '../store/resumeStore';

interface Props {
  open: boolean;
  onClose: () => void;
}

type Stage = 'idle' | 'extracting' | 'improving' | 'done' | 'error';

export default function ImproveModal({ open, onClose }: Props) {
  const resume = useResumeStore((s) => s.resume);
  const setResume = useResumeStore((s) => s.setResume);
  const markAiEnhanced = useResumeStore((s) => s.markAiEnhanced);

  const [stage, setStage] = useState<Stage>('idle');
  const [status, setStatus] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [fileName, setFileName] = useState<string | null>(null);
  const [resumeText, setResumeText] = useState('');
  const [progress, setProgress] = useState(0);
  const fileRef = useRef<HTMLInputElement>(null);

  const stageTarget = stage === 'extracting' ? 0.25 : stage === 'improving' ? 0.9 : 0;

  useEffect(() => {
    if (stage !== 'extracting' && stage !== 'improving') return;
    const id = setInterval(() => {
      setProgress((p) => Math.min(p + (stageTarget - p) * 0.08, 0.985));
    }, 100);
    return () => clearInterval(id);
  }, [stage, stageTarget]);

  if (!open) return null;

  const busy = stage === 'extracting' || stage === 'improving';

  const reset = () => {
    setStage('idle');
    setStatus('');
    setError(null);
    setFileName(null);
    setResumeText('');
    setProgress(0);
  };

  const close = () => {
    if (busy) return;
    reset();
    onClose();
  };

  const onPickFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setError(null);
    setFileName(file.name);
    setProgress(0.02);
    setStage('extracting');
    setStatus('Reading your PDF…');
    try {
      const text = await extractTextFromPdf(file);
      if (!text.trim()) {
        throw new Error(
          'No text found in that PDF. Scanned or image-only PDFs cannot be read — ' +
            'paste your resume text instead.',
        );
      }
      setResumeText(text);
      setStage('idle');
      setStatus('');
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
      setStage('error');
    } finally {
      // Allow re-picking the same file.
      if (fileRef.current) fileRef.current.value = '';
    }
  };

  const improve = async () => {
    if (!resumeText.trim()) {
      setError('Upload a PDF or paste your resume text first.');
      setStage('error');
      return;
    }
    setError(null);
    try {
      setProgress((p) => Math.max(p, 0.28));
      setStage('improving');
      setStatus('Rewriting your resume with AI…');
      // Enhancement is free; payment is collected at download time instead.
      const result = await api.parseResume('', resumeText);

      setResume(mergeAiResume(resume, result.resume));
      markAiEnhanced();
      setProgress(1);
      setStage('done');
      setStatus('');
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
      setStage('error');
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
          <h3 className="text-lg font-semibold">Import &amp; Improve Resume</h3>
        </div>

        {stage === 'done' ? (
          <>
            <p className="text-sm text-ink-muted">
              Your resume has been rewritten and loaded into the editor. Review
              the wording, then download it as a PDF — that's when the one-time
              ₹19 applies.
            </p>
            <div className="mt-4 rounded-lg border border-emerald-500/30 bg-emerald-500/10 p-3 text-[13px] text-emerald-400">
              AI rewrite applied.
            </div>
            <button type="button" onClick={close} className="btn-primary w-full mt-4">
              Review my resume
            </button>
          </>
        ) : (
          <>
            <p className="text-sm text-ink-muted">
              Upload your existing resume and let AI rewrite it in stronger,
              more professional language.{' '}
              <span className="text-brand font-semibold">Enhancing is free</span>
              {' '}— you only pay ₹19 when you download the result.
            </p>

            {/* Step 1 — source */}
            <div className="mt-4">
              <label className="text-[12px] font-medium text-ink-muted">
                1. Your current resume
              </label>
              <input
                ref={fileRef}
                type="file"
                accept="application/pdf,.pdf"
                onChange={onPickFile}
                disabled={busy}
                className="hidden"
                id="improve-file"
              />
              <button
                type="button"
                onClick={() => fileRef.current?.click()}
                disabled={busy}
                className="btn-secondary w-full mt-2 disabled:opacity-50"
              >
                {fileName ? `📄 ${fileName}` : 'Choose a PDF…'}
              </button>

              <div className="text-center text-[11px] text-ink-muted my-2">or</div>

              <textarea
                value={resumeText}
                onChange={(e) => setResumeText(e.target.value)}
                disabled={busy}
                rows={5}
                placeholder="Paste your resume text here…"
                className="w-full rounded-lg border border-bg-border bg-bg-soft p-3 text-[13px] outline-none focus:border-brand disabled:opacity-50"
              />
            </div>

            {error && (
              <div className="mt-3 rounded-lg border border-red-500/30 bg-red-500/10 p-3 text-[12px] text-red-400">
                {error}
              </div>
            )}

            {busy && (
              <div className="mt-3">
                <div className="h-2 w-full rounded-full bg-brand/15 overflow-hidden">
                  <div
                    className="h-full bg-brand transition-[width] duration-150 ease-out"
                    style={{ width: `${Math.round(progress * 100)}%` }}
                  />
                </div>
                <div className="mt-2 flex items-center justify-between">
                  <span className="text-[12px] font-medium text-ink">
                    {status || 'Working…'}
                  </span>
                  <span className="text-[13px] font-bold text-brand">
                    {Math.round(progress * 100)}%
                  </span>
                </div>
              </div>
            )}

            {/* Step 2 — pay & improve */}
            <button
              type="button"
              onClick={improve}
              disabled={busy || !resumeText.trim()}
              className="btn-primary w-full mt-4 disabled:opacity-50"
            >
              {busy ? status || 'Processing…' : '✨ Improve with AI — free'}
            </button>

            <p className="mt-3 text-[11px] text-ink-muted">
              Everything else — building, editing, exporting PDF, job matching
              and cover-letter drafting — remains free. See our{' '}
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

            <button
              type="button"
              onClick={close}
              disabled={busy}
              className="btn-ghost w-full mt-2 disabled:opacity-40"
            >
              Continue editing for free
            </button>
          </>
        )}
      </div>
    </div>
  );
}
