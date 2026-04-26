import { useResumeStore } from '../store/resumeStore';
import { computeScore } from '../utils/score';
import type { TemplateId } from '../types/resume';

const templates: { id: TemplateId; name: string; desc: string }[] = [
  { id: 'classic', name: 'Classic', desc: 'Centered, serif, formal' },
  { id: 'modern', name: 'Modern', desc: 'Sidebar, accent-driven' },
  { id: 'minimal', name: 'Minimal', desc: 'Clean, timeline-style' },
];

const palette = ['#7c5cff', '#22d3ee', '#10b981', '#f59e0b', '#ef4444', '#0f172a'];

export default function CustomizationPanel() {
  const resume = useResumeStore((s) => s.resume);
  const ui = useResumeStore((s) => s.ui);
  const setTemplate = useResumeStore((s) => s.setTemplate);
  const setAccent = useResumeStore((s) => s.setAccent);
  const setZoom = useResumeStore((s) => s.setZoom);

  const { score, tips } = computeScore(resume);

  return (
    <div className="space-y-4">
      <div className="card p-4">
        <div className="section-title mb-2">Resume Score</div>
        <div className="flex items-center gap-3">
          <div className="relative w-14 h-14">
            <svg viewBox="0 0 36 36" className="w-14 h-14 -rotate-90">
              <circle cx="18" cy="18" r="15.9" fill="none" stroke="#222836" strokeWidth="3" />
              <circle
                cx="18"
                cy="18"
                r="15.9"
                fill="none"
                stroke={ui.accent}
                strokeWidth="3"
                strokeLinecap="round"
                strokeDasharray={`${score} 100`}
              />
            </svg>
            <div className="absolute inset-0 flex items-center justify-center text-sm font-semibold">
              {score}
            </div>
          </div>
          <div className="text-xs text-ink-muted leading-relaxed">
            {score >= 85
              ? 'Looks great — ready to send.'
              : score >= 60
              ? 'Solid draft. A few tweaks will help.'
              : 'Add more details to boost your score.'}
          </div>
        </div>
        {tips.length > 0 && (
          <ul className="mt-3 space-y-1 text-[11px] text-ink-muted list-disc pl-4">
            {tips.slice(0, 3).map((t, i) => (
              <li key={i}>{t}</li>
            ))}
          </ul>
        )}
      </div>

      <div className="card p-4">
        <div className="section-title mb-3">Template</div>
        <div className="space-y-2">
          {templates.map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTemplate(t.id)}
              className={`w-full text-left px-3 py-2 rounded-md border transition ${
                ui.template === t.id
                  ? 'border-brand bg-brand/10'
                  : 'border-bg-border hover:bg-bg-soft'
              }`}
            >
              <div className="text-sm font-medium">{t.name}</div>
              <div className="text-[11px] text-ink-muted">{t.desc}</div>
            </button>
          ))}
        </div>
      </div>

      <div className="card p-4">
        <div className="section-title mb-3">Accent color</div>
        <div className="flex flex-wrap gap-2">
          {palette.map((c) => (
            <button
              key={c}
              type="button"
              aria-label={`Accent ${c}`}
              onClick={() => setAccent(c)}
              className={`w-7 h-7 rounded-full border-2 ${
                ui.accent === c ? 'border-white' : 'border-bg-border'
              }`}
              style={{ backgroundColor: c }}
            />
          ))}
          <input
            type="color"
            value={ui.accent}
            onChange={(e) => setAccent(e.target.value)}
            className="w-7 h-7 rounded-full bg-transparent border border-bg-border cursor-pointer"
            aria-label="Custom color"
          />
        </div>
      </div>

      <div className="card p-4">
        <div className="section-title mb-2">Zoom</div>
        <input
          type="range"
          min={0.5}
          max={1.2}
          step={0.05}
          value={ui.zoom}
          onChange={(e) => setZoom(parseFloat(e.target.value))}
          className="w-full accent-brand"
        />
        <div className="text-[11px] text-ink-muted text-right">
          {Math.round(ui.zoom * 100)}%
        </div>
      </div>
    </div>
  );
}
