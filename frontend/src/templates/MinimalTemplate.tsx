import type { ReactNode } from 'react';
import type { ResumeData } from '../types/resume';

interface Props {
  resume: ResumeData;
  accent: string;
}

export default function MinimalTemplate({ resume, accent }: Props) {
  return (
    <div className="resume-page font-sans px-14 py-14 text-[13px] leading-relaxed">
      <header className="mb-8">
        <h1 className="text-4xl font-light text-gray-900 tracking-tight">
          {resume.name || 'Your Name'}
        </h1>
        {resume.title && (
          <p className="mt-1 text-gray-600 text-sm">{resume.title}</p>
        )}
        <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-[12px] text-gray-500">
          {resume.email && <span>{resume.email}</span>}
          {resume.phone && <span>{resume.phone}</span>}
          {resume.location && <span>{resume.location}</span>}
          {resume.linkedin && <span>{resume.linkedin}</span>}
        </div>
      </header>

      {resume.summary && (
        <Section title="About" accent={accent}>
          <p className="text-gray-800">{resume.summary}</p>
        </Section>
      )}

      {resume.experience.length > 0 && (
        <Section title="Experience" accent={accent}>
          {resume.experience.map((e) => (
            <div key={e.id} className="grid grid-cols-[120px_1fr] gap-6 mb-4">
              <div className="text-[11px] text-gray-500 pt-0.5">{e.duration}</div>
              <div>
                <div className="font-semibold text-gray-900">{e.role}</div>
                {e.company && <div className="text-gray-600 text-[12px]">{e.company}</div>}
                {e.description && (
                  <p className="mt-1 text-gray-800 whitespace-pre-line">{e.description}</p>
                )}
              </div>
            </div>
          ))}
        </Section>
      )}

      {resume.education.length > 0 && (
        <Section title="Education" accent={accent}>
          {resume.education.map((e) => (
            <div key={e.id} className="grid grid-cols-[120px_1fr] gap-6 mb-3">
              <div className="text-[11px] text-gray-500 pt-0.5">{e.duration}</div>
              <div>
                <div className="font-semibold text-gray-900">{e.degree}</div>
                {e.institution && <div className="text-gray-600 text-[12px]">{e.institution}</div>}
                {e.description && <p className="text-gray-800 mt-1">{e.description}</p>}
              </div>
            </div>
          ))}
        </Section>
      )}

      {resume.skills.length > 0 && (
        <Section title="Skills" accent={accent}>
          <p className="text-gray-800">{resume.skills.filter(Boolean).join(' / ')}</p>
        </Section>
      )}

      {resume.projects.length > 0 && (
        <Section title="Projects" accent={accent}>
          {resume.projects.map((p) => (
            <div key={p.id} className="mb-2">
              <div className="font-semibold text-gray-900">
                {p.name}
                {p.link && <span className="text-[11px] text-gray-400 ml-2">{p.link}</span>}
              </div>
              {p.description && <p className="text-gray-800">{p.description}</p>}
            </div>
          ))}
        </Section>
      )}

      {resume.languages.length > 0 && (
        <Section title="Languages" accent={accent}>
          <p className="text-gray-800">{resume.languages.filter(Boolean).join(' / ')}</p>
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
    <section className="mb-6">
      <h2
        className="text-[11px] font-medium uppercase tracking-[0.3em] mb-3"
        style={{ color: accent }}
      >
        {title}
      </h2>
      {children}
    </section>
  );
}
