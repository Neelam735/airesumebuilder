import { useResumeStore } from '../store/resumeStore';
import SectionCard from './SectionCard';
import { TextArea, TextField } from './Field';
import { uid } from '../utils/uid';

export default function ExperienceForm() {
  const resume = useResumeStore((s) => s.resume);
  const patch = useResumeStore((s) => s.patchResume);

  const update = (id: string, field: string, value: string) => {
    patch({
      experience: resume.experience.map((e) =>
        e.id === id ? { ...e, [field]: value } : e,
      ),
    });
  };

  const remove = (id: string) =>
    patch({ experience: resume.experience.filter((e) => e.id !== id) });

  const add = () =>
    patch({
      experience: [
        ...resume.experience,
        { id: uid(), role: '', company: '', duration: '', description: '' },
      ],
    });

  return (
    <SectionCard
      title="Experience"
      actions={
        <button type="button" onClick={add} className="btn-secondary text-xs">
          + Add
        </button>
      }
    >
      {resume.experience.map((e, i) => (
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
              label="Role"
              value={e.role}
              onChange={(ev) => update(e.id, 'role', ev.target.value)}
              placeholder="Senior Engineer"
            />
            <TextField
              label="Company"
              value={e.company}
              onChange={(ev) => update(e.id, 'company', ev.target.value)}
              placeholder="Acme Corp"
            />
          </div>
          <TextField
            label="Duration"
            value={e.duration}
            onChange={(ev) => update(e.id, 'duration', ev.target.value)}
            placeholder="2022 — Present"
          />
          <TextArea
            label="Description"
            rows={3}
            value={e.description}
            onChange={(ev) => update(e.id, 'description', ev.target.value)}
            placeholder="What you did and the impact you delivered."
          />
        </div>
      ))}
      {resume.experience.length === 0 && (
        <p className="text-sm text-ink-muted">No experience yet. Click “+ Add”.</p>
      )}
    </SectionCard>
  );
}
