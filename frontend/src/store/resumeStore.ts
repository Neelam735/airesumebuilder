import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { ResumeData, UISettings, TemplateId } from '../types/resume';
import { uid } from '../utils/uid';

const defaultResume: ResumeData = {
  name: 'Aarav Sharma',
  title: 'Senior Software Engineer',
  email: 'aarav@example.com',
  phone: '+91 98765 43210',
  location: 'Bengaluru, India',
  linkedin: 'linkedin.com/in/aaravsharma',
  summary:
    'Engineer with 6+ years building scalable web platforms. Skilled in TypeScript, Java, and cloud-native systems.',
  skills: ['TypeScript', 'React', 'Java', 'Spring Boot', 'AWS', 'PostgreSQL'],
  experience: [
    {
      id: uid(),
      role: 'Senior Software Engineer',
      company: 'Acme Corp',
      duration: '2022 — Present',
      description:
        'Led migration to microservices, reducing deployment time by 60%. Mentored 4 engineers across two squads.',
    },
    {
      id: uid(),
      role: 'Software Engineer',
      company: 'Beta Labs',
      duration: '2019 — 2022',
      description:
        'Shipped a billing platform handling 2M+ monthly transactions with 99.99% uptime.',
    },
  ],
  education: [
    {
      id: uid(),
      degree: 'B.Tech, Computer Science',
      institution: 'IIT Roorkee',
      duration: '2015 — 2019',
      description: 'Graduated with distinction. Specialization in distributed systems.',
    },
  ],
  projects: [
    {
      id: uid(),
      name: 'Open-source CLI for cloud migrations',
      description: '3k+ GitHub stars. Reduced manual migration steps by 80%.',
      link: 'github.com/aarav/cloudmig',
    },
  ],
  languages: ['English', 'Hindi'],
};

const defaultUI: UISettings = {
  template: 'modern',
  accent: '#7c5cff',
  zoom: 0.8,
};

interface ResumeState {
  resume: ResumeData;
  ui: UISettings;
  /** True once the resume has been rewritten by AI. Enhancement itself is
   *  free; this is what makes the next download a paid one. */
  aiEnhanced: boolean;
  /** Server-issued token proving the download was paid for. */
  paymentToken: string | null;
  /** Points the user at the Download button right after an enhancement, so
   *  the next step is obvious instead of the dialog just closing. */
  downloadHint: boolean;
  setResume: (data: ResumeData) => void;
  patchResume: (patch: Partial<ResumeData>) => void;
  setUI: (patch: Partial<UISettings>) => void;
  setTemplate: (t: TemplateId) => void;
  setAccent: (c: string) => void;
  setZoom: (z: number) => void;
  markAiEnhanced: () => void;
  dismissDownloadHint: () => void;
  setPaymentToken: (token: string | null) => void;
  reset: () => void;
}

export const useResumeStore = create<ResumeState>()(
  persist(
    (set) => ({
      resume: defaultResume,
      ui: defaultUI,
      aiEnhanced: false,
      paymentToken: null,
      downloadHint: false,
      setResume: (data) => set({ resume: data }),
      patchResume: (patch) =>
        set((state) => ({ resume: { ...state.resume, ...patch } })),
      setUI: (patch) => set((state) => ({ ui: { ...state.ui, ...patch } })),
      setTemplate: (template) =>
        set((state) => ({ ui: { ...state.ui, template } })),
      setAccent: (accent) => set((state) => ({ ui: { ...state.ui, accent } })),
      setZoom: (zoom) => set((state) => ({ ui: { ...state.ui, zoom } })),
      // A payment unlocks the enhanced resume it was made for. Enhancing again
      // produces a different resume, so the previous unlock is cleared and the
      // new one has to be paid for; without this, one payment would have made
      // every later enhancement free.
      markAiEnhanced: () =>
        set({ aiEnhanced: true, paymentToken: null, downloadHint: true }),
      dismissDownloadHint: () => set({ downloadHint: false }),
      setPaymentToken: (paymentToken) => set({ paymentToken }),
      reset: () =>
        set({
          resume: defaultResume,
          ui: defaultUI,
          aiEnhanced: false,
          paymentToken: null,
          downloadHint: false,
        }),
    }),
    { name: 'rb.resume' },
  ),
);
