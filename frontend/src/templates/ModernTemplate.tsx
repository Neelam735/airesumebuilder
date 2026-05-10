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
  return (
    <div
      className="resume-page font-sans text-[13px]"
      style={{ display: 'grid', gridTemplateColumns: '34% 66%' }}
    >
      <aside
        className="p-8"
        style={{ backgroundColor: hexToRgba(accent, 0.07), minHeight: '100%' }}
      >
        {/* Name block */}
        <div style={{ marginBottom: '24px' }}>
          <div
            style={{
              width: '56px',
              height: '3px',
              borderRadius: '999px',
              backgroundColor: '#d1d5db',
              marginBottom: '10px',
            }}
          />
          <h1
            style={{
              fontSize: '22px',
              fontWeight: '700',
              color: '#111827',
              lineHeight: '1.25',
              margin: 0,
            }}
          >
            {resume.name || 'Your Name'}
          </h1>
          {resume.title && (
            <p
              style={{
                fontSize: '12px',
                fontWeight: '500',
                color: accent,
                marginTop: '4px',
                marginBottom: 0,
              }}
            >
              {resume.title}
            </p>
          )}
        </div>

        <SidebarBlock title="Contact" accent={accent}>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {resume.email && (
              <li style={{ color: '#374151', marginBottom: '6px', wordBreak: 'break-all' }}>
                {resume.email}
              </li>
            )}
            {resume.phone && (
              <li style={{ color: '#374151', marginBottom: '6px' }}>{resume.phone}</li>
            )}
            {resume.location && (
              <li style={{ color: '#374151', marginBottom: '6px' }}>{resume.location}</li>
            )}
            {resume.linkedin && (
              <li style={{ color: '#374151', marginBottom: '6px', wordBreak: 'break-all' }}>
                {resume.linkedin}
              </li>
            )}
          </ul>
        </SidebarBlock>

        {resume.skills.length > 0 && (
          <SidebarBlock title="Skills" accent={accent}>
            <div
              style={{
                display: 'flex',
                flexWrap: 'wrap',
                gap: '6px',
              }}
            >
              {resume.skills.filter(Boolean).map((s, i) => (
                <span
                  key={i}
                  style={{
                    display: 'inline-block',
                    backgroundColor: '#f3f4f6',
                    color: '#374151',
                    padding: '2px 8px',
                    borderRadius: '4px',
                    fontSize: '11px',
                    fontWeight: '500',
                    whiteSpace: 'nowrap',
                  }}
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
              <div key={e.id} style={{ marginBottom: '12px' }}>
                <div style={{ fontWeight: '600', color: '#111827' }}>{e.degree}</div>
                <div style={{ color: '#374151', fontSize: '12px' }}>{e.institution}</div>
                {e.duration && (
                  <div style={{ color: '#6b7280', fontSize: '11px' }}>{e.duration}</div>
                )}
              </div>
            ))}
          </SidebarBlock>
        )}

        {resume.languages.length > 0 && (
          <SidebarBlock title="Languages" accent={accent}>
            <p style={{ color: '#374151', margin: 0 }}>
              {resume.languages.filter(Boolean).join(', ')}
            </p>
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
              <div key={e.id} style={{ marginBottom: '16px', position: 'relative', paddingLeft: '16px' }}>
                <span
                  style={{
                    position: 'absolute',
                    left: 0,
                    top: '7px',
                    width: '6px',
                    height: '6px',
                    borderRadius: '50%',
                    backgroundColor: accent,
                  }}
                />
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                  <h3 style={{ fontWeight: '600', color: '#111827', margin: 0 }}>{e.role}</h3>
                  {e.duration && (
                    <span style={{ fontSize: '11px', color: '#6b7280' }}>{e.duration}</span>
                  )}
                </div>
                {e.company && (
                  <div style={{ fontSize: '12px', color: '#4b5563', fontStyle: 'italic' }}>
                    {e.company}
                  </div>
                )}
                {e.description && (
                  <p style={{ marginTop: '4px', color: '#374151', whiteSpace: 'pre-line', margin: '4px 0 0' }}>
                    {e.description}
                  </p>
                )}
              </div>
            ))}
          </MainBlock>
        )}

        {resume.projects.length > 0 && (
          <MainBlock title="Projects" accent={accent}>
            {resume.projects.map((p) => (
              <div key={p.id} style={{ marginBottom: '12px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ fontWeight: '600', color: '#111827' }}>{p.name}</span>
                  {p.link && (
                    <span style={{ fontSize: '11px', color: '#6b7280' }}>{p.link}</span>
                  )}
                </div>
                {p.description && (
                  <p style={{ color: '#374151', margin: '2px 0 0' }}>{p.description}</p>
                )}
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
    <section style={{ marginBottom: '20px' }}>
      <h2
        style={{
          fontSize: '10px',
          textTransform: 'uppercase',
          letterSpacing: '0.18em',
          fontWeight: '700',
          color: accent,
          marginBottom: '8px',
          marginTop: 0,
        }}
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
    <section style={{ marginBottom: '20px' }}>
      <h2
        style={{
          fontSize: '11px',
          textTransform: 'uppercase',
          letterSpacing: '0.22em',
          fontWeight: '700',
          color: accent,
          borderBottom: `2px solid ${accent}`,
          paddingBottom: '4px',
          marginBottom: '12px',
          marginTop: 0,
        }}
      >
        {title}
      </h2>
      {children}
    </section>
  );
}
