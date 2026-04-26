const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();
const STORE_PATH = path.join(__dirname, '..', 'data', 'contacts.json');

const ensureStore = () => {
    const dir = path.dirname(STORE_PATH);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    if (!fs.existsSync(STORE_PATH)) fs.writeFileSync(STORE_PATH, '[]', 'utf8');
};

const isEmail = (v) => typeof v === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);

router.post('/', (req, res) => {
    const { name, email, message } = req.body || {};

    if (!name || typeof name !== 'string' || name.trim().length < 2) {
        return res.status(400).json({ error: 'Name is required (min 2 chars)' });
    }
    if (!isEmail(email)) {
        return res.status(400).json({ error: 'Valid email is required' });
    }
    if (!message || typeof message !== 'string' || message.trim().length < 10) {
        return res.status(400).json({ error: 'Message is required (min 10 chars)' });
    }

    const entry = {
        id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
        name: name.trim(),
        email: email.trim().toLowerCase(),
        message: message.trim(),
        createdAt: new Date().toISOString()
    };

    try {
        ensureStore();
        const list = JSON.parse(fs.readFileSync(STORE_PATH, 'utf8'));
        list.push(entry);
        fs.writeFileSync(STORE_PATH, JSON.stringify(list, null, 2), 'utf8');
        console.log('[CONTACT]', entry.email, '-', entry.name);
        return res.status(201).json({ success: true, id: entry.id });
    } catch (err) {
        console.error('[CONTACT][ERROR]', err);
        return res.status(500).json({ error: 'Could not save message' });
    }
});

router.get('/', (_req, res) => {
    try {
        ensureStore();
        const list = JSON.parse(fs.readFileSync(STORE_PATH, 'utf8'));
        return res.json({ count: list.length, items: list });
    } catch {
        return res.json({ count: 0, items: [] });
    }
});

module.exports = router;
