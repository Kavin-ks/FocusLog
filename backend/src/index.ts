import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import session from 'express-session';
import pgSession from 'connect-pg-simple';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import { pool } from './db.js';
import authRoutes from './routes/auth.js';
import entriesRoutes from './routes/entries.js';

dotenv.config();

const app = express();
app.use(helmet());
app.use(express.json());
app.use(cors({ origin: true, credentials: true }));

const PgStore = pgSession(session as any);

const sessionMiddleware = session({
  store: new PgStore({ pool }),
  secret: process.env.SESSION_SECRET || 'dev-secret',
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    maxAge: 1000 * 60 * 60 * 24 * 30, // 30 days
  },
});

app.use(sessionMiddleware);

const limiter = rateLimit({ windowMs: 1000 * 60, max: 60 });
app.use(limiter);

app.use('/api/auth', authRoutes);
app.use('/api/entries', entriesRoutes);

app.get('/api/me', (req, res) => {
  if (!req.session || !req.session.userId) return res.status(401).json({ error: 'unauthenticated' });
  res.json({ user: { id: req.session.userId } });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Backend listening on ${port}`);
});

export default app;
