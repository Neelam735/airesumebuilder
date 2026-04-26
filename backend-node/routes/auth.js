const express = require('express');
const router = express.Router();

// Basic auth stubs - replace with real auth (JWT, OAuth, etc.) before production.
const isEmail = (v) => typeof v === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);

router.post('/signup', (req, res) => {
    const { name, email, password } = req.body || {};
    if (!name || name.trim().length < 2) return res.status(400).json({ error: 'Name required' });
    if (!isEmail(email)) return res.status(400).json({ error: 'Valid email required' });
    if (!password || password.length < 6) return res.status(400).json({ error: 'Password must be 6+ characters' });

    // TODO: hash password, persist user, return JWT
    return res.status(201).json({
        success: true,
        user: { name: name.trim(), email: email.trim().toLowerCase() },
        token: 'demo-token-' + Date.now()
    });
});

router.post('/login', (req, res) => {
    const { email, password } = req.body || {};
    if (!isEmail(email)) return res.status(400).json({ error: 'Valid email required' });
    if (!password || password.length < 6) return res.status(400).json({ error: 'Password required' });

    // TODO: verify against stored user
    return res.json({
        success: true,
        user: { email: email.trim().toLowerCase() },
        token: 'demo-token-' + Date.now()
    });
});

module.exports = router;
