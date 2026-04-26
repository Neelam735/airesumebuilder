import { useRef, useState } from 'react';
import TopBar from '../components/TopBar';
import PersonalInfoForm from '../components/PersonalInfoForm';
import SkillsForm from '../components/SkillsForm';
import ExperienceForm from '../components/ExperienceForm';
import EducationForm from '../components/EducationForm';
import ProjectsForm from '../components/ProjectsForm';
import LanguagesForm from '../components/LanguagesForm';
import ResumePreview from '../components/ResumePreview';
import CustomizationPanel from '../components/CustomizationPanel';
import ImproveModal from '../components/ImproveModal';
import { useResumeStore } from '../store/resumeStore';
import { exportElementAsPdf } from '../utils/pdfExport';

export default function BuilderPage() {
  const [improveOpen, setImproveOpen] = useState(false);
  const [exporting, setExporting] = useState(false);
  const previewRef = useRef<HTMLDivElement>(null);
  const reset = useResumeStore((s) => s.reset);
  const resume = useResumeStore((s) => s.resume);
  const setZoom = useResumeStore((s) => s.setZoom);
  const ui = useResumeStore((s) => s.ui);

  const handleDownload = async () => {
    if (!previewRef.current) return;
    setExporting(true);
    const prevZoom = ui.zoom;
    setZoom(1);
    await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
    try {
      const target = previewRef.current.firstElementChild as HTMLElement | null;
      if (!target) throw new Error('Preview not ready');
      const safeName = (resume.name || 'resume').toLowerCase().replace(/[^a-z0-9]+/g, '-');
      await exportElementAsPdf(target, `${safeName}.pdf`);
    } finally {
      setZoom(prevZoom);
      setExporting(false);
    }
  };

  const handleReset = () => {
    if (confirm('Reset to the example resume? Your current data will be replaced.')) {
      reset();
    }
  };

  return (
    <div className="min-h-screen flex flex-col">
      <TopBar
        onImprove={() => setImproveOpen(true)}
        onDownload={handleDownload}
        onReset={handleReset}
        isExporting={exporting}
      />

      <main className="flex-1">
        <div className="max-w-[1600px] mx-auto grid grid-cols-12 gap-4 p-4 lg:p-6">
          <section className="col-span-12 lg:col-span-4 xl:col-span-3 space-y-3 max-h-[calc(100vh-5rem)] overflow-y-auto pr-1 scroll-area">
            <PersonalInfoForm />
            <SkillsForm />
            <ExperienceForm />
            <EducationForm />
            <ProjectsForm />
            <LanguagesForm />
          </section>

          <section className="col-span-12 lg:col-span-5 xl:col-span-6 max-h-[calc(100vh-5rem)] overflow-auto scroll-area">
            <div className="py-2">
              <ResumePreview ref={previewRef} />
            </div>
          </section>

          <aside className="col-span-12 lg:col-span-3 max-h-[calc(100vh-5rem)] overflow-y-auto pr-1 scroll-area">
            <CustomizationPanel />
          </aside>
        </div>
      </main>

      <ImproveModal open={improveOpen} onClose={() => setImproveOpen(false)} />
    </div>
  );
}
