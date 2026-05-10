import { useState } from 'react';
import type { ReactNode } from 'react';

interface Props {
  title: string;
  subtitle?: string;
  defaultOpen?: boolean;
  actions?: ReactNode;
  children: ReactNode;
}

export default function SectionCard({
  title,
  subtitle,
  defaultOpen = true,
  actions,
  children,
}: Props) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className="card">
      <header className="flex items-center justify-between p-4 border-b border-bg-border">
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          className="flex items-center gap-2 text-left"
        >
          <span
            className={`inline-block w-2 h-2 rounded-full transition ${
              open ? 'bg-brand' : 'bg-bg-border'
            }`}
          />
          <div>
            <div className="text-sm font-semibold">{title}</div>
            {subtitle && <div className="text-[11px] text-ink-muted">{subtitle}</div>}
          </div>
        </button>
        <div className="flex items-center gap-2">{actions}</div>
      </header>
      {open && <div className="p-4 space-y-3">{children}</div>}
    </div>
  );
}
