import { useRef, useState } from 'react';
import { useResumeStore } from '../store/resumeStore';
import { api } from '../utils/api';
import { extractTextFromPdf } from '../utils/pdfExtract';
import { mergeAiResume } from '../utils/applyAiResume';

interface Props {
  open: boolean;
  onClose: () => void;
}

type Phase = 'idle' | 'parsing' | 'done' | 'error';

export default function ImproveModal({ open, onClose }: Props) {
  const [file, setFile] = useState<File | null>(null);
  const [text, setText] = useState('');
  const [phase, setPhase] = useState<Phase>('idle');
  const [error, setError] = useState('');
  const fileRef = useRef<HTMLInputElement>(null);
  const resume = useResumeStore((s) => s.resume);
  const setResume = useResumeStore((s) => s.setResume);

  if (!open) return null;

  const handleClose = () => {
    setFile(null);
    setText('');
    setPhase('idle');
    setError('');
    onClose();
  };

  const handleImprove = async () => {
    setPhase('parsing');
    setError('');
    try {
      let resumeText = text.trim();
      if (file) {
        resumeText = await extractTextFromPdf(file);
      }
      if (!resumeText) {
        setError('Please upload a PDF or paste your resume text.');
        setPhase('idle');
        return;
      }
      const result = await api.parseResume(resumeText);
      setResume(mergeAiResume(resume, result.resume));
      setPhase('done');
    } catch (e: any) {
      setError(e?.message || 'Something went wrong. Please try again.');
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

        {phase === 'done' ? (
          <>
            <div className="flex items-center gap-2 mb-3">
              <span className="text-green-400 text-xl">✓</span>
              <h3 className="text-lg font-semibold">Resume improved!</h3>
            </div>
            <p className="text-sm text-ink-muted mb-5">
              AI has parsed and enhanced your resume. Review the changes in the editor.
            </p>
            <button type="button" onClick={handleClose} className="btn-primary w-full">
              View improved resume
            </button>
          </>
        ) : (
          <>
            <div className="flex items-center gap-2 mb-1">
              <span className="inline-block w-1.5 h-1.5 rounded-full bg-brand pulse-dot" />
              <h3 className="text-lg font-semibold">Import &amp; Improve Resume</h3>
            </div>
            <p className="text-sm text-ink-muted mb-4">
              Upload your existing resume PDF or paste the text — AI will parse and enhance it for free.
            </p>

            <div
              className="border-2 border-dashed border-bg-border rounded-lg p-4 text-center cursor-pointer hover:border-brand/50 transition mb-3"
              onClick={() => fileRef.current?.click()}
            >
              <input
                ref={fileRef}
                type="file"
                accept=".pdf"
                className="hidden"
                onChange={(e) => {
                  setFile(e.target.files?.[0] ?? null);
                  setText('');
                }}
              />
              {file ? (
                <p className="text-sm text-ink">{file.name}</p>
              ) : (
                <>
                  <p className="text-sm text-ink-muted">Click to upload PDF</p>
                  <p className="text-[11px] text-ink-dim mt-1">or paste resume text below</p>
                </>
              )}
            </div>

            {!file && (
              <textarea
                className="input-base resize-none mb-3"
                rows={5}
                placeholder="Paste your resume text here…"
                value={text}
                onChange={(e) => setText(e.target.value)}
              />
            )}

            {phase === 'error' && (
              <p className="text-sm text-red-400 mb-3">{error}</p>
            )}

            <button
              type="button"
              onClick={handleImprove}
              disabled={phase === 'parsing' || (!file && !text.trim())}
              className="btn-primary w-full"
            >
              {phase === 'parsing' ? 'Improving…' : '✨ Improve with AI'}
            </button>
            <button type="button" onClick={handleClose} className="btn-ghost w-full mt-2">
              Cancel
            </button>
          </>
        )}
      </div>
    </div>
  );
}
