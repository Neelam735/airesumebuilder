// BuildifyAi - main.js
const API_BASE = window.API_BASE || 'http://localhost:5000';

const NAV = `
<header class="navbar">
    <div class="container nav-container">
        <a href="index.html" class="logo">
            <span class="logo-mark">⚡</span>
            <span>BuildifyAi</span>
        </a>
        <nav class="nav-links" id="navLinks">
            <a href="index.html" data-nav="home">Home</a>
            <a href="services.html" data-nav="services">Services</a>
            <a href="portfolio.html" data-nav="portfolio">Portfolio</a>
            <a href="about.html" data-nav="about">About</a>
            <a href="contact.html" data-nav="contact">Contact</a>
            <a href="contact.html" class="btn btn-primary">Get Started</a>
        </nav>
        <button class="nav-toggle" id="navToggle" aria-label="Toggle navigation">
            <span></span><span></span><span></span>
        </button>
    </div>
</header>`;

const FOOTER = `
<footer class="footer">
    <div class="container">
        <div class="footer-grid">
            <div>
                <a href="index.html" class="logo logo-light">
                    <span class="logo-mark">⚡</span>
                    <span>BuildifyAi</span>
                </a>
                <p class="muted">We design and build powerful mobile apps and websites that help startups and businesses grow online.</p>
            </div>
            <div>
                <h4>Company</h4>
                <a href="about.html">About</a>
                <a href="portfolio.html">Portfolio</a>
                <a href="contact.html">Contact</a>
            </div>
            <div>
                <h4>Services</h4>
                <a href="services.html#mobile">Mobile Apps</a>
                <a href="services.html#web">Websites</a>
                <a href="services.html#design">UI / UX Design</a>
                <a href="services.html#support">Maintenance</a>
            </div>
            <div>
                <h4>Get in touch</h4>
                <a href="mailto:hello@buildifyai.com">hello@buildifyai.com</a>
                <a href="tel:+10000000000">+1 (000) 000-0000</a>
            </div>
        </div>
        <div class="footer-bottom">
            <small>© <span id="year"></span> BuildifyAi. All rights reserved.</small>
            <small>Built with ⚡ in the cloud.</small>
        </div>
    </div>
</footer>`;

document.addEventListener('DOMContentLoaded', () => {
    // Inject shared chrome
    const navMount = document.getElementById('site-nav');
    const footerMount = document.getElementById('site-footer');
    if (navMount) navMount.innerHTML = NAV;
    if (footerMount) footerMount.innerHTML = FOOTER;

    // Active nav link
    const page = document.body.dataset.page;
    if (page) {
        const link = document.querySelector(`[data-nav="${page}"]`);
        if (link) link.classList.add('active');
    }

    // Footer year
    const yearEl = document.getElementById('year');
    if (yearEl) yearEl.textContent = new Date().getFullYear();

    // Mobile nav
    const navToggle = document.getElementById('navToggle');
    const navLinks = document.getElementById('navLinks');
    if (navToggle && navLinks) {
        navToggle.addEventListener('click', () => navLinks.classList.toggle('open'));
        navLinks.querySelectorAll('a').forEach(a => a.addEventListener('click', () => navLinks.classList.remove('open')));
    }

    // Reveal-on-scroll
    const obs = new IntersectionObserver((entries) => {
        entries.forEach(e => {
            if (e.isIntersecting) { e.target.classList.add('in'); obs.unobserve(e.target); }
        });
    }, { threshold: 0.12 });
    document.querySelectorAll('.reveal').forEach(el => obs.observe(el));

    // Contact form
    initContactForm();
});

// ----- Validation helpers -----
const isEmail = (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
const showError = (id, msg) => {
    const el = document.getElementById(id);
    if (!el) return;
    el.textContent = msg;
    el.classList.add('show');
};
const clearErrors = (form) => form.querySelectorAll('.error-text').forEach(e => e.classList.remove('show'));
const setStatus = (form, msg, type) => {
    const el = form.querySelector('.form-status');
    if (!el) return;
    el.textContent = msg;
    el.className = `form-status show ${type}`;
};

// ----- Contact form -----
function initContactForm() {
    const form = document.getElementById('contactForm');
    if (!form) return;

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        clearErrors(form);

        const name = form.name.value.trim();
        const email = form.email.value.trim();
        const company = form.company ? form.company.value.trim() : '';
        const service = form.service ? form.service.value : '';
        const message = form.message.value.trim();

        let valid = true;
        if (name.length < 2) { showError('err-name', 'Please enter your name'); valid = false; }
        if (!isEmail(email)) { showError('err-email', 'Enter a valid email'); valid = false; }
        if (message.length < 10) { showError('err-message', 'Please share a few details (10+ chars)'); valid = false; }
        if (!valid) return;

        const btn = form.querySelector('button[type="submit"]');
        btn.disabled = true;
        btn.textContent = 'Sending…';

        try {
            const res = await fetch(`${API_BASE}/api/contact`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name, email, company, service, message })
            });
            if (!res.ok) throw new Error('Server error');
            setStatus(form, '✅ Thanks! We\'ll get back within 24 hours.', 'success');
            form.reset();
        } catch (err) {
            setStatus(form, '⚠️ Could not send. Please try again later.', 'error');
        } finally {
            btn.disabled = false;
            btn.textContent = "Let's Build Your Idea";
        }
    });
}
