import { useState } from 'react';

interface Props {
  label?: string;
  values: string[];
  onChange: (next: string[]) => void;
  placeholder?: string;
}

export default function ListInput({ label, values, onChange, placeholder }: Props) {
  const [draft, setDraft] = useState('');

  const add = () => {
    const v = draft.trim();
    if (!v) return;
    onChange([...values, v]);
    setDraft('');
  };

  return (
    <div>
      {label && <span className="label-base">{label}</span>}
      <div className="flex gap-2">
        <input
          className="input-base flex-1"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          placeholder={placeholder ?? 'Type and press Enter'}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              add();
            }
          }}
        />
        <button type="button" onClick={add} className="btn-secondary">
          Add
        </button>
      </div>
      {values.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-1.5">
          {values.map((v, i) => (
            <span
              key={i}
              className="inline-flex items-center gap-1 px-2 py-1 rounded-md text-xs bg-bg-soft border border-bg-border"
            >
              {v}
              <button
                type="button"
                onClick={() => onChange(values.filter((_, j) => j !== i))}
                className="text-ink-muted hover:text-red-400"
                aria-label={`Remove ${v}`}
              >
                ×
              </button>
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
