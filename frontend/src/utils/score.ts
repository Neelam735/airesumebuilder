import type { ResumeData } from '../types/resume';

export function computeScore(r: ResumeData): { score: number; tips: string[] } {
  let score = 0;
  const tips: string[] = [];

  if (r.name) score += 5;
  if (r.title) score += 5;
  if (r.email && /\S+@\S+\.\S+/.test(r.email)) score += 5;
  else tips.push('Add a valid email');
  if (r.phone) score += 5; else tips.push('Add a phone number');
  if (r.location) score += 3;
  if (r.linkedin) score += 2;

  if (r.summary && r.summary.length > 60) score += 10;
  else tips.push('Add a 2–3 line summary');

  const skillCount = r.skills.filter(Boolean).length;
  score += Math.min(15, skillCount * 2);
  if (skillCount < 5) tips.push('Add at least 5 relevant skills');

  const expScore = r.experience.reduce((acc, e) => {
    let s = 0;
    if (e.role) s += 2;
    if (e.company) s += 2;
    if (e.duration) s += 1;
    if (e.description && e.description.length > 40) s += 5;
    return acc + s;
  }, 0);
  score += Math.min(30, expScore);
  if (r.experience.length === 0) tips.push('Add at least one experience entry');

  const eduScore = r.education.length > 0 ? 10 : 0;
  score += eduScore;
  if (!eduScore) tips.push('Add education details');

  const projScore = Math.min(10, r.projects.length * 5);
  score += projScore;
  if (!projScore) tips.push('Showcase 1–2 projects');

  return { score: Math.min(100, score), tips };
}
