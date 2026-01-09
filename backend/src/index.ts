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
import categoriesRoutes from './routes/categories.js';
import reflectionsRoutes from './routes/reflections.js';

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
app.use('/api/categories', categoriesRoutes);
app.use('/api/reflections', reflectionsRoutes);

app.get('/api/me', async (req, res) => {
  if (!req.session || !req.session.userId) return res.status(401).json({ error: 'Please log in to continue.' });
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT id, name, email FROM users WHERE id = $1', [req.session.userId]);
    if (result.rowCount === 0) return res.status(401).json({ error: 'Please log in to continue.' });
    res.json({ user: result.rows[0] });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Backend listening on ${port}`);
});

export default app;
