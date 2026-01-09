import express from 'express';
import bcrypt from 'bcrypt';
import { pool } from '../db.js';
import { z } from 'zod';

const router = express.Router();

const signupSchema = z.object({ username: z.string().min(3), password: z.string().min(6) });

router.post('/signup', async (req, res) => {
  const parsed = signupSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid input' });
  const { username, password } = parsed.data;

  const client = await pool.connect();
  try {
    const existing = await client.query('SELECT id FROM users WHERE username = $1', [username]);
    if (existing.rowCount > 0) return res.status(409).json({ error: 'username taken' });
    const hashed = await bcrypt.hash(password, 10);
    const result = await client.query('INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id', [username, hashed]);
    const id = result.rows[0].id;
    // Set session
    (req.session as any).userId = id;
    res.json({ user: { id, username } });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'internal_error' });
  } finally {
    client.release();
  }
});

const loginSchema = z.object({ username: z.string().min(1), password: z.string().min(1) });

router.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid input' });
  const { username, password } = parsed.data;
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT id, password_hash FROM users WHERE username = $1', [username]);
    if (result.rowCount === 0) return res.status(401).json({ error: 'invalid' });
    const { id, password_hash } = result.rows[0];
    const ok = await bcrypt.compare(password, password_hash);
    if (!ok) return res.status(401).json({ error: 'invalid' });
    (req.session as any).userId = id;
    res.json({ user: { id, username } });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'internal_error' });
  } finally {
    client.release();
  }
});

router.post('/logout', async (req, res) => {
  req.session?.destroy((err) => {
    if (err) return res.status(500).json({ error: 'could_not_logout' });
    res.clearCookie('connect.sid');
    res.json({ ok: true });
  });
});

// Delete account and cascade entries
router.delete('/account', async (req, res) => {
  const userId = (req.session as any).userId;
  if (!userId) return res.status(401).json({ error: 'unauthenticated' });
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM entries WHERE user_id = $1', [userId]);
    await client.query('DELETE FROM users WHERE id = $1', [userId]);
    await client.query('COMMIT');
    req.session?.destroy(() => {});
    res.json({ ok: true });
  } catch (e) {
    await client.query('ROLLBACK');
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'internal' });
  } finally {
    client.release();
  }
});

export default router;
