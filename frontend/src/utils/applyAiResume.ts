import type { ResumeData } from '../types/resume';
import { uid } from './uid';

const str = (v: unknown, fallback = ''): string =>
  typeof v === 'string' ? v.trim() : fallback;

const list = (v: unknown): string[] =>
  Array.isArray(v) ? v.filter((x) => typeof x === 'string').map((s) => s.trim()).filter(Boolean) : [];

export function mergeAiResume(current: ResumeData, raw: any): ResumeData {
  if (!raw || typeof raw !== 'object') return current;

  const experience = Array.isArray(raw.experience)
    ? raw.experience.map((e: any) => ({
        id: uid(),
        role: str(e?.role),
        company: str(e?.company),
        duration: str(e?.duration),
        description: str(e?.description),
      }))
    : current.experience;

  const education = Array.isArray(raw.education)
    ? raw.education.map((e: any) => ({
        id: uid(),
        degree: str(e?.degree ?? e?.title),
        institution: str(e?.institution ?? e?.school),
        duration: str(e?.duration),
        description: str(e?.description),
      }))
    : current.education;

  const projects = Array.isArray(raw.projects)
    ? raw.projects.map((p: any) => ({
        id: uid(),
        name: str(p?.name ?? p?.title),
        description: str(p?.description),
        link: str(p?.link ?? p?.url),
      }))
    : current.projects;

  return {
    name: str(raw.name, current.name),
    title: str(raw.title, current.title),
    email: str(raw.email, current.email),
    phone: str(raw.phone, current.phone),
    location: str(raw.location, current.location),
    linkedin: str(raw.linkedin, current.linkedin),
    summary: str(raw.summary, current.summary),
    skills: list(raw.skills).length ? list(raw.skills) : current.skills,
    experience: experience.length ? experience : current.experience,
    education: education.length ? education : current.education,
    projects: projects.length ? projects : current.projects,
    languages: list(raw.languages).length ? list(raw.languages) : current.languages,
  };
}
