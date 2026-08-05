import { useResumeStore } from '../store/resumeStore';
import SectionCard from './SectionCard';
import ListInput from './ListInput';

export default function SkillsForm() {
  const resume = useResumeStore((s) => s.resume);
  const patch = useResumeStore((s) => s.patchResume);

  return (
    <SectionCard title="Skills" subtitle="Technologies and tools">
      <ListInput
        values={resume.skills}
        onChange={(skills) => patch({ skills })}
        placeholder="e.g. TypeScript"
      />
    </SectionCard>
  );
}
