import type { ReactNode } from 'react';
import type { ResumeData } from '../types/resume';

interface Props {
  resume: ResumeData;
  accent: string;
}

export default function ClassicTemplate({ resume, accent }: Props) {
  return (
    <div className="resume-page font-serif px-14 py-12 text-[13px] leading-relaxed">
      <header className="text-center border-b-2 pb-4 mb-6" style={{ borderColor: accent }}>
        <h1 className="text-3xl font-semibold tracking-wide text-gray-900">
          {resume.name || 'Your Name'}
        </h1>
        {resume.title && (
          <p className="mt-1 text-sm text-gray-600 uppercase tracking-[0.2em]">
            {resume.title}
          </p>
        )}
        <div className="mt-3 flex flex-wrap justify-center gap-x-4 gap-y-1 text-xs text-gray-700">
          {resume.email && <span>{resume.email}</span>}
          {resume.phone && <span>{resume.phone}</span>}
          {resume.location && <span>{resume.location}</span>}
          {resume.linkedin && <span>{resume.linkedin}</span>}
        </div>
      </header>

      {resume.summary && (
        <Section title="Summary" accent={accent}>
          <p className="text-gray-800">{resume.summary}</p>
        </Section>
      )}

      {resume.experience.length > 0 && (
        <Section title="Experience" accent={accent}>
          {resume.experience.map((e) => (
            <div key={e.id} className="mb-3">
              <div className="flex justify-between items-baseline">
                <div>
                  <span className="font-semibold text-gray-900">{e.role}</span>
                  {e.company && <span className="text-gray-700"> · {e.company}</span>}
                </div>
                {e.duration && <span className="text-xs text-gray-500">{e.duration}</span>}
              </div>
              {e.description && (
                <p className="mt-1 text-gray-800 whitespace-pre-line">{e.description}</p>
              )}
            </div>
          ))}
        </Section>
      )}

      {resume.skills.length > 0 && (
        <Section title="Skills" accent={accent}>
          <p className="text-gray-800">{resume.skills.filter(Boolean).join(' · ')}</p>
        </Section>
      )}

      {resume.education.length > 0 && (
        <Section title="Education" accent={accent}>
          {resume.education.map((e) => (
            <div key={e.id} className="mb-2">
              <div className="flex justify-between">
                <span className="font-semibold text-gray-900">{e.degree}</span>
                {e.duration && <span className="text-xs text-gray-500">{e.duration}</span>}
              </div>
              {e.institution && <div className="text-gray-700">{e.institution}</div>}
              {e.description && <p className="text-gray-800 mt-1">{e.description}</p>}
            </div>
          ))}
        </Section>
      )}

      {resume.projects.length > 0 && (
        <Section title="Projects" accent={accent}>
          {resume.projects.map((p) => (
            <div key={p.id} className="mb-2">
              <div className="flex justify-between">
                <span className="font-semibold text-gray-900">{p.name}</span>
                {p.link && <span className="text-xs text-gray-500">{p.link}</span>}
              </div>
              {p.description && <p className="text-gray-800">{p.description}</p>}
            </div>
          ))}
        </Section>
      )}

      {resume.languages.length > 0 && (
        <Section title="Languages" accent={accent}>
          <p className="text-gray-800">{resume.languages.filter(Boolean).join(' · ')}</p>
        </Section>
      )}
    </div>
  );
}

function Section({
  title,
  accent,
  children,
}: {
  title: string;
  accent: string;
  children: ReactNode;
}) {
  return (
    <section className="mb-5">
      <h2
        className="text-xs uppercase tracking-[0.25em] font-semibold mb-2 pb-1 border-b"
        style={{ color: accent, borderColor: `${accent}33` }}
      >
        {title}
      </h2>
      {children}
    </section>
  );
}
