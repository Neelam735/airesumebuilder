const BASE = (import.meta.env.VITE_API_BASE as string | undefined) ?? '/api/v1';

async function postJSON<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : '{}',
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    let message = `Request failed (${res.status})`;
    try {
      const parsed = JSON.parse(text);
      if (parsed?.error) message = parsed.error;
    } catch {
      if (text) message = text;
    }
    throw new Error(message);
  }
  return res.json() as Promise<T>;
}

export interface JobMatchItem {
  id: string;
  title: string;
  company: string;
  location: string;
  jobType: string;
  salary: string;
  url: string;
  publishedAt: string;
  tags: string[];
  matchedSkills: string[];
  score: number;
  snippet: string;
}

export interface JobMatchResponse {
  matches: JobMatchItem[];
  totalScanned: number;
  source: string;
}

export const api = {
  parseResume: (paymentToken: string, resumeText: string) =>
    postJSON<{ resume: any; message: string }>('/resume/parse', {
      paymentToken,
      resumeText,
    }),

  matchJobs: (payload: {
    skills: string[];
    title?: string;
    location?: string;
    limit?: number;
  }) => postJSON<JobMatchResponse>('/jobs/match', payload),

  draftCoverLetter: (payload: {
    name: string;
    title: string;
    summary: string;
    skills: string[];
    jobTitle: string;
    company: string;
    jobDescription: string;
  }) => postJSON<{ coverLetter: string }>('/jobs/cover-letter', payload),
};
