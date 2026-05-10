import { forwardRef } from 'react';
import { useResumeStore } from '../store/resumeStore';
import ClassicTemplate from '../templates/ClassicTemplate';
import ModernTemplate from '../templates/ModernTemplate';
import MinimalTemplate from '../templates/MinimalTemplate';

const ResumePreview = forwardRef<HTMLDivElement>((_, ref) => {
  const resume = useResumeStore((s) => s.resume);
  const ui = useResumeStore((s) => s.ui);

  return (
    <div
      ref={ref}
      style={{
        transform: `scale(${ui.zoom})`,
        transformOrigin: 'top center',
      }}
    >
      {ui.template === 'classic' && <ClassicTemplate resume={resume} accent={ui.accent} />}
      {ui.template === 'modern' && <ModernTemplate resume={resume} accent={ui.accent} />}
      {ui.template === 'minimal' && <MinimalTemplate resume={resume} accent={ui.accent} />}
    </div>
  );
});

ResumePreview.displayName = 'ResumePreview';
export default ResumePreview;
