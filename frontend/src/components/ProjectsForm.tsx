import { useResumeStore } from '../store/resumeStore';
import SectionCard from './SectionCard';
import { TextArea, TextField } from './Field';
import { uid } from '../utils/uid';

export default function ProjectsForm() {
  const resume = useResumeStore((s) => s.resume);
  const patch = useResumeStore((s) => s.patchResume);

  const update = (id: string, field: string, value: string) =>
    patch({
      projects: resume.projects.map((p) =>
        p.id === id ? { ...p, [field]: value } : p,
      ),
    });

  const remove = (id: string) =>
    patch({ projects: resume.projects.filter((p) => p.id !== id) });

  const add = () =>
    patch({
      projects: [
        ...resume.projects,
        { id: uid(), name: '', description: '', link: '' },
      ],
    });

  return (
    <SectionCard
      title="Projects"
      defaultOpen={false}
      actions={
        <button type="button" onClick={add} className="btn-secondary text-xs">
          + Add
        </button>
      }
    >
      {resume.projects.map((p, i) => (
        <div key={p.id} className="border border-bg-border rounded-lg p-3 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-[11px] text-ink-muted uppercase tracking-widest">
              #{i + 1}
            </span>
            <button
              type="button"
              onClick={() => remove(p.id)}
              className="text-xs text-ink-muted hover:text-red-400"
            >
              Remove
            </button>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <TextField
              label="Name"
              value={p.name}
              onChange={(ev) => update(p.id, 'name', ev.target.value)}
            />
            <TextField
              label="Link"
              value={p.link}
              onChange={(ev) => update(p.id, 'link', ev.target.value)}
              placeholder="github.com/..."
            />
          </div>
          <TextArea
            label="Description"
            rows={2}
            value={p.description}
            onChange={(ev) => update(p.id, 'description', ev.target.value)}
          />
        </div>
      ))}
    </SectionCard>
  );
}
