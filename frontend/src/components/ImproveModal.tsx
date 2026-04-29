interface Props {
  open: boolean;
  onClose: () => void;
}

export default function ImproveModal({ open, onClose }: Props) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
      <div className="card w-full max-w-md p-6 relative">
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
          <h3 className="text-lg font-semibold">Import &amp; Improve Resume</h3>
        </div>
        <p className="text-sm text-ink-muted">
          AI resume rewrite is available as a paid one-time unlock through
          Google Play in-app purchase, on the Android app.
        </p>

        <div className="mt-5 rounded-lg border border-bg-border bg-bg-soft p-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-md bg-brand/20 flex items-center justify-center text-brand">
              📱
            </div>
            <div className="text-sm">
              <div className="font-medium">Get Resume Forge AI on Android</div>
              <div className="text-[12px] text-ink-muted">
                Build, improve and auto-apply on your phone.
              </div>
            </div>
          </div>
          <ul className="mt-3 text-[12px] text-ink-muted list-disc pl-5 space-y-1">
            <li>One-time ₹29 unlock via Google Play Billing</li>
            <li>Same templates and editor as the web app</li>
            <li>Smart job matching by skills, with AI-tailored cover letters</li>
          </ul>
        </div>

        <p className="mt-4 text-[11px] text-ink-muted">
          Everything else on the web app — building, editing, exporting PDF,
          job matching, and cover-letter drafting — remains free.
        </p>

        <button type="button" onClick={onClose} className="btn-secondary w-full mt-4">
          Continue editing
        </button>
      </div>
    </div>
  );
}
