import { useEffect, useRef, useState } from 'react';
import { useResumeStore } from '../store/resumeStore';
import { api, type JobMatchItem } from '../utils/api';
import { exportElementAsPdf } from '../utils/pdfExport';
import ResumePreview from './ResumePreview';

interface Props {
  job: JobMatchItem | null;
  open: boolean;
  onClose: () => void;
}

type Stage = 'drafting' | 'ready' | 'applying' | 'done' | 'error';

export default function CoverLetterModal({ job, open, onClose }: Props) {
  const resume = useResumeStore((s) => s.resume);
  const setZoom = useResumeStore((s) => s.setZoom);
  const ui = useResumeStore((s) => s.ui);
  const [stage, setStage] = useState<Stage>('drafting');
  const [letter, setLetter] = useState('');
  const [error, setError] = useState<string | null>(null);
  const hiddenPreviewRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open || !job) return;
    setStage('drafting');
    setError(null);
    setLetter('');
    api
      .draftCoverLetter({
        name: resume.name,
        title: resume.title,
        summary: resume.summary,
        skills: resume.skills,
        jobTitle: job.title,
        company: job.company,
        jobDescription: job.snippet,
      })
      .then((res) => {
        setLetter(res.coverLetter);
        setStage('ready');
      })
      .catch((e) => {
        const err = e as Error;
        setError(err.message || 'Could not draft cover letter');
        setStage('error');
      });
  }, [open, job, resume]);

  if (!open || !job) return null;

  const downloadPdfAndOpenJob = async () => {
    setStage('applying');
    try {
      const target = hiddenPreviewRef.current?.firstElementChild as HTMLElement | null;
      const safeName = (resume.name || 'resume').toLowerCase().replace(/[^a-z0-9]+/g, '-');
      const prevZoom = ui.zoom;
      setZoom(1);
      await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
      if (target) await exportElementAsPdf(target, `${safeName}-${job.company.toLowerCase()}.pdf`);
      setZoom(prevZoom);

      window.open(job.url, '_blank', 'noopener,noreferrer');
      setStage('done');
    } catch (e) {
      const err = e as Error;
      setError(err.message || 'Could not finalise application');
      setStage('error');
    }
  };

  const copyLetter = () => navigator.clipboard.writeText(letter);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
      <div className="card w-full max-w-2xl p-6 relative max-h-[90vh] overflow-y-auto scroll-area">
        <button
          type="button"
          onClick={onClose}
          className="absolute top-3 right-3 text-ink-muted hover:text-ink"
          aria-label="Close"
        >
          ×
        </button>

        <div className="mb-4">
          <div className="text-[11px] uppercase tracking-widest text-ink-muted">
            Apply with AI
          </div>
          <h3 className="text-lg font-semibold mt-1">{job.title}</h3>
          <div className="text-xs text-ink-muted">
            {job.company}
            {job.location && ` · ${job.location}`}
          </div>
        </div>

        {stage === 'drafting' && (
          <div className="rounded-lg border border-bg-border bg-bg-soft p-6 text-center">
            <span className="inline-block w-2 h-2 rounded-full bg-brand pulse-dot mr-2" />
            Drafting a tailored cover letter…
          </div>
        )}

        {stage === 'error' && (
          <div className="rounded-lg border border-red-500/30 bg-red-500/10 text-red-300 p-3 text-sm">
            {error || 'Something went wrong.'}
          </div>
        )}

        {(stage === 'ready' || stage === 'applying' || stage === 'done') && (
          <>
            <div className="text-xs text-ink-muted mb-1">Cover letter (editable)</div>
            <textarea
              value={letter}
              onChange={(e) => setLetter(e.target.value)}
              rows={14}
              className="input-base text-sm font-serif leading-relaxed"
            />

            <div className="mt-4 grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={copyLetter}
                className="btn-secondary text-sm"
              >
                📋 Copy letter
              </button>
              <button
                type="button"
                onClick={downloadPdfAndOpenJob}
                disabled={stage === 'applying'}
                className="btn-primary text-sm"
              >
                {stage === 'applying'
                  ? 'Preparing…'
                  : stage === 'done'
                  ? '✓ Opened — apply now'
                  : '⬇ Download PDF & open job'}
              </button>
            </div>

            {stage === 'done' && (
              <p className="mt-3 text-[11px] text-ink-muted leading-relaxed">
                Your resume PDF was downloaded and the job page was opened in a new tab.
                Paste the cover letter above into the application form.
              </p>
            )}
          </>
        )}

        <div
          ref={hiddenPreviewRef}
          style={{
            position: 'fixed',
            left: '-10000px',
            top: 0,
            pointerEvents: 'none',
            opacity: 0,
          }}
        >
          <ResumePreview />
        </div>
      </div>
    </div>
  );
}
