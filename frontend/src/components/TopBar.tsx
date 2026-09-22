import { useResumeStore } from '../store/resumeStore';

interface Props {
  onImprove: () => void;
  onDownload: () => void;
  onReset: () => void;
  isExporting: boolean;
}

/**
 * A pointer that hangs below a header button: a bouncing arrow aiming up at
 * it, plus a short caption. It sits below rather than over the button because
 * the header is sticky and only 56px tall, so anything above would be clipped.
 */
function StepHint({
  step,
  title,
  detail,
  onDismiss,
}: {
  step: string;
  title: string;
  detail: string;
  onDismiss: () => void;
}) {
  return (
    <div className="absolute right-0 top-full mt-3 w-64 z-40">
      <div className="flex justify-end pr-5 -mb-1">
        <span className="text-brand text-xl leading-none animate-bounce">▲</span>
      </div>
      <div className="relative rounded-lg bg-brand text-white px-3 py-2.5 shadow-xl">
        <button
          type="button"
          onClick={onDismiss}
          aria-label="Dismiss"
          className="absolute top-1.5 right-2 text-white/70 hover:text-white text-sm leading-none"
        >
          ×
        </button>
        <div className="text-[10px] uppercase tracking-wide text-white/75 font-semibold">
          {step}
        </div>
        <div className="text-[12px] font-semibold pr-4">{title}</div>
        <div className="text-[11px] text-white/90 mt-0.5">{detail}</div>
      </div>
    </div>
  );
}

export default function TopBar({ onImprove, onDownload, onReset, isExporting }: Props) {
  const improveHint = useResumeStore((s) => s.improveHint);
  const downloadHint = useResumeStore((s) => s.downloadHint);
  const dismissImproveHint = useResumeStore((s) => s.dismissImproveHint);
  const dismissDownloadHint = useResumeStore((s) => s.dismissDownloadHint);

  // Only ever one pointer at a time, and none while an export is running.
  const showDownloadHint = downloadHint && !isExporting;
  const showImproveHint = improveHint && !downloadHint && !isExporting;

  const improve = () => {
    dismissImproveHint();
    onImprove();
  };

  const download = () => {
    dismissDownloadHint();
    onDownload();
  };

  return (
    <header className="sticky top-0 z-30 bg-bg/80 backdrop-blur border-b border-bg-border">
      <div className="max-w-[1600px] mx-auto px-6 h-14 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-md bg-brand/20 flex items-center justify-center">
            <span className="text-brand font-bold">R</span>
          </div>
          <div>
            <div className="text-sm font-semibold leading-none">AI Resume Builder</div>
            <div className="text-[11px] text-ink-muted">Build · Improve · Export</div>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button onClick={onReset} className="btn-ghost text-xs">
            Reset
          </button>

          <div className="relative">
            <button
              onClick={improve}
              className={`btn-primary ${
                showImproveHint ? 'ring-2 ring-brand ring-offset-2 ring-offset-bg' : ''
              }`}
            >
              <span>✨</span>
              <span>Import &amp; Improve Resume</span>
            </button>

            {showImproveHint && (
              <StepHint
                step="Step 1"
                title="Start here"
                detail="Upload or paste your resume and let AI rewrite it — free."
                onDismiss={dismissImproveHint}
              />
            )}
          </div>

          <div className="relative">
            <button
              onClick={download}
              className={`btn-secondary ${
                showDownloadHint ? 'ring-2 ring-brand ring-offset-2 ring-offset-bg' : ''
              }`}
              disabled={isExporting}
            >
              {isExporting ? 'Exporting…' : '⬇ Download PDF'}
            </button>

            {showDownloadHint && (
              <StepHint
                step="Step 2"
                title="Your resume is enhanced ✨"
                detail="Next step — download it as a PDF."
                onDismiss={dismissDownloadHint}
              />
            )}
          </div>
        </div>
      </div>
    </header>
  );
}
