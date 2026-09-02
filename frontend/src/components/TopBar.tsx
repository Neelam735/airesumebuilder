interface Props {
  onImprove: () => void;
  onDownload: () => void;
  onReset: () => void;
  isExporting: boolean;
}

export default function TopBar({ onImprove, onDownload, onReset, isExporting }: Props) {
  return (
    <header className="sticky top-0 z-30 bg-bg/80 backdrop-blur border-b border-bg-border">
      <div className="max-w-[1600px] mx-auto px-6 h-14 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-md bg-brand/20 flex items-center justify-center">
            <span className="text-brand font-bold">R</span>
          </div>
          <div>
            <div className="text-sm font-semibold leading-none">AI Resume Builder</div>
            <div className="text-[11px] text-ink-muted">Build · Enhance · Export</div>
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
          <button onClick={onDownload} className="btn-secondary" disabled={isExporting}>
            {isExporting ? 'Exporting…' : '⬇ Download PDF'}
          </button>
        </div>
      </div>
    </header>
  );
}
