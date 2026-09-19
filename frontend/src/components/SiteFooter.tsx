const LINKS = [
  { href: '/pricing.html', label: 'Pricing' },
  { href: '/refund-policy.html', label: 'Refund & Cancellation' },
  { href: '/terms-and-conditions.html', label: 'Terms & Conditions' },
  { href: '/privacy-policy.html', label: 'Privacy Policy' },
  { href: '/contact-us.html', label: 'Contact Us' },
];

/**
 * Policy links. Payment providers check that pricing, refund, terms, privacy
 * and contact details are reachable from the live site, so these are served
 * from public/ and linked here rather than living only in the repo.
 */
export default function SiteFooter() {
  return (
    <footer className="border-t border-bg-border mt-6">
      <div className="max-w-[1600px] mx-auto px-4 lg:px-6 py-5 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <nav className="flex flex-wrap gap-x-4 gap-y-2">
          {LINKS.map((l) => (
            <a
              key={l.href}
              href={l.href}
              target="_blank"
              rel="noopener"
              className="text-[12px] text-ink-muted hover:text-ink underline-offset-2 hover:underline"
            >
              {l.label}
            </a>
          ))}
        </nav>
        <p className="text-[11px] text-ink-muted">
          © {new Date().getFullYear()} AI Resume Builder · Building and AI
          enhancement are free; downloading an AI-enhanced resume costs ₹10 once.
        </p>
      </div>
    </footer>
  );
}
