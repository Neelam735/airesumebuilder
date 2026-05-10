export interface ExperienceItem {
  id: string;
  role: string;
  company: string;
  duration: string;
  description: string;
}

export interface EducationItem {
  id: string;
  degree: string;
  institution: string;
  duration: string;
  description: string;
}

export interface ProjectItem {
  id: string;
  name: string;
  description: string;
  link: string;
}

export interface ResumeData {
  name: string;
  title: string;
  email: string;
  phone: string;
  location: string;
  linkedin: string;
  summary: string;
  skills: string[];
  experience: ExperienceItem[];
  education: EducationItem[];
  projects: ProjectItem[];
  languages: string[];
}

export type TemplateId = 'classic' | 'modern' | 'minimal';

export interface UISettings {
  template: TemplateId;
  accent: string;
  zoom: number;
}
