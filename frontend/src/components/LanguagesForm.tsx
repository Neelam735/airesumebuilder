import { useResumeStore } from '../store/resumeStore';
import SectionCard from './SectionCard';
import ListInput from './ListInput';

export default function LanguagesForm() {
  const resume = useResumeStore((s) => s.resume);
  const patch = useResumeStore((s) => s.patchResume);

  return (
    <SectionCard title="Languages" defaultOpen={false}>
      <ListInput
        values={resume.languages}
        onChange={(languages) => patch({ languages })}
        placeholder="e.g. English"
      />
    </SectionCard>
  );
}
