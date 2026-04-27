require('dotenv').config();
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const contactRouter = require('./routes/contact');
const authRouter = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 5000;

const allowedOrigins = (process.env.CORS_ORIGIN || '*').split(',').map(o => o.trim());

app.use(cors({
    origin: (origin, cb) => {
        if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) return cb(null, true);
        return cb(new Error('Not allowed by CORS'));
    }
}));
app.use(express.json({ limit: '100kb' }));

app.use('/api', rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 60,
    standardHeaders: true,
    legacyHeaders: false
}));

app.get('/', (_req, res) => res.json({ name: 'BuildifyAi API', status: 'ok' }));
app.get('/health', (_req, res) => res.json({ status: 'healthy', uptime: process.uptime() }));

app.use('/api/contact', contactRouter);
app.use('/api/auth', authRouter);

app.use((err, _req, res, _next) => {
    console.error('[ERROR]', err.message);
    res.status(err.status || 500).json({ error: err.message || 'Server error' });
});

app.listen(PORT, () => {
    console.log(`✅ BuildifyAi API running on http://localhost:${PORT}`);
});
