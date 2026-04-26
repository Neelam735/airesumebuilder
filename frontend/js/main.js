// BuildifyAi - main.js
// Backend endpoint - update this to your deployed backend URL
const API_BASE = window.API_BASE || 'http://localhost:5000';

document.addEventListener('DOMContentLoaded', () => {
    // Footer year
    const yearEl = document.getElementById('year');
    if (yearEl) yearEl.textContent = new Date().getFullYear();

    // Mobile nav toggle
    const navToggle = document.getElementById('navToggle');
    const navLinks = document.getElementById('navLinks');
    if (navToggle && navLinks) {
        navToggle.addEventListener('click', () => navLinks.classList.toggle('open'));
        navLinks.querySelectorAll('a').forEach(a => a.addEventListener('click', () => navLinks.classList.remove('open')));
    }

    // Forms
    initContactForm();
    initAuthForm('loginForm', '/api/auth/login');
    initAuthForm('signupForm', '/api/auth/signup');
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
        const message = form.message.value.trim();

        let valid = true;
        if (name.length < 2) { showError('err-name', 'Please enter your name'); valid = false; }
        if (!isEmail(email)) { showError('err-email', 'Enter a valid email'); valid = false; }
        if (message.length < 10) { showError('err-message', 'Message must be at least 10 characters'); valid = false; }
        if (!valid) return;

        const btn = form.querySelector('button[type="submit"]');
        btn.disabled = true;
        btn.textContent = 'Sending…';

        try {
            const res = await fetch(`${API_BASE}/api/contact`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name, email, message })
            });
            if (!res.ok) throw new Error('Server error');
            setStatus(form, '✅ Thanks! We\'ll get back to you soon.', 'success');
            form.reset();
        } catch (err) {
            setStatus(form, '⚠️ Could not send. Please try again later.', 'error');
        } finally {
            btn.disabled = false;
            btn.textContent = 'Send Message';
        }
    });
}

// ----- Auth (UI only - validates and shows success) -----
function initAuthForm(formId, endpoint) {
    const form = document.getElementById(formId);
    if (!form) return;

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        clearErrors(form);

        const email = form.email.value.trim();
        const password = form.password.value;
        const name = form.name ? form.name.value.trim() : null;

        let valid = true;
        if (name !== null && name.length < 2) { showError('err-name', 'Enter your full name'); valid = false; }
        if (!isEmail(email)) { showError('err-email', 'Enter a valid email'); valid = false; }
        if (password.length < 6) { showError('err-password', 'Password must be at least 6 characters'); valid = false; }
        if (!valid) return;

        const btn = form.querySelector('button[type="submit"]');
        btn.disabled = true;
        const originalText = btn.textContent;
        btn.textContent = 'Please wait…';

        // Simulated auth - swap to real API when backend is ready
        try {
            await new Promise(r => setTimeout(r, 700));
            setStatus(form, formId === 'signupForm' ? '🎉 Account created! Redirecting…' : '✅ Signed in! Redirecting…', 'success');
            setTimeout(() => { window.location.href = 'index.html'; }, 1200);
        } catch (err) {
            setStatus(form, '⚠️ Something went wrong.', 'error');
            btn.disabled = false;
            btn.textContent = originalText;
        }
    });
}
