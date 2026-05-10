import { useState } from 'react';
import { useResumeStore } from '../store/resumeStore';
import { api, type JobMatchItem } from '../utils/api';
import CoverLetterModal from './CoverLetterModal';

interface State {
  loading: boolean;
  error: string | null;
  matches: JobMatchItem[];
  totalScanned: number;
}

export default function JobMatches() {
  const resume = useResumeStore((s) => s.resume);
  const [titleQuery, setTitleQuery] = useState('');
  const [locationQuery, setLocationQuery] = useState('');
  const [state, setState] = useState<State>({
    loading: false,
    error: null,
    matches: [],
    totalScanned: 0,
  });
  const [activeJob, setActiveJob] = useState<JobMatchItem | null>(null);

  const search = async () => {
    setState({ loading: true, error: null, matches: [], totalScanned: 0 });
    try {
      const res = await api.matchJobs({
        skills: resume.skills,
        title: titleQuery || resume.title,
        location: locationQuery || undefined,
        limit: 12,
      });
      setState({
        loading: false,
        error: null,
        matches: res.matches,
        totalScanned: res.totalScanned,
      });
    } catch (e) {
      const err = e as Error;
      setState({
        loading: false,
        error: err.message || 'Could not load matches',
        matches: [],
        totalScanned: 0,
      });
    }
  };

  return (
    <div className="card p-4 space-y-3">
      <div className="flex items-center gap-2">
        <span className="inline-block w-1.5 h-1.5 rounded-full bg-brand-accent pulse-dot" />
        <div className="text-sm font-semibold">Auto-apply by skills</div>
      </div>
      <p className="text-[11px] text-ink-muted leading-relaxed">
        We scan thousands of remote jobs and rank them against your resume's skills.
        Click <strong>Apply</strong> on any match to draft a tailored cover letter,
        download your resume PDF, and open the application.
      </p>

      <div className="grid grid-cols-2 gap-2">
        <input
          className="input-base text-xs"
          placeholder={resume.title || 'Role (e.g. Backend Engineer)'}
          value={titleQuery}
          onChange={(e) => setTitleQuery(e.target.value)}
        />
        <input
          className="input-base text-xs"
          placeholder="Location (optional)"
          value={locationQuery}
          onChange={(e) => setLocationQuery(e.target.value)}
        />
      </div>

      <button
        type="button"
        onClick={search}
        disabled={state.loading || resume.skills.length === 0}
        className="btn-primary w-full text-sm"
      >
        {state.loading ? 'Scanning…' : '🎯 Find matching jobs'}
      </button>

      {resume.skills.length === 0 && (
        <div className="text-[11px] text-ink-muted">
          Add at least one skill to enable job matching.
        </div>
      )}

      {state.error && (
        <div className="text-xs rounded-md border border-red-500/30 bg-red-500/10 text-red-300 p-2">
          {state.error}
        </div>
      )}

      {state.matches.length > 0 && (
        <div className="space-y-2 max-h-[460px] overflow-y-auto pr-1 scroll-area">
          <div className="text-[11px] text-ink-muted">
            {state.matches.length} matches · scanned {state.totalScanned}
          </div>
          {state.matches.map((job) => (
            <JobCard key={job.id} job={job} onApply={() => setActiveJob(job)} />
          ))}
        </div>
      )}

      <CoverLetterModal
        job={activeJob}
        open={activeJob !== null}
        onClose={() => setActiveJob(null)}
      />
    </div>
  );
}

function JobCard({ job, onApply }: { job: JobMatchItem; onApply: () => void }) {
  const score = Math.round(job.score);
  const tone =
    score >= 70 ? 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30'
    : score >= 40 ? 'bg-amber-500/15 text-amber-300 border-amber-500/30'
    : 'bg-bg-soft text-ink-muted border-bg-border';

  return (
    <div className="border border-bg-border rounded-lg p-3 hover:border-brand/40 transition">
      <div className="flex items-start justify-between gap-2">
        <div className="flex-1 min-w-0">
          <div className="text-sm font-semibold text-ink truncate">{job.title}</div>
          <div className="text-[11px] text-ink-muted truncate">
            {job.company}
            {job.location && ` · ${job.location}`}
            {job.jobType && ` · ${job.jobType.replace(/_/g, ' ')}`}
          </div>
        </div>
        <span className={`text-[10px] px-1.5 py-0.5 rounded-md border ${tone}`}>
          {score}% match
        </span>
      </div>

      {job.matchedSkills.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-1">
          {job.matchedSkills.slice(0, 6).map((s) => (
            <span
              key={s}
              className="text-[10px] px-1.5 py-0.5 rounded bg-brand/15 text-brand-accent border border-brand/20"
            >
              {s}
            </span>
          ))}
        </div>
      )}

      {job.salary && (
        <div className="mt-1 text-[11px] text-ink-muted">💰 {job.salary}</div>
      )}

      {job.snippet && (
        <p className="mt-2 text-[11px] text-ink-muted line-clamp-3">{job.snippet}</p>
      )}

      <div className="mt-2 flex items-center gap-2">
        <button type="button" onClick={onApply} className="btn-primary text-xs flex-1">
          ✨ Apply with AI
        </button>
        <a
          href={job.url}
          target="_blank"
          rel="noopener noreferrer"
          className="btn-secondary text-xs"
        >
          View
        </a>
      </div>
    </div>
  );
}
