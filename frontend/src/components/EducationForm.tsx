import { useResumeStore } from '../store/resumeStore';
import SectionCard from './SectionCard';
import { TextArea, TextField } from './Field';
import { uid } from '../utils/uid';

export default function EducationForm() {
  const resume = useResumeStore((s) => s.resume);
  const patch = useResumeStore((s) => s.patchResume);

  const update = (id: string, field: string, value: string) =>
    patch({
      education: resume.education.map((e) =>
        e.id === id ? { ...e, [field]: value } : e,
      ),
    });

  const remove = (id: string) =>
    patch({ education: resume.education.filter((e) => e.id !== id) });

  const add = () =>
    patch({
      education: [
        ...resume.education,
        { id: uid(), degree: '', institution: '', duration: '', description: '' },
      ],
    });

  return (
    <SectionCard
      title="Education"
      actions={
        <button type="button" onClick={add} className="btn-secondary text-xs">
          + Add
        </button>
      }
    >
      {resume.education.map((e, i) => (
        <div key={e.id} className="border border-bg-border rounded-lg p-3 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-[11px] text-ink-muted uppercase tracking-widest">
              #{i + 1}
            </span>
            <button
              type="button"
              onClick={() => remove(e.id)}
              className="text-xs text-ink-muted hover:text-red-400"
            >
              Remove
            </button>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <TextField
              label="Degree"
              value={e.degree}
              onChange={(ev) => update(e.id, 'degree', ev.target.value)}
            />
            <TextField
              label="Institution"
              value={e.institution}
              onChange={(ev) => update(e.id, 'institution', ev.target.value)}
            />
          </div>
          <TextField
            label="Duration"
            value={e.duration}
            onChange={(ev) => update(e.id, 'duration', ev.target.value)}
            placeholder="2015 — 2019"
          />
          <TextArea
            label="Description"
            rows={2}
            value={e.description}
            onChange={(ev) => update(e.id, 'description', ev.target.value)}
          />
        </div>
      ))}
    </SectionCard>
  );
}
