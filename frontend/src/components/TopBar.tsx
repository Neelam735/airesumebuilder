import { useResumeStore } from '../store/resumeStore';

interface Props {
  onImprove: () => void;
  onDownload: () => void;
  onReset: () => void;
  isExporting: boolean;
}

export default function TopBar({ onImprove, onDownload, onReset, isExporting }: Props) {
  const downloadHint = useResumeStore((s) => s.downloadHint);
  const dismissDownloadHint = useResumeStore((s) => s.dismissDownloadHint);

  // Only guide the user while the hint is live and nothing is in flight.
  const showHint = downloadHint && !isExporting;

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
          <button onClick={onImprove} className="btn-primary">
            <span>✨</span>
            <span>Import &amp; Improve Resume</span>
          </button>

          {/* The hint hangs below the button, so the header keeps its height. */}
          <div className="relative">
            <button
              onClick={download}
              className={`btn-secondary ${
                showHint ? 'ring-2 ring-brand ring-offset-2 ring-offset-bg' : ''
              }`}
              disabled={isExporting}
            >
              {isExporting ? 'Exporting…' : '⬇ Download PDF'}
            </button>

            {showHint && (
              <div className="absolute right-0 top-full mt-3 w-64 z-40">
                {/* Bouncing arrow pointing up at the Download button. */}
                <div className="flex justify-end pr-5 -mb-1">
                  <span className="text-brand text-xl leading-none animate-bounce">
                    ▲
                  </span>
                </div>
                <div className="relative rounded-lg bg-brand text-white px-3 py-2.5 shadow-xl">
                  <button
                    type="button"
                    onClick={dismissDownloadHint}
                    aria-label="Dismiss"
                    className="absolute top-1.5 right-2 text-white/70 hover:text-white text-sm leading-none"
                  >
                    ×
                  </button>
                  <div className="text-[12px] font-semibold pr-4">
                    Your resume is enhanced ✨
                  </div>
                  <div className="text-[11px] text-white/90 mt-0.5">
                    Next step — download it as a PDF.
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
}
