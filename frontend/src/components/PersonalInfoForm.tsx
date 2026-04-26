import { useResumeStore } from '../store/resumeStore';
import SectionCard from './SectionCard';
import { TextArea, TextField } from './Field';

export default function PersonalInfoForm() {
  const resume = useResumeStore((s) => s.resume);
  const patch = useResumeStore((s) => s.patchResume);

  return (
    <SectionCard title="Personal Information" subtitle="Basics & contact">
      <div className="grid grid-cols-2 gap-3">
        <TextField
          label="Full name"
          value={resume.name}
          onChange={(e) => patch({ name: e.target.value })}
          placeholder="Aarav Sharma"
        />
        <TextField
          label="Title"
          value={resume.title}
          onChange={(e) => patch({ title: e.target.value })}
          placeholder="Senior Software Engineer"
        />
        <TextField
          label="Email"
          type="email"
          value={resume.email}
          onChange={(e) => patch({ email: e.target.value })}
          placeholder="you@example.com"
        />
        <TextField
          label="Phone"
          value={resume.phone}
          onChange={(e) => patch({ phone: e.target.value })}
          placeholder="+91 98765 43210"
        />
        <TextField
          label="Location"
          value={resume.location}
          onChange={(e) => patch({ location: e.target.value })}
          placeholder="Bengaluru, India"
        />
        <TextField
          label="LinkedIn"
          value={resume.linkedin}
          onChange={(e) => patch({ linkedin: e.target.value })}
          placeholder="linkedin.com/in/handle"
        />
      </div>
      <TextArea
        label="Summary"
        rows={3}
        value={resume.summary}
        onChange={(e) => patch({ summary: e.target.value })}
        placeholder="One short paragraph about you."
      />
    </SectionCard>
  );
}
