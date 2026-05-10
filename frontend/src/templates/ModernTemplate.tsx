import type { ReactNode } from 'react';
import type { ResumeData } from '../types/resume';

interface Props {
  resume: ResumeData;
  accent: string;
}

function hexToRgba(hex: string, alpha: number): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

export default function ModernTemplate({ resume, accent }: Props) {
  const sidebarBg = hexToRgba(accent, 0.08);
  return (
    <div className="resume-page font-sans grid grid-cols-[34%_66%] text-[13px]">
      <aside className="p-8" style={{ backgroundColor: sidebarBg }}>
        <div className="mb-6">
          <div
            className="w-16 h-1.5 rounded-full mb-3"
            style={{ backgroundColor: accent }}
          />
          <h1 className="text-2xl font-bold leading-tight" style={{ color: '#111827' }}>
            {resume.name || 'Your Name'}
          </h1>
          {resume.title && (
            <p className="text-sm font-medium mt-1" style={{ color: accent }}>
              {resume.title}
            </p>
          )}
        </div>

        <SidebarBlock title="Contact" accent={accent}>
          <ul className="space-y-1.5 text-gray-800">
            {resume.email && <li className="break-words">{resume.email}</li>}
            {resume.phone && <li>{resume.phone}</li>}
            {resume.location && <li>{resume.location}</li>}
            {resume.linkedin && <li className="break-words">{resume.linkedin}</li>}
          </ul>
        </SidebarBlock>

        {resume.skills.length > 0 && (
          <SidebarBlock title="Skills" accent={accent}>
            <div className="flex flex-wrap gap-1.5">
              {resume.skills.filter(Boolean).map((s, i) => (
                <span
                  key={i}
                  className="px-2 py-0.5 rounded text-[11px] font-medium"
                  style={{ backgroundColor: hexToRgba(accent, 0.15), color: '#1f2937' }}
                >
                  {s}
                </span>
              ))}
            </div>
          </SidebarBlock>
        )}

        {resume.education.length > 0 && (
          <SidebarBlock title="Education" accent={accent}>
            {resume.education.map((e) => (
              <div key={e.id} className="mb-3">
                <div className="font-semibold text-gray-900">{e.degree}</div>
                <div className="text-gray-700 text-[12px]">{e.institution}</div>
                {e.duration && <div className="text-gray-500 text-[11px]">{e.duration}</div>}
              </div>
            ))}
          </SidebarBlock>
        )}

        {resume.languages.length > 0 && (
          <SidebarBlock title="Languages" accent={accent}>
            <p className="text-gray-800">{resume.languages.filter(Boolean).join(', ')}</p>
          </SidebarBlock>
        )}
      </aside>

      <main className="p-9">
        {resume.summary && (
          <MainBlock title="Profile" accent={accent}>
            <p className="text-gray-800 leading-relaxed">{resume.summary}</p>
          </MainBlock>
        )}

        {resume.experience.length > 0 && (
          <MainBlock title="Experience" accent={accent}>
            {resume.experience.map((e) => (
              <div key={e.id} className="mb-4 relative pl-4">
                <span
                  className="absolute left-0 top-2 w-1.5 h-1.5 rounded-full"
                  style={{ backgroundColor: accent }}
                />
                <div className="flex justify-between items-baseline">
                  <h3 className="font-semibold text-gray-900">{e.role}</h3>
                  {e.duration && (
                    <span className="text-[11px] text-gray-500">{e.duration}</span>
                  )}
                </div>
                {e.company && (
                  <div className="text-[12px] text-gray-600 italic">{e.company}</div>
                )}
                {e.description && (
                  <p className="mt-1 text-gray-800 whitespace-pre-line">{e.description}</p>
                )}
              </div>
            ))}
          </MainBlock>
        )}

        {resume.projects.length > 0 && (
          <MainBlock title="Projects" accent={accent}>
            {resume.projects.map((p) => (
              <div key={p.id} className="mb-3">
                <div className="flex justify-between">
                  <span className="font-semibold text-gray-900">{p.name}</span>
                  {p.link && <span className="text-[11px] text-gray-500">{p.link}</span>}
                </div>
                {p.description && <p className="text-gray-800">{p.description}</p>}
              </div>
            ))}
          </MainBlock>
        )}
      </main>
    </div>
  );
}

function SidebarBlock({
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
        className="text-[11px] uppercase tracking-[0.2em] font-bold mb-2"
        style={{ color: accent }}
      >
        {title}
      </h2>
      {children}
    </section>
  );
}

function MainBlock({
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
        className="text-[12px] uppercase tracking-[0.25em] font-bold pb-1 mb-3 border-b-2"
        style={{ color: accent, borderColor: accent }}
      >
        {title}
      </h2>
      {children}
    </section>
  );
}
